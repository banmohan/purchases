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
	finance.transaction_master.office_id
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
finance.transaction_master.transaction_ts;


GO

