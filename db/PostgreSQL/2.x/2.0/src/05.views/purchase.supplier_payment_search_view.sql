DROP VIEW IF EXISTS purchase.supplier_payment_search_view;

CREATE VIEW purchase.supplier_payment_search_view
AS
SELECT
	purchase.supplier_payments.transaction_master_id AS tran_id,
	finance.transaction_master.transaction_code AS tran_code,
	purchase.supplier_payments.supplier_id,
	inventory.get_supplier_name_by_supplier_id(purchase.supplier_payments.supplier_id) AS supplier,
	COALESCE(purchase.supplier_payments.amount, purchase.supplier_payments.check_amount, COALESCE(purchase.supplier_payments.tender, 0) - COALESCE(purchase.supplier_payments.change, 0)) AS amount,
	finance.transaction_master.value_date,
	finance.transaction_master.book_date,
	COALESCE(finance.transaction_master.reference_number, '') AS reference_number,
	COALESCE(finance.transaction_master.statement_reference, '') AS statement_reference,
	account.get_name_by_user_id(finance.transaction_master.user_id) AS posted_by,
	core.get_office_name_by_office_id(finance.transaction_master.office_id) AS office,
	finance.get_verification_status_name_by_verification_status_id(finance.transaction_master.verification_status_id) AS status,
	COALESCE(account.get_name_by_user_id(finance.transaction_master.verified_by_user_id), '') AS verified_by,
	finance.transaction_master.last_verified_on,
	finance.transaction_master.verification_reason AS reason,
	finance.transaction_master.office_id
FROM purchase.supplier_payments
INNER JOIN finance.transaction_master
ON purchase.supplier_payments.transaction_master_id = finance.transaction_master.transaction_master_id
WHERE NOT finance.transaction_master.deleted;
