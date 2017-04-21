-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/01.types-domains-tables-and-constraints/tables-and-constraints.sql --<--<--
DROP SCHEMA IF EXISTS purchase CASCADE;
CREATE SCHEMA purchase;

CREATE TABLE purchase.price_types
(
    price_type_id                           SERIAL PRIMARY KEY,
    price_type_code                         national character varying(24) NOT NULL,
    price_type_name                         national character varying(500) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX price_types_price_type_code_uix
ON purchase.price_types(UPPER(price_type_code))
WHERE NOT deleted;

CREATE UNIQUE INDEX price_types_price_type_name_uix
ON purchase.price_types(UPPER(price_type_name))
WHERE NOT deleted;

CREATE TABLE purchase.item_cost_prices
(   
    item_cost_price_id                      BIGSERIAL PRIMARY KEY,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    supplier_id                             integer REFERENCES inventory.suppliers,
    lead_time_in_days                       integer NOT NULL DEFAULT(0),
    includes_tax                            boolean NOT NULL
                                            CONSTRAINT item_cost_prices_includes_tax_df   
                                            DEFAULT(false),
    price                                   public.money_strict NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE UNIQUE INDEX item_cost_prices_item_id_unit_id_supplier_id_uix
ON purchase.item_cost_prices(item_id, unit_id, supplier_id)
WHERE NOT deleted;


CREATE TABLE purchase.supplierwise_selling_prices
(
	selling_price_id						BIGSERIAL PRIMARY KEY,
	supplier_id								integer NOT NULL REFERENCES inventory.suppliers,
	unit_id									integer NOT NULL REFERENCES inventory.units,
	price									numeric(30, 6),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE TABLE purchase.purchases
(
    purchase_id                             BIGSERIAL PRIMARY KEY,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
	price_type_id							integer NOT NULL REFERENCES purchase.price_types
);


CREATE TABLE purchase.purchase_returns
(
    purchase_return_id                      BIGSERIAL PRIMARY KEY,
    purchase_id                             bigint NOT NULL REFERENCES purchase.purchases,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers   
);


CREATE TABLE purchase.quotations
(
    quotation_id                            BIGSERIAL PRIMARY KEY,
    value_date                              date NOT NULL,
	expected_delivery_date					date NOT NULL,
    transaction_timestamp                   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT(NOW()),
    supplier_id                             integer NOT NULL REFERENCES inventory.customers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
	shipper_id								integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
	terms									national character varying(500),
    internal_memo                           national character varying(500),
	taxable_total 							numeric(30, 6) NOT NULL DEFAULT(0),
	discount 								numeric(30, 6) NOT NULL DEFAULT(0),
	tax_rate 								numeric(30, 6) NOT NULL DEFAULT(0),
	tax 									numeric(30, 6) NOT NULL DEFAULT(0),
	nontaxable_total 						numeric(30, 6) NOT NULL DEFAULT(0),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE TABLE purchase.quotation_details
(
    quotation_detail_id                     BIGSERIAL PRIMARY KEY,
    quotation_id                            bigint NOT NULL REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   public.money_strict NOT NULL,
	discount_rate							decimal(30, 6) NOT NULL,
    discount                           		public.decimal_strict2 NOT NULL DEFAULT(0),    
	is_taxed 								boolean NOT NULL,
    shipping_charge                         public.money_strict2 NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                public.decimal_strict2 NOT NULL
);


CREATE TABLE purchase.orders
(
    order_id                                BIGSERIAL PRIMARY KEY,
    quotation_id                            bigint REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
	expected_delivery_date					date NOT NULL,
    transaction_timestamp                   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT(NOW()),
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
	shipper_id								integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                   national character varying(500),
    internal_memo                           national character varying(500),
	taxable_total 							numeric(30, 6) NOT NULL DEFAULT(0),
	discount 								numeric(30, 6) NOT NULL DEFAULT(0),
	tax_rate 								numeric(30, 6) NOT NULL DEFAULT(0),
	tax 									numeric(30, 6) NOT NULL DEFAULT(0),
	nontaxable_total 						numeric(30, 6) NOT NULL DEFAULT(0),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                TIMESTAMP WITH TIME ZONE DEFAULT(NOW()),
	deleted									boolean DEFAULT(false)
);

CREATE TABLE purchase.order_details
(
    order_detail_id                         BIGSERIAL PRIMARY KEY,
    order_id                                bigint NOT NULL REFERENCES purchase.orders,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   public.money_strict NOT NULL,
	discount_rate							decimal(30, 6) NOT NULL,
    discount                           		public.decimal_strict2 NOT NULL DEFAULT(0),    
	is_taxed 								boolean NOT NULL,
    shipping_charge                         public.money_strict2 NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                public.decimal_strict2 NOT NULL
);

CREATE TABLE purchase.supplier_payments
(
    payment_id                              BIGSERIAL PRIMARY KEY,
    transaction_master_id                   bigint NOT NULL REFERENCES finance.transaction_master,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    currency_code                           national character varying(12) NOT NULL REFERENCES core.currencies,
    er_debit                                decimal_strict NOT NULL,
    er_credit                               decimal_strict NOT NULL,
    cash_repository_id                      integer NULL REFERENCES finance.cash_repositories,
    posted_date                             date NULL,
    tender                                  public.money_strict2,
    change                                  public.money_strict2,
    amount                                  public.money_strict2,
    bank_id					                integer REFERENCES finance.bank_accounts,
	bank_instrument_code			        national character varying(500),
	bank_transaction_code			        national character varying(500),
	check_number                            national character varying(100),
    check_date                              date,
    check_bank_name                         national character varying(1000),
    check_amount                            public.money_strict2
);

CREATE INDEX supplier_payments_transaction_master_id_inx
ON purchase.supplier_payments(transaction_master_id);

CREATE INDEX supplier_payments_supplier_id_inx
ON purchase.supplier_payments(supplier_id);

CREATE INDEX supplier_payments_currency_code_inx
ON purchase.supplier_payments(currency_code);

CREATE INDEX supplier_payments_cash_repository_id_inx
ON purchase.supplier_payments(cash_repository_id);

CREATE INDEX supplier_payments_posted_date_inx
ON purchase.supplier_payments(posted_date);



CREATE TYPE purchase.purchase_detail_type
AS
(
    store_id            integer,
	transaction_type	national character varying(2),
    item_id           	integer,
    quantity            public.integer_strict,
    unit_id           	integer,
    price               public.money_strict,
    discount_rate       public.money_strict2,
    tax                 public.money_strict2,
    shipping_charge     public.money_strict2
);



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.get_item_cost_price.sql --<--<--
DROP FUNCTION IF EXISTS purchase.get_item_cost_price(_item_id integer, _supplier_id bigint, _unit_id integer);

CREATE FUNCTION purchase.get_item_cost_price(_item_id integer, _supplier_id bigint, _unit_id integer)
RETURNS public.money_strict2
STABLE
AS
$$
    DECLARE _price              public.money_strict2;
    DECLARE _costing_unit_id    integer;
    DECLARE _factor             decimal(30, 6);
  
BEGIN
    --Fist pick the catalog price which matches all these fields:
    --Item, Customer Type, Price Type, and Unit.
    --This is the most effective price.
    SELECT 
        purchase.item_cost_prices.price, 
        purchase.item_cost_prices.unit_id
    INTO 
        _price,
        _costing_unit_id
    FROM purchase.item_cost_prices
    WHERE purchase.item_cost_prices.item_id=_item_id
    AND purchase.item_cost_prices.supplier_id =_supplier_id
    AND purchase.item_cost_prices.unit_id = _unit_id
    AND NOT purchase.item_cost_prices.deleted;


    IF(_costing_unit_id IS NULL) THEN
        --We do not have a cost price of this item for the unit supplied.
        --Let's see if this item has a price for other units.
        SELECT 
            purchase.item_cost_prices.price, 
            purchase.item_cost_prices.unit_id
        INTO 
            _price, 
            _costing_unit_id
        FROM purchase.item_cost_prices
        WHERE purchase.item_cost_prices.item_id=_item_id
        AND purchase.item_cost_prices.supplier_id =_supplier_id
	AND NOT purchase.item_cost_prices.deleted;
    END IF;

    
    IF(_price IS NULL) THEN
        --This item does not have cost price defined in the catalog.
        --Therefore, getting the default cost price from the item definition.
        SELECT 
            cost_price, 
            unit_id
        INTO 
            _price, 
            _costing_unit_id
        FROM inventory.items
        WHERE inventory.items.item_id = _item_id
		AND NOT inventory.items.deleted;
    END IF;

        --Get the unitary conversion factor if the requested unit does not match with the price defition.
    _factor := inventory.convert_unit(_unit_id, _costing_unit_id);
    RETURN _price * _factor;
END
$$
LANGUAGE plpgsql;

--SELECT * FROM purchase.get_item_cost_price(6, 1, 7);


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.get_order_view.sql --<--<--
DROP FUNCTION IF EXISTS purchase.get_order_view
(
    _user_id                        integer,
    _office_id                      integer,
    _supplier                       national character varying(500),
    _from                           date,
    _to                             date,
    _expected_from                  date,
    _expected_to                    date,
    _id                             bigint,
    _reference_number               national character varying(500),
    _internal_memo                  national character varying(500),
    _terms                          national character varying(500),
    _posted_by                      national character varying(500),
    _office                         national character varying(500)
);

CREATE FUNCTION purchase.get_order_view
(
    _user_id                        integer,
    _office_id                      integer,
    _supplier                       national character varying(500),
    _from                           date,
    _to                             date,
    _expected_from                  date,
    _expected_to                    date,
    _id                             bigint,
    _reference_number               national character varying(500),
    _internal_memo                  national character varying(500),
    _terms                          national character varying(500),
    _posted_by                      national character varying(500),
    _office                         national character varying(500)
)
RETURNS TABLE
(
    id                              bigint,
    supplier                        national character varying(500),
    value_date                      date,
    expected_date                   date,
    reference_number                national character varying(24),
    terms                           national character varying(500),
    internal_memo                   national character varying(500),
    posted_by                       national character varying(500),
    office                          national character varying(500),
    transaction_ts                  TIMESTAMP WITH TIME ZONE
)
AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE office_cte(office_id) AS 
    (
        SELECT _office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    SELECT 
        purchase.orders.order_id,
        inventory.get_supplier_name_by_supplier_id(purchase.orders.supplier_id),
        purchase.orders.value_date,
        purchase.orders.expected_delivery_date,
        purchase.orders.reference_number,
        purchase.orders.terms,
        purchase.orders.internal_memo,
        account.get_name_by_user_id(purchase.orders.user_id)::national character varying(500) AS posted_by,
        core.get_office_name_by_office_id(office_id)::national character varying(500) AS office,
        purchase.orders.transaction_timestamp
    FROM purchase.orders
    WHERE 1 = 1
    AND purchase.orders.value_date BETWEEN _from AND _to
    AND purchase.orders.expected_delivery_date BETWEEN _expected_from AND _expected_to
    AND purchase.orders.office_id IN (SELECT office_id FROM office_cte)
    AND (COALESCE(_id, 0) = 0 OR _id = purchase.orders.order_id)
    AND COALESCE(LOWER(purchase.orders.reference_number), '') LIKE '%' || LOWER(_reference_number) || '%' 
    AND COALESCE(LOWER(purchase.orders.internal_memo), '') LIKE '%' || LOWER(_internal_memo) || '%' 
    AND COALESCE(LOWER(purchase.orders.terms), '') LIKE '%' || LOWER(_terms) || '%' 
    AND LOWER(inventory.get_customer_name_by_customer_id(purchase.orders.supplier_id)) LIKE '%' || LOWER(_supplier) || '%' 
    AND LOWER(account.get_name_by_user_id(purchase.orders.user_id)) LIKE '%' || LOWER(_posted_by) || '%' 
    AND LOWER(core.get_office_name_by_office_id(purchase.orders.office_id)) LIKE '%' || LOWER(_office) || '%' 
    AND NOT purchase.orders.deleted;
END
$$
LANGUAGE plpgsql;


--SELECT * FROM purchase.get_order_view(1,1,'', '11/27/2010','11/27/2016','1-1-2000','1-1-2020', null,'','','','', '');


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.get_price_type_id_by_price_type_code.sql --<--<--
DROP FUNCTION IF EXISTS purchase.get_price_type_id_by_price_type_code(_price_type_code national character varying(24));

CREATE FUNCTION purchase.get_price_type_id_by_price_type_code(_price_type_code national character varying(24))
RETURNS integer
AS
$$
BEGIN
    RETURN purchase.price_types.price_type_id
    FROM purchase.price_types
    WHERE purchase.price_types.price_type_code = _price_type_code;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.get_price_type_id_by_price_type_name.sql --<--<--
DROP FUNCTION IF EXISTS purchase.get_price_type_id_by_price_type_name(_price_type_name national character varying(24));

CREATE FUNCTION purchase.get_price_type_id_by_price_type_name(_price_type_name national character varying(24))
RETURNS integer
AS
$$
BEGIN
    RETURN purchase.price_types.price_type_id
    FROM purchase.price_types
    WHERE purchase.price_types.price_type_name = _price_type_name;
END
$$
LANGUAGE plpgsql;

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.get_quotation_view.sql --<--<--
DROP FUNCTION IF EXISTS purchase.get_quotation_view
(
    _user_id                        integer,
    _office_id                      integer,
    _supplier                       national character varying(500),
    _from                           date,
    _to                             date,
    _expected_from                  date,
    _expected_to                    date,
    _id                             bigint,
    _reference_number               national character varying(500),
    _internal_memo                  national character varying(500),
    _terms                          national character varying(500),
    _posted_by                      national character varying(500),
    _office                         national character varying(500)
);

CREATE FUNCTION purchase.get_quotation_view
(
    _user_id                        integer,
    _office_id                      integer,
    _supplier                       national character varying(500),
    _from                           date,
    _to                             date,
    _expected_from                  date,
    _expected_to                    date,
    _id                             bigint,
    _reference_number               national character varying(500),
    _internal_memo                  national character varying(500),
    _terms                          national character varying(500),
    _posted_by                      national character varying(500),
    _office                         national character varying(500)
)
RETURNS TABLE
(
    id                              bigint,
    supplier                        national character varying(500),
    value_date                      date,
    expected_date                   date,
    reference_number                national character varying(24),
    terms                           national character varying(500),
    internal_memo                   national character varying(500),
    posted_by                       national character varying(500),
    office                          national character varying(500),
    transaction_ts                  TIMESTAMP WITH TIME ZONE
)
AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE office_cte(office_id) AS 
    (
        SELECT _office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    SELECT 
        purchase.quotations.quotation_id,
        inventory.get_supplier_name_by_supplier_id(purchase.quotations.supplier_id),
        purchase.quotations.value_date,
        purchase.quotations.expected_delivery_date,
        purchase.quotations.reference_number,
        purchase.quotations.terms,
        purchase.quotations.internal_memo,
        account.get_name_by_user_id(purchase.quotations.user_id)::national character varying(500) AS posted_by,
        core.get_office_name_by_office_id(office_id)::national character varying(500) AS office,
        purchase.quotations.transaction_timestamp
    FROM purchase.quotations
    WHERE 1 = 1
    AND purchase.quotations.value_date BETWEEN _from AND _to
    AND purchase.quotations.expected_delivery_date BETWEEN _expected_from AND _expected_to
    AND purchase.quotations.office_id IN (SELECT office_id FROM office_cte)
    AND (COALESCE(_id, 0) = 0 OR _id = purchase.quotations.quotation_id)
    AND COALESCE(LOWER(purchase.quotations.reference_number), '') LIKE '%' || LOWER(_reference_number) || '%' 
    AND COALESCE(LOWER(purchase.quotations.internal_memo), '') LIKE '%' || LOWER(_internal_memo) || '%' 
    AND COALESCE(LOWER(purchase.quotations.terms), '') LIKE '%' || LOWER(_terms) || '%' 
    AND LOWER(inventory.get_customer_name_by_customer_id(purchase.quotations.supplier_id)) LIKE '%' || LOWER(_supplier) || '%' 
    AND LOWER(account.get_name_by_user_id(purchase.quotations.user_id)) LIKE '%' || LOWER(_posted_by) || '%' 
    AND LOWER(core.get_office_name_by_office_id(purchase.quotations.office_id)) LIKE '%' || LOWER(_office) || '%' 
    AND NOT purchase.quotations.deleted;
END
$$
LANGUAGE plpgsql;


--SELECT * FROM purchase.get_quotation_view(1,1,'', '11/27/2010','11/27/2016','1-1-2000','1-1-2020', null,'','','','', '');


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.get_supplier_id_by_supplier_code.sql --<--<--
DROP FUNCTION IF EXISTS purchase.get_supplier_id_by_supplier_code(text);

CREATE FUNCTION purchase.get_supplier_id_by_supplier_code(text)
RETURNS bigint
AS
$$
BEGIN
    RETURN
    (
        SELECT
            supplier_id
        FROM
            inventory.suppliers
        WHERE 
            inventory.suppliers.supplier_code=$1
	AND NOT
	    inventory.suppliers.deleted
    );
END
$$
LANGUAGE plpgsql;



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.post_purchase.sql --<--<--
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

    IF(_supplier_id IS NULL) THEN
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
        base_quantity                   	decimal(30, 6),
        base_unit_id                    	integer,
        price                           	public.money_strict NOT NULL DEFAULT(0),
        cost_of_goods_sold              	public.money_strict2 NOT NULL DEFAULT(0),
        discount_rate                       decimal(30, 6),
        discount                        	public.money_strict2 NOT NULL DEFAULT(0),
        is_taxable_item                     boolean,
        amount                              public.money_strict2,
        shipping_charge                     public.money_strict2 NOT NULL DEFAULT(0),
        purchase_account_id             	integer, 
        purchase_discount_account_id    	integer, 
        inventory_account_id            	integer
    ) ON COMMIT DROP;



    INSERT INTO temp_checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, shipping_charge)
    SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, shipping_charge
    FROM explode_array(_details);


    UPDATE temp_checkout_details 
    SET
        base_quantity                   	= inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                    	= inventory.get_root_unit_id(unit_id),
        purchase_account_id             	= inventory.get_purchase_account_id(item_id),
        purchase_discount_account_id    	= inventory.get_purchase_discount_account_id(item_id),
        inventory_account_id            	= inventory.get_inventory_account_id(item_id),
        discount                            = ROUND(((price * quantity) + shipping_charge) * (discount_rate / 100), 2);
    
    UPDATE temp_checkout_details 
    SET is_taxable_item = inventory.items.is_taxable_item
    FROM inventory.items
    WHERE inventory.items.item_id = temp_checkout_details.item_id;

    UPDATE temp_checkout_details
    SET amount = (COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0);

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
        COALESCE(SUM(CASE WHEN is_taxable_item = true THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0),
        COALESCE(SUM(CASE WHEN is_taxable_item = false THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0)
    INTO
        _taxable_total,
        _nontaxable_total
    FROM temp_checkout_details;

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

    INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity)
    SELECT _checkout_id, _value_date, _book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity
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


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.post_return.sql --<--<--
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
	_invoice_discount						decimal(30, 6)
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
	_invoice_discount						decimal(30, 6)
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
    DECLARE _grand_total            decimal(30, 6);
    DECLARE _discount_total         decimal(30, 6);
    DECLARE _is_credit              bit;
    DECLARE _default_currency_code  national character varying(12);
    DECLARE _cost_of_goods_sold     decimal(30, 6);
    DECLARE _ck_id                  bigint;
    DECLARE _purchase_id            bigint;
    DECLARE _tax_total              decimal(30, 6);
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
		quantity					decimal(30, 6),
		unit_id						integer,
        base_quantity				decimal(30, 6),
        base_unit_id                integer,                
		price						decimal(30, 6),
		discount_rate				decimal(30, 6),
		discount					decimal(30, 6),
		shipping_charge				decimal(30, 6)
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

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.post_supplier_payment.sql --<--<--
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

CREATE FUNCTION purchase.post_supplier_payment
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
)
RETURNS bigint
AS
$$
    DECLARE _value_date                         date;
    DECLARE _book_date                          date;
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
    _value_date                             := finance.get_value_date(_office_id);
    _book_date                              := _value_date;
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
        RAISE EXCEPTION 'Invalid exchange rate.'
        USING ERRCODE='P3055';
    END IF;

    IF(_base_currency_code = _currency_code AND _exchange_rate_credit != 1) THEN
        RAISE EXCEPTION 'Invalid exchange rate.'
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
    SELECT _transaction_master_id, _supplier_id, _currency_code, _amount,  _exchange_rate_debit, _exchange_rate_credit, _cash_repository_id, _posted_date, _bank_account_id, _bank_instrument_code, _bank_tran_code;

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

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/02.functions-and-logic/purchase.validate_items_for_return.sql --<--<--
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
    DECLARE _error_quantity                 decimal(30, 6);
    DECLARE _error_unit                     text;
    DECLARE _error_amount                   decimal(30, 6);
    DECLARE _original_purchase_id           bigint;
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
        tax                 money_strict2,
        shipping_charge     money_strict2,
        root_unit_id        integer,
        base_quantity       numeric(30, 6)
    ) ON COMMIT DROP;

    INSERT INTO details_temp(store_id, item_id, quantity, unit_id, price, discount_rate, tax, shipping_charge)
    SELECT store_id, item_id, quantity, unit_id, price, discount_rate, tax, shipping_charge
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



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/03.menus/menus.sql --<--<--
DELETE FROM auth.menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'MixERP.Purchases'
);

DELETE FROM auth.group_menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'MixERP.Purchases'
);

DELETE FROM core.menus
WHERE app_name = 'MixERP.Purchases';


SELECT * FROM core.create_app('MixERP.Purchases', 'Purchase', 'Purchase', '1.0', 'MixERP Inc.', 'December 1, 2015', 'newspaper yellow', '/dashboard/purchase/tasks/entry', NULL::text[]);

SELECT * FROM core.create_menu('MixERP.Purchases', 'Tasks', 'Tasks', '', 'lightning', '');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchaseEntry', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'write', 'Tasks');
SELECT * FROM core.create_menu('MixERP.Purchases', 'SupplierPayment', 'Supplier Payment', '/dashboard/purchase/tasks/payment', 'write', 'Tasks');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchaseReturns', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'minus', 'Tasks');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchaseQuotations', 'Purchase Quotations', '/dashboard/purchase/tasks/quotation', 'newspaper', 'Tasks');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchaseOrders', 'Purchase Orders', '/dashboard/purchase/tasks/order', 'file text outline', 'Tasks');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchaseVerification', 'Purchase Verification', '/dashboard/purchase/tasks/entry/verification', 'checkmark', 'Tasks');
SELECT * FROM core.create_menu('MixERP.Purchases', 'SupplierPaymentVerification', 'Supplier Payment Verification', '/dashboard/purchase/tasks/payment/verification', 'checkmark', 'Tasks');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchaseReturnVerification', 'Purchase Return Verification', '/dashboard/purchase/tasks/return/verification', 'minus', 'Tasks');

SELECT * FROM core.create_menu('MixERP.Purchases', 'Setup', 'Setup', 'square outline', 'configure', '');
SELECT * FROM core.create_menu('MixERP.Purchases', 'Suppliers', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PriceTypes', 'Price Types', '/dashboard/purchase/setup/price-types', 'dollar', 'Setup');
SELECT * FROM core.create_menu('MixERP.Purchases', 'CostPrices', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'rupee', 'Setup');
SELECT * FROM core.create_menu('MixERP.Purchases', 'SupplierwiseCostPrices', 'Supplierwise Cost Prices', '/dashboard/purchase/setup/cost-prices/supplier', 'rupee', 'Setup');

SELECT * FROM core.create_menu('MixERP.Purchases', 'Reports', 'Reports', '', 'block layout', '');
SELECT * FROM core.create_menu('MixERP.Purchases', 'AccountPayables', 'Account Payables', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/AccountPayables.xml', 'spy', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'TopSuppliers', 'Top Suppliers', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/TopSuppliers.xml', 'spy', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchasesByOffice', 'Purchases by Office', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PurchasesByOffice.xml', 'building', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'LowInventoryProducts', 'Low Inventory Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/LowInventory.xml', 'warning', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'OutOfStockProducts', 'Out of Stock Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/OutOfStock.xml', 'remove circle', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'SupplierContacts', 'Supplier Contacts', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/SupplierContacts.xml', 'remove circle', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchaseSummary', 'Purchase Summary', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PurchaseSummary.xml', 'grid layout icon', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PurchaseDiscountStatus', 'Purchase Discount Status', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PurchaseDiscountStatus.xml', 'shopping basket icon', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'PaymentJournalSummary', 'Payment Journal Summary Report', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PaymentJournalSummary.xml', 'angle double right icon', 'Reports');
SELECT * FROM core.create_menu('MixERP.Purchases', 'AccountPayableVendor', 'Account Payable Vendor Report', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/AccountPayableVendor.xml', 'external share icon', 'Reports');

SELECT * FROM auth.create_app_menu_policy
(
    'Admin', 
    core.get_office_id_by_office_name('Default'), 
    'MixERP.Purchases',
    '{*}'::text[]
);



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/04.default-values/01.default-values.sql --<--<--
INSERT INTO purchase.price_types(price_type_code, price_type_name)
SELECT 'RET',   'Retail' UNION ALL
SELECT 'WHO',   'Wholesale';


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/05.reports/purchase.get_account_payables_report.sql --<--<--
DROP FUNCTION IF EXISTS purchase.get_account_payables_report(_office_id integer, _from date);

CREATE FUNCTION purchase.get_account_payables_report(_office_id integer, _from date)
RETURNS TABLE
(
    office_id                   integer,
    office_name                 national character varying(500),
    account_id                  integer,
    account_number              national character varying(24),
    account_name                national character varying(500),
    previous_period             numeric(30, 6),
    current_period              numeric(30, 6),
    total_amount                numeric(30, 6)
)
AS
$$
BEGIN
    DROP TABLE IF EXISTS _results;
    
    CREATE TEMPORARY TABLE _results
    (
        office_id                   integer,
        office_name                 national character varying(500),
        account_id                  integer,
        account_number              national character varying(24),
        account_name                national character varying(500),
        previous_period             numeric(30, 6),
        current_period              numeric(30, 6),
        total_amount                numeric(30, 6)
    ) ON COMMIT DROP;

    INSERT INTO _results(account_id, office_name, office_id)
    SELECT DISTINCT inventory.suppliers.account_id, core.get_office_name_by_office_id(_office_id), _office_id FROM inventory.suppliers;

    UPDATE _results
    SET
        account_number  = finance.accounts.account_number,
        account_name    = finance.accounts.account_name
    FROM finance.accounts
    WHERE finance.accounts.account_id = _results.account_id;


    UPDATE _results AS results
    SET previous_period = 
    (        
        SELECT 
            SUM
            (
                CASE WHEN finance.verified_transaction_view.tran_type = 'Cr' THEN
                finance.verified_transaction_view.amount_in_local_currency
                ELSE
                finance.verified_transaction_view.amount_in_local_currency * -1
                END                
            ) AS amount
        FROM finance.verified_transaction_view
        WHERE finance.verified_transaction_view.value_date < _from
        AND finance.verified_transaction_view.office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        AND finance.verified_transaction_view.account_id IN
        (
            SELECT * FROM finance.get_account_ids(results.account_id)
        )
    );

    UPDATE _results AS results
    SET current_period = 
    (        
        SELECT 
            SUM
            (
                CASE WHEN finance.verified_transaction_view.tran_type = 'Cr' THEN
                finance.verified_transaction_view.amount_in_local_currency
                ELSE
                finance.verified_transaction_view.amount_in_local_currency * -1
                END                
            ) AS amount
        FROM finance.verified_transaction_view
        WHERE finance.verified_transaction_view.value_date >= _from
        AND finance.verified_transaction_view.office_id IN (SELECT * FROM core.get_office_ids(_office_id))
        AND finance.verified_transaction_view.account_id IN
        (
            SELECT * FROM finance.get_account_ids(results.account_id)
        )
    );

    UPDATE _results
    SET total_amount = COALESCE(_results.previous_period, 0) + COALESCE(_results.current_period, 0);
    
	DELETE FROM _results
	WHERE COALESCE(previous_period, 0) = 0
	AND COALESCE(current_period, 0) = 0
	AND COALESCE(total_amount, 0) = 0;

    RETURN QUERY
    SELECT * FROM _results;
END
$$
LANGUAGE plpgsql;


--SELECT * FROM purchase.get_account_payables_report(1, '1-1-2000');


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/05.scrud-views/purchase.item_cost_price_scrud_view.sql --<--<--
DROP VIEW IF EXISTS purchase.item_cost_price_scrud_view;

CREATE VIEW purchase.item_cost_price_scrud_view
AS
SELECT
    purchase.item_cost_prices.item_cost_price_id,
    purchase.item_cost_prices.item_id,
    inventory.items.item_code || ' (' || inventory.items.item_name || ')' AS item,
    purchase.item_cost_prices.unit_id,
    inventory.units.unit_code || ' (' || inventory.units.unit_name || ')' AS unit,
    purchase.item_cost_prices.supplier_id,
    inventory.suppliers.supplier_code || ' (' || inventory.suppliers.supplier_name || ')' AS supplier,
    purchase.item_cost_prices.lead_time_in_days,
    purchase.item_cost_prices.includes_tax,
    purchase.item_cost_prices.price
FROM purchase.item_cost_prices
INNER JOIN inventory.items
ON inventory.items.item_id = purchase.item_cost_prices.item_id
INNER JOIN inventory.units
ON inventory.units.unit_id = purchase.item_cost_prices.unit_id
INNER JOIN inventory.suppliers
ON inventory.suppliers.supplier_id = purchase.item_cost_prices.supplier_id
WHERE NOT purchase.item_cost_prices.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/05.views/purchase.item_view.sql --<--<--
DROP VIEW IF EXISTS purchase.item_view;

CREATE VIEW purchase.item_view
AS
SELECT
    inventory.items.item_id,
    inventory.items.item_code,
    inventory.items.item_name,
    inventory.items.is_taxable_item,
    inventory.items.barcode,
    inventory.items.item_group_id,
    inventory.item_groups.item_group_name,
    inventory.item_types.item_type_id,
    inventory.item_types.item_type_name,
    inventory.items.brand_id,
    inventory.brands.brand_name,
    inventory.items.preferred_supplier_id,
    inventory.items.unit_id,
    array_to_string(inventory.get_associated_unit_list(inventory.items.unit_id), ',') AS valid_units,
    inventory.units.unit_code,
    inventory.units.unit_name,
    inventory.items.hot_item,
    inventory.items.cost_price,
    inventory.items.cost_price_includes_tax,
    inventory.items.photo
FROM inventory.items
INNER JOIN inventory.item_groups
ON inventory.item_groups.item_group_id = inventory.items.item_group_id
INNER JOIN inventory.item_types
ON inventory.item_types.item_type_id = inventory.items.item_type_id
INNER JOIN inventory.brands
ON inventory.brands.brand_id = inventory.items.brand_id
INNER JOIN inventory.units
ON inventory.units.unit_id = inventory.items.unit_id
WHERE NOT inventory.items.deleted
AND inventory.items.allow_purchase
AND inventory.items.maintain_inventory;

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/05.views/purchase.order_search_view.sql --<--<--
DROP VIEW IF EXISTS purchase.order_search_view;

CREATE VIEW purchase.order_search_view
AS
SELECT
	purchase.orders.order_id,
	inventory.get_supplier_name_by_supplier_id(purchase.orders.supplier_id) AS supplier,
	purchase.orders.value_date,
	purchase.orders.expected_delivery_date AS expected_date,
	COALESCE(purchase.orders.taxable_total, 0) + 
	COALESCE(purchase.orders.tax, 0) + 
	COALESCE(purchase.orders.nontaxable_total, 0) - 
	COALESCE(purchase.orders.discount, 0) AS total_amount,
	COALESCE(purchase.orders.reference_number, '') AS reference_number,
	COALESCE(purchase.orders.terms, '') AS terms,
	COALESCE(purchase.orders.internal_memo, '') AS memo,
	account.get_name_by_user_id(purchase.orders.user_id) AS posted_by,
	core.get_office_name_by_office_id(purchase.orders.office_id) AS office,
	purchase.orders.transaction_timestamp AS posted_on,
	purchase.orders.office_id,
	purchase.orders.discount,
	purchase.orders.tax	
FROM purchase.orders;


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/05.views/purchase.purchase_search_view.sql --<--<--
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
	finance.transaction_master.office_id
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
finance.transaction_master.transaction_ts;



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/05.views/purchase.quotation_search_view.sql --<--<--
DROP VIEW IF EXISTS purchase.quotation_search_view;

CREATE VIEW purchase.quotation_search_view
AS
SELECT
	purchase.quotations.quotation_id,
	inventory.get_supplier_name_by_supplier_id(purchase.quotations.supplier_id) AS supplier,
	purchase.quotations.value_date,
	purchase.quotations.expected_delivery_date AS expected_date,
	COALESCE(purchase.quotations.taxable_total, 0) + 
	COALESCE(purchase.quotations.tax, 0) + 
	COALESCE(purchase.quotations.nontaxable_total, 0) - 
	COALESCE(purchase.quotations.discount, 0) AS total_amount,
	COALESCE(purchase.quotations.reference_number, '') AS reference_number,
	COALESCE(purchase.quotations.terms, '') AS terms,
	COALESCE(purchase.quotations.internal_memo, '') AS memo,
	account.get_name_by_user_id(purchase.quotations.user_id) AS posted_by,
	core.get_office_name_by_office_id(purchase.quotations.office_id) AS office,
	purchase.quotations.transaction_timestamp AS posted_on,
	purchase.quotations.office_id,
	purchase.quotations.discount,
	purchase.quotations.tax	
FROM purchase.quotations;


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/05.views/purchase.return_search_view.sql --<--<--
DROP VIEW IF EXISTS purchase.return_search_view;

CREATE VIEW purchase.return_search_view
AS
SELECT
	finance.transaction_master.transaction_master_id::text AS tran_id,
	finance.transaction_master.transaction_code AS tran_code,
	purchase.purchase_returns.supplier_id,
	inventory.get_supplier_name_by_supplier_id(purchase.purchase_returns.supplier_id) AS supplier,
	SUM(CASE WHEN finance.transaction_details.tran_type = 'Dr' THEN finance.transaction_details.amount_in_local_currency ELSE 0 END) AS amount,
	finance.transaction_master.value_date,
	finance.transaction_master.book_date,
	COALESCE(finance.transaction_master.reference_number, '') AS reference_number,
	COALESCE(finance.transaction_master.statement_reference, '') AS statement_reference,
	account.get_name_by_user_id(finance.transaction_master.user_id) AS posted_by,
	core.get_office_name_by_office_id(finance.transaction_master.office_id) AS office,
	finance.get_verification_status_name_by_verification_status_id(finance.transaction_master.verification_status_id) AS status,
	COALESCE(account.get_name_by_user_id(finance.transaction_master.verified_by_user_id), '') AS verified_by,
	finance.transaction_master.last_verified_on,
	finance.transaction_master.verification_reason AS reason,
	finance.transaction_master.office_id
FROM purchase.purchase_returns
INNER JOIN inventory.checkouts
ON inventory.checkouts.checkout_id = purchase.purchase_returns.checkout_id
INNER JOIN finance.transaction_master
ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
INNER JOIN finance.transaction_details
ON finance.transaction_details.transaction_master_id = finance.transaction_master.transaction_master_id
WHERE NOT finance.transaction_master.deleted
GROUP BY
finance.transaction_master.transaction_master_id,
finance.transaction_master.transaction_code,
purchase.purchase_returns.supplier_id,
finance.transaction_master.value_date,
finance.transaction_master.book_date,
finance.transaction_master.reference_number,
finance.transaction_master.statement_reference,
finance.transaction_master.user_id,
finance.transaction_master.office_id,
finance.transaction_master.verification_status_id,
finance.transaction_master.verified_by_user_id,
finance.transaction_master.last_verified_on,
finance.transaction_master.verification_reason;


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/05.views/purchase.supplier_payment_search_view.sql --<--<--
DROP VIEW IF EXISTS purchase.supplier_payment_search_view;

CREATE VIEW purchase.supplier_payment_search_view
AS
SELECT
	purchase.supplier_payments.transaction_master_id::text AS tran_id,
	finance.transaction_master.transaction_code AS tran_code,
	purchase.supplier_payments.supplier_id,
	inventory.get_supplier_name_by_supplier_id(purchase.supplier_payments.supplier_id) AS supplier,
	COALESCE(purchase.supplier_payments.amount, purchase.supplier_payments.check_amount, COALESCE(purchase.supplier_payments.tender, 0) - COALESCE(purchase.supplier_payments.change, 0)) AS amount,
	finance.transaction_master.value_date,
	finance.transaction_master.book_date,
	COALESCE(finance.transaction_master.reference_number, '') AS reference_number,
	COALESCE(finance.transaction_master.statement_reference, '') AS statement_reference,
	account.get_name_by_user_id(finance.transaction_master.user_id) AS posted_by,
	core.get_office_name_by_office_id(finance.transaction_master.office_id) AS office,
	finance.get_verification_status_name_by_verification_status_id(finance.transaction_master.verification_status_id) AS status,
	COALESCE(account.get_name_by_user_id(finance.transaction_master.verified_by_user_id), '') AS verified_by,
	finance.transaction_master.last_verified_on,
	finance.transaction_master.verification_reason AS reason,
	finance.transaction_master.office_id
FROM purchase.supplier_payments
INNER JOIN finance.transaction_master
ON purchase.supplier_payments.transaction_master_id = finance.transaction_master.transaction_master_id
WHERE NOT finance.transaction_master.deleted;


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/99.ownership.sql --<--<--
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


