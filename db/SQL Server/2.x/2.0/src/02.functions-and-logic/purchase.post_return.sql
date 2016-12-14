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
    @details                                purchase.purchase_detail_type
)
AS
BEGIN    
    DECLARE @purchase_id                    bigint;
    DECLARE @original_price_type_id         integer;
    DECLARE @tran_master_id                 bigint;
    DECLARE @checkout_detail_id             bigint;
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code national character varying(50);
    DECLARE @checkout_id                    bigint;
    DECLARE @grand_total                    dbo.money_strict;
    DECLARE @discount_total                 dbo.money_strict2;
    DECLARE @tax_total                      dbo.money_strict2;
    DECLARE @credit_account_id              integer;
    DECLARE @default_currency_code          national character varying(12);
    DECLARE @sm_id                          bigint;
    DECLARE this                            RECORD;
    DECLARE @is_periodic                    bit = inventory.is_periodic_inventory(@office_id);
    DECLARE @book_name                      national character varying(1000)='Purchase Return';
    DECLARE @receivable                     dbo.money_strict;
    DECLARE @tax_account_id                 integer;

    IF NOT finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date)
    BEGIN
        RETURN 0;
    END;

    DECLARE @temp_checkout_details TABLE
    (
        id                                  integer IDENTITY PRIMARY KEY,
        checkout_id                         bigint, 
        transaction_type                    national character varying(2), 
        store_id                            integer,
        item_code national character varying(50),
        item_id                             integer, 
        quantity                            dbo.integer_strict,
        unit_name                           national character varying(1000),
        unit_id                             integer,
        base_quantity                       decimal,
        base_unit_id                        integer,                
        price                               dbo.money_strict,
        discount                            dbo.money_strict2,
        tax                                 dbo.money_strict2,
        shipping_charge                     dbo.money_strict2,
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
        amount_in_currency                  dbo.money_strict, 
        local_currency_code                 national character varying(12), 
        er                                  dbo.decimal_strict, 
        amount_in_local_currency            dbo.money_strict
    ) ;
   
    SELECT purchase.purchases.purchase_id INTO @purchase_id
    FROM purchase.purchases
    INNER JOIN inventory.checkouts
    ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
    INNER JOIN finance.transaction_master
    ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
    WHERE finance.transaction_master.transaction_master_id = @transaction_master_id;

    SELECT purchase.purchases.price_type_id INTO @original_price_type_id
    FROM purchase.purchases
    WHERE purchase.purchases.purchase_id = @purchase_id;

    IF(@price_type_id != @original_price_type_id)
    BEGIN
        RAISERROR('Please select the right price type.', 10, 1);
    END;
    
    SELECT checkout_id INTO @sm_id 
    FROM inventory.checkouts 
    WHERE inventory.checkouts.transaction_master_id = @transaction_master_id
    AND inventory.checkouts.deleted = 0;

    INSERT INTO @temp_checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount, tax, shipping_charge)
    SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount, tax, shipping_charge
    FROM @details;

    UPDATE @temp_checkout_details 
    SET
        base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
        base_unit_id                    = inventory.get_root_unit_id(unit_id),
        purchase_account_id             = inventory.get_purchase_account_id(item_id),
        purchase_discount_account_id    = inventory.get_purchase_discount_account_id(item_id),
        inventory_account_id            = inventory.get_inventory_account_id(item_id);    

    IF EXISTS
    (
        SELECT TOP 1 0 FROM @temp_checkout_details AS details
        WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
    )
    BEGIN
        RAISERROR('Item/unit mismatch.', 10, 1);
    END;

    
    @default_currency_code              = core.get_currency_code_by_office_id(@office_id);
    @tran_master_id                     = nextval(pg_get_integer IDENTITY_sequence('finance.transaction_master', 'transaction_master_id'));
    @checkout_id                        = nextval(pg_get_integer IDENTITY_sequence('inventory.checkouts', 'checkout_id'));
    @tran_counter                       = finance.get_new_transaction_counter(@value_date);
    @transaction_code                   = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);
       
    SELECT SUM(COALESCE(tax, 0))                                INTO @tax_total FROM @temp_checkout_details;
    SELECT SUM(COALESCE(discount, 0))                           INTO @discount_total FROM @temp_checkout_details;
    SELECT SUM(COALESCE(price, 0) * COALESCE(quantity, 0))      INTO @grand_total FROM @temp_checkout_details;

    @receivable = @grand_total + @tax_total - COALESCE(@discount_total, 0);


    IF(@is_periodic = 1)
    BEGIN
        INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', purchase_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM @temp_checkout_details
        GROUP BY purchase_account_id;
    END
    ELSE
    BEGIN
        --Perpetutal Inventory Accounting System
        INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', inventory_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0)), 1, @default_currency_code, SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
        FROM @temp_checkout_details
        GROUP BY inventory_account_id;
    END;


    IF(COALESCE(@discount_total, 0) > 0)
    BEGIN
        INSERT INTO @temp_transaction_details(transaction_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', purchase_discount_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(discount, 0)), 1, @default_currency_code, SUM(COALESCE(discount, 0))
        FROM @temp_checkout_details
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
    UPDATE @temp_checkout_details           SET checkout_id         = @checkout_id;

    INSERT INTO finance.transaction_master(transaction_master_id, transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
    SELECT @tran_master_id, @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;


    INSERT INTO finance.transaction_details(office_id, value_date, book_date, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
    SELECT @office_id, @value_date, @book_date, transaction_master_id, transaction_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
    FROM @temp_transaction_details
    ORDER BY transaction_type DESC;


    INSERT INTO inventory.checkouts(value_date, book_date, checkout_id, transaction_master_id, transaction_book, posted_by, office_id, shipper_id)
    SELECT @value_date, @book_date, @checkout_id, @tran_master_id, @book_name, @user_id, @office_id, @shipper_id;
            
    FOR this IN SELECT * FROM @temp_checkout_details ORDER BY id
    LOOP
        @checkout_detail_id        = nextval(pg_get_integer IDENTITY_sequence('inventory.checkout_details', 'checkout_detail_id'));

        INSERT INTO inventory.checkout_details(checkout_detail_id, value_date, book_date, checkout_id, transaction_type, store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, discount, tax, shipping_charge)
        SELECT @checkout_detail_id, @value_date, @book_date, this.checkout_id, this.transaction_type, this.store_id, this.item_id, this.quantity, this.unit_id, this.base_quantity, this.base_unit_id, this.price, this.discount, this.tax, this.shipping_charge
        FROM @temp_checkout_details
        WHERE id = this.id;        
    END LOOP;

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
