DROP FUNCTION IF EXISTS purchase.post_return
(
    _transaction_master_id                  bigint,
    _office_id                              integer,
    _user_id                                integer,
    _login_id                               bigint,
    _value_date                             date,
    _book_date                              date,
    _store_id								integer,
    _cost_center_id                         integer,
    _supplier_id                            integer,
    _price_type_id                          integer,
    _shipper_id                             integer,
    _reference_number                       national character varying(24),
    _statement_reference                    national character varying(2000),
    _details                                purchase.purchase_detail_type[],
	_invoice_discount						numeric(30, 6)
);

CREATE FUNCTION purchase.post_return
(
    _transaction_master_id                  bigint,
    _office_id                              integer,
    _user_id                                integer,
    _login_id                               bigint,
    _value_date                             date,
    _book_date                              date,
    _store_id								integer,
    _cost_center_id                         integer,
    _supplier_id                            integer,
    _price_type_id                          integer,
    _shipper_id                             integer,
    _reference_number                       national character varying(24),
    _statement_reference                    national character varying(2000),
    _details                                purchase.purchase_detail_type[],
	_invoice_discount						numeric(30, 6)
)
RETURNS bigint
AS
$$
	DECLARE _reversal_tran_id		bigint;
	DECLARE _new_tran_id			bigint;
    DECLARE _book_name              national character varying(50) = 'Purchase Return';
    DECLARE _tran_counter           integer;
    DECLARE _tran_code              national character varying(50);
    DECLARE _checkout_id            bigint;
    DECLARE _grand_total            numeric(30, 6);
    DECLARE _discount_total         numeric(30, 6);
    DECLARE _is_credit              bit;
    DECLARE _default_currency_code  national character varying(12);
    DECLARE _cost_of_goods_sold     numeric(30, 6);
    DECLARE _ck_id                  bigint;
    DECLARE _purchase_id            bigint;
    DECLARE _tax_total              numeric(30, 6);
    DECLARE _tax_account_id         integer;
	DECLARE _fiscal_year_code		national character varying(12);
    DECLARE _can_post_transaction   bit;
    DECLARE _error_message          text;
	DECLARE _original_checkout_id	bigint;
	DECLARE _original_supplier_id	integer;
	DECLARE _difference				purchase.purchase_detail_type;
BEGIN

	SELECT 
		_original_supplier_id = purchase.purchases.supplier_id,
		_original_checkout_id = inventory.checkouts.checkout_id
	FROM purchase.purchases
	INNER JOIN inventory.checkouts
	ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
	INNER JOIN finance.transaction_master
	ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
	AND finance.transaction_master.verification_status_id > 0
	AND finance.transaction_master.transaction_master_id = _transaction_master_id;

	DROP TABLE IF EXISTS _new_checkout_items;
	CREATE TEMPORARY TABLE _new_checkout_items
	(
		store_id					integer,
		transaction_type			national character varying(2),
		item_id						integer,
		quantity					numeric(30, 6),
		unit_id						integer,
        base_quantity				numeric(30, 6),
        base_unit_id                integer,                
		price						numeric(30, 6),
		discount_rate				numeric(30, 6),
		discount					numeric(30, 6),
		shipping_charge				numeric(30, 6)
	) ON COMMIT DROP;
	
        
    IF NOT finance.can_post_transaction(_login_id, _user_id, _office_id, _book_name, _value_date) THEN
        RETURN 0;
    END IF;

    _tax_account_id := finance.get_sales_tax_account_id_by_office_id(_office_id);

    
    IF(_original_supplier_id IS NULL) THEN
        RAISE EXCEPTION '%', 'Invalid transaction.';
    END IF;

    IF(_original_supplier_id != _supplier_id) THEN
        RAISE EXCEPTION '%', 'This supplier is not associated with the purchase you are trying to return.';
    END IF;

    IF(NOT purchase.validate_items_for_return(_transaction_master_id, _details)) THEN
        RETURN 0;
    END IF;


    _default_currency_code      := core.get_currency_code_by_office_id(_office_id);
    _tran_counter               := finance.get_new_transaction_counter(_value_date);
    _tran_code                  := finance.get_transaction_code(_value_date, _office_id, _user_id, _login_id);

    SELECT _purchase_id = purchase.purchases.purchase_id 
    FROM purchase.purchases
    INNER JOIN inventory.checkouts
    ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
    AND inventory.checkouts.transaction_master_id = _transaction_master_id;




    --Returned items are subtracted
    INSERT INTO _new_checkout_items(store_id, item_id, quantity, unit_id, price, discount_rate, shipping_charge)
    SELECT store_id, item_id, quantity *-1, unit_id, price *-1, discount_rate, shipping_charge *-1
    FROM _details;


    --Original items are added
    INSERT INTO _new_checkout_items(store_id, item_id, quantity, unit_id, price, discount_rate, shipping_charge)
    SELECT 
        inventory.checkout_details.store_id, 
        inventory.checkout_details.item_id,
        inventory.checkout_details.quantity,
        inventory.checkout_details.unit_id,
        inventory.checkout_details.price,
        inventory.checkout_details.discount_rate,
        inventory.checkout_details.shipping_charge
    FROM inventory.checkout_details
    WHERE checkout_id = _original_checkout_id;

    UPDATE _new_checkout_items 
    SET
        base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                    = inventory.get_root_unit_id(unit_id),
        discount                        = ROUND(((price * quantity) + shipping_charge) * (discount_rate / 100), 2);


    IF EXISTS
    (
        SELECT item_id, COUNT(DISTINCT unit_id) 
        FROM _new_checkout_items
        GROUP BY item_id
        HAVING COUNT(DISTINCT unit_id) > 1
    ) THEN
        RAISE EXCEPTION '%', 'A return entry must exactly macth the unit of measure provided during purchase.';
    END IF;

    IF EXISTS
    (
        SELECT item_id, COUNT(DISTINCT ABS(price))
        FROM _new_checkout_items
        GROUP BY item_id
        HAVING COUNT(DISTINCT ABS(price)) > 1
    ) THEN
        RAISE EXCEPTION '%', 'A return entry must exactly macth the price provided during purchase.';
    END IF;

    IF EXISTS
    (
        SELECT item_id, COUNT(DISTINCT discount_rate) 
        FROM _new_checkout_items
        GROUP BY item_id
        HAVING COUNT(DISTINCT discount_rate) > 1
    ) THEN
        RAISE EXCEPTION '%', 'A return entry must exactly macth the discount rate provided during purchase.';
    END IF;


    IF EXISTS
    (
        SELECT item_id, COUNT(DISTINCT store_id) 
        FROM _new_checkout_items
        GROUP BY item_id
        HAVING COUNT(DISTINCT store_id) > 1
    ) THEN
        RAISE EXCEPTION '%', 'A return entry must exactly macth the store provided during purchase.';
    END IF;

    INSERT INTO _difference(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, shipping_charge)
    SELECT store_id, 'Dr', item_id, SUM(quantity), unit_id, SUM(price), discount_rate, SUM(shipping_charge)
    FROM _new_checkout_items
    GROUP BY store_id, item_id, unit_id, discount_rate;

        
    DELETE FROM _difference
    WHERE quantity = 0;

    --> REVERSE THE ORIGINAL TRANSACTION
    INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference)
    SELECT _tran_counter, _tran_code, _book_name, _value_date, _book_date, _user_id, _login_id, _office_id, _cost_center_id, _reference_number, _statement_reference
    RETURNING finance.transaction_master.transaction_master_id INTO _reversal_tran_id;


    INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
    SELECT 
        _reversal_tran_id, 
        office_id, 
        value_date, 
        book_date, 
        CASE WHEN tran_type = 'Dr' THEN 'Cr' ELSE 'Dr' END, 
        account_id, 
        _statement_reference, 
        currency_code, 
        amount_in_currency, 
        er, 
        local_currency_code, 
        amount_in_local_currency
    FROM finance.transaction_details
    WHERE finance.transaction_details.transaction_master_id = _transaction_master_id;

    IF EXISTS(SELECT * FROM _difference) THEN
        --> ADD A NEW PURCHASE INVOICE
         _new_tran_id := purchase.post_purchase
            _office_id,
            _user_id,
            _login_id,
            _value_date,
            _book_date,
            _cost_center_id,
            _reference_number,
            _statement_reference,
            _supplier_id,
            _price_type_id,
            _shipper_id,
            _store_id,
            _difference,
            _invoice_discount;
    ELSE
        _tran_counter               := finance.get_new_transaction_counter(_value_date);
        _tran_code                  := finance.get_transaction_code(_value_date, _office_id, _user_id, _login_id);

        INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference)
        SELECT _tran_counter, _tran_code, _book_name, _value_date, _book_date, _user_id, _login_id, _office_id, _cost_center_id, _reference_number, _statement_reference
        RETURNING finance.transaction_master.transaction_master_id INTO _new_tran_id;
    END IF;

    INSERT INTO inventory.checkouts(transaction_book, value_date, book_date, transaction_master_id, office_id, posted_by, discount, taxable_total, tax_rate, tax, nontaxable_total) 
    SELECT _book_name, _value_date, _book_date, _new_tran_id, office_id, _user_id, discount, taxable_total, tax_rate, tax, nontaxable_total
    FROM inventory.checkouts
    WHERE inventory.checkouts.checkout_id = _original_checkout_id
    RETURNING inventory.checkouts.checkout_id INTO _checkout_id;

    INSERT INTO inventory.checkout_details(value_date, book_date, checkout_id, transaction_type, store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, is_taxed, cost_of_goods_sold, discount)
    SELECT _value_date, _book_date, _checkout_id, 
    CASE WHEN transaction_type = 'Dr' THEN 'Cr' ELSE 'Dr' END, 
    store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, is_taxed, cost_of_goods_sold, discount
    FROM inventory.checkout_details
    WHERE inventory.checkout_details.checkout_id = _original_checkout_id;

    INSERT INTO purchase.purchase_returns(purchase_id, checkout_id, supplier_id)
    SELECT _purchase_id, _checkout_id, _supplier_id;

    RETURN _new_tran_id;
END
$$
LANGUAGE plpgsql;


-- SELECT * FROM purchase.post_return
-- (
--     1,
--     1,
--     1,
--     1,
--     finance.get_value_date(1),
--     finance.get_value_date(1),
--     1,
--     1,
--     1,
--     1,
--     '',
--     '',
--     ARRAY[
--         ROW(1, 'Dr', 1, 1, 1,180000, 0, 1200, 200)::purchase.purchase_detail_type,
--         ROW(1, 'Dr', 2, 1, 7,130000, 300, 1200, 30)::purchase.purchase_detail_type,
--         ROW(1, 'Dr', 3, 1, 1,110000, 5000, 1200, 50)::purchase.purchase_detail_type
--         ]
-- );