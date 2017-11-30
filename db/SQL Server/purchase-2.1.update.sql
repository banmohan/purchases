-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/01.types-domains-tables-and-constraints/tables-and-constraints.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/02.functions-and-logic/purchase.post_purchase.sql --<--<--
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
    @store_id								integer,
    @details                                purchase.purchase_detail_type READONLY,
	@invoice_discount						numeric(30, 6) = 0,
	@transaction_master_id					bigint OUTPUT,
	@book_name								national character varying(48) = 'Purchase Entry'
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @checkout_id                    bigint;
    DECLARE @checkout_detail_id             bigint;
    DECLARE @shipping_address_id            integer;
    DECLARE @grand_total                    numeric(30, 6);
    DECLARE @discount_total                 numeric(30, 6);
    DECLARE @payable                        numeric(30, 6);
    DECLARE @default_currency_code          national character varying(12);
    DECLARE @is_periodic                    bit = inventory.is_periodic_inventory(@office_id);
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code               national character varying(50);
    DECLARE @tax_total                      numeric(30, 6);
    DECLARE @tax_account_id                 integer;
    DECLARE @shipping_charge                numeric(30, 6);
	DECLARE @sales_tax_rate					numeric(30, 6);

    DECLARE @can_post_transaction           bit;
    DECLARE @error_message                  national character varying(MAX);
	DECLARE @taxable_total					numeric(30, 6);
	DECLARE @nontaxable_total				numeric(30, 6);

    DECLARE @checkout_details TABLE
    (
        id                                  integer IDENTITY PRIMARY KEY,
        checkout_id                         bigint, 
        store_id                            integer,
        transaction_type                    national character varying(2),
        item_id                             integer, 
        quantity                            numeric(30, 6),
        unit_id                             integer,
        base_quantity                       numeric(30, 6),
        base_unit_id                        integer,
        price                               numeric(30, 6) NOT NULL DEFAULT(0),
        cost_of_goods_sold                  numeric(30, 6) NOT NULL DEFAULT(0),
        discount_rate                       numeric(30, 6),
        discount                            numeric(30, 6) NOT NULL DEFAULT(0),
		is_taxable_item						bit,
		is_taxed							bit,
        amount								numeric(30, 6),
        shipping_charge                     numeric(30, 6) NOT NULL DEFAULT(0),
        purchase_account_id                 integer, 
        purchase_discount_account_id        integer, 
        inventory_account_id                integer
    );

    DECLARE @temp_transaction_details TABLE
    (
        transaction_master_id               bigint, 
        tran_type                           national character varying(4), 
        account_id                          integer, 
        statement_reference                 national character varying(2000), 
        currency_code                       national character varying(12), 
        amount_in_currency                  numeric(30, 6), 
        local_currency_code                 national character varying(12), 
        er                                  numeric(30, 6), 
        amount_in_local_currency            numeric(30, 6)
    );

    BEGIN TRY
        DECLARE @tran_count int = @@TRANCOUNT;
        
        IF(@tran_count= 0)
        BEGIN
            BEGIN TRANSACTION
        END;
        
        SELECT
            @can_post_transaction           = can_post_transaction,
            @error_message                  = error_message
        FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date);

        IF(@can_post_transaction = 0)
        BEGIN
            RAISERROR(@error_message, 13, 1);
            RETURN;
        END;

        SET @tax_account_id                 = finance.get_sales_tax_account_id_by_office_id(@office_id);

        IF(COALESCE(@supplier_id, 0) = 0)
        BEGIN
            RAISERROR('Invalid supplier', 13, 1);
        END;
        


		SELECT @sales_tax_rate = finance.tax_setups.sales_tax_rate
		FROM finance.tax_setups
		WHERE finance.tax_setups.deleted = 0
		AND finance.tax_setups.office_id = @office_id;

        INSERT INTO @checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
        SELECT store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, COALESCE(is_taxed, 1)
        FROM @details;

        UPDATE @checkout_details 
        SET
            base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
            base_unit_id                    = inventory.get_root_unit_id(unit_id),
            purchase_account_id             = inventory.get_purchase_account_id(item_id),
            purchase_discount_account_id    = inventory.get_purchase_discount_account_id(item_id),
            inventory_account_id            = inventory.get_inventory_account_id(item_id);
        
		UPDATE @checkout_details
		SET
            discount                        = COALESCE(ROUND(((price * quantity) + shipping_charge) * (discount_rate / 100), 2), 0)
		WHERE COALESCE(discount, 0) = 0;

		UPDATE @checkout_details
		SET
            discount_rate                   = COALESCE(ROUND(100 * discount / ((price * quantity) + shipping_charge), 2), 0)
		WHERE COALESCE(discount_rate, 0) = 0;


		UPDATE @checkout_details 
		SET 
			is_taxable_item = inventory.items.is_taxable_item
		FROM @checkout_details AS checkout_details
		INNER JOIN inventory.items
		ON inventory.items.item_id = checkout_details.item_id;

		UPDATE @checkout_details
		SET is_taxed = 0
		WHERE is_taxable_item = 0;

		UPDATE @checkout_details
		SET amount = (COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0);

		IF EXISTS
		(
			SELECT 1
			FROM @checkout_details
			WHERE amount < 0
		)
		BEGIN
			RAISERROR('A line amount cannot be less than zero.', 16, 1);
		END;

        IF EXISTS
        (
            SELECT TOP 1 0 FROM @checkout_details AS details
            WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
        )
        BEGIN
            RAISERROR('Item/unit mismatch.', 13, 1);
        END;

		SELECT 
			@taxable_total		= COALESCE(SUM(CASE WHEN is_taxed = 1 THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0),
			@nontaxable_total	= COALESCE(SUM(CASE WHEN is_taxed = 0 THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0)
		FROM @checkout_details;

		IF(@invoice_discount > @taxable_total)
		BEGIN
			RAISERROR('The invoice discount cannot be greater than total taxable amount.', 16, 1);
		END;

        SELECT @discount_total				= SUM(COALESCE(discount, 0)) FROM @checkout_details;

        SELECT @shipping_charge				= SUM(COALESCE(shipping_charge, 0)) FROM @checkout_details;
        SELECT @tax_total					= ROUND((COALESCE(@taxable_total, 0) - COALESCE(@invoice_discount, 0)) * (@sales_tax_rate / 100), 2);
        SELECT @grand_total					= COALESCE(@taxable_total, 0) + COALESCE(@nontaxable_total, 0) + COALESCE(@tax_total, 0) - COALESCE(@discount_total, 0)  - COALESCE(@invoice_discount, 0);
        SET @payable						= @grand_total;

        SET @default_currency_code          = core.get_currency_code_by_office_id(@office_id);
        SET @tran_counter                   = finance.get_new_transaction_counter(@value_date);
        SET @transaction_code               = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);

        IF(@is_periodic = 1)
        BEGIN
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 
				'Dr', purchase_account_id, @statement_reference, @default_currency_code, 
				SUM((COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0)), 
				1, @default_currency_code, 
				SUM((COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0))
            FROM @checkout_details
            GROUP BY purchase_account_id;
        END
        ELSE
        BEGIN
            --Perpetutal Inventory Accounting System
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 
				'Dr', inventory_account_id, @statement_reference, @default_currency_code, 
				SUM((COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0)), 
				1, @default_currency_code, 
				SUM((COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0))
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

        IF(@invoice_discount > 0)
        BEGIN
			DECLARE @purchase_discount_account_id integer;

			SELECT @purchase_discount_account_id = inventory.stores.purchase_discount_account_id
			FROM inventory.stores
			WHERE inventory.stores.store_id = @store_id;

            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Cr', @purchase_discount_account_id, @statement_reference, @default_currency_code, @invoice_discount, 1, @default_currency_code, @invoice_discount;
        END;


        IF(COALESCE(@tax_total, 0) > 0)
        BEGIN
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Dr', @tax_account_id, @statement_reference, @default_currency_code, @tax_total, 1, @default_currency_code, @tax_total;
        END;    


        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Cr', inventory.get_account_id_by_supplier_id(@supplier_id), @statement_reference, @default_currency_code, @payable, 1, @default_currency_code, @payable;
        

		IF
		(
			SELECT SUM(CASE WHEN tran_type = 'Cr' THEN 1 ELSE -1 END * amount_in_local_currency)
			FROM @temp_transaction_details
		) != 0
		BEGIN
			--SELECT finance.get_account_name_by_account_id(account_id), * FROM @temp_transaction_details ORDER BY tran_type;
			RAISERROR('Could not balance the Journal Entry. Nothing was saved.', 16, 1);		
		END;

        INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
        SELECT @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;
        SET @transaction_master_id = SCOPE_IDENTITY();
        
        UPDATE @temp_transaction_details SET transaction_master_id = @transaction_master_id;        

        INSERT INTO finance.transaction_details(value_date, book_date, office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
        SELECT @value_date, @book_date, @office_id, @transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
        FROM @temp_transaction_details
        ORDER BY tran_type DESC;


        INSERT INTO inventory.checkouts(value_date, book_date, transaction_master_id, transaction_book, posted_by, shipper_id, office_id, discount, taxable_total, tax_rate, tax, nontaxable_total)
        SELECT @value_date, @book_date, @transaction_master_id, @book_name, @user_id, @shipper_id, @office_id, @invoice_discount, @taxable_total, @sales_tax_rate, @tax_total, @nontaxable_total;
        SET @checkout_id                = SCOPE_IDENTITY();
        UPDATE @checkout_details SET checkout_id = @checkout_id;

        INSERT INTO purchase.purchases(checkout_id, supplier_id, price_type_id)
        SELECT @checkout_id, @supplier_id, @price_type_id;

        INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity, is_taxed)
        SELECT @checkout_id, @value_date, @book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity, is_taxed
        FROM @checkout_details;
        

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
--DECLARE @office_id								integer 							= (SELECT TOP 1 office_id FROM core.offices);
--DECLARE @user_id                                integer 							= (SELECT TOP 1 user_id FROM account.users);
--DECLARE @login_id                               bigint  							= (SELECT TOP 1 login_id FROM account.logins WHERE user_id = @user_id);
--DECLARE @value_date                             date								= finance.get_value_date(@office_id);
--DECLARE @book_date                              date								= finance.get_value_date(@office_id);
--DECLARE @cost_center_id                         integer								= (SELECT TOP 1 cost_center_id FROM finance.cost_centers);
--DECLARE @reference_number                       national character varying(24)		= 'N/A';
--DECLARE @statement_reference                    national character varying(2000)	= 'Test';
--DECLARE @supplier_id                            integer								= (SELECT TOP 1 supplier_id FROM inventory.suppliers);
--DECLARE @price_type_id                          integer								= (SELECT TOP 1 price_type_id FROM sales.price_types);
--DECLARE @shipper_id                             integer								= (SELECT TOP 1 shipper_id FROM inventory.shippers);
--DECLARE @store_id                               integer								= (SELECT TOP 1 store_id FROM inventory.stores WHERE store_name='Cold Room FG');
--DECLARE @details								purchase.purchase_detail_type;
--DECLARE @invoice_discount						numeric(30, 6)						= 0.00;
--DECLARE @transaction_master_id					bigint;

--INSERT INTO @details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge)
--SELECT @store_id, 'Dr', 1, 1, 6, 1600, 16.67, 300, 200;

--EXECUTE purchase.post_purchase
--    @office_id,
--    @user_id,
--    @login_id,
--    @value_date,
--    @book_date,
--    @cost_center_id,
--    @reference_number,
--    @statement_reference,
--    @supplier_id,
--    @price_type_id,
--    @shipper_id,
--    @store_id,
--    @details,
--	@invoice_discount,
--	@transaction_master_id OUTPUT;


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/02.functions-and-logic/purchase.post_return.sql --<--<--
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
    @store_id								integer,
    @cost_center_id                         integer,
    @supplier_id                            integer,
    @price_type_id                          integer,
    @shipper_id                             integer,
    @reference_number                       national character varying(24),
    @statement_reference                    national character varying(2000),
    @details                                purchase.purchase_detail_type READONLY,
	@invoice_discount						numeric(30, 6),
    @tran_master_id                         bigint OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	DECLARE @reversal_tran_id		bigint;
	DECLARE @new_tran_id			bigint;
    DECLARE @book_name              national character varying(50) = 'Purchase Return';
    DECLARE @tran_counter           integer;
    DECLARE @tran_code              national character varying(50);
    DECLARE @checkout_id            bigint;
    DECLARE @grand_total            numeric(30, 6);
    DECLARE @discount_total         numeric(30, 6);
    DECLARE @is_credit              bit;
    DECLARE @default_currency_code  national character varying(12);
    DECLARE @cost_of_goods_sold     numeric(30, 6);
    DECLARE @ck_id                  bigint;
    DECLARE @purchase_id            bigint;
    DECLARE @tax_total              numeric(30, 6);
    DECLARE @tax_account_id         integer;
	DECLARE @fiscal_year_code		national character varying(12);
    DECLARE @can_post_transaction   bit;
    DECLARE @error_message          national character varying(MAX);
	DECLARE @original_checkout_id	bigint;
	DECLARE @original_supplier_id	integer;
	DECLARE @difference				purchase.purchase_detail_type;
	DECLARE @validate				bit;

	SELECT @validate = validate_returns 
	FROM inventory.inventory_setup
	WHERE office_id = @office_id;

	
	IF(COALESCE(@transaction_master_id, 0) = 0 AND @validate = 0)
	BEGIN
		EXECUTE purchase.post_return_without_validation
			@office_id                      ,
			@user_id                        ,
			@login_id                       ,
			@value_date                     ,
			@book_date                      ,
			@store_id                       ,
			@cost_center_id                 ,
			@supplier_id                    ,
			@price_type_id                  ,
			@shipper_id						,
			@reference_number               ,
			@statement_reference            ,
			@details                        ,
			@invoice_discount				,
			@tran_master_id                 OUTPUT;
		
		RETURN;
	END;

	SELECT 
		@original_supplier_id = purchase.purchases.supplier_id,
		@original_checkout_id = inventory.checkouts.checkout_id
	FROM purchase.purchases
	INNER JOIN inventory.checkouts
	ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
	INNER JOIN finance.transaction_master
	ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
	AND finance.transaction_master.verification_status_id > 0
	AND finance.transaction_master.transaction_master_id = @transaction_master_id;

	DECLARE @new_checkout_items TABLE
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
		is_taxed					bit
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

        SET @tax_account_id                         = finance.get_sales_tax_account_id_by_office_id(@office_id);

		
		IF(@original_supplier_id IS NULL)
		BEGIN
			RAISERROR('Invalid transaction.', 16, 1);
		END;

		IF(@original_supplier_id != @supplier_id)
		BEGIN
			RAISERROR('This supplier is not associated with the purchase you are trying to return.', 16, 1);
		END;

		DECLARE @is_valid_transaction	bit;
		SELECT
			@is_valid_transaction	=	is_valid,
			@error_message			=	"error_message"
		FROM purchase.validate_items_for_return(@transaction_master_id, @details);

        IF(@is_valid_transaction = 0)
        BEGIN
            RAISERROR(@error_message, 16, 1);
            RETURN;
        END;

        SET @default_currency_code      = core.get_currency_code_by_office_id(@office_id);
        SET @tran_counter               = finance.get_new_transaction_counter(@value_date);
        SET @tran_code                  = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);

        SELECT @purchase_id = purchase.purchases.purchase_id 
        FROM purchase.purchases
		INNER JOIN inventory.checkouts
		ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
        AND inventory.checkouts.transaction_master_id = @transaction_master_id;

		--Returned items are subtracted
		INSERT INTO @new_checkout_items(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
		SELECT store_id, transaction_type, item_id, quantity *-1, unit_id, price, discount_rate, discount, shipping_charge, is_taxed
		FROM @details;

		--Original items are added
		INSERT INTO @new_checkout_items(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
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
		WHERE checkout_id = @original_checkout_id;


		UPDATE @new_checkout_items 
		SET
			base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
			base_unit_id                    = inventory.get_root_unit_id(unit_id),
			discount                        = ROUND(((price * quantity) + shipping_charge) * (discount_rate / 100), 2);

		IF EXISTS
		(
			SELECT item_id, COUNT(DISTINCT unit_id) 
			FROM @new_checkout_items
			GROUP BY item_id
			HAVING COUNT(DISTINCT unit_id) > 1
		)
		BEGIN
			RAISERROR('A return entry must exactly macth the unit of measure provided during purchase.', 16, 1);
		END;
	
		IF EXISTS
		(
			SELECT item_id, COUNT(DISTINCT ABS(price))
			FROM @new_checkout_items
			GROUP BY item_id
			HAVING COUNT(DISTINCT ABS(price)) > 1
		)
		BEGIN
			RAISERROR('A return entry must exactly macth the price provided during purchase.', 16, 1);
		END;
	
		IF EXISTS
		(
			SELECT item_id, COUNT(DISTINCT discount_rate) 
			FROM @new_checkout_items
			GROUP BY item_id
			HAVING COUNT(DISTINCT discount_rate) > 1
		)
		BEGIN
			RAISERROR('A return entry must exactly macth the discount rate provided during purchase.', 16, 1);
		END;
	
	
		IF EXISTS
		(
			SELECT item_id, COUNT(DISTINCT store_id) 
			FROM @new_checkout_items
			GROUP BY item_id
			HAVING COUNT(DISTINCT store_id) > 1
		)
		BEGIN
			RAISERROR('A return entry must exactly macth the store provided during purchase.', 16, 1);
		END;

		INSERT INTO @difference(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
		SELECT store_id, 'Dr', item_id, SUM(quantity), unit_id, price, discount_rate, discount, shipping_charge, is_taxed
		FROM @new_checkout_items
		GROUP BY store_id, item_id, unit_id, discount_rate, discount, price, is_taxed, shipping_charge;
		
		DELETE FROM @difference
		WHERE quantity = 0;

		--> REVERSE THE ORIGINAL TRANSACTION
        INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference)
		SELECT @tran_counter, @tran_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;

		SET @reversal_tran_id = SCOPE_IDENTITY();

		INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
		SELECT 
			@reversal_tran_id, 
			office_id, 
			value_date, 
			book_date, 
			CASE WHEN tran_type = 'Dr' THEN 'Cr' ELSE 'Dr' END, 
			account_id, 
			@statement_reference, 
			currency_code, 
			amount_in_currency, 
			er, 
			local_currency_code, 
			amount_in_local_currency
		FROM finance.transaction_details
		WHERE finance.transaction_details.transaction_master_id = @transaction_master_id;

		IF EXISTS(SELECT * FROM @difference)
		BEGIN
			--> ADD A NEW PURCHASE INVOICE
			EXECUTE purchase.post_purchase
				@office_id,
				@user_id,
				@login_id,
				@value_date,
				@book_date,
				@cost_center_id,
				@reference_number,
				@statement_reference,
				@supplier_id,
				@price_type_id,
				@shipper_id,
				@store_id,
				@difference,
				@invoice_discount,
				@new_tran_id  OUTPUT,
				@book_name;
		END;
		ELSE
		BEGIN
			SET @tran_counter               = finance.get_new_transaction_counter(@value_date);
			SET @tran_code                  = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);

			INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference)
			SELECT @tran_counter, @tran_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;

			SET @new_tran_id = SCOPE_IDENTITY();
		END;

		INSERT INTO inventory.checkouts(transaction_book, value_date, book_date, transaction_master_id, office_id, posted_by, discount, taxable_total, tax_rate, tax, nontaxable_total)
		SELECT @book_name, @value_date, @book_date, @new_tran_id, office_id, @user_id, discount, taxable_total, tax_rate, tax, nontaxable_total
		FROM inventory.checkouts
		WHERE inventory.checkouts.checkout_id = @original_checkout_id;

		SET @checkout_id = SCOPE_IDENTITY();

        INSERT INTO inventory.checkout_details(value_date, book_date, checkout_id, transaction_type, store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, is_taxed, cost_of_goods_sold, discount)
		SELECT @value_date, @book_date, @checkout_id, 
		CASE WHEN transaction_type = 'Dr' THEN 'Cr' ELSE 'Dr' END, 
		store_id, item_id, quantity, unit_id, base_quantity, base_unit_id, price, is_taxed, cost_of_goods_sold, discount
		FROM inventory.checkout_details
		WHERE inventory.checkout_details.checkout_id = @original_checkout_id;

		INSERT INTO purchase.purchase_returns(purchase_id, checkout_id, supplier_id)
		SELECT @purchase_id, @checkout_id, @supplier_id;

		SET @tran_master_id = @new_tran_id;

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




 --DECLARE @transaction_master_id          bigint = 80077;
 --DECLARE @office_id                      integer = 1;
 --DECLARE @user_id                        integer = 1;
 --DECLARE @login_id                       bigint = (SELECT TOP 1 login_id FROM account.logins WHERE user_id = @user_id);
 --DECLARE @value_date                     date = finance.get_value_date(@office_id);
 --DECLARE @book_date                      date = finance.get_value_date(@office_id);
 --DECLARE @store_id                       integer = 1;
 --DECLARE @cost_center_id                 integer = 1;
 --DECLARE @shipper_id					 integer = 1;
 --DECLARE @supplier_id                    integer = 3010;
 --DECLARE @price_type_id                  integer = 1;
 --DECLARE @reference_number               national character varying(24) = 'N/A';
 --DECLARE @statement_reference            national character varying(2000) = 'Test';
 --DECLARE @details                        purchase.purchase_detail_type;
 --DECLARE @tran_master_id                 bigint;

 --INSERT INTO @details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
 --SELECT @store_id, 'Dr', 28789, 1, 1, 32.24, 0, 0, 0, 1;


 --EXECUTE purchase.post_return
 --    @transaction_master_id          ,
 --    @office_id                      ,
 --    @user_id                        ,
 --    @login_id                       ,
 --    @value_date                     ,
 --    @book_date                      ,
 --    @store_id                       ,
 --    @cost_center_id                 ,
 --    @supplier_id                    ,
 --    @price_type_id                  ,
	-- @shipper_id						,
 --    @reference_number               ,
 --    @statement_reference            ,
 --    @details                        ,
	-- 400,--discount
 --    @tran_master_id                 OUTPUT;






-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/02.functions-and-logic/purchase.post_return_without_validation.sql --<--<--
IF OBJECT_ID('purchase.post_return_without_validation') IS NOT NULL
DROP PROCEDURE purchase.post_return_without_validation;

GO

CREATE PROCEDURE purchase.post_return_without_validation
(
    @office_id                              integer,
    @user_id                                integer,
    @login_id                               bigint,
    @value_date                             date,
    @book_date                              date,
    @store_id								integer,
    @cost_center_id                         integer,
    @supplier_id                            integer,
    @price_type_id                          integer,
    @shipper_id                             integer,
    @reference_number                       national character varying(24),
    @statement_reference                    national character varying(2000),
    @details                                purchase.purchase_detail_type READONLY,
	@invoice_discount						numeric(30, 6),
    @tran_master_id                         bigint OUTPUT
)
AS
BEGIN    
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @checkout_id                    bigint;
    DECLARE @checkout_detail_id             bigint;
    DECLARE @shipping_address_id            integer;
    DECLARE @grand_total                    numeric(30, 6);
    DECLARE @discount_total                 numeric(30, 6);
    DECLARE @payable                        numeric(30, 6);
    DECLARE @default_currency_code          national character varying(12);
    DECLARE @is_periodic                    bit = inventory.is_periodic_inventory(@office_id);
    DECLARE @tran_counter                   integer;
    DECLARE @transaction_code               national character varying(50);
    DECLARE @tax_total                      numeric(30, 6);
    DECLARE @tax_account_id                 integer;
    DECLARE @shipping_charge                numeric(30, 6);
	DECLARE @sales_tax_rate					numeric(30, 6);
    DECLARE @book_name						national character varying(50) = 'Purchase Return';
    DECLARE @can_post_transaction           bit;
    DECLARE @error_message                  national character varying(MAX);
	DECLARE @taxable_total					numeric(30, 6);
	DECLARE @nontaxable_total				numeric(30, 6);

    DECLARE @checkout_details TABLE
    (
        id                                  integer IDENTITY PRIMARY KEY,
        checkout_id                         bigint, 
        store_id                            integer,
        transaction_type                    national character varying(2),
        item_id                             integer, 
        quantity                            numeric(30, 6),
        unit_id                             integer,
        base_quantity                       numeric(30, 6),
        base_unit_id                        integer,
        price                               numeric(30, 6) NOT NULL DEFAULT(0),
        cost_of_goods_sold                  numeric(30, 6) NOT NULL DEFAULT(0),
        discount_rate                       numeric(30, 6),
        discount                            numeric(30, 6) NOT NULL DEFAULT(0),
		is_taxable_item						bit,
		is_taxed							bit,
        amount								numeric(30, 6),
        shipping_charge                     numeric(30, 6) NOT NULL DEFAULT(0),
        purchase_account_id                 integer, 
        purchase_discount_account_id        integer, 
        inventory_account_id                integer
    );

    DECLARE @temp_transaction_details TABLE
    (
        transaction_master_id               bigint, 
        tran_type                           national character varying(4), 
        account_id                          integer, 
        statement_reference                 national character varying(2000), 
        currency_code                       national character varying(12), 
        amount_in_currency                  numeric(30, 6), 
        local_currency_code                 national character varying(12), 
        er                                  numeric(30, 6), 
        amount_in_local_currency            numeric(30, 6)
    );

    BEGIN TRY
        DECLARE @tran_count int = @@TRANCOUNT;
        
        IF(@tran_count= 0)
        BEGIN
            BEGIN TRANSACTION
        END;
        
        SELECT
            @can_post_transaction           = can_post_transaction,
            @error_message                  = error_message
        FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book_name, @value_date);

        IF(@can_post_transaction = 0)
        BEGIN
            RAISERROR(@error_message, 13, 1);
            RETURN;
        END;

        SET @tax_account_id                 = finance.get_sales_tax_account_id_by_office_id(@office_id);

        IF(COALESCE(@supplier_id, 0) = 0)
        BEGIN
            RAISERROR('Invalid supplier', 13, 1);
        END;
        


		SELECT @sales_tax_rate = finance.tax_setups.sales_tax_rate
		FROM finance.tax_setups
		WHERE finance.tax_setups.deleted = 0
		AND finance.tax_setups.office_id = @office_id;

        INSERT INTO @checkout_details(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, is_taxed)
        SELECT store_id, 'Cr', item_id, quantity, unit_id, price, discount_rate, discount, shipping_charge, COALESCE(is_taxed, 1)
        FROM @details;

        UPDATE @checkout_details 
        SET
            base_quantity                   = inventory.get_base_quantity_by_unit_id(unit_id, quantity),
            base_unit_id                    = inventory.get_root_unit_id(unit_id),
            purchase_account_id             = inventory.get_purchase_account_id(item_id),
            purchase_discount_account_id    = inventory.get_purchase_discount_account_id(item_id),
            inventory_account_id            = inventory.get_inventory_account_id(item_id);
        
		UPDATE @checkout_details
		SET
            discount                        = COALESCE(ROUND(((price * quantity) + shipping_charge) * (discount_rate / 100), 2), 0)
		WHERE COALESCE(discount, 0) = 0;

		UPDATE @checkout_details
		SET
            discount_rate                   = COALESCE(ROUND(100 * discount / ((price * quantity) + shipping_charge), 2), 0)
		WHERE COALESCE(discount_rate, 0) = 0;


		UPDATE @checkout_details 
		SET 
			is_taxable_item = inventory.items.is_taxable_item
		FROM @checkout_details AS checkout_details
		INNER JOIN inventory.items
		ON inventory.items.item_id = checkout_details.item_id;

		UPDATE @checkout_details
		SET is_taxed = 0
		WHERE is_taxable_item = 0;

		UPDATE @checkout_details
		SET amount = (COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0);

		IF EXISTS
		(
			SELECT 1
			FROM @checkout_details
			WHERE amount < 0
		)
		BEGIN
			RAISERROR('A line amount cannot be less than zero.', 16, 1);
		END;

        IF EXISTS
        (
            SELECT TOP 1 0 FROM @checkout_details AS details
            WHERE inventory.is_valid_unit_id(details.unit_id, details.item_id) = 0
        )
        BEGIN
            RAISERROR('Item/unit mismatch.', 13, 1);
        END;

		SELECT 
			@taxable_total		= COALESCE(SUM(CASE WHEN is_taxed = 1 THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0),
			@nontaxable_total	= COALESCE(SUM(CASE WHEN is_taxed = 0 THEN 1 ELSE 0 END * COALESCE(amount, 0)), 0)
		FROM @checkout_details;

		IF(@invoice_discount > @taxable_total)
		BEGIN
			RAISERROR('The invoice discount cannot be greater than total taxable amount.', 16, 1);
		END;

        SELECT @discount_total				= SUM(COALESCE(discount, 0)) FROM @checkout_details;

        SELECT @shipping_charge				= SUM(COALESCE(shipping_charge, 0)) FROM @checkout_details;
        SELECT @tax_total					= ROUND((COALESCE(@taxable_total, 0) - COALESCE(@invoice_discount, 0)) * (@sales_tax_rate / 100), 2);
        SELECT @grand_total					= COALESCE(@taxable_total, 0) + COALESCE(@nontaxable_total, 0) + COALESCE(@tax_total, 0) - COALESCE(@discount_total, 0)  - COALESCE(@invoice_discount, 0);
        SET @payable						= @grand_total;

        SET @default_currency_code          = core.get_currency_code_by_office_id(@office_id);
        SET @tran_counter                   = finance.get_new_transaction_counter(@value_date);
        SET @transaction_code               = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);

        IF(@is_periodic = 1)
        BEGIN
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 
				'Cr', purchase_account_id, @statement_reference, @default_currency_code, 
				SUM((COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0)), 
				1, @default_currency_code, 
				SUM((COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0))
            FROM @checkout_details
            GROUP BY purchase_account_id;
        END
        ELSE
        BEGIN
            --Perpetutal Inventory Accounting System
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 
				'Cr', inventory_account_id, @statement_reference, @default_currency_code, 
				SUM((COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0)), 
				1, @default_currency_code, 
				SUM((COALESCE(price, 0) * COALESCE(quantity, 0)) - COALESCE(discount, 0) + COALESCE(shipping_charge, 0))
            FROM @checkout_details
            GROUP BY inventory_account_id;
        END;


        IF(@discount_total > 0)
        BEGIN
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Dr', purchase_discount_account_id, @statement_reference, @default_currency_code, SUM(COALESCE(discount, 0)), 1, @default_currency_code, SUM(COALESCE(discount, 0))
            FROM @checkout_details
            GROUP BY purchase_discount_account_id;
        END;

        IF(@invoice_discount > 0)
        BEGIN
			DECLARE @purchase_discount_account_id integer;

			SELECT @purchase_discount_account_id = inventory.stores.purchase_discount_account_id
			FROM inventory.stores
			WHERE inventory.stores.store_id = @store_id;

            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Dr', @purchase_discount_account_id, @statement_reference, @default_currency_code, @invoice_discount, 1, @default_currency_code, @invoice_discount;
        END;


        IF(COALESCE(@tax_total, 0) > 0)
        BEGIN
            INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
            SELECT 'Cr', @tax_account_id, @statement_reference, @default_currency_code, @tax_total, 1, @default_currency_code, @tax_total;
        END;    


        INSERT INTO @temp_transaction_details(tran_type, account_id, statement_reference, currency_code, amount_in_currency, er, local_currency_code, amount_in_local_currency)
        SELECT 'Dr', inventory.get_account_id_by_supplier_id(@supplier_id), @statement_reference, @default_currency_code, @payable, 1, @default_currency_code, @payable;
        

		IF
		(
			SELECT SUM(CASE WHEN tran_type = 'Cr' THEN 1 ELSE -1 END * amount_in_local_currency)
			FROM @temp_transaction_details
		) != 0
		BEGIN
			--SELECT finance.get_account_name_by_account_id(account_id), * FROM @temp_transaction_details ORDER BY tran_type;
			RAISERROR('Could not balance the Journal Entry. Nothing was saved.', 16, 1);		
		END;

        INSERT INTO finance.transaction_master(transaction_counter, transaction_code, book, value_date, book_date, user_id, login_id, office_id, cost_center_id, reference_number, statement_reference) 
        SELECT @tran_counter, @transaction_code, @book_name, @value_date, @book_date, @user_id, @login_id, @office_id, @cost_center_id, @reference_number, @statement_reference;
        SET @tran_master_id = SCOPE_IDENTITY();

        UPDATE @temp_transaction_details SET transaction_master_id = @tran_master_id;        
        UPDATE @checkout_details SET checkout_id = @checkout_id;
        
        INSERT INTO finance.transaction_details(value_date, book_date, office_id, transaction_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency)
        SELECT @value_date, @book_date, @office_id, @tran_master_id, tran_type, account_id, statement_reference, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency
        FROM @temp_transaction_details
        ORDER BY tran_type DESC;


        INSERT INTO inventory.checkouts(value_date, book_date, transaction_master_id, transaction_book, posted_by, shipper_id, office_id, discount, taxable_total, tax_rate, tax, nontaxable_total)
        SELECT @value_date, @book_date, @tran_master_id, @book_name, @user_id, @shipper_id, @office_id, @invoice_discount, @taxable_total, @sales_tax_rate, @tax_total, @nontaxable_total;
        SET @checkout_id                = SCOPE_IDENTITY();

        INSERT INTO purchase.purchases(checkout_id, supplier_id, price_type_id)
        SELECT @checkout_id, @supplier_id, @price_type_id;

        INSERT INTO inventory.checkout_details(checkout_id, value_date, book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity, is_taxed)
        SELECT @checkout_id, @value_date, @book_date, store_id, transaction_type, item_id, price, discount_rate, discount, cost_of_goods_sold, shipping_charge, unit_id, quantity, base_unit_id, base_quantity, is_taxed
        FROM @checkout_details;
        

		ALTER TABLE purchase.purchase_returns
		ALTER COLUMN purchase_id bigint NULL;

		INSERT INTO purchase.purchase_returns(purchase_id, checkout_id, supplier_id)
		SELECT NULL, @checkout_id, @supplier_id;

        EXECUTE finance.auto_verify @tran_master_id, @office_id;

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




-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/02.functions-and-logic/purchase.post_supplier_payment.sql --<--<--
IF OBJECT_ID('purchase.post_supplier_payment') IS NOT NULL
DROP PROCEDURE purchase.post_supplier_payment;

GO

CREATE PROCEDURE purchase.post_supplier_payment
(
	@value_date									date,
	@book_date									date,
    @user_id                                    integer, 
    @office_id                                  integer, 
    @login_id                                   bigint,
    @supplier_id                                integer, 
    @currency_code                              national character varying(12),
    @cash_account_id                            integer,
    @amount                                     numeric(30, 6), 
    @exchange_rate_debit                        numeric(30, 6), 
    @exchange_rate_credit                       numeric(30, 6),
    @reference_number                           national character varying(24), 
    @statement_reference                        national character varying(128), 
    @cost_center_id                             integer,
    @cash_repository_id                         integer,
    @posted_date                                date,
    @bank_id									integer,
    @bank_instrument_code                       national character varying(128),
    @bank_tran_code                             national character varying(128),
	@transaction_master_id						bigint OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	DECLARE @bank_account_id					integer = finance.get_account_id_by_bank_account_id(@bank_id);
    DECLARE @book                               national character varying(50);
    DECLARE @base_currency_code                 national character varying(12);
    DECLARE @local_currency_code                national character varying(12);
    DECLARE @supplier_account_id                integer;
    DECLARE @debit                              numeric(30, 6);
    DECLARE @credit                             numeric(30, 6);
    DECLARE @lc_debit                           numeric(30, 6);
    DECLARE @lc_credit                          numeric(30, 6);
    DECLARE @is_cash                            bit;
    DECLARE @can_post_transaction				bit;
    DECLARE @error_message						national character varying(MAX);

    BEGIN TRY
        DECLARE @tran_count int = @@TRANCOUNT;
        
        IF(@tran_count= 0)
        BEGIN
            BEGIN TRANSACTION
        END;
        
        SELECT
            @can_post_transaction   = can_post_transaction,
            @error_message          = error_message
        FROM finance.can_post_transaction(@login_id, @user_id, @office_id, @book, @value_date);

        IF(@can_post_transaction = 0)
        BEGIN
            RAISERROR(@error_message, 13, 1);
            RETURN;
        END;

		IF(@cash_repository_id > 0)
		BEGIN
			IF(@posted_date IS NOT NULL OR @bank_id IS NOT NULL OR COALESCE(@bank_instrument_code, '') != '' OR COALESCE(@bank_tran_code, '') != '')
			BEGIN
				RAISERROR('Invalid bank transaction information provided.', 16, 1);
			END;

			SET @is_cash = 1;
		END;

		SET @book                                   = 'Purchase Payment';    
		SET @supplier_account_id                    = inventory.get_account_id_by_supplier_id(@supplier_id);    
		SET @local_currency_code                    = core.get_currency_code_by_office_id(@office_id);
		SET @base_currency_code                     = inventory.get_currency_code_by_supplier_id(@supplier_id);

		IF(@local_currency_code = @currency_code AND @exchange_rate_debit != 1)
		BEGIN
			RAISERROR('Invalid exchange rate.', 16, 1);
		END;

		IF(@local_currency_code = @base_currency_code AND @exchange_rate_credit != 1)
		BEGIN
			RAISERROR('Invalid exchange rate.', 16, 1);
		END;
        
		SET @debit                                  = @amount;
		SET @lc_debit                               = @amount * @exchange_rate_debit;

		SET @credit                                 = @amount * (@exchange_rate_debit/ @exchange_rate_credit);
		SET @lc_credit                              = @amount * @exchange_rate_debit;
    
		INSERT INTO finance.transaction_master
		(
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
			finance.get_new_transaction_counter(@value_date), 
			finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id),
			@book,
			@value_date,
			@book_date,
			@user_id,
			@login_id,
			@office_id,
			@cost_center_id,
			@reference_number,
			@statement_reference;


		SET @transaction_master_id = SCOPE_IDENTITY();

		--Debit
		IF(@is_cash = 1)
		BEGIN
			INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
			SELECT @transaction_master_id, @office_id, @value_date, @book_date, 'Cr', @cash_account_id, @statement_reference, @cash_repository_id, @currency_code, @debit, @local_currency_code, @exchange_rate_debit, @lc_debit, @user_id;
		END
		ELSE
		BEGIN
			INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
			SELECT @transaction_master_id, @office_id, @value_date, @book_date, 'Cr', @bank_account_id, @statement_reference, NULL, @currency_code, @debit, @local_currency_code, @exchange_rate_debit, @lc_debit, @user_id;        
		END;

		--Credit
		INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
		SELECT @transaction_master_id, @office_id, @value_date, @book_date, 'Dr', @supplier_account_id, @statement_reference, NULL, @base_currency_code, @credit, @local_currency_code, @exchange_rate_credit, @lc_credit, @user_id;
    
    
		INSERT INTO purchase.supplier_payments(transaction_master_id, supplier_id, currency_code, amount, er_debit, er_credit, cash_repository_id, posted_date, bank_id, bank_instrument_code, bank_transaction_code)
		SELECT @transaction_master_id, @supplier_id, @currency_code, @amount,  @exchange_rate_debit, @exchange_rate_credit, @cash_repository_id, @posted_date, @bank_account_id, @bank_instrument_code, @bank_tran_code;

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

--EXECUTE purchase.post_supplier_payment

--     1, --@user_id                                    integer, 
--     1, --@office_id                                  integer, 
--     1, --@login_id                                   bigint,
--     1, --@supplier_id                                integer, 
--     'USD', --@currency_code                              national character varying(12), 
--     1,--    @cash_account_id                            integer,
--     100, --@amount                                     numeric(30, 6), 
--     1, --@exchange_rate_debit                        numeric(30, 6), 
--     1, --@exchange_rate_credit                       numeric(30, 6),
--     '', --@reference_number                           national character varying(24), 
--     '', --@statement_reference                        national character varying(128), 
--     1, --@cost_center_id                             integer,
--     1, --@cash_repository_id                         integer,
--     NULL, --@posted_date                                date,
--     NULL, --@bank_id                            bigint,
--     NULL, -- @bank_instrument_code                       national character varying(128),
--     NULL, -- @bank_tran_code                             national character varying(128),
--	 NULL
--;


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/02.functions-and-logic/purchase.validate_items_for_return.sql --<--<--
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



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/03.menus/menus.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/05.views/purchase.purchase_search_view.sql --<--<--
IF OBJECT_ID('purchase.purchase_search_view') IS NOT NULL
DROP VIEW purchase.purchase_search_view;

GO

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
WHERE finance.transaction_master.deleted = 0
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


GO



-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/SQL Server/2.1.update/src/99.ownership.sql --<--<--
EXEC sp_addrolemember  @rolename = 'db_owner', @membername  = 'frapid_db_user'
GO

EXEC sp_addrolemember  @rolename = 'db_datareader', @membername  = 'report_user'
GO

DECLARE @proc sysname
DECLARE @cmd varchar(8000)

DECLARE cur CURSOR FOR 
SELECT '[' + schema_name(schema_id) + '].[' + name + ']' FROM sys.objects
WHERE type IN('FN')
AND is_ms_shipped = 0
ORDER BY 1
OPEN cur
FETCH next from cur into @proc
WHILE @@FETCH_STATUS = 0
BEGIN
     SET @cmd = 'GRANT EXEC ON ' + @proc + ' TO report_user';
     EXEC (@cmd)

     FETCH next from cur into @proc
END
CLOSE cur
DEALLOCATE cur

GO

