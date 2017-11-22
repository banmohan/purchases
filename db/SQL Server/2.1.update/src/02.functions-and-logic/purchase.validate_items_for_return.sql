IF OBJECT_ID('purchase.validate_items_for_return') IS NOT NULL
DROP FUNCTION purchase.validate_items_for_return;

GO

CREATE FUNCTION purchase.validate_items_for_return
(
    @transaction_master_id                  bigint, 
    @details                                purchase.purchase_detail_type READONLY
)
RETURNS @result TABLE
(
    is_valid                                bit,
    "error_message"                         national character varying(2000)
)
AS
BEGIN        
    DECLARE @checkout_id                    bigint = 0;
    DECLARE @is_purchase                    bit = 0;
    DECLARE @item_id                        integer = 0;
    DECLARE @factor_to_base_unit            numeric(30, 6);
    DECLARE @returned_in_previous_batch     numeric(30, 6) = 0;
    DECLARE @in_verification_queue          numeric(30, 6) = 0;
    DECLARE @actual_price_in_root_unit      numeric(30, 6) = 0;
    DECLARE @price_in_root_unit             numeric(30, 6) = 0;
    DECLARE @item_in_stock                  numeric(30, 6) = 0;
    DECLARE @error_item_id                  integer;
    DECLARE @error_quantity                 numeric(30, 6);
    DECLARE @error_unit						national character varying(500);
    DECLARE @error_amount                   numeric(30, 6);
    DECLARE @error_message                  national character varying(MAX);

    DECLARE @total_rows                     integer = 0;
    DECLARE @counter                        integer = 0;
    DECLARE @loop_id                        integer;
    DECLARE @loop_item_id                   integer;
    DECLARE @loop_price                     numeric(30, 6);
    DECLARE @loop_base_quantity             numeric(30, 6);
	DECLARE @original_purchase_id			bigint;

    SET @checkout_id                        = inventory.get_checkout_id_by_transaction_master_id(@transaction_master_id);

    SELECT 
		@original_purchase_id = purchase.purchases.purchase_id
	FROM purchase.purchases
    INNER JOIN inventory.checkouts
    ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
    WHERE inventory.checkouts.transaction_master_id = @transaction_master_id;

    INSERT INTO @result(is_valid, "error_message")
    SELECT 0, '';


    DECLARE @details_temp TABLE
    (
        id                  integer IDENTITY,
        store_id            integer,
        item_id             integer,
        item_in_stock       numeric(30, 6),
        quantity            numeric(30, 6),        
        unit_id             integer,
        price               numeric(30, 6),
        discount_rate       numeric(30, 6),
        discount			numeric(30, 6),
        is_taxed            bit,
        shipping_charge     numeric(30, 6),
        root_unit_id        integer,
        base_quantity       numeric(30, 6)
    ) ;

    INSERT INTO @details_temp(store_id, item_id, quantity, unit_id, price, discount_rate, discount, is_taxed, shipping_charge)
    SELECT store_id, item_id, quantity, unit_id, price, discount_rate, discount, is_taxed, shipping_charge
    FROM @details;

    UPDATE @details_temp
    SET 
        item_in_stock = inventory.count_item_in_stock(item_id, unit_id, store_id);
       
    UPDATE @details_temp
    SET root_unit_id = inventory.get_root_unit_id(unit_id);

    UPDATE @details_temp
    SET base_quantity = inventory.convert_unit(unit_id, root_unit_id) * quantity;


    --Determine whether the quantity of the returned item(s) is less than or equal to the same on the actual transaction
    DECLARE @item_summary TABLE
    (
        store_id                    integer,
        item_id                     integer,
        root_unit_id                integer,
        returned_quantity           numeric(30, 6),
        actual_quantity             numeric(30, 6),
        returned_in_previous_batch  numeric(30, 6),
        in_verification_queue       numeric(30, 6)
    ) ;
    
    INSERT INTO @item_summary(store_id, item_id, root_unit_id, returned_quantity)
    SELECT
        store_id,
        item_id,
        root_unit_id, 
        SUM(base_quantity)
    FROM @details_temp
    GROUP BY 
        store_id, 
        item_id,
        root_unit_id;

    UPDATE @item_summary
    SET actual_quantity = 
    (
        SELECT SUM(base_quantity)
        FROM inventory.checkout_details
        WHERE inventory.checkout_details.checkout_id = @checkout_id
        AND inventory.checkout_details.item_id = item_summary.item_id
    )
    FROM @item_summary AS item_summary;

    UPDATE @item_summary
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
                AND purchase.purchase_returns.purchase_id = @original_purchase_id
            )
        )
        AND item_id = item_summary.item_id
    )
    FROM @item_summary AS item_summary;

    UPDATE @item_summary
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
                AND purchase.purchase_returns.purchase_id = @original_purchase_id
            )
        )
        AND item_id = item_summary.item_id
    )
    FROM @item_summary AS item_summary;
    
    --Determine whether the price of the returned item(s) is less than or equal to the same on the actual transaction
    DECLARE @cumulative_pricing TABLE
    (
        item_id                     integer,
        base_price                  numeric(30, 6),
        allowed_returns             numeric(30, 6)
    ) ;

    INSERT INTO @cumulative_pricing
    SELECT 
        item_id,
        MIN(price  / base_quantity * quantity) as base_price,
        SUM(base_quantity) OVER(ORDER BY item_id, base_quantity) as allowed_returns
    FROM inventory.checkout_details 
    WHERE checkout_id = @checkout_id
    GROUP BY item_id, base_quantity;

    IF EXISTS(SELECT 0 FROM @details_temp WHERE store_id IS NULL OR store_id <= 0)
    BEGIN
        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = 'Invalid store.';
        RETURN;
    END;    

    IF EXISTS(SELECT 0 FROM @details_temp WHERE item_id IS NULL OR item_id <= 0)
    BEGIN
        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = 'Invalid item.';

        RETURN;
    END;

    IF EXISTS(SELECT 0 FROM @details_temp WHERE unit_id IS NULL OR unit_id <= 0)
    BEGIN
        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = 'Invalid unit.';
        RETURN;
    END;

    IF EXISTS(SELECT 0 FROM @details_temp WHERE quantity IS NULL OR quantity <= 0)
    BEGIN
        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = 'Invalid quantity.';
        RETURN;
    END;

    IF(@checkout_id  IS NULL OR @checkout_id  <= 0)
    BEGIN
        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = 'Invalid transaction id.';
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT * FROM finance.transaction_master
        WHERE transaction_master_id = @transaction_master_id
        AND verification_status_id > 0
    )
    BEGIN
        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = 'Invalid or rejected transaction.' ;
        RETURN;
    END;
        
    SELECT @item_id = item_id
    FROM @details_temp
    WHERE item_id NOT IN
    (
        SELECT item_id FROM inventory.checkout_details
        WHERE checkout_id = @checkout_id
    );

    IF(COALESCE(@item_id, 0) != 0)
    BEGIN
        SET @error_message = FORMATMESSAGE('The item %s is not associated with this transaction.', inventory.get_item_name_by_item_id(@item_id));

        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = @error_message;
        RETURN;
    END;
	SELECT TOP 1
		@item_id = details_temp.item_id
	FROM @details_temp details_temp
	INNER JOIN inventory.checkout_details
	ON inventory.checkout_details.checkout_id = @checkout_id
	AND details_temp.item_id = inventory.checkout_details.item_id
	WHERE details_temp.is_taxed != inventory.checkout_details.is_taxed;

    IF(COALESCE(@item_id, 0) != 0)
    BEGIN
        SET @error_message = FORMATMESSAGE('Cannot have a different tax during return for the item %s.', inventory.get_item_name_by_item_id(@item_id));

        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = @error_message;
        RETURN;
    END;

    IF NOT EXISTS
    (
        SELECT TOP 1 0 FROM inventory.checkout_details
        INNER JOIN @details_temp AS details_temp
        ON inventory.checkout_details.item_id = details_temp.item_id
        WHERE checkout_id = @checkout_id
        AND inventory.get_root_unit_id(details_temp.unit_id) = inventory.get_root_unit_id(inventory.checkout_details.unit_id)
    )
    BEGIN
        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = 'Invalid or incompatible unit specified.';
        RETURN;
    END;

    SELECT TOP 1
        @error_item_id = item_id,
        @error_quantity = returned_quantity,
		@error_unit = inventory.get_unit_name_by_unit_id(root_unit_id)
    FROM @item_summary
    WHERE returned_quantity + returned_in_previous_batch + in_verification_queue > actual_quantity;

    IF(@error_item_id IS NOT NULL)
    BEGIN
        SET @error_message = FORMATMESSAGE('The returned quantity (%s %s) of %s is greater than actual quantity.', CAST(@error_quantity AS varchar(30)), @error_unit, inventory.get_item_name_by_item_id(@error_item_id));

        UPDATE @result 
        SET 
            is_valid = 0, 
            "error_message" = @error_message;
        RETURN;
    END;


    SELECT @total_rows = MAX(id) FROM @details_temp;
	

    WHILE @counter <= @total_rows
    BEGIN

        SELECT TOP 1
            @loop_id                = id,
            @loop_item_id           = item_id,
            @loop_price             = CAST((price / base_quantity * quantity) AS numeric(30, 6)),
            @loop_base_quantity     = base_quantity
        FROM @details_temp
        WHERE id >= @counter
        ORDER BY id;


        IF(@loop_id IS NOT NULL)
        BEGIN
            SET @counter = @loop_id + 1;        
        END
        ELSE
        BEGIN
            BREAK;
        END;


        SELECT TOP 1
            @error_item_id = item_id,
            @error_amount = base_price
        FROM @cumulative_pricing
        WHERE item_id = @loop_item_id
        AND base_price <  @loop_price
        AND allowed_returns >= @loop_base_quantity;
        

        IF (@error_item_id IS NOT NULL)
        BEGIN
            SET @error_message = FORMATMESSAGE
            (
                'The returned base amount %s of %s cannot be greater than actual amount %s.', 
                CAST(@loop_price AS varchar(30)), 
                inventory.get_item_name_by_item_id(@error_item_id), 
                CAST(@error_amount AS varchar(30))
            );

            UPDATE @result 
            SET 
                is_valid = 0, 
                "error_message" = @error_message;
        RETURN;
        END;
    END;
    
    UPDATE @result 
    SET 
        is_valid = 1, 
        "error_message" = '';
    RETURN;
END;

GO


--DECLARE @details purchase.purchase_detail_type;
--INSERT INTO @details
--SELECT 1, 'Dr', 1, 1, 1,180000, 0, 200, 0 UNION ALL
--SELECT 1, 'Dr', 2, 1, 7,130000, 300, 30, 0 UNION ALL
--SELECT 1, 'Dr', 3, 1, 1,110000, 5000, 50, 0;

--SELECT * FROM purchase.validate_items_for_return
--(
--    6,
--	@details
--);

