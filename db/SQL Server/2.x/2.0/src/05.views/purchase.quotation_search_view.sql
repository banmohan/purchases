IF OBJECT_ID('purchase.quotation_search_view') IS NOT NULL
DROP VIEW purchase.quotation_search_view;

GO

CREATE VIEW purchase.quotation_search_view
AS
SELECT
	purchase.quotations.quotation_id,
	inventory.get_supplier_name_by_supplier_id(purchase.quotations.supplier_id) AS supplier,
	SUM(

        ROUND
		(
			(
			(purchase.quotation_details.price * purchase.quotation_details.quantity)
			* ((100 - purchase.quotation_details.discount_rate)/100)) 
		, 4)  + purchase.quotation_details.tax		
	) AS total_amount,
	purchase.quotations.value_date,
	purchase.quotations.expected_delivery_date AS expected_date,
	COALESCE(purchase.quotations.reference_number, '') AS reference_number,
	COALESCE(purchase.quotations.terms, '') AS terms,
	COALESCE(purchase.quotations.internal_memo, '') AS memo,
	account.get_name_by_user_id(purchase.quotations.user_id) AS posted_by,
	core.get_office_name_by_office_id(purchase.quotations.office_id) AS office,
	purchase.quotations.transaction_timestamp AS posted_on,
	purchase.quotations.office_id
FROM purchase.quotations
INNER JOIN purchase.quotation_details
ON purchase.quotations.quotation_id = purchase.quotation_details.quotation_id
GROUP BY
	purchase.quotations.quotation_id,
	purchase.quotations.supplier_id,
	purchase.quotations.value_date,
	purchase.quotations.expected_delivery_date,
	purchase.quotations.reference_number,
	purchase.quotations.terms,
	purchase.quotations.internal_memo,
	purchase.quotations.user_id,
	purchase.quotations.transaction_timestamp,
	purchase.quotations.office_id;

GO
