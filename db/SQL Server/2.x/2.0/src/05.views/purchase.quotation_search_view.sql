IF OBJECT_ID('purchase.quotation_search_view') IS NOT NULL
DROP VIEW purchase.quotation_search_view;

GO

CREATE VIEW purchase.quotation_search_view
AS
SELECT
	purchase.quotations.quotation_id,
	inventory.get_supplier_name_by_supplier_id(purchase.quotations.supplier_id) AS supplier,
	purchase.quotations.value_date,
	purchase.quotations.expected_delivery_date AS expected_date,
	COALESCE(purchase.quotations.taxable_total, 0) + 
	COALESCE(purchase.quotations.tax, 0) + 
	COALESCE(purchase.quotations.nontaxable_total, 0) - 
	COALESCE(purchase.quotations.discount, 0) AS total_amount,
	COALESCE(purchase.quotations.reference_number, '') AS reference_number,
	COALESCE(purchase.quotations.terms, '') AS terms,
	COALESCE(purchase.quotations.internal_memo, '') AS memo,
	account.get_name_by_user_id(purchase.quotations.user_id) AS posted_by,
	core.get_office_name_by_office_id(purchase.quotations.office_id) AS office,
	purchase.quotations.transaction_timestamp AS posted_on,
	purchase.quotations.office_id
FROM purchase.quotations;

GO
