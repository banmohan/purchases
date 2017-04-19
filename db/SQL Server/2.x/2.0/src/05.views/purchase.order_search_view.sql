IF OBJECT_ID('purchase.order_search_view') IS NOT NULL
DROP VIEW purchase.order_search_view;

GO

CREATE VIEW purchase.order_search_view
AS
SELECT
	purchase.orders.order_id,
	inventory.get_supplier_name_by_supplier_id(purchase.orders.supplier_id) AS supplier,
	purchase.orders.value_date,
	purchase.orders.expected_delivery_date AS expected_date,
	COALESCE(purchase.orders.taxable_total, 0) + 
	COALESCE(purchase.orders.tax, 0) + 
	COALESCE(purchase.orders.nontaxable_total, 0) - 
	COALESCE(purchase.orders.discount, 0) AS total_amount,
	COALESCE(purchase.orders.reference_number, '') AS reference_number,
	COALESCE(purchase.orders.terms, '') AS terms,
	COALESCE(purchase.orders.internal_memo, '') AS memo,
	account.get_name_by_user_id(purchase.orders.user_id) AS posted_by,
	core.get_office_name_by_office_id(purchase.orders.office_id) AS office,
	purchase.orders.transaction_timestamp AS posted_on,
	purchase.orders.office_id
FROM purchase.orders;

GO
