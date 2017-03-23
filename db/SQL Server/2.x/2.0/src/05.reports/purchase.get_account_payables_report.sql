IF OBJECT_ID('purchase.get_account_payables_report') IS NOT NULL
DROP FUNCTION purchase.get_account_payables_report;

GO

CREATE FUNCTION purchase.get_account_payables_report(@office_id integer, @from date)
RETURNS @results TABLE
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
BEGIN
    INSERT INTO @results(account_id, office_name, office_id)
    SELECT DISTINCT inventory.suppliers.account_id, core.get_office_name_by_office_id(@office_id), @office_id FROM inventory.suppliers;


    UPDATE @results
    SET
        account_number  = finance.accounts.account_number,
        account_name    = finance.accounts.account_name
    FROM @results AS results
	INNER JOIN finance.accounts
    ON finance.accounts.account_id = results.account_id;


    UPDATE @results
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
        WHERE finance.verified_transaction_view.value_date < @from
        AND finance.verified_transaction_view.office_id IN (SELECT * FROM core.get_office_ids(@office_id))
        AND finance.verified_transaction_view.account_id IN
        (
            SELECT * FROM finance.get_account_ids(results.account_id)
        )
    )
	FROM @results  results;


    UPDATE @results
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
        WHERE finance.verified_transaction_view.value_date >= @from
        AND finance.verified_transaction_view.office_id IN (SELECT * FROM core.get_office_ids(@office_id))
        AND finance.verified_transaction_view.account_id IN
        (
            SELECT * FROM finance.get_account_ids(results.account_id)
        )
    ) FROM @results AS results;

    UPDATE @results
    SET total_amount = COALESCE(results.previous_period, 0) + COALESCE(results.current_period, 0)
	FROM @results AS results;

	DELETE FROM @results
	WHERE COALESCE(previous_period, 0) = 0
	AND COALESCE(current_period, 0) = 0
	AND COALESCE(total_amount, 0) = 0;
    
    RETURN;
END

GO

--SELECT * FROM purchase.get_account_payables_report(1, '1-1-2000');

