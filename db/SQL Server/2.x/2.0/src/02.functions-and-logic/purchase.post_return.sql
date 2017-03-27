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
    @details                                purchase.purchase_detail_type READONLY,
    @tran_master_id                         bigint OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @purchase_id                    bigint;
    DECLARE @original_price_type_id         integer;
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code				national character varying(50);
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
    DECLARE @can_post_transaction           bit;
    DECLARE @error_message                  national character varying(MAX);
        
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
        discount_rate                       decimal(30, 6),
        discount                            decimal(30, 6),
        tax                                 decimal(30, 6),
        shipping_charge                     decimal(30, 6),
        purchase_account_id                 integer, 
        purchase_discount_account_id        integer, 
        inventory_account_id                integer
    );

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
    );


    BEGIN TRY
        DECLARE @tran_count int = @@TRANCOUNT;
        
        IF(@tran_count= 0)
        BEGIN
            BEGIN TRANSACTION
        END;
        
        SELECT
            @can_post_transaction   = can_post_transaction,
            @error_message          = error_message
        FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date);

        IF(@can_post_transaction = 0)
        BEGIN
            RAISERROR(@error_message, 13, 1);
            RETURN;
        END;

       
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
            RAISERROR('Please select the right price type.', 13, 1);
        END;
        
        SELECT @sm_id = checkout_id 
        FROM inventory.checkouts 
        WHERE inventory.checkouts.transaction_master_id = @transaction_master_id
        AND inventory.checkouts.deleted = 0;

        INSERT INTO @checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, tax, shipping_charge)
        SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, tax, shipping_charge
        FROM @details;

        UPDATE @checkout_details 
        SET
            base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
            base_unit_id                    = inventory.get_root_unit_id(unit_id),
            purchase_account_id             = inventory.get_purchase_account_id(item_id),
            purchase_discount_account_id    = inventory.get_purchase_discount_account_id(item_id),
            inventory_account_id            = inventory.get_inventory_account_id(item_id),
            discount                        = ROUND((price * quantity) * (discount_rate / 100), 2);

        IF EXISTS
        (
            SELECT TOP 1 0 FROM @checkout_details AS details
            WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
        )
        BEGIN
            RAISERROR('Item/unit mismatch.', 13, 1);
        END;

        
		SET @tax_account_id                     = finance.get_sales_tax_account_id_by_office_id(@office_id);
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




        INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
        SELECT @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;

        SET @tran_master_id = SCOPE_IDENTITY();

        UPDATE @temp_transaction_details
		SET transaction_master_id   = @tran_master_id;


        INSERT INTO finance.transaction_details(office_id, value_date, book_date, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
        SELECT @office_id, @value_date, @book_date, transaction_master_id, transaction_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
        FROM @temp_transaction_details
        ORDER BY transaction_type DESC;


        INSERT INTO inventory.checkouts(value_date, book_date, transaction_master_id, transaction_book, posted_by, office_id, shipper_id)
        SELECT @value_date, @book_date, @tran_master_id, @book_name, @user_id, @office_id, @shipper_id;
 
        SET @checkout_id = SCOPE_IDENTITY();

        UPDATE @checkout_details				
		SET checkout_id				= @checkout_id;
               
        INSERT INTO inventory.checkout_details(value_date, book_date, checkout_id, transaction_type, store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, discount, tax, shipping_charge)
        SELECT @value_date, @book_date, checkout_id, transaction_type, store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, discount, tax, shipping_charge
        FROM @checkout_details;

        INSERT INTO purchase.purchase_returns(checkout_id, purchase_id, supplier_id)
        SELECT @checkout_id, @purchase_id, @supplier_id;

        
        EXECUTE finance.auto_verify @transaction_master_id, @office_id;

        IF(@tran_count = 0)
        BEGIN
            COMMIT TRANSACTION;
        END;
    END TRY
    BEGIN CATCH
        IF(XACT_STATE() <> 0 AND @tran_count = 0) 
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE @ErrorMessage national character varying(4000)  = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int                              = ERROR_SEVERITY();
        DECLARE @ErrorState int                                 = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

GO
