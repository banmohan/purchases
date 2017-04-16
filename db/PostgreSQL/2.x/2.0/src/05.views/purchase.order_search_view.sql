DROP VIEW IF EXISTS purchase.order_search_view;

CREATE VIEW purchase.order_search_view
AS
SELECT
	purchase.orders.order_id,
	inventory.get_supplier_name_by_supplier_id(purchase.orders.supplier_id) AS supplier,
	SUM(

        ROUND
		(
			(
			(purchase.order_details.price * purchase.order_details.quantity)
			* ((100 - purchase.order_details.discount_rate)/100)) 
		, 4)  + purchase.order_details.tax		
	) AS total_amount,
	purchase.orders.value_date,
	purchase.orders.expected_delivery_date AS expected_date,
	COALESCE(purchase.orders.reference_number, '') AS reference_number,
	COALESCE(purchase.orders.terms, '') AS terms,
	COALESCE(purchase.orders.internal_memo, '') AS memo,
	account.get_name_by_user_id(purchase.orders.user_id) AS posted_by,
	core.get_office_name_by_office_id(purchase.orders.office_id) AS office,
	purchase.orders.transaction_timestamp AS posted_on,
	purchase.orders.office_id
FROM purchase.orders
INNER JOIN purchase.order_details
ON purchase.orders.order_id = purchase.order_details.order_id
GROUP BY
	purchase.orders.order_id,
	purchase.orders.supplier_id,
	purchase.orders.value_date,
	purchase.orders.expected_delivery_date,
	purchase.orders.reference_number,
	purchase.orders.terms,
	purchase.orders.internal_memo,
	purchase.orders.user_id,
	purchase.orders.transaction_timestamp,
	purchase.orders.office_id
ORDER BY purchase.orders.order_id;

