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
		SELECT @transaction_master_id, @supplier_id, @currency_code, @amount,  @exchange_rate_debit, @exchange_rate_credit, @cash_repository_id, @posted_date, @bank_id, @bank_instrument_code, @bank_tran_code;

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
