-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/01.types-domains-tables-and-constraints/tables-and-constraints.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/02.functions-and-logic/purchase.post_purchase.sql --<--<--
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
    _details                                purchase.purchase_detail_type[],
    _invoice_discount				        numeric(30, 6)
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
    _details                                purchase.purchase_detail_type[],
    _invoice_discount				        numeric(30, 6) DEFAULT(0)
)
RETURNS bigint
AS
$$
    DECLARE _transaction_master_id          bigint;
    DECLARE _checkout_id                    bigint;
    DECLARE _checkout_detail_id             bigint;
    DECLARE _shipping_address_id            integer;
    DECLARE _grand_total                    public.money_strict;
    DECLARE _discount_total                 public.money_strict2;
    DECLARE _payable                        public.money_strict2;
    DECLARE _default_currency_code          national character varying(12);
    DECLARE _is_periodic                    boolean = inventory.is_periodic_inventory(_office_id);
    DECLARE _tran_counter                   integer;
    DECLARE _transaction_code               text;
	DECLARE _taxable_total					numeric(30, 6);
    DECLARE _tax_total                      public.money_strict2;
	DECLARE _nontaxable_total				numeric(30, 6);
    DECLARE _tax_account_id                 integer;
    DECLARE _shipping_charge                public.money_strict2;
    DECLARE _sales_tax_rate                 numeric(30, 6);
    DECLARE _book_name                      national character varying(100) = 'Purchase Entry';
BEGIN
    IF NOT finance.can_post_transaction(_login_id, _user_id, _office_id, _book_name, _value_date) THEN
        RETURN 0;
    END IF;

    _tax_account_id                         := finance.get_sales_tax_account_id_by_office_id(_office_id);

    IF(COALESCE(_supplier_id, 0) = 0) THEN
        RAISE EXCEPTION '%', 'Invalid supplier';
    END IF;
    
    SELECT finance.tax_setups.sales_tax_rate
    INTO _sales_tax_rate 
    FROM finance.tax_setups
    WHERE NOT finance.tax_setups.deleted
    AND finance.tax_setups.office_id = _office_id;

    DROP TABLE IF EXISTS temp_checkout_details CASCADE;
    CREATE TEMPORARY TABLE temp_checkout_details
    (
        id                              	SERIAL PRIMARY KEY,
        checkout_id                     	bigint, 
        store_id                        	integer,
        transaction_type                	national character varying(2),
        item_id                         	integer, 
        quantity                        	public.integer_strict,
        unit_id                         	integer,
        base_quantity                   	numeric(30, 6),
        base_unit_id                    	integer,
        price                           	public.money_strict NOT NULL DEFAULT(0),
        cost_of_goods_sold              	public.money_strict2 NOT NULL DEFAULT(0),
        discount_rate                       numeric(30, 6),
        discount                        	public.money_strict2 NOT NULL DEFAULT(0),
        is_taxable_item                     boolean,
        is_taxed                            boolean,
        amount                              public.money_strict2,
        shipping_charge                     public.money_strict2 NOT NULL DEFAULT(0),
        purchase_account_id             	integer, 
        purchase_discount_account_id    	integer, 
        inventory_account_id            	integer
    ) ON COMMIT DROP;



    INSERT INTO temp_checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, is_taxed, shipping_charge)
    SELECT store_id, 'Dr', item_id, quantity, unit_id, price, discount_rate, discount, is_taxed, shipping_charge
    FROM explode_array(_details);


    UPDATE temp_checkout_details 
    SET
        base_quantity                   	= inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                    	= inventory.get_root_unit_id(unit_id),
        purchase_account_id             	= inventory.get_purchase_account_id(item_id),
        purchase_discount_account_id    	= inventory.get_purchase_discount_account_id(item_id),
        inventory_account_id            	= inventory.get_inventory_account_id(item_id);
    
    UPDATE temp_checkout_details
    SET
        discount                        = COALESCE(ROUND(((price * quantity) + shipping_charge) * (discount_rate / 100), 2), 0)
    WHERE COALESCE(discount, 0) = 0;

    UPDATE temp_checkout_details
    SET
        discount_rate                   = COALESCE(ROUND(100 * discount / ((price * quantity) + shipping_charge), 2), 0)
    WHERE COALESCE(discount_rate, 0) = 0;

    UPDATE temp_checkout_details 
    SET is_taxable_item = inventory.items.is_taxable_item
    FROM inventory.items
    WHERE inventory.items.item_id = temp_checkout_details.item_id;

    UPDATE temp_checkout_details
    SET is_taxed = false
    WHERE NOT is_taxable_item;

    UPDATE temp_checkout_details
    SET amount = (COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0);

    IF EXISTS
    (
        SELECT 1
        FROM temp_checkout_details
        WHERE amount < 0
    ) THEN
        RAISE EXCEPTION '%', 'A line amount cannot be less than zero.';
    END IF;

    IF EXISTS
    (
            SELECT 1 FROM temp_checkout_details AS details
            WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = false
            LIMIT 1
    ) THEN
        RAISE EXCEPTION 'Item/unit mismatch.'
        USING ERRCODE='P3201';
    END IF;
    
    SELECT 
        COALESCE(SUM(CASE WHEN is_taxed = true THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0),
        COALESCE(SUM(CASE WHEN is_taxed = false THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0)
    INTO
        _taxable_total,
        _nontaxable_total
    FROM temp_checkout_details;

    IF(_invoice_discount > _taxable_total) THEN
        RAISE EXCEPTION 'The invoice discount cannot be greater than total taxable amount.';
    END IF;

    SELECT ROUND(SUM(COALESCE(discount, 0)), 2)                         INTO _discount_total FROM temp_checkout_details;
    SELECT ROUND(SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 2)    INTO _grand_total FROM temp_checkout_details;
    SELECT ROUND(SUM(COALESCE(shipping_charge, 0)), 2)                  INTO _shipping_charge FROM temp_checkout_details;

    _tax_total := ROUND((COALESCE(_taxable_total, 0) - COALESCE(_invoice_discount, 0)) * (_sales_tax_rate / 100), 2);
    _grand_total := COALESCE(_taxable_total, 0) + COALESCE(_nontaxable_total, 0) + COALESCE(_tax_total, 0) - COALESCE(_discount_total, 0)  - COALESCE(_invoice_discount, 0);
    _payable := _grand_total;


    DROP TABLE IF EXISTS temp_transaction_details;
    CREATE TEMPORARY TABLE temp_transaction_details
    (
        transaction_master_id       		BIGINT, 
        tran_type                   		national character varying(4), 
        account_id                  		integer, 
        statement_reference         		text, 
        currency_code               		national character varying(12), 
        amount_in_currency          		public.money_strict, 
        local_currency_code         		national character varying(12), 
        er                          		decimal_strict, 
        amount_in_local_currency    		public.money_strict
    ) ON COMMIT DROP;

    _default_currency_code              	:= core.get_currency_code_by_office_id(_office_id);
    _transaction_master_id  				:= nextval(pg_get_serial_sequence('finance.transaction_master', 'transaction_master_id'));
    _checkout_id            				:= nextval(pg_get_serial_sequence('inventory.checkouts', 'checkout_id'));
    _tran_counter           				:= finance.get_new_transaction_counter(_value_date);
    _transaction_code       				:= finance.get_transaction_code(_value_date, _office_id, _user_id, _login_id);

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

    IF(COALESCE(_tax_total, 0) > 0) THEN
        INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', _tax_account_id, _statement_reference, _default_currency_code, _tax_total, 1, _default_currency_code, _tax_total;
    END IF;	

 
    INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
    SELECT 'Cr', inventory.get_account_id_by_supplier_id(_supplier_id), _statement_reference, _default_currency_code, _payable, 1, _default_currency_code, _payable;

    --RAISE EXCEPTION '%', _BOOK_DATE;



    UPDATE temp_transaction_details     SET transaction_master_id   = _transaction_master_id;
    UPDATE temp_checkout_details           SET checkout_id         = _checkout_id;
    
    IF
    (
        SELECT SUM(CASE WHEN tran_type = 'Cr' THEN 1 ELSE -1 END * amount_in_local_currency)
        FROM temp_transaction_details
    ) != 0 THEN
        RAISE EXCEPTION 'Could not balance the Journal Entry. Nothing was saved.';
    END IF;

    INSERT INTO finance.transaction_master(transaction_master_id, transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
    SELECT _transaction_master_id, _tran_counter, _transaction_code, _book_name, _value_date, _book_date, _user_id, _login_id, _office_id, _cost_center_id, _reference_number, _statement_reference;

    
    INSERT INTO finance.transaction_details(value_date, book_date, office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
    SELECT _value_date, _book_date, _office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
    FROM temp_transaction_details
    ORDER BY tran_type DESC;


    INSERT INTO inventory.checkouts(value_date, book_date, checkout_id, transaction_master_id, transaction_book, posted_by, shipper_id, office_id, discount, taxable_total, tax_rate, tax, nontaxable_total)
    SELECT _value_date, _book_date, _checkout_id, _transaction_master_id, _book_name, _user_id, _shipper_id, _office_id, _invoice_discount, _taxable_total, _sales_tax_rate, _tax_total, _nontaxable_total;

    INSERT INTO purchase.purchases(checkout_id, supplier_id, price_type_id)
    SELECT _checkout_id, _supplier_id, _price_type_id;

    INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity, is_taxed)
    SELECT _checkout_id, _value_date, _book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity, is_taxed
    FROM temp_checkout_details;
    
    PERFORM finance.auto_verify(_transaction_master_id, _office_id);
    RETURN _transaction_master_id;
END
$$
LANGUAGE plpgsql;



-- SELECT * FROM purchase.post_purchase(1, 1, 11, finance.get_value_date(1), finance.get_value_date(1), 1, '', '', 1, 1, NULL, 1,
-- ARRAY[
-- ROW(1, 'Dr', 1, 1, 1,180000, 1, 10, 200)::purchase.purchase_detail_type,
-- ROW(1, 'Dr', 2, 1, 7,130000, 300, 10, 30)::purchase.purchase_detail_type,
-- ROW(1, 'Dr', 3, 1, 1,110000, 5000, 10, 50)::purchase.purchase_detail_type]);
-- 


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/02.functions-and-logic/purchase.post_return.sql --<--<--
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
	DECLARE _validate				boolean;
BEGIN
	SELECT validate_returns INTO _validate
	FROM inventory.inventory_setup
	WHERE office_id = @office_id;

	IF(COALESCE(_transaction_master_id, 0) = 0 AND NOT _validate) THEN
        RETURN purchase.post_return_without_validation
        (
            _transaction_master_id                  ,
            _office_id                              ,
            _user_id                                ,
            _login_id                               ,
            _value_date                             ,
            _book_date                              ,
            _store_id								,
            _cost_center_id                         ,
            _supplier_id                            ,
            _price_type_id                          ,
            _shipper_id                             ,
            _reference_number                       ,
            _statement_reference                    ,
            _details                                ,
            _invoice_discount						
        );
	END IF;

	SELECT 
		purchase.purchases.supplier_id,
		inventory.checkouts.checkout_id
    INTO
        _original_supplier_id,
        _original_checkout_id
	FROM purchase.purchases
	INNER JOIN inventory.checkouts
	ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
	INNER JOIN finance.transaction_master
	ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
	AND finance.transaction_master.verification_status_id > 0
	AND finance.transaction_master.transaction_master_id = _transaction_master_id;

	DROP TABLE IF EXISTS _difference;
	CREATE TEMPORARY TABLE _difference
	(
		store_id					integer,
        transaction_type            national character varying(2),
        item_id                     integer,
        quantity                    integer,
        unit_id                     integer,
        price                       public.money_strict,
        discount_rate               public.money_strict2,
        discount                    public.money_strict2,
        shipping_charge             public.money_strict2,
        is_taxed boolean
	) ON COMMIT DROP;

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
		shipping_charge				numeric(30, 6),
		is_taxed					boolean
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

    SELECT purchase.purchases.purchase_id INTO _purchase_id
    FROM purchase.purchases
    INNER JOIN inventory.checkouts
    ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
    AND inventory.checkouts.transaction_master_id = _transaction_master_id;


    --Returned items are subtracted
    INSERT INTO _new_checkout_items(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
    SELECT store_id, transaction_type, item_id, quantity *-1, unit_id, price, discount_rate, discount, shipping_charge, is_taxed
    FROM explode_array(_details);

    --Original items are added
    INSERT INTO _new_checkout_items(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
    SELECT 
        inventory.checkout_details.store_id, 
        inventory.checkout_details.transaction_type,
        inventory.checkout_details.item_id,
        inventory.checkout_details.quantity,
        inventory.checkout_details.unit_id,
        inventory.checkout_details.price,
        inventory.checkout_details.discount_rate,
        inventory.checkout_details.discount,
        inventory.checkout_details.shipping_charge,
        inventory.checkout_details.is_taxed
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


    INSERT INTO _difference(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
    SELECT store_id, 'Dr', item_id, SUM(quantity), unit_id, price, discount_rate, discount, shipping_charge, is_taxed
    FROM _new_checkout_items
    GROUP BY store_id, item_id, unit_id, discount_rate, discount, price, is_taxed, shipping_charge;

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

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/02.functions-and-logic/purchase.post_return_without_validation.sql --<--<--
DROP FUNCTION IF EXISTS purchase.post_return_without_validation
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

CREATE FUNCTION purchase.post_return_without_validation
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
    DECLARE _transaction_master_id          bigint;
    DECLARE _checkout_id                    bigint;
    DECLARE _checkout_detail_id             bigint;
    DECLARE _shipping_address_id            integer;
    DECLARE _grand_total                    public.money_strict;
    DECLARE _discount_total                 public.money_strict2;
    DECLARE _payable                        public.money_strict2;
    DECLARE _default_currency_code          national character varying(12);
    DECLARE _is_periodic                    boolean = inventory.is_periodic_inventory(_office_id);
    DECLARE _tran_counter                   integer;
    DECLARE _transaction_code               text;
	DECLARE _taxable_total					numeric(30, 6);
    DECLARE _tax_total                      public.money_strict2;
	DECLARE _nontaxable_total				numeric(30, 6);
    DECLARE _tax_account_id                 integer;
    DECLARE _shipping_charge                public.money_strict2;
    DECLARE _sales_tax_rate                 numeric(30, 6);
    DECLARE _book_name                      national character varying(100) = 'Purchase Return';
BEGIN
    IF NOT finance.can_post_transaction(_login_id, _user_id, _office_id, _book_name, _value_date) THEN
        RETURN 0;
    END IF;

    _tax_account_id                         := finance.get_sales_tax_account_id_by_office_id(_office_id);

    IF(COALESCE(_supplier_id, 0) = 0) THEN
        RAISE EXCEPTION '%', 'Invalid supplier';
    END IF;
    
    SELECT finance.tax_setups.sales_tax_rate
    INTO _sales_tax_rate 
    FROM finance.tax_setups
    WHERE NOT finance.tax_setups.deleted
    AND finance.tax_setups.office_id = _office_id;

    DROP TABLE IF EXISTS temp_checkout_details CASCADE;
    CREATE TEMPORARY TABLE temp_checkout_details
    (
        id                              	SERIAL PRIMARY KEY,
        checkout_id                     	bigint, 
        store_id                        	integer,
        transaction_type                	national character varying(2),
        item_id                         	integer, 
        quantity                        	public.integer_strict,
        unit_id                         	integer,
        base_quantity                   	numeric(30, 6),
        base_unit_id                    	integer,
        price                           	public.money_strict NOT NULL DEFAULT(0),
        cost_of_goods_sold              	public.money_strict2 NOT NULL DEFAULT(0),
        discount_rate                       numeric(30, 6),
        discount                        	public.money_strict2 NOT NULL DEFAULT(0),
        is_taxable_item                     boolean,
        is_taxed                            boolean,
        amount                              public.money_strict2,
        shipping_charge                     public.money_strict2 NOT NULL DEFAULT(0),
        purchase_account_id             	integer, 
        purchase_discount_account_id    	integer, 
        inventory_account_id            	integer
    ) ON COMMIT DROP;



    INSERT INTO temp_checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, is_taxed, shipping_charge)
    SELECT store_id, 'Cr', item_id, quantity, unit_id, price, discount_rate, discount, is_taxed, shipping_charge
    FROM explode_array(_details);


    UPDATE temp_checkout_details 
    SET
        base_quantity                   	= inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                    	= inventory.get_root_unit_id(unit_id),
        purchase_account_id             	= inventory.get_purchase_account_id(item_id),
        purchase_discount_account_id    	= inventory.get_purchase_discount_account_id(item_id),
        inventory_account_id            	= inventory.get_inventory_account_id(item_id);
    
    UPDATE temp_checkout_details
    SET
        discount                        = COALESCE(ROUND(((price * quantity) + shipping_charge) * (discount_rate / 100), 2), 0)
    WHERE COALESCE(discount, 0) = 0;

    UPDATE temp_checkout_details
    SET
        discount_rate                   = COALESCE(ROUND(100 * discount / ((price * quantity) + shipping_charge), 2), 0)
    WHERE COALESCE(discount_rate, 0) = 0;

    UPDATE temp_checkout_details 
    SET is_taxable_item = inventory.items.is_taxable_item
    FROM inventory.items
    WHERE inventory.items.item_id = temp_checkout_details.item_id;

    UPDATE temp_checkout_details
    SET is_taxed = false
    WHERE NOT is_taxable_item;

    UPDATE temp_checkout_details
    SET amount = (COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0);

    IF EXISTS
    (
        SELECT 1
        FROM temp_checkout_details
        WHERE amount < 0
    ) THEN
        RAISE EXCEPTION '%', 'A line amount cannot be less than zero.';
    END IF;

    IF EXISTS
    (
            SELECT 1 FROM temp_checkout_details AS details
            WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = false
            LIMIT 1
    ) THEN
        RAISE EXCEPTION 'Item/unit mismatch.'
        USING ERRCODE='P3201';
    END IF;
    
    SELECT 
        COALESCE(SUM(CASE WHEN is_taxed = true THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0),
        COALESCE(SUM(CASE WHEN is_taxed = false THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0)
    INTO
        _taxable_total,
        _nontaxable_total
    FROM temp_checkout_details;

    IF(_invoice_discount > _taxable_total) THEN
        RAISE EXCEPTION 'The invoice discount cannot be greater than total taxable amount.';
    END IF;

    SELECT ROUND(SUM(COALESCE(discount, 0)), 2)                         INTO _discount_total FROM temp_checkout_details;
    SELECT ROUND(SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 2)    INTO _grand_total FROM temp_checkout_details;
    SELECT ROUND(SUM(COALESCE(shipping_charge, 0)), 2)                  INTO _shipping_charge FROM temp_checkout_details;

    _tax_total := ROUND((COALESCE(_taxable_total, 0) - COALESCE(_invoice_discount, 0)) * (_sales_tax_rate / 100), 2);
    _grand_total := COALESCE(_taxable_total, 0) + COALESCE(_nontaxable_total, 0) + COALESCE(_tax_total, 0) - COALESCE(_discount_total, 0)  - COALESCE(_invoice_discount, 0);
    _payable := _grand_total;


    DROP TABLE IF EXISTS temp_transaction_details;
    CREATE TEMPORARY TABLE temp_transaction_details
    (
        transaction_master_id       		BIGINT, 
        tran_type                   		national character varying(4), 
        account_id                  		integer, 
        statement_reference         		text, 
        currency_code               		national character varying(12), 
        amount_in_currency          		public.money_strict, 
        local_currency_code         		national character varying(12), 
        er                          		decimal_strict, 
        amount_in_local_currency    		public.money_strict
    ) ON COMMIT DROP;

    _default_currency_code              	:= core.get_currency_code_by_office_id(_office_id);
    _transaction_master_id  				:= nextval(pg_get_serial_sequence('finance.transaction_master', 'transaction_master_id'));
    _checkout_id            				:= nextval(pg_get_serial_sequence('inventory.checkouts', 'checkout_id'));
    _tran_counter           				:= finance.get_new_transaction_counter(_value_date);
    _transaction_code       				:= finance.get_transaction_code(_value_date, _office_id, _user_id, _login_id);

    IF(_is_periodic = true) THEN
        INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', purchase_account_id, _statement_reference, _default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, _default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM temp_checkout_details
        GROUP BY purchase_account_id;
    ELSE
        --Perpetutal Inventory Accounting System
        INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', inventory_account_id, _statement_reference, _default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, _default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM temp_checkout_details
        GROUP BY inventory_account_id;
    END IF;


    IF(_discount_total > 0) THEN
        INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', purchase_discount_account_id, _statement_reference, _default_currency_code, SUM(COALESCE(discount, 0)), 1, _default_currency_code, SUM(COALESCE(discount, 0))
        FROM temp_checkout_details
        GROUP BY purchase_discount_account_id;
    END IF;

    IF(COALESCE(_tax_total, 0) > 0) THEN
        INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', _tax_account_id, _statement_reference, _default_currency_code, _tax_total, 1, _default_currency_code, _tax_total;
    END IF;	

 
    INSERT INTO temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
    SELECT 'Dr', inventory.get_account_id_by_supplier_id(_supplier_id), _statement_reference, _default_currency_code, _payable, 1, _default_currency_code, _payable;

    --RAISE EXCEPTION '%', _BOOK_DATE;



    UPDATE temp_transaction_details     SET transaction_master_id   = _transaction_master_id;
    UPDATE temp_checkout_details           SET checkout_id         = _checkout_id;
    
    IF
    (
        SELECT SUM(CASE WHEN tran_type = 'Cr' THEN 1 ELSE -1 END * amount_in_local_currency)
        FROM temp_transaction_details
    ) != 0 THEN
        RAISE EXCEPTION 'Could not balance the Journal Entry. Nothing was saved.';
    END IF;

    INSERT INTO finance.transaction_master(transaction_master_id, transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
    SELECT _transaction_master_id, _tran_counter, _transaction_code, _book_name, _value_date, _book_date, _user_id, _login_id, _office_id, _cost_center_id, _reference_number, _statement_reference;

    
    INSERT INTO finance.transaction_details(value_date, book_date, office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
    SELECT _value_date, _book_date, _office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
    FROM temp_transaction_details
    ORDER BY tran_type DESC;


    INSERT INTO inventory.checkouts(value_date, book_date, checkout_id, transaction_master_id, transaction_book, posted_by, shipper_id, office_id, discount, taxable_total, tax_rate, tax, nontaxable_total)
    SELECT _value_date, _book_date, _checkout_id, _transaction_master_id, _book_name, _user_id, _shipper_id, _office_id, _invoice_discount, _taxable_total, _sales_tax_rate, _tax_total, _nontaxable_total;

    INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity, is_taxed)
    SELECT _checkout_id, _value_date, _book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity, is_taxed
    FROM temp_checkout_details;

    ALTER TABLE purchase.purchase_returns
    ALTER COLUMN purchase_id DROP NOT NULL;

    INSERT INTO purchase.purchase_returns(purchase_id, checkout_id, supplier_id)
    SELECT NULL, _checkout_id, _supplier_id;
    
    PERFORM finance.auto_verify(_transaction_master_id, _office_id);
    RETURN _transaction_master_id;
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

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/02.functions-and-logic/purchase.post_supplier_payment.sql --<--<--
DROP FUNCTION IF EXISTS purchase.post_supplier_payment
(
    _user_id                                    integer, 
    _office_id                                  integer, 
    _login_id                                   bigint,
    _supplier_id                                integer, 
    _currency_code                              national character varying(12), 
    _cash_account_id                            integer,
    _amount                                     public.money_strict, 
    _exchange_rate_debit                        public.decimal_strict, 
    _exchange_rate_credit                       public.decimal_strict,
    _reference_number                           national character varying(24), 
    _statement_reference                        national character varying(128), 
    _cost_center_id                             integer,
    _cash_repository_id                         integer,
    _posted_date                                date,
    _bank_id                                    integer,
    _bank_instrument_code                       national character varying(128),
    _bank_tran_code                             national character varying(128)
);

DROP FUNCTION IF EXISTS purchase.post_supplier_payment
(
	_value_date									date,
	_book_date									date,
    _user_id                                    integer, 
    _office_id                                  integer, 
    _login_id                                   bigint,
    _supplier_id                                integer, 
    _currency_code                              national character varying(12), 
    _cash_account_id                            integer,
    _amount                                     public.money_strict, 
    _exchange_rate_debit                        public.decimal_strict, 
    _exchange_rate_credit                       public.decimal_strict,
    _reference_number                           national character varying(24), 
    _statement_reference                        national character varying(128), 
    _cost_center_id                             integer,
    _cash_repository_id                         integer,
    _posted_date                                date,
    _bank_id                                    integer,
    _bank_instrument_code                       national character varying(128),
    _bank_tran_code                             national character varying(128)
);

CREATE FUNCTION purchase.post_supplier_payment
(
	_value_date									date,
	_book_date									date,
    _user_id                                    integer, 
    _office_id                                  integer, 
    _login_id                                   bigint,
    _supplier_id                                integer, 
    _currency_code                              national character varying(12),
    _cash_account_id                            integer,
    _amount                                     public.money_strict, 
    _exchange_rate_debit                        public.decimal_strict, 
    _exchange_rate_credit                       public.decimal_strict,
    _reference_number                           national character varying(24), 
    _statement_reference                        national character varying(128), 
    _cost_center_id                             integer,
    _cash_repository_id                         integer,
    _posted_date                                date,
    _bank_id                                    integer,
    _bank_instrument_code                       national character varying(128),
    _bank_tran_code                             national character varying(128)
)
RETURNS bigint
AS
$$
    DECLARE _book                               text;
    DECLARE _transaction_master_id              bigint;
    DECLARE _base_currency_code                 national character varying(12);
    DECLARE _local_currency_code                national character varying(12);
    DECLARE _supplier_account_id                integer;
    DECLARE _debit                              public.money_strict2;
    DECLARE _credit                             public.money_strict2;
    DECLARE _lc_debit                           public.money_strict2;
    DECLARE _lc_credit                          public.money_strict2;
    DECLARE _is_cash                            boolean;
	DECLARE _bank_account_id					integer;
BEGIN
	_bank_account_id					    := finance.get_account_id_by_bank_account_id(_bank_id);    

    IF(finance.can_post_transaction(_login_id, _user_id, _office_id, _book, _value_date) = false) THEN
        RETURN 0;
    END IF;

    IF(_cash_repository_id > 0) THEN
        IF(_posted_date IS NOT NULL OR _bank_id IS NOT NULL OR COALESCE(_bank_instrument_code, '') != '' OR COALESCE(_bank_tran_code, '') != '') THEN
            RAISE EXCEPTION 'Invalid bank transaction information provided.'
            USING ERRCODE='P5111';
        END IF;
        _is_cash                            := true;
    END IF;

    _book                                   := 'Purchase Payment';
    
    _supplier_account_id                    := inventory.get_account_id_by_supplier_id(_supplier_id);    
    _local_currency_code                    := core.get_currency_code_by_office_id(_office_id);
    _base_currency_code                     := inventory.get_currency_code_by_supplier_id(_supplier_id);

    IF(_local_currency_code = _currency_code AND _exchange_rate_debit != 1) THEN
        RAISE EXCEPTION 'Invalid exchange rate. % % %', _local_currency_code, _currency_code, _exchange_rate_debit
        USING ERRCODE='P3055';
    END IF;

    IF(_local_currency_code = _base_currency_code AND _exchange_rate_credit != 1) THEN
        RAISE EXCEPTION 'Invalid exchange rate. % % %', _base_currency_code, _currency_code, _exchange_rate_debit
        USING ERRCODE='P3055';
    END IF;
        
    _debit                                  := _amount;
    _lc_debit                               := _amount * _exchange_rate_debit;

    _credit                                 := _amount * (_exchange_rate_debit/ _exchange_rate_credit);
    _lc_credit                              := _amount * _exchange_rate_debit;
    
    INSERT INTO finance.transaction_master
    (
        transaction_master_id, 
        transaction_counter, 
        transaction_code, 
        book, 
        value_date, 
        book_date, 
        user_id, 
        login_id, 
        office_id, 
        cost_center_id, 
        reference_number, 
        statement_reference
    )
    SELECT 
        nextval(pg_get_serial_sequence('finance.transaction_master', 'transaction_master_id')), 
        finance.get_new_transaction_counter(_value_date), 
        finance.get_transaction_code(_value_date, _office_id, _user_id, _login_id),
        _book,
        _value_date,
        _book_date,
        _user_id,
        _login_id,
        _office_id,
        _cost_center_id,
        _reference_number,
        _statement_reference;


    _transaction_master_id := currval(pg_get_serial_sequence('finance.transaction_master', 'transaction_master_id'));

    --Debit
    IF(_is_cash) THEN
        INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
        SELECT _transaction_master_id, _office_id, _value_date, _book_date, 'Cr', _cash_account_id, _statement_reference, _cash_repository_id, _currency_code, _debit, _local_currency_code, _exchange_rate_debit, _lc_debit, _user_id;
    ELSE
        INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
        SELECT _transaction_master_id, _office_id, _value_date, _book_date, 'Cr', _bank_account_id, _statement_reference, NULL, _currency_code, _debit, _local_currency_code, _exchange_rate_debit, _lc_debit, _user_id;        
    END IF;

    --Credit
    INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
    SELECT _transaction_master_id, _office_id, _value_date, _book_date, 'Dr', _supplier_account_id, _statement_reference, NULL, _base_currency_code, _credit, _local_currency_code, _exchange_rate_credit, _lc_credit, _user_id;
    
    
    INSERT INTO purchase.supplier_payments(transaction_master_id, supplier_id, currency_code, amount, er_debit, er_credit, cash_repository_id, posted_date, bank_id, bank_instrument_code, bank_transaction_code)
    SELECT _transaction_master_id, _supplier_id, _currency_code, _amount,  _exchange_rate_debit, _exchange_rate_credit, _cash_repository_id, _posted_date, _bank_id, _bank_instrument_code, _bank_tran_code;

    PERFORM finance.auto_verify(_transaction_master_id, _office_id);
    RETURN _transaction_master_id;
END
$$
LANGUAGE plpgsql;


-- SELECT * FROM purchase.post_supplier_payment
-- (
--     1, --_user_id                                    integer, 
--     1, --_office_id                                  integer, 
--     1, --_login_id                                   bigint,
--     1, --_supplier_id                                integer, 
--     'USD', --_currency_code                              national character varying(12), 
--     1,--    _cash_account_id                            integer,
--     100, --_amount                                     public.money_strict, 
--     1, --_exchange_rate_debit                        public.decimal_strict, 
--     1, --_exchange_rate_credit                       public.decimal_strict,
--     '', --_reference_number                           national character varying(24), 
--     '', --_statement_reference                        national character varying(128), 
--     1, --_cost_center_id                             integer,
--     1, --_cash_repository_id                         integer,
--     NULL, --_posted_date                                date,
--     NULL, --_bank_account_id                            bigint,
--     NULL, -- _bank_instrument_code                       national character varying(128),
--     NULL -- _bank_tran_code                             national character varying(128),
-- );

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/02.functions-and-logic/purchase.validate_items_for_return.sql --<--<--
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



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/03.menus/menus.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/05.views/purchase.purchase_search_view.sql --<--<--
DROP VIEW IF EXISTS purchase.purchase_search_view;

CREATE VIEW purchase.purchase_search_view
AS
SELECT 
    CAST(finance.transaction_master.transaction_master_id AS varchar(100)) AS tran_id, 
    finance.transaction_master.transaction_code AS tran_code,
    finance.transaction_master.value_date,
    finance.transaction_master.book_date,
    inventory.get_supplier_name_by_supplier_id(purchase.purchases.supplier_id) AS supplier,
	SUM(CASE WHEN finance.transaction_details.tran_type = 'Dr' THEN finance.transaction_details.amount_in_local_currency ELSE 0 END) AS amount,
    finance.transaction_master.reference_number,
    finance.transaction_master.statement_reference,
    account.get_name_by_user_id(finance.transaction_master.user_id) as posted_by,
    core.get_office_name_by_office_id(finance.transaction_master.office_id) as office,
    finance.get_verification_status_name_by_verification_status_id(finance.transaction_master.verification_status_id) as status,
    account.get_name_by_user_id(finance.transaction_master.verified_by_user_id) as verified_by,
    finance.transaction_master.last_verified_on AS verified_on,
    finance.transaction_master.verification_reason AS reason,    
    finance.transaction_master.transaction_ts AS posted_on,
	finance.transaction_master.office_id,
	CASE WHEN inventory.checkouts.nontaxable_total = 0 THEN 'taxable' ELSE 'nontaxable' END AS purchase_type
FROM finance.transaction_master
INNER JOIN inventory.checkouts
ON inventory.checkouts.transaction_master_id = finance.transaction_master.transaction_master_id
INNER JOIN purchase.purchases
ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
INNER JOIN finance.transaction_details
ON finance.transaction_details.transaction_master_id = finance.transaction_master.transaction_master_id
WHERE NOT finance.transaction_master.deleted
GROUP BY
finance.transaction_master.transaction_master_id,
finance.transaction_master.transaction_code,
purchase.purchases.supplier_id,
finance.transaction_master.value_date,
finance.transaction_master.book_date,
finance.transaction_master.reference_number,
finance.transaction_master.statement_reference,
finance.transaction_master.user_id,
finance.transaction_master.office_id,
finance.transaction_master.verification_status_id,
finance.transaction_master.verified_by_user_id,
finance.transaction_master.last_verified_on,
finance.transaction_master.verification_reason,
finance.transaction_master.transaction_ts,
inventory.checkouts.nontaxable_total;



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/99.ownership.sql --<--<--
DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_tables 
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND tableowner <> 'frapid_db_user'
    LOOP
        EXECUTE 'ALTER TABLE '|| this.schemaname || '.' || this.tablename ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT oid::regclass::text as mat_view
    FROM   pg_class
    WHERE  relkind = 'm'
    LOOP
        EXECUTE 'ALTER TABLE '|| this.mat_view ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'ALTER '
        || CASE WHEN p.proisagg THEN 'AGGREGATE ' ELSE 'FUNCTION ' END
        || quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' 
        || pg_catalog.pg_get_function_identity_arguments(p.oid) || ') OWNER TO frapid_db_user;' AS sql
    FROM   pg_catalog.pg_proc p
    JOIN   pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE  NOT n.nspname = ANY(ARRAY['pg_catalog', 'information_schema'])
    LOOP        
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_views
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND viewowner <> 'frapid_db_user'
    LOOP
        EXECUTE 'ALTER VIEW '|| this.schemaname || '.' || this.viewname ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'ALTER SCHEMA ' || nspname || ' OWNER TO frapid_db_user;' AS sql FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname <> 'information_schema'
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;



DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT      'ALTER TYPE ' || n.nspname || '.' || t.typname || ' OWNER TO frapid_db_user;' AS sql
    FROM        pg_type t 
    LEFT JOIN   pg_catalog.pg_namespace n ON n.oid = t.typnamespace 
    WHERE       (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) 
    AND         NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
    AND         typtype NOT IN ('b')
    AND         n.nspname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_tables 
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND tableowner <> 'report_user'
    LOOP
        EXECUTE 'GRANT SELECT ON TABLE '|| this.schemaname || '.' || this.tablename ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT oid::regclass::text as mat_view
    FROM   pg_class
    WHERE  relkind = 'm'
    LOOP
        EXECUTE 'GRANT SELECT ON TABLE '|| this.mat_view  ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'GRANT EXECUTE ON '
        || CASE WHEN p.proisagg THEN 'AGGREGATE ' ELSE 'FUNCTION ' END
        || quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' 
        || pg_catalog.pg_get_function_identity_arguments(p.oid) || ') TO report_user;' AS sql
    FROM   pg_catalog.pg_proc p
    JOIN   pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE  NOT n.nspname = ANY(ARRAY['pg_catalog', 'information_schema'])
    LOOP        
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_views
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND viewowner <> 'report_user'
    LOOP
        EXECUTE 'GRANT SELECT ON '|| this.schemaname || '.' || this.viewname ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'GRANT USAGE ON SCHEMA ' || nspname || ' TO report_user;' AS sql FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname <> 'information_schema'
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


