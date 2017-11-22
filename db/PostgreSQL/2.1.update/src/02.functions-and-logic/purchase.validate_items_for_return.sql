DROP FUNCTION IF EXISTS purchase.validate_items_for_return
(
    _transaction_master_id                  bigint, 
    _details                                purchase.purchase_detail_type[]
);

CREATE FUNCTION purchase.validate_items_for_return
(
    _transaction_master_id                  bigint, 
    _details                                purchase.purchase_detail_type[]
)
RETURNS boolean
AS
$$
    DECLARE _checkout_id                    bigint = 0;
    DECLARE _is_purchase                    boolean = false;
    DECLARE _item_id                        integer = 0;
    DECLARE _factor_to_base_unit            numeric(30, 6);
    DECLARE _returned_in_previous_batch     public.decimal_strict2 = 0;
    DECLARE _in_verification_queue          public.decimal_strict2 = 0;
    DECLARE _actual_price_in_root_unit      public.money_strict2 = 0;
    DECLARE _price_in_root_unit             public.money_strict2 = 0;
    DECLARE _item_in_stock                  public.decimal_strict2 = 0;
    DECLARE _error_item_id                  integer;
    DECLARE _error_quantity                 numeric(30, 6);
    DECLARE _error_unit                     text;
    DECLARE _error_amount                   numeric(30, 6);
    DECLARE _original_purchase_id           bigint;
    DECLARE _original_checkout_id           bigint;
    DECLARE this                            RECORD; 
BEGIN        
    _checkout_id                            := inventory.get_checkout_id_by_transaction_master_id(_transaction_master_id);

    SELECT purchase.purchases.purchase_id
    INTO _original_purchase_id
    FROM purchase.purchases
    INNER JOIN inventory.checkouts
    ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
    WHERE inventory.checkouts.transaction_master_id = _transaction_master_id;
    
    DROP TABLE IF EXISTS details_temp;
    CREATE TEMPORARY TABLE details_temp
    (
        store_id            integer,
        item_id             integer,
        item_in_stock       numeric(30, 6),
        quantity            public.decimal_strict,        
        unit_id             integer,
        price               public.money_strict,
        discount_rate       public.decimal_strict2,
        discount            money_strict2,
		is_taxed			boolean,
        shipping_charge     money_strict2,
        root_unit_id        integer,
        base_quantity       numeric(30, 6)
    ) ON COMMIT DROP;

    INSERT INTO details_temp(store_id, item_id, quantity, unit_id, price, discount_rate, discount, is_taxed, shipping_charge)
    SELECT store_id, item_id, quantity, unit_id, price, discount_rate, discount, is_taxed, shipping_charge
    FROM explode_array(_details);

    UPDATE details_temp
    SET 
        item_in_stock = inventory.count_item_in_stock(item_id, unit_id, store_id);
       
    UPDATE details_temp
    SET root_unit_id = inventory.get_root_unit_id(unit_id);

    UPDATE details_temp
    SET base_quantity = inventory.convert_unit(unit_id, root_unit_id) * quantity;


    --Determine whether the quantity of the returned item(s) is less than or equal to the same on the actual transaction
    DROP TABLE IF EXISTS item_summary_temp;
    CREATE TEMPORARY TABLE item_summary_temp
    (
        store_id                    integer,
        item_id                     integer,
        root_unit_id                integer,
        returned_quantity           numeric(30, 6),
        actual_quantity             numeric(30, 6),
        returned_in_previous_batch  numeric(30, 6),
        in_verification_queue       numeric(30, 6)
    ) ON COMMIT DROP;
    
    INSERT INTO item_summary_temp(store_id, item_id, root_unit_id, returned_quantity)
    SELECT
        store_id,
        item_id,
        root_unit_id, 
        SUM(base_quantity)
    FROM details_temp
    GROUP BY 
        store_id, 
        item_id,
        root_unit_id;

    UPDATE item_summary_temp
    SET actual_quantity = 
    (
        SELECT SUM(base_quantity)
        FROM inventory.checkout_details
        WHERE inventory.checkout_details.checkout_id = _checkout_id
        AND inventory.checkout_details.item_id = item_summary_temp.item_id
    );

    UPDATE item_summary_temp
    SET returned_in_previous_batch = 
    (
        SELECT 
            COALESCE(SUM(base_quantity), 0)
        FROM inventory.checkout_details
        WHERE checkout_id IN
        (
            SELECT checkout_id
            FROM inventory.checkouts
            INNER JOIN finance.transaction_master
            ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
            WHERE finance.transaction_master.verification_status_id > 0
            AND inventory.checkouts.transaction_master_id IN 
            (
                SELECT inventory.checkouts.transaction_master_id
                FROM inventory.checkouts
                INNER JOIN purchase.purchase_returns
                ON purchase.purchase_returns.checkout_id = inventory.checkouts.checkout_id
                INNER JOIN finance.transaction_master
                ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id                
            WHERE finance.transaction_master.verification_status_id > 0
                AND purchase.purchase_returns.purchase_id = _original_purchase_id
            )
        )
        AND item_id = item_summary_temp.item_id
    );

    UPDATE item_summary_temp
    SET in_verification_queue = 
    (
        SELECT 
            COALESCE(SUM(base_quantity), 0)
        FROM inventory.checkout_details
        WHERE checkout_id IN
        (
            SELECT checkout_id
            FROM inventory.checkouts
            INNER JOIN finance.transaction_master
            ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
            WHERE finance.transaction_master.verification_status_id > 0
            AND inventory.checkouts.transaction_master_id IN 
            (
                SELECT inventory.checkouts.transaction_master_id
                FROM inventory.checkouts
                INNER JOIN purchase.purchase_returns
                ON purchase.purchase_returns.checkout_id = inventory.checkouts.checkout_id
                INNER JOIN finance.transaction_master
                ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id                
            WHERE finance.transaction_master.verification_status_id = 0
                AND purchase.purchase_returns.purchase_id = _original_purchase_id
            )
        )
        AND item_id = item_summary_temp.item_id
    );
    
    --Determine whether the price of the returned item(s) is less than or equal to the same on the actual transaction
    DROP TABLE IF EXISTS cumulative_pricing_temp;
    CREATE TEMPORARY TABLE cumulative_pricing_temp
    (
        item_id                     integer,
        base_price                  numeric(30, 6),
        allowed_returns             numeric(30, 6)
    ) ON COMMIT DROP;

    INSERT INTO cumulative_pricing_temp
    SELECT 
        item_id,
        MIN(price  / base_quantity * quantity) as base_price,
        SUM(base_quantity) OVER(ORDER BY item_id, base_quantity) as allowed_returns
    FROM inventory.checkout_details 
    WHERE checkout_id = _checkout_id
    GROUP BY item_id, base_quantity;

    IF EXISTS(SELECT 0 FROM details_temp WHERE store_id IS NULL OR store_id <= 0) THEN
        RAISE EXCEPTION 'Invalid store.'
        USING ERRCODE='P3012';
    END IF;

    IF EXISTS(SELECT 0 FROM details_temp WHERE item_id IS NULL OR item_id <= 0) THEN
        RAISE EXCEPTION 'Invalid item.'
        USING ERRCODE='P3051';
    END IF;

    IF EXISTS(SELECT 0 FROM details_temp WHERE unit_id IS NULL OR unit_id <= 0) THEN
        RAISE EXCEPTION 'Invalid unit.'
        USING ERRCODE='P3052';
    END IF;

    IF EXISTS(SELECT 0 FROM details_temp WHERE quantity IS NULL OR quantity <= 0) THEN
        RAISE EXCEPTION 'Invalid quantity.'
        USING ERRCODE='P3301';
    END IF;

    IF(_checkout_id  IS NULL OR _checkout_id  <= 0) THEN
        RAISE EXCEPTION 'Invalid transaction id.'
        USING ERRCODE='P3302';
    END IF;

    IF NOT EXISTS
    (
        SELECT * FROM finance.transaction_master
        WHERE transaction_master_id = _transaction_master_id
        AND verification_status_id > 0
    ) THEN
        RAISE EXCEPTION 'Invalid or rejected transaction.'
        USING ERRCODE='P5301';
    END IF;
        
    SELECT item_id INTO _item_id
    FROM details_temp
    WHERE item_id NOT IN
    (
        SELECT item_id FROM inventory.checkout_details
        WHERE checkout_id = _checkout_id
    )
    LIMIT 1;

    IF(COALESCE(_item_id, 0) != 0) THEN
        RAISE EXCEPTION '%', format('The item %1$s is not associated with this transaction.', inventory.get_item_name_by_item_id(_item_id))
        USING ERRCODE='P4020';
    END IF;

    SELECT
		details_temp.item_id
    INTO
        _item_id
	FROM details_temp
	INNER JOIN inventory.checkout_details
	ON inventory.checkout_details.checkout_id = _checkout_id
	AND details_temp.item_id = inventory.checkout_details.item_id
	WHERE details_temp.is_taxed != inventory.checkout_details.is_taxed
	LIMIT 1;

    IF(COALESCE(_item_id, 0) != 0) THEN
        RAISE EXCEPTION '%', FORMAT('Cannot have a different tax during return for the item %1$s.', inventory.get_item_name_by_item_id(_item_id));
    END IF;

    IF NOT EXISTS
    (
        SELECT * FROM inventory.checkout_details
        INNER JOIN details_temp
        ON inventory.checkout_details.item_id = details_temp.item_id
        WHERE checkout_id = _checkout_id
        AND inventory.get_root_unit_id(details_temp.unit_id) = inventory.get_root_unit_id(inventory.checkout_details.unit_id)
        LIMIT 1
    ) THEN
        RAISE EXCEPTION 'Invalid or incompatible unit specified'
        USING ERRCODE='P3053';
    END IF;

    SELECT 
        item_id,
        returned_quantity,
        inventory.get_unit_name_by_unit_id(root_unit_id)
    INTO
        _error_item_id,
        _error_quantity,
        _error_unit
    FROM item_summary_temp
    WHERE returned_quantity + returned_in_previous_batch + in_verification_queue > actual_quantity
    LIMIT 1;

    IF(_error_item_id IS NOT NULL) THEN    
        RAISE EXCEPTION 'The returned quantity (% %) of % is greater than actual quantity.', _error_quantity, _error_unit, inventory.get_item_name_by_item_id(_error_item_id)
        USING ERRCODE='P5203';
    END IF;

    FOR this IN
    SELECT item_id, base_quantity, (price / base_quantity * quantity)::numeric(30, 6) as price
    FROM details_temp
    LOOP
        SELECT 
            item_id,
            base_price
        INTO
            _error_item_id,
            _error_amount
        FROM cumulative_pricing_temp
        WHERE item_id = this.item_id
        AND base_price <  this.price
        AND allowed_returns >= this.base_quantity
        LIMIT 1;
        
        IF (_error_item_id IS NOT NULL) THEN
            RAISE EXCEPTION 'The returned base amount % of % cannot be greater than actual amount %.', this.price, inventory.get_item_name_by_item_id(_error_item_id), _error_amount
            USING ERRCODE='P5204';

            RETURN FALSE;
        END IF;
    END LOOP;
    
    RETURN TRUE;
END
$$
LANGUAGE plpgsql;

-- SELECT * FROM purchase.validate_items_for_return
-- (
--     6,
--     ARRAY[
--         ROW(1, 'Dr', 1, 1, 1,180000, 0, 200, 0)::purchase.purchase_detail_type,
--         ROW(1, 'Dr', 2, 1, 7,130000, 300, 30, 0)::purchase.purchase_detail_type,
--         ROW(1, 'Dr', 3, 1, 1,110000, 5000, 50, 0)::purchase.purchase_detail_type
--     ]
-- );

