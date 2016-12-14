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
    @details                                purchase.purchase_detail_type
)
AS
BEGIN
    DECLARE @transaction_master_id          bigint;
    DECLARE @checkout_id                    bigint;
    DECLARE @checkout_detail_id             bigint;
    DECLARE @shipping_address_id            integer;
    DECLARE @grand_total                    dbo.money_strict;
    DECLARE @discount_total                 dbo.money_strict2;
    DECLARE @payable                        dbo.money_strict2;
    DECLARE @default_currency_code          national character varying(12);
    DECLARE @is_periodic                    bit = inventory.is_periodic_inventory(@office_id);
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code               national character varying(50);
    DECLARE @tax_total                      dbo.money_strict2;
    DECLARE @tax_account_id                 integer;
    DECLARE @shipping_charge                dbo.money_strict2;
    DECLARE @book_name                      national character varying(100) = 'Purchase';

    IF NOT finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date)
    BEGIN
        RETURN 0;
    END;

    @tax_account_id                         = finance.get_sales_tax_account_id_by_office_id(@office_id);

    IF(@supplier_id IS NULL)
    BEGIN
        RAISERROR('Invalid supplier', 10, 1);
    END;
    
    DECLARE @temp_checkout_details TABLE
    (
        id                                  integer IDENTITY PRIMARY KEY,
        checkout_id                         bigint, 
        store_id                            integer,
        transaction_type                    national character varying(2),
        item_id                             integer, 
        quantity                            dbo.integer_strict,
        unit_id                             integer,
        base_quantity                       decimal,
        base_unit_id                        integer,
        price                               dbo.money_strict NOT NULL DEFAULT(0),
        cost_of_ods_sold                  dbo.money_strict2 NOT NULL DEFAULT(0),
        discount                            dbo.money_strict2 NOT NULL DEFAULT(0),
        tax                                 dbo.money_strict2 NOT NULL DEFAULT(0),
        shipping_charge                     dbo.money_strict2 NOT NULL DEFAULT(0),
        purchase_account_id                 integer, 
        purchase_discount_account_id        integer, 
        inventory_account_id                integer
    ) ;



    INSERT INTO @temp_checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount, tax, shipping_charge)
    SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount, tax, shipping_charge
    FROM @details;


    UPDATE @temp_checkout_details 
    SET
        base_quantity                       = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                        = inventory.get_root_unit_id(unit_id),
        purchase_account_id                 = inventory.get_purchase_account_id(item_id),
        purchase_discount_account_id        = inventory.get_purchase_discount_account_id(item_id),
        inventory_account_id                = inventory.get_inventory_account_id(item_id);    
    
    IF EXISTS
    (
        SELECT TOP 1 0 FROM @temp_checkout_details AS details
        WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
    )
    BEGIN
        RAISERROR('Item/unit mismatch.', 10, 1);
    END;

    SELECT SUM(COALESCE(discount, 0))                               INTO @discount_total FROM @temp_checkout_details;
    SELECT SUM(COALESCE(price, 0) * COALESCE(quantity, 0))          INTO @grand_total FROM @temp_checkout_details;
    SELECT SUM(COALESCE(shipping_charge, 0))                        INTO @shipping_charge FROM @temp_checkout_details;
   SELECT SUM(COALESCE(tax, 0))                                     INTO @tax_total FROM @temp_checkout_details;


    DECLARE @temp_transaction_details TABLE
    (
        transaction_master_id               BIGINT, 
        tran_type                           national character varying(4), 
        account_id                          integer, 
        statement_reference                 national character varying(2000), 
        currency_code                       national character varying(12), 
        amount_in_currency                  dbo.money_strict, 
        local_currency_code                 national character varying(12), 
        er                                  decimal_strict, 
        amount_in_local_currency            dbo.money_strict
    ) ;

    @payable                                = @grand_total - COALESCE(@discount_total, 0) + COALESCE(@shipping_charge, 0) + COALESCE(@tax_total, 0);
    @default_currency_code                  = core.get_currency_code_by_office_id(@office_id);
    @transaction_master_id                  = nextval(pg_get_integer IDENTITY_sequence('finance.transaction_master', 'transaction_master_id'));
    @checkout_id                            = nextval(pg_get_integer IDENTITY_sequence('inventory.checkouts', 'checkout_id'));
    @tran_counter                           = finance.get_new_transaction_counter(@value_date);
    @transaction_code                       = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);

    IF(@is_periodic = 1)
    BEGIN
        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', purchase_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM @temp_checkout_details
        GROUP BY purchase_account_id;
    END
    ELSE
    BEGIN
        --Perpetutal Inventory Accounting System
        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', inventory_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM @temp_checkout_details
        GROUP BY inventory_account_id;
    END;


    IF(@discount_total > 0)
    BEGIN
        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', purchase_discount_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(discount, 0)), 1, @default_currency_code, SUM(COALESCE(discount, 0))
        FROM @temp_checkout_details
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
    UPDATE @temp_checkout_details           SET checkout_id         = @checkout_id;
    
    INSERT INTO finance.transaction_master(transaction_master_id, transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
    SELECT @transaction_master_id, @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;

    
    INSERT INTO finance.transaction_details(value_date, book_date, office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
    SELECT @value_date, @book_date, @office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
    FROM @temp_transaction_details
    ORDER BY tran_type DESC;


    INSERT INTO inventory.checkouts(value_date, book_date, checkout_id, transaction_master_id, transaction_book, posted_by, shipper_id, office_id)
    SELECT @value_date, @book_date, @checkout_id, @transaction_master_id, @book_name, @user_id, @shipper_id, @office_id;

    INSERT INTO purchase.purchases(checkout_id, supplier_id, price_type_id)
    SELECT @checkout_id, @supplier_id, @price_type_id;

    INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, store_id, transaction_type, item_id, price, discount, cost_of_ods_sold, tax, shipping_charge, unit_id, quantity, base_unit_id, base_quantity)
    SELECT @checkout_id, @value_date, @book_date, store_id, transaction_type, item_id, price, discount, cost_of_ods_sold, tax, shipping_charge, unit_id, quantity, base_unit_id, base_quantity
    FROM @temp_checkout_details;
    
    EXECUTE finance.auto_verify @transaction_master_id, @office_id;
    SELECT @transaction_master_id;
END;





-- SELECT * FROM purchase.post_purchase(1, 1, 1, finance.get_value_date(1), finance.get_value_date(1), 1, '', '', 1, 1, NULL,
-- ARRAY[
-- ROW(1, 'Dr', 1, 1, 1,180000, 0, 10, 200),
-- ROW(1, 'Dr', 2, 1, 7,130000, 300, 10, 30),
-- ROW(1, 'Dr', 3, 1, 1,110000, 5000, 10, 50)]);
-- 


GO
