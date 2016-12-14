IF OBJECT_ID('purchase.get_price_type_id_by_price_type_name') IS NOT NULL
DROP FUNCTION purchase.get_price_type_id_by_price_type_name;

GO

CREATE FUNCTION purchase.get_price_type_id_by_price_type_name(@price_type_name national character varying(24))
RETURNS integer
AS

BEGIN
    RETURN
    (
	    SELECT purchase.price_types.price_type_id
	    FROM purchase.price_types
	    WHERE purchase.price_types.price_type_name = @price_type_name
    );
END;

GO
