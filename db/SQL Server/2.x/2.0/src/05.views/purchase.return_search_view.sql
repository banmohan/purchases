IF OBJECT_ID('purchase.return_search_view') IS NOT NULL
DROP VIEW purchase.return_search_view;

GO

CREATE VIEW purchase.return_search_view
AS
SELECT 
	finance.transaction_master.transaction_master_id AS tran_id,
	finance.transaction_master.transaction_code AS tran_code,
	purchase.purchase_returns.supplier_id,
	inventory.get_supplier_name_by_supplier_id(purchase.purchase_returns.supplier_id) AS supplier,
	inventory.checkouts.taxable_total + inventory.checkouts.nontaxable_total + inventory.checkouts.tax - inventory.checkouts.discount AS amount,
	finance.transaction_master.value_date,
	finance.transaction_master.book_date,
	finance.transaction_master.reference_number,
	finance.transaction_master.statement_reference,
	account.get_name_by_user_id(finance.transaction_master.user_id) AS posted_by,
	core.get_office_name_by_office_id(finance.transaction_master.office_id) AS office,
	core.verification_statuses.verification_status_name AS status,
	account.get_name_by_user_id(finance.transaction_master.verified_by_user_id) AS verified_by,
	finance.transaction_master.last_verified_on,
	finance.transaction_master.verification_reason AS reason,
	finance.transaction_master.office_id
FROM purchase.purchase_returns
INNER JOIN inventory.checkouts
ON inventory.checkouts.checkout_id = purchase.purchase_returns.checkout_id
INNER JOIN finance.transaction_master
ON finance.transaction_master.transaction_master_id = inventory.checkouts.transaction_master_id
LEFT JOIN core.verification_statuses
ON core.verification_statuses.verification_status_id = finance.transaction_master.verification_status_id;


GO

