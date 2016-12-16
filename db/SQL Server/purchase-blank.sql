-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/01.types-domains-tables-and-constraints/tables-and-constraints.sql --<--<--
EXECUTE dbo.drop_schema 'purchase';
GO
CREATE SCHEMA purchase;
GO


--TODO: CREATE UNIQUE INDEXES

CREATE TABLE purchase.price_types
(
    price_type_id                           integer IDENTITY PRIMARY KEY,
    price_type_code                         national character varying(24) NOT NULL,
    price_type_name                         national character varying(500) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);


CREATE TABLE purchase.item_cost_prices
(   
    item_cost_price_id                      bigint IDENTITY PRIMARY KEY,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    supplier_id                             integer REFERENCES inventory.suppliers,
    lead_time_in_days                       integer NOT NULL DEFAULT(0),
    includes_tax                            bit NOT NULL
                                            CONSTRAINT item_cost_prices_includes_tax_df   
                                            DEFAULT(0),
    price                                   decimal(30, 6) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);



CREATE TABLE purchase.purchases
(
    purchase_id                             bigint IDENTITY PRIMARY KEY,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    price_type_id                            integer NOT NULL REFERENCES purchase.price_types
);


CREATE TABLE purchase.purchase_returns
(
    purchase_return_id                      bigint IDENTITY PRIMARY KEY,
    purchase_id                             bigint NOT NULL REFERENCES purchase.purchases,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers   
);


CREATE TABLE purchase.quotations
(
    quotation_id                            bigint IDENTITY PRIMARY KEY,
    value_date                              date NOT NULL,
    expected_delivery_date                    date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETDATE()),
    supplier_id                             integer NOT NULL REFERENCES inventory.customers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
    shipper_id                                integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                    national character varying(500),
    internal_memo                           national character varying(500),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE purchase.quotation_details
(
    quotation_detail_id                     bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint NOT NULL REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   decimal(30, 6) NOT NULL,
    discount_rate                           decimal(30, 6) NOT NULL DEFAULT(0),    
    tax                                     decimal(30, 6) NOT NULL DEFAULT(0),    
    shipping_charge                         decimal(30, 6) NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                decimal(30, 6) NOT NULL
);


CREATE TABLE purchase.orders
(
    order_id                                bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    expected_delivery_date                    date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETDATE()),
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
    shipper_id                                integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                   national character varying(500),
    internal_memo                           national character varying(500),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE purchase.order_details
(
    order_detail_id                         bigint IDENTITY PRIMARY KEY,
    order_id                                bigint NOT NULL REFERENCES purchase.orders,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   decimal(30, 6) NOT NULL,
    discount_rate                           decimal(30, 6) NOT NULL DEFAULT(0),    
    tax                                     decimal(30, 6) NOT NULL DEFAULT(0),    
    shipping_charge                         decimal(30, 6) NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                decimal(30, 6) NOT NULL
);

CREATE TYPE purchase.purchase_detail_type
AS TABLE
(
    store_id            integer,
    transaction_type    national character varying(2),
    item_id             integer,
    quantity            decimal(30, 6),
    unit_id             integer,
    price               decimal(30, 6),
    discount            decimal(30, 6),
    tax                 decimal(30, 6),
    shipping_charge     decimal(30, 6)
);



GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_item_cost_price.sql --<--<--
IF OBJECT_ID('purchase.get_item_cost_price') IS NOT NULL
DROP FUNCTION purchase.get_item_cost_price;

GO

CREATE FUNCTION purchase.get_item_cost_price(@item_id integer, @supplier_id bigint, @unit_id integer)
RETURNS decimal(30, 6)
AS  
BEGIN
    DECLARE @price              decimal(30, 6);
    DECLARE @costing_unit_id    integer;
    DECLARE @factor             decimal(30, 6);

    --Fist pick the catalog price which matches all these fields:
    --Item, Customer Type, Price Type, and Unit.
    --This is the most effective price.
    SELECT 
        @price = purchase.item_cost_prices.price, 
        @costing_unit_id = purchase.item_cost_prices.unit_id
    FROM purchase.item_cost_prices
    WHERE purchase.item_cost_prices.item_id = @item_id
    AND purchase.item_cost_prices.supplier_id = @supplier_id
    AND purchase.item_cost_prices.unit_id = @unit_id
    AND purchase.item_cost_prices.deleted = 0;


    IF(@costing_unit_id IS NULL)
    BEGIN
        --We do not have a cost price of this item for the unit supplied.
        --Let's see if this item has a price for other units.
        SELECT 
            @price = purchase.item_cost_prices.price, 
            @costing_unit_id = purchase.item_cost_prices.unit_id
        FROM purchase.item_cost_prices
        WHERE purchase.item_cost_prices.item_id = @item_id
        AND purchase.item_cost_prices.supplier_id = @supplier_id
        AND purchase.item_cost_prices.deleted = 0;
    END;

    
    IF(@price IS NULL)
    BEGIN
        --This item does not have cost price defined in the catalog.
        --Therefore, getting the default cost price from the item definition.
        SELECT 
            @price = cost_price, 
            @costing_unit_id = unit_id
        FROM inventory.items
        WHERE inventory.items.item_id = @item_id
        AND inventory.items.deleted = 0;
    END;

        --Get the unitary conversion factor if the requested unit does not match with the price defition.
    SET @factor = inventory.convert_unit(@unit_id, @costing_unit_id);
    RETURN @price * @factor;
END;



--SELECT * FROM purchase.get_item_cost_price(6, 1, 7);


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_order_view.sql --<--<--
IF OBJECT_ID('purchase.get_order_view') IS NOT NULL
DROP FUNCTION purchase.get_order_view;

GO

CREATE FUNCTION purchase.get_order_view
(
    @user_id                        integer,
    @office_id                      integer,
    @supplier                       national character varying(500),
    @from                           date,
    @to                             date,
    @expected_from                  date,
    @expected_to                    date,
    @id                             bigint,
    @reference_number               national character varying(500),
    @internal_memo                  national character varying(500),
    @terms                          national character varying(500),
    @posted_by                      national character varying(500),
    @office                         national character varying(500)
)
RETURNS @result TABLE
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
    transaction_ts                  DATETIMEOFFSET
)
AS

BEGIN
    WITH office_cte(office_id) AS 
    (
        SELECT @office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    INSERT INTO @result
    SELECT 
        purchase.orders.order_id,
        inventory.get_supplier_name_by_supplier_id(purchase.orders.supplier_id),
        purchase.orders.value_date,
        purchase.orders.expected_delivery_date,
        purchase.orders.reference_number,
        purchase.orders.terms,
        purchase.orders.internal_memo,
        account.get_name_by_user_id(purchase.orders.user_id) AS posted_by,
        core.get_office_name_by_office_id(office_id) AS office,
        purchase.orders.transaction_timestamp
    FROM purchase.orders
    WHERE 1 = 1
    AND purchase.orders.value_date BETWEEN @from AND @to
    AND purchase.orders.expected_delivery_date BETWEEN @expected_from AND @expected_to
    AND purchase.orders.office_id IN (SELECT office_id FROM office_cte)
    AND (COALESCE(@id, 0) = 0 OR @id = purchase.orders.order_id)
    AND COALESCE(LOWER(purchase.orders.reference_number), '') LIKE '%' + LOWER(@reference_number) + '%' 
    AND COALESCE(LOWER(purchase.orders.internal_memo), '') LIKE '%' + LOWER(@internal_memo) + '%' 
    AND COALESCE(LOWER(purchase.orders.terms), '') LIKE '%' + LOWER(@terms) + '%' 
    AND LOWER(inventory.get_customer_name_by_customer_id(purchase.orders.supplier_id)) LIKE '%' + LOWER(@supplier) + '%' 
    AND LOWER(account.get_name_by_user_id(purchase.orders.user_id)) LIKE '%' + LOWER(@posted_by) + '%' 
    AND LOWER(core.get_office_name_by_office_id(purchase.orders.office_id)) LIKE '%' + LOWER(@office) + '%' 
    AND purchase.orders.deleted = 0;

    RETURN;
END;




--SELECT * FROM purchase.get_order_view(1,1,'', '11/27/2010','11/27/2016','1-1-2000','1-1-2020', null,'','','','', '');


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_price_type_id_by_price_type_code.sql --<--<--
IF OBJECT_ID('purchase.get_price_type_id_by_price_type_code') IS NOT NULL
DROP FUNCTION purchase.get_price_type_id_by_price_type_code;

GO

CREATE FUNCTION purchase.get_price_type_id_by_price_type_code(@price_type_code national character varying(24))
RETURNS integer
AS
BEGIN
    RETURN
    (
	    SELECT purchase.price_types.price_type_id
	    FROM purchase.price_types
	    WHERE purchase.price_types.price_type_code = @price_type_code
    );
END



GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_price_type_id_by_price_type_name.sql --<--<--
IF OBJECT_ID('purchase.get_price_type_id_by_price_type_name') IS NOT NULL
DROP FUNCTION purchase.get_price_type_id_by_price_type_name;

GO

CREATE FUNCTION purchase.get_price_type_id_by_price_type_name(@price_type_name national character varying(24))
RETURNS integer
AS

BEGIN
    RETURN
    (
	    SELECT purchase.price_types.price_type_id
	    FROM purchase.price_types
	    WHERE purchase.price_types.price_type_name = @price_type_name
    );
END;

GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_quotation_view.sql --<--<--
IF OBJECT_ID('purchase.get_quotation_view') IS NOT NULL
DROP FUNCTION purchase.get_quotation_view;

GO

CREATE FUNCTION purchase.get_quotation_view
(
    @user_id                        integer,
    @office_id                      integer,
    @supplier                       national character varying(500),
    @from                           date,
    @to                             date,
    @expected_from                  date,
    @expected_to                    date,
    @id                             bigint,
    @reference_number               national character varying(500),
    @internal_memo                  national character varying(500),
    @terms                          national character varying(500),
    @posted_by                      national character varying(500),
    @office                         national character varying(500)
)
RETURNS @result TABLE
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
    transaction_ts                  DATETIMEOFFSET
)
AS

BEGIN
    WITH office_cte(office_id) AS 
    (
        SELECT @office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    INSERT INTO @result
    SELECT 
        purchase.quotations.quotation_id,
        inventory.get_supplier_name_by_supplier_id(purchase.quotations.supplier_id),
        purchase.quotations.value_date,
        purchase.quotations.expected_delivery_date,
        purchase.quotations.reference_number,
        purchase.quotations.terms,
        purchase.quotations.internal_memo,
        account.get_name_by_user_id(purchase.quotations.user_id) AS posted_by,
        core.get_office_name_by_office_id(office_id) AS office,
        purchase.quotations.transaction_timestamp
    FROM purchase.quotations
    WHERE 1 = 1
    AND purchase.quotations.value_date BETWEEN @from AND @to
    AND purchase.quotations.expected_delivery_date BETWEEN @expected_from AND @expected_to
    AND purchase.quotations.office_id IN (SELECT office_id FROM office_cte)
    AND (COALESCE(@id, 0) = 0 OR @id = purchase.quotations.quotation_id)
    AND COALESCE(LOWER(purchase.quotations.reference_number), '') LIKE '%' + LOWER(@reference_number) + '%' 
    AND COALESCE(LOWER(purchase.quotations.internal_memo), '') LIKE '%' + LOWER(@internal_memo) + '%' 
    AND COALESCE(LOWER(purchase.quotations.terms), '') LIKE '%' + LOWER(@terms) + '%' 
    AND LOWER(inventory.get_customer_name_by_customer_id(purchase.quotations.supplier_id)) LIKE '%' + LOWER(@supplier) + '%' 
    AND LOWER(account.get_name_by_user_id(purchase.quotations.user_id)) LIKE '%' + LOWER(@posted_by) + '%' 
    AND LOWER(core.get_office_name_by_office_id(purchase.quotations.office_id)) LIKE '%' + LOWER(@office) + '%' 
    AND purchase.quotations.deleted = 0;

    RETURN;
END;




--SELECT * FROM purchase.get_quotation_view(1,1,'', '11/27/2010','11/27/2016','1-1-2000','1-1-2020', null,'','','','', '');


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.get_supplier_id_by_supplier_code.sql --<--<--
IF OBJECT_ID('purchase.get_supplier_id_by_supplier_code') IS NOT NULL
DROP FUNCTION purchase.get_supplier_id_by_supplier_code;

GO

CREATE FUNCTION purchase.get_supplier_id_by_supplier_code(@supplier_code national character varying(24))
RETURNS bigint
AS

BEGIN
    RETURN
    (
		SELECT supplier_id
		FROM inventory.suppliers
		WHERE inventory.suppliers.supplier_code=@supplier_code
		AND inventory.suppliers.deleted = 0
    );
END;





GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.post_purchase.sql --<--<--
IF OBJECT_ID('purchase.post_purchase') IS NOT NULL
DROP PROCEDURE purchase.post_purchase;

GO


CREATE PROCEDURE purchase.post_purchase
(
    @office_id                              integer,
    @user_id                                integer,
    @login_id                               bigint,
    @value_date                             date,
    @book_date                              date,
    @cost_center_id                         integer,
    @reference_number                       national character varying(24),
    @statement_reference                    national character varying(2000),
    @supplier_id                            integer,
    @price_type_id                          integer,
    @shipper_id                             integer,
    @details                                purchase.purchase_detail_type READONLY
)
AS
BEGIN
    DECLARE @transaction_master_id          bigint;
    DECLARE @checkout_id                    bigint;
    DECLARE @checkout_detail_id             bigint;
    DECLARE @shipping_address_id            integer;
    DECLARE @grand_total                    decimal(30, 6);
    DECLARE @discount_total                 decimal(30, 6);
    DECLARE @payable                        decimal(30, 6);
    DECLARE @default_currency_code          national character varying(12);
    DECLARE @is_periodic                    bit = inventory.is_periodic_inventory(@office_id);
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code               national character varying(50);
    DECLARE @tax_total                      decimal(30, 6);
    DECLARE @tax_account_id                 integer;
    DECLARE @shipping_charge                decimal(30, 6);
    DECLARE @book_name                      national character varying(100) = 'Purchase';

    DECLARE @can_post_transaction           bit;
    DECLARE @error_message                  national character varying(MAX);

    SELECT
        @can_post_transaction   = can_post_transaction,
        @error_message          = error_message
    FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date);

    IF(@can_post_transaction = 0)
    BEGIN
        RAISERROR(@error_message, 10, 1);
        RETURN;
    END;

    SET @tax_account_id                         = finance.get_sales_tax_account_id_by_office_id(@office_id);

    IF(@supplier_id IS NULL)
    BEGIN
        RAISERROR('Invalid supplier', 10, 1);
    END;
    
    DECLARE @checkout_details TABLE
    (
        id                                  integer IDENTITY PRIMARY KEY,
        checkout_id                         bigint, 
        store_id                            integer,
        transaction_type                    national character varying(2),
        item_id                             integer, 
        quantity                            decimal(30, 6),
        unit_id                             integer,
        base_quantity                       decimal(30, 6),
        base_unit_id                        integer,
        price                               decimal(30, 6) NOT NULL DEFAULT(0),
        cost_of_goods_sold                  decimal(30, 6) NOT NULL DEFAULT(0),
        discount                            decimal(30, 6) NOT NULL DEFAULT(0),
        tax                                 decimal(30, 6) NOT NULL DEFAULT(0),
        shipping_charge                     decimal(30, 6) NOT NULL DEFAULT(0),
        purchase_account_id                 integer, 
        purchase_discount_account_id        integer, 
        inventory_account_id                integer
    ) ;



    INSERT INTO @checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount, tax, shipping_charge)
    SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount, tax, shipping_charge
    FROM @details;


    UPDATE @checkout_details 
    SET
        base_quantity                       = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                        = inventory.get_root_unit_id(unit_id),
        purchase_account_id                 = inventory.get_purchase_account_id(item_id),
        purchase_discount_account_id        = inventory.get_purchase_discount_account_id(item_id),
        inventory_account_id                = inventory.get_inventory_account_id(item_id);    
    
    IF EXISTS
    (
        SELECT TOP 1 0 FROM @checkout_details AS details
        WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
    )
    BEGIN
        RAISERROR('Item/unit mismatch.', 10, 1);
    END;

    SELECT @discount_total  = SUM(COALESCE(discount, 0)) FROM @checkout_details;
    SELECT @grand_total     = SUM(COALESCE(price, 0) * COALESCE(quantity, 0)) FROM @checkout_details;
    SELECT @shipping_charge = SUM(COALESCE(shipping_charge, 0)) FROM @checkout_details;
    SELECT @tax_total       = SUM(COALESCE(tax, 0)) FROM @checkout_details;


    DECLARE @temp_transaction_details TABLE
    (
        transaction_master_id               BIGINT, 
        tran_type                           national character varying(4), 
        account_id                          integer, 
        statement_reference                 national character varying(2000), 
        currency_code                       national character varying(12), 
        amount_in_currency                  decimal(30, 6), 
        local_currency_code                 national character varying(12), 
        er                                  decimal_strict, 
        amount_in_local_currency            decimal(30, 6)
    ) ;

    SET @payable                                = @grand_total - COALESCE(@discount_total, 0) + COALESCE(@shipping_charge, 0) + COALESCE(@tax_total, 0);
    SET @default_currency_code                  = core.get_currency_code_by_office_id(@office_id);
    SET @tran_counter                           = finance.get_new_transaction_counter(@value_date);
    SET @transaction_code                       = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);

    IF(@is_periodic = 1)
    BEGIN
        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', purchase_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM @checkout_details
        GROUP BY purchase_account_id;
    END
    ELSE
    BEGIN
        --Perpetutal Inventory Accounting System
        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', inventory_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM @checkout_details
        GROUP BY inventory_account_id;
    END;


    IF(@discount_total > 0)
    BEGIN
        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', purchase_discount_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(discount, 0)), 1, @default_currency_code, SUM(COALESCE(discount, 0))
        FROM @checkout_details
        GROUP BY purchase_discount_account_id;
    END;

    IF(COALESCE(@tax_total, 0) > 0)
    BEGIN
        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', @tax_account_id, @statement_reference, @default_currency_code, @tax_total, 1, @default_currency_code, @tax_total;
    END;    

    INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
    SELECT 'Cr', inventory.get_account_id_by_supplier_id(@supplier_id), @statement_reference, @default_currency_code, @payable, 1, @default_currency_code, @payable;


    UPDATE @temp_transaction_details        SET transaction_master_id   = @transaction_master_id;
    UPDATE @checkout_details           SET checkout_id         = @checkout_id;
    
    INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
    SELECT @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;
    SET @transaction_master_id = SCOPE_IDENTITY();


    
    INSERT INTO finance.transaction_details(value_date, book_date, office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
    SELECT @value_date, @book_date, @office_id, @transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
    FROM @temp_transaction_details
    ORDER BY tran_type DESC;


    INSERT INTO inventory.checkouts(value_date, book_date, transaction_master_id, transaction_book, posted_by, shipper_id, office_id)
    SELECT @value_date, @book_date, @transaction_master_id, @book_name, @user_id, @shipper_id, @office_id;
    SET @checkout_id                = SCOPE_IDENTITY();

    INSERT INTO purchase.purchases(checkout_id, supplier_id, price_type_id)
    SELECT @checkout_id, @supplier_id, @price_type_id;

    INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, store_id, transaction_type, item_id, price, discount, cost_of_goods_sold, tax, shipping_charge, unit_id, quantity, base_unit_id, base_quantity)
    SELECT @checkout_id, @value_date, @book_date, store_id, transaction_type, item_id, price, discount, cost_of_goods_sold, tax, shipping_charge, unit_id, quantity, base_unit_id, base_quantity
    FROM @checkout_details;
    

    EXECUTE finance.auto_verify @transaction_master_id, @office_id;
    SELECT @transaction_master_id;
END;


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/02.functions-and-logic/purchase.post_return.sql --<--<--
IF OBJECT_ID('purchase.post_return') IS NOT NULL
DROP PROCEDURE purchase.post_return;

GO

CREATE PROCEDURE purchase.post_return
(
    @transaction_master_id                  bigint,
    @office_id                              integer,
    @user_id                                integer,
    @login_id                               bigint,
    @value_date                             date,
    @book_date                              date,
    @cost_center_id                         integer,
    @supplier_id                            integer,
    @price_type_id                          integer,
    @shipper_id                             integer,
    @reference_number                       national character varying(24),
    @statement_reference                    national character varying(2000),
    @details                                purchase.purchase_detail_type READONLY
)
AS
BEGIN    
    DECLARE @purchase_id                    bigint;
    DECLARE @original_price_type_id         integer;
    DECLARE @tran_master_id                 bigint;
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code national character varying(50);
    DECLARE @checkout_id                    bigint;
    DECLARE @grand_total                    decimal(30, 6);
    DECLARE @discount_total                 decimal(30, 6);
    DECLARE @tax_total                      decimal(30, 6);
    DECLARE @credit_account_id              integer;
    DECLARE @default_currency_code          national character varying(12);
    DECLARE @sm_id                          bigint;
    DECLARE @is_periodic                    bit = inventory.is_periodic_inventory(@office_id);
    DECLARE @book_name                      national character varying(1000)='Purchase Return';
    DECLARE @receivable                     decimal(30, 6);
    DECLARE @tax_account_id                 integer;

    DECLARE @total_rows                     integer = 0;
    DECLARE @counter                        integer = 0;
    DECLARE @loop_id                        integer;
    DECLARE @loop_checkout_id               bigint;
    DECLARE @loop_transaction_type          national character varying(2);
    DECLARE @loop_store_id                  integer;
    DECLARE @loop_item_id                   integer;
    DECLARE @loop_quantity                  decimal(30, 6);
    DECLARE @loop_unit_id                   integer;
    DECLARE @loop_base_quantity             decimal(30, 6);
    DECLARE @loop_base_unit_id              integer;
    DECLARE @loop_price                     decimal(30, 6);
    DECLARE @loop_discount                  decimal(30, 6);
    DECLARE @loop_tax                       decimal(30, 6);
    DECLARE @loop_shipping_charge           decimal(30, 6);

    DECLARE @can_post_transaction           bit;
    DECLARE @error_message                  national character varying(MAX);

    SELECT
        @can_post_transaction   = can_post_transaction,
        @error_message          = error_message
    FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date);

    IF(@can_post_transaction = 0)
    BEGIN
        RAISERROR(@error_message, 10, 1);
        RETURN;
    END;

    DECLARE @checkout_details TABLE
    (
        id                                  integer IDENTITY PRIMARY KEY,
        checkout_id                         bigint, 
        transaction_type                    national character varying(2), 
        store_id                            integer,
        item_code                           national character varying(50),
        item_id                             integer, 
        quantity                            decimal(30, 6),
        unit_name                           national character varying(1000),
        unit_id                             integer,
        base_quantity                       decimal(30, 6),
        base_unit_id                        integer,                
        price                               decimal(30, 6),
        discount                            decimal(30, 6),
        tax                                 decimal(30, 6),
        shipping_charge                     decimal(30, 6),
        purchase_account_id                 integer, 
        purchase_discount_account_id        integer, 
        inventory_account_id                integer
    ) ;

    DECLARE @temp_transaction_details TABLE
    (
        transaction_master_id               BIGINT, 
        transaction_type                    national character varying(2), 
        account_id                          integer, 
        statement_reference                 national character varying(2000), 
        currency_code                       national character varying(12), 
        amount_in_currency                  decimal(30, 6), 
        local_currency_code                 national character varying(12), 
        er                                  decimal(30, 6), 
        amount_in_local_currency            decimal(30, 6)
    ) ;
   
    SELECT @purchase_id = purchase.purchases.purchase_id
    FROM purchase.purchases
    INNER JOIN inventory.checkouts
    ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
    INNER JOIN finance.transaction_master
    ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
    WHERE finance.transaction_master.transaction_master_id = @transaction_master_id;

    SELECT @original_price_type_id = purchase.purchases.price_type_id
    FROM purchase.purchases
    WHERE purchase.purchases.purchase_id = @purchase_id;

    IF(@price_type_id != @original_price_type_id)
    BEGIN
        RAISERROR('Please select the right price type.', 10, 1);
    END;
    
    SELECT @sm_id = checkout_id 
    FROM inventory.checkouts 
    WHERE inventory.checkouts.transaction_master_id = @transaction_master_id
    AND inventory.checkouts.deleted = 0;

    INSERT INTO @checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount, tax, shipping_charge)
    SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount, tax, shipping_charge
    FROM @details;

    UPDATE @checkout_details 
    SET
        base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                    = inventory.get_root_unit_id(unit_id),
        purchase_account_id             = inventory.get_purchase_account_id(item_id),
        purchase_discount_account_id    = inventory.get_purchase_discount_account_id(item_id),
        inventory_account_id            = inventory.get_inventory_account_id(item_id);    

    IF EXISTS
    (
        SELECT TOP 1 0 FROM @checkout_details AS details
        WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
    )
    BEGIN
        RAISERROR('Item/unit mismatch.', 10, 1);
    END;

    
    SET @default_currency_code              = core.get_currency_code_by_office_id(@office_id);
    SET @tran_counter                       = finance.get_new_transaction_counter(@value_date);
    SET @transaction_code                   = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);
       
    SELECT @tax_total = SUM(COALESCE(tax, 0)) FROM @checkout_details;
    SELECT @discount_total = SUM(COALESCE(discount, 0)) FROM @checkout_details;
    SELECT @grand_total = SUM(COALESCE(price, 0) * COALESCE(quantity, 0)) FROM @checkout_details;

    SET @receivable = @grand_total + @tax_total - COALESCE(@discount_total, 0);


    IF(@is_periodic = 1)
    BEGIN
        INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', purchase_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM @checkout_details
        GROUP BY purchase_account_id;
    END
    ELSE
    BEGIN
        --Perpetutal Inventory Accounting System
        INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', inventory_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM @checkout_details
        GROUP BY inventory_account_id;
    END;


    IF(COALESCE(@discount_total, 0) > 0)
    BEGIN
        INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', purchase_discount_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(discount, 0)), 1, @default_currency_code, SUM(COALESCE(discount, 0))
        FROM @checkout_details
        GROUP BY purchase_discount_account_id;
    END;

    IF(COALESCE(@tax_total, 0) > 0)
    BEGIN
        INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', @tax_account_id, @statement_reference, @default_currency_code, @tax_total, 1, @default_currency_code, @tax_total;
    END;

    INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
    SELECT 'Dr', inventory.get_account_id_by_supplier_id(@supplier_id), @statement_reference, @default_currency_code, @receivable, 1, @default_currency_code, @receivable;



    UPDATE @temp_transaction_details        SET transaction_master_id   = @transaction_master_id;
    UPDATE @checkout_details           SET checkout_id         = @checkout_id;

    INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
    SELECT @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;

    SET @transaction_master_id = SCOPE_IDENTITY();


    INSERT INTO finance.transaction_details(office_id, value_date, book_date, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
    SELECT @office_id, @value_date, @book_date, transaction_master_id, transaction_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
    FROM @temp_transaction_details
    ORDER BY transaction_type DESC;


    SET IDENTITY_INSERT inventory.checkouts ON;
    INSERT INTO inventory.checkouts(value_date, book_date, checkout_id, transaction_master_id, transaction_book, posted_by, office_id, shipper_id)
    SELECT @value_date, @book_date, @checkout_id, @tran_master_id, @book_name, @user_id, @office_id, @shipper_id;
    SET IDENTITY_INSERT inventory.checkouts OFF;
            
    SELECT @total_rows=MAX(id) FROM @checkout_details;

    WHILE @counter<@total_rows
    BEGIN
        SELECT TOP 1 
            @loop_checkout_id = checkout_id,
            @loop_transaction_type = transaction_type,
            @loop_store_id = store_id,
            @loop_item_id = item_id,
            @loop_quantity = quantity,
            @loop_unit_id = unit_id,
            @loop_base_quantity = base_quantity,
            @loop_base_unit_id = base_unit_id,
            @loop_price = price,
            @loop_discount = discount,
            @loop_tax = tax,
            @loop_shipping_charge = shipping_charge,
            @loop_id = id
        FROM @checkout_details
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

        INSERT INTO inventory.checkout_details(value_date, book_date, checkout_id, transaction_type, store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, discount, tax, shipping_charge)
        SELECT @value_date, @book_date, @loop_checkout_id, @loop_transaction_type, @loop_store_id, @loop_item_id, @loop_quantity, @loop_unit_id, @loop_base_quantity, @loop_base_unit_id, @loop_price, @loop_discount, @loop_tax, @loop_shipping_charge
        FROM @checkout_details
        WHERE id = @loop_id;  
    END;

    INSERT INTO purchase.purchase_returns(checkout_id, purchase_id, supplier_id)
    SELECT @checkout_id, @purchase_id, @supplier_id;

    
    EXECUTE finance.auto_verify @transaction_master_id, @office_id;
    SELECT @tran_master_id;
END;




-- SELECT * FROM purchase.post_return(4, 1, 1, 1, '1-1-2000', '1-1-2000', 1, 1, 1, '1234-AD', 'Test', 
-- ARRAY[
-- ROW(1, 'Dr', 1, 1, 1,180000, 0, 200),
-- ROW(1, 'Dr', 2, 1, 7,130000, 300, 30),
-- ROW(1, 'Dr', 3, 1, 1,110000, 5000, 50)]);
-- 


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/03.menus/menus.sql --<--<--
DELETE FROM auth.menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'Purchase'
);

DELETE FROM auth.group_menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'Purchase'
);

DELETE FROM core.menus
WHERE app_name = 'Purchase';


EXECUTE core.create_app 'Purchase', 'Purchase', '1.0', 'MixERP Inc.', 'December 1, 2015', 'newspaper yellow', '/dashboard/purchase/tasks/entry', NULL;

EXECUTE core.create_menu 'Purchase', 'Tasks', '', 'lightning', '';
EXECUTE core.create_menu 'Purchase', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'write', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'minus', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Quotation', '/dashboard/purchase/tasks/quotation', 'newspaper', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Orders', '/dashboard/purchase/tasks/order', 'file national character varying(1000) outline', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Verification', '/dashboard/purchase/tasks/entry/verification', 'checkmark', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Return Verification', '/dashboard/purchase/tasks/return/verification', 'minus', 'Tasks';

EXECUTE core.create_menu 'Purchase', 'Setup', 'square outline', 'configure', '';
EXECUTE core.create_menu 'Purchase', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup';
EXECUTE core.create_menu 'Purchase', 'Price Types', '/dashboard/purchase/setup/price-types', 'dollar', 'Setup';
EXECUTE core.create_menu 'Purchase', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'rupee', 'Setup';

EXECUTE core.create_menu 'Purchase', 'Reports', '', 'block layout', '';
EXECUTE core.create_menu 'Purchase', 'Top Suppliers', '/dashboard/purchase/reports/purchase-account-statement', 'spy', 'Reports';
EXECUTE core.create_menu 'Purchase', 'Low Inventory Products', '/dashboard/purchase/reports/purchase-account-statement', 'warning', 'Reports';
EXECUTE core.create_menu 'Purchase', 'Out of Stock Products', '/dashboard/purchase/reports/purchase-account-statement', 'remove circle', 'Reports';



DECLARE @office_id integer = core.get_office_id_by_office_name('Default');
EXECUTE auth.create_app_menu_policy
'Admin', 
@office_id, 
'Purchase',
'{*}';



GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/04.default-values/01.default-values.sql --<--<--
INSERT INTO purchase.price_types(price_type_code, price_type_name)
SELECT 'RET',   'Retail' UNION ALL
SELECT 'WHO',   'Wholesale';


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/05.scrud-views/purchase.item_cost_price_scrud_view.sql --<--<--
IF OBJECT_ID('purchase.item_cost_price_scrud_view') IS NOT NULL
DROP VIEW purchase.item_cost_price_scrud_view;

GO



CREATE VIEW purchase.item_cost_price_scrud_view
AS
SELECT
    purchase.item_cost_prices.item_cost_price_id,
    purchase.item_cost_prices.item_id,
    inventory.items.item_code + ' (' + inventory.items.item_name + ')' AS item,
    purchase.item_cost_prices.unit_id,
    inventory.units.unit_code + ' (' + inventory.units.unit_name + ')' AS unit,
    purchase.item_cost_prices.supplier_id,
    inventory.suppliers.supplier_code + ' (' + inventory.suppliers.supplier_name + ')' AS supplier,
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
WHERE purchase.item_cost_prices.deleted = 0;


GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/05.views/purchase.item_view.sql --<--<--
IF OBJECT_ID('purchase.item_view') IS NOT NULL
DROP VIEW purchase.item_view;

GO



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
    inventory.get_associated_unit_list_csv(inventory.items.unit_id) AS valid_units,
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
WHERE inventory.items.deleted = 0
AND inventory.items.allow_purchase = 1
AND inventory.items.maintain_inventory = 1;

GO


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.x/2.0/src/99.ownership.sql --<--<--
EXEC sp_addrolemember  @rolename = 'db_owner', @membername  = 'frapid_db_user'


EXEC sp_addrolemember  @rolename = 'db_datareader', @membername  = 'report_user'


GO

