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
	@invoice_discount						decimal(30, 6),
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
    DECLARE @grand_total            decimal(30, 6);
    DECLARE @discount_total         decimal(30, 6);
    DECLARE @is_credit              bit;
    DECLARE @default_currency_code  national character varying(12);
    DECLARE @cost_of_goods_sold     decimal(30, 6);
    DECLARE @ck_id                  bigint;
    DECLARE @purchase_id            bigint;
    DECLARE @tax_total              decimal(30, 6);
    DECLARE @tax_account_id         integer;
	DECLARE @fiscal_year_code		national character varying(12);
    DECLARE @can_post_transaction   bit;
    DECLARE @error_message          national character varying(MAX);
	DECLARE @original_checkout_id	bigint;
	DECLARE @original_supplier_id	integer;
	DECLARE @difference				purchase.purchase_detail_type;

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
		quantity					decimal(30, 6),
		unit_id						integer,
        base_quantity				decimal(30, 6),
        base_unit_id                integer,                
		price						decimal(30, 6),
		discount_rate				decimal(30, 6),
		discount					decimal(30, 6),
		shipping_charge				decimal(30, 6)
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

        SET @default_currency_code          = core.get_currency_code_by_office_id(@office_id);
        SET @tran_counter               = finance.get_new_transaction_counter(@value_date);
        SET @tran_code                  = finance.get_transaction_code(@value_date, @office_id, @user_id, @login_id);

        SELECT @purchase_id = purchase.purchases.purchase_id 
        FROM purchase.purchases
		INNER JOIN inventory.checkouts
		ON inventory.checkouts.checkout_id = purchase.purchases.checkout_id
        AND inventory.checkouts.transaction_master_id = @transaction_master_id;




		--Returned items are subtracted
		INSERT INTO @new_checkout_items(store_id, item_id, quantity, unit_id, price, discount_rate, shipping_charge)
		SELECT store_id, item_id, quantity *-1, unit_id, price *-1, discount_rate, shipping_charge *-1
		FROM @details;
	

		--Original items are added
		INSERT INTO @new_checkout_items(store_id, item_id, quantity, unit_id, price, discount_rate, shipping_charge)
		SELECT 
			inventory.checkout_details.store_id, 
			inventory.checkout_details.item_id,
			inventory.checkout_details.quantity,
			inventory.checkout_details.unit_id,
			inventory.checkout_details.price,
			inventory.checkout_details.discount_rate,
			inventory.checkout_details.shipping_charge
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

		INSERT INTO @difference(store_id, transaction_type, item_id, quantity, unit_id, price, discount_rate, shipping_charge)
		SELECT store_id, 'Dr', item_id, SUM(quantity), unit_id, SUM(price), discount_rate, SUM(shipping_charge)
		FROM @new_checkout_items
		GROUP BY store_id, item_id, unit_id, discount_rate;

			
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
				@new_tran_id  OUTPUT;
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




-- DECLARE @transaction_master_id          bigint = 245;
-- DECLARE @office_id                      integer = (SELECT TOP 1 office_id FROM core.offices);
-- DECLARE @user_id                        integer = (SELECT TOP 1 user_id FROM account.users);
-- DECLARE @login_id                       bigint = (SELECT TOP 1 login_id FROM account.logins WHERE user_id = @user_id);
-- DECLARE @value_date                     date = finance.get_value_date(@office_id);
-- DECLARE @book_date                      date = finance.get_value_date(@office_id);
-- DECLARE @store_id                       integer = (SELECT TOP 1 store_id FROM inventory.stores WHERE store_name='Cold Room RM');
-- DECLARE @cost_center_id                 integer = (SELECT TOP 1 cost_center_id FROM finance.cost_centers);
-- DECLARE @shipper_id						integer = (SELECT TOP 1 shipper_id FROM inventory.shippers);
-- DECLARE @supplier_id                    integer = 13;
-- DECLARE @price_type_id                  integer = (SELECT TOP 1 price_type_id FROM purchase.price_types);
-- DECLARE @reference_number               national character varying(24) = 'N/A';
-- DECLARE @statement_reference            national character varying(2000) = 'Test';
-- DECLARE @details                        purchase.purchase_detail_type;
-- DECLARE @tran_master_id                 bigint;

-- INSERT INTO @details
-- SELECT @store_id, 'Cr', item_id, 1, unit_id, 500, 0, 500* 0.13, 0
-- FROM inventory.items
-- WHERE inventory.items.item_code IN('SHS0005');


-- EXECUTE purchase.post_return
    -- @transaction_master_id          ,
    -- @office_id                      ,
    -- @user_id                        ,
    -- @login_id                       ,
    -- @value_date                     ,
    -- @book_date                      ,
    -- @store_id                       ,
    -- @cost_center_id                 ,
    -- @supplier_id                    ,
    -- @price_type_id                  ,
	-- @shipper_id						,
    -- @reference_number               ,
    -- @statement_reference            ,
    -- @details                        ,
	-- 400,--discount
    -- @tran_master_id                 OUTPUT;




