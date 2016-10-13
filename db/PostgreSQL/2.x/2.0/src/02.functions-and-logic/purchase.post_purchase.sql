DROP FUNCTION IF EXISTS purchase.post_purchase
(
    _office_id                              integer,
    _user_id                                integer,
    _login_id                               bigint,
    _value_date                             date,
    _book_date                              date,
    _cost_center_id                         integer,
    _reference_number                       national character varying(24),
    _statement_reference                    text,
    _supplier_id                            integer,
    _price_type_id                          integer,
    _shipper_id                             integer,
    _store_id                               integer,
    _details                                purchase.purchase_detail_type[]
);


CREATE FUNCTION purchase.post_purchase
(
    _office_id                              integer,
    _user_id                                integer,
    _login_id                               bigint,
    _value_date                             date,
    _book_date                              date,
    _cost_center_id                         integer,
    _reference_number                       national character varying(24),
    _statement_reference                    text,
    _supplier_id                            integer,
    _price_type_id                          integer,
    _shipper_id                             integer,
    _store_id                               integer,
    _details                                purchase.purchase_detail_type[]
)
RETURNS bigint
AS
$$
    DECLARE _transaction_master_id          bigint;
    DECLARE _checkout_id                    bigint;
    DECLARE _checkout_detail_id             bigint;
    DECLARE _shipping_address_id            integer;
    DECLARE _grand_total                    money_strict;
    DECLARE _discount_total                 money_strict2;
    DECLARE _payable                        money_strict2;
    DECLARE _default_currency_code          national character varying(12);
    DECLARE _is_periodic                    boolean = inventory.is_periodic_inventory(_office_id);
    DECLARE _tran_counter                   integer;
    DECLARE _transaction_code               text;
    DECLARE _shipping_charge                money_strict2;
BEGIN
    _default_currency_code                  := core.get_currency_code_by_office_id(_office_id);

    IF(_supplier_id IS NULL) THEN
        RAISE EXCEPTION '%', 'Invalid supplier';
    END IF;
    
    DROP TABLE IF EXISTS temp_checkout_details CASCADE;
    CREATE TEMPORARY TABLE temp_checkout_details
    (
        id                              SERIAL PRIMARY KEY,
        checkout_id                     bigint, 
        tran_type                       national character varying(4), 
        store_id                        integer,
        item_id                         integer, 
        quantity                        integer_strict,
        unit_id                         integer,
        base_quantity                   decimal,
        base_unit_id                    integer,
        price                           money_strict NOT NULL DEFAULT(0),
        cost_of_goods_sold              money_strict2 NOT NULL DEFAULT(0),
        discount                        money_strict2 NOT NULL DEFAULT(0),
        shipping_charge                 money_strict2 NOT NULL DEFAULT(0),
        purchase_account_id             integer, 
        purchase_discount_account_id    integer, 
        inventory_account_id            integer
    ) ON COMMIT DROP;



    INSERT INTO temp_checkout_details(store_id, item_id, quantity, unit_id, price, discount, shipping_charge)
    SELECT store_id, item_id, quantity, unit_id, price, discount, shipping_charge
    FROM explode_array(_details);


    UPDATE temp_checkout_details 
    SET
        tran_type                       = 'Dr',
        base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                    = inventory.get_root_unit_id(unit_id);

    UPDATE temp_checkout_details
    SET
        purchase_account_id             = inventory.get_purchase_account_id(item_id),
        purchase_discount_account_id    = inventory.get_purchase_discount_account_id(item_id),
        inventory_account_id            = inventory.get_inventory_account_id(item_id);    
    
    IF EXISTS
    (
            SELECT 1 FROM temp_checkout_details AS details
            WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = false
            LIMIT 1
    ) THEN
        RAISE EXCEPTION 'Item/unit mismatch.'
        USING ERRCODE='P3201';
    END IF;

    SELECT SUM(COALESCE(discount, 0))                               INTO _discount_total FROM temp_checkout_details;
    SELECT SUM(COALESCE(price, 0) * COALESCE(quantity, 0))          INTO _grand_total FROM temp_checkout_details;
    SELECT SUM(COALESCE(shipping_charge, 0))                        INTO _shipping_charge FROM temp_checkout_details;

    _payable                                := _grand_total - COALESCE(_discount_total, 0) + COALESCE(_shipping_charge, 0);

    DROP TABLE IF EXISTS temp_transaction_details;
    CREATE TEMPORARY TABLE temp_transaction_details
    (
        transaction_master_id       BIGINT, 
        tran_type                   national character varying(4), 
        account_id                  integer, 
        statement_reference         text, 
        currency_code               national character varying(12), 
        amount_in_currency          money_strict, 
        local_currency_code         national character varying(12), 
        er                          decimal_strict, 
        amount_in_local_currency    money_strict
    ) ON COMMIT DROP;

    IF(_is_periodic = true) THEN
        INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', purchase_account_id, _statement_reference, _default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, _default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM temp_checkout_details
        GROUP BY purchase_account_id;
    ELSE
        --Perpetutal Inventory Accounting System
        INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', inventory_account_id, _statement_reference, _default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, _default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM temp_checkout_details
        GROUP BY inventory_account_id;
    END IF;


    IF(_discount_total > 0) THEN
        INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', purchase_discount_account_id, _statement_reference, _default_currency_code, SUM(COALESCE(discount, 0)), 1, _default_currency_code, SUM(COALESCE(discount, 0))
        FROM temp_checkout_details
        GROUP BY purchase_discount_account_id;
    END IF;

    INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
    SELECT 'Cr', inventory.get_account_id_by_supplier_id(_supplier_id), _statement_reference, _default_currency_code, _payable, 1, _default_currency_code, _payable;

    --RAISE EXCEPTION '%', _BOOK_DATE;


    _transaction_master_id  := nextval(pg_get_serial_sequence('finance.transaction_master', 'transaction_master_id'));
    _checkout_id            := nextval(pg_get_serial_sequence('inventory.checkouts', 'checkout_id'));
    _tran_counter           := finance.get_new_transaction_counter(_value_date);
    _transaction_code       := finance.get_transaction_code(_value_date, _office_id, _user_id, _login_id);

    UPDATE temp_transaction_details     SET transaction_master_id   = _transaction_master_id;
    UPDATE temp_checkout_details           SET checkout_id         = _checkout_id;
    
    INSERT INTO finance.transaction_master(transaction_master_id, transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
    SELECT _transaction_master_id, _tran_counter, _transaction_code, 'Purchase', _value_date, _book_date, _user_id, _login_id, _office_id, _cost_center_id, _reference_number, _statement_reference;

    
    INSERT INTO finance.transaction_details(value_date, book_date, office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
    SELECT _value_date, _book_date, _office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
    FROM temp_transaction_details
    ORDER BY tran_type DESC;


    INSERT INTO inventory.checkouts(value_date, book_date, checkout_id, transaction_master_id, transaction_type, transaction_book, posted_by, shipper_id, store_id, office_id)
    SELECT _value_date, _book_date, _checkout_id, _transaction_master_id, 'IN', 'Purchase', _user_id, _shipper_id, _store_id, _office_id;

    INSERT INTO purchase.purchases(checkout_id, supplier_id, price_type_id)
    SELECT _checkout_id, _supplier_id, _price_type_id;

    INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, item_id, price, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity)
    SELECT _checkout_id, _value_date, _book_date, item_id, price, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity
    FROM temp_checkout_details;
    
    PERFORM finance.auto_verify(_transaction_master_id, _office_id);
    RETURN _transaction_master_id;
END
$$
LANGUAGE plpgsql;



SELECT * FROM purchase.post_purchase(1, 1, 1, '2/2/2015', '2/2/2015', 1, '', '', 1, 1, NULL, 1, 
      ARRAY[
                 ROW(1, 1, 1, 1,180000, 0, 200)::purchase.purchase_detail_type,
                 ROW(1, 2, 1, 7,130000, 300, 30)::purchase.purchase_detail_type,
                 ROW(1, 3, 1, 1,110000, 5000, 50)::purchase.purchase_detail_type]);

--SELECT * FROM inventory.suppliers