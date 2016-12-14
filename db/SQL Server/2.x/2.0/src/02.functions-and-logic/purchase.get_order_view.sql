IF OBJECT_ID('purchase.get_order_view') IS NOT NULL
DROP FUNCTION purchase.get_order_view;

GO

CREATE FUNCTION purchase.get_order_view
(
    @user_id                        integer,
    @office_id                      integer,
    @supplier                       national character varying(500),
    @from                           date,
    @to                             date,
    @expected_from                  date,
    @expected_to                    date,
    @id                             bigint,
    @reference_number               national character varying(500),
    @internal_memo                  national character varying(500),
    @terms                          national character varying(500),
    @posted_by                      national character varying(500),
    @office                         national character varying(500)
)
RETURNS @result TABLE
(
    id                              bigint,
    supplier                        national character varying(500),
    value_date                      date,
    expected_date                   date,
    reference_number                national character varying(24),
    terms                           national character varying(500),
    internal_memo                   national character varying(500),
    posted_by                       national character varying(500),
    office                          national character varying(500),
    transaction_ts                  DATETIMEOFFSET
)
AS

BEGIN
    WITH office_cte(office_id) AS 
    (
        SELECT @office_id
        UNION ALL
        SELECT
            c.office_id
        FROM 
        office_cte AS p, 
        core.offices AS c 
        WHERE 
        parent_office_id = p.office_id
    )

    INSERT INTO @result
    SELECT 
        purchase.orders.order_id,
        inventory.get_supplier_name_by_supplier_id(purchase.orders.supplier_id),
        purchase.orders.value_date,
        purchase.orders.expected_delivery_date,
        purchase.orders.reference_number,
        purchase.orders.terms,
        purchase.orders.internal_memo,
        account.get_name_by_user_id(purchase.orders.user_id) AS posted_by,
        core.get_office_name_by_office_id(office_id) AS office,
        purchase.orders.transaction_timestamp
    FROM purchase.orders
    WHERE 1 = 1
    AND purchase.orders.value_date BETWEEN @from AND @to
    AND purchase.orders.expected_delivery_date BETWEEN @expected_from AND @expected_to
    AND purchase.orders.office_id IN (SELECT office_id FROM office_cte)
    AND (COALESCE(@id, 0) = 0 OR @id = purchase.orders.order_id)
    AND COALESCE(LOWER(purchase.orders.reference_number), '') LIKE '%' + LOWER(@reference_number) + '%' 
    AND COALESCE(LOWER(purchase.orders.internal_memo), '') LIKE '%' + LOWER(@internal_memo) + '%' 
    AND COALESCE(LOWER(purchase.orders.terms), '') LIKE '%' + LOWER(@terms) + '%' 
    AND LOWER(inventory.get_customer_name_by_customer_id(purchase.orders.supplier_id)) LIKE '%' + LOWER(@supplier) + '%' 
    AND LOWER(account.get_name_by_user_id(purchase.orders.user_id)) LIKE '%' + LOWER(@posted_by) + '%' 
    AND LOWER(core.get_office_name_by_office_id(purchase.orders.office_id)) LIKE '%' + LOWER(@office) + '%' 
    AND purchase.orders.deleted = 0;

    RETURN;
END;




--SELECT * FROM purchase.get_order_view(1,1,'', '11/27/2010','11/27/2016','1-1-2000','1-1-2020', null,'','','','', '');


GO
