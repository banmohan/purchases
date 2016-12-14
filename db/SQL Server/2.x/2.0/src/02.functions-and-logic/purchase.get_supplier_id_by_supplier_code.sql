IF OBJECT_ID('purchase.get_supplier_id_by_supplier_code') IS NOT NULL
DROP FUNCTION purchase.get_supplier_id_by_supplier_code;

GO

CREATE FUNCTION purchase.get_supplier_id_by_supplier_code(@supplier_code national character varying(24))
RETURNS bigint
AS

BEGIN
    RETURN
    (
		SELECT supplier_id
		FROM inventory.suppliers
		WHERE inventory.suppliers.supplier_code=@supplier_code
		AND inventory.suppliers.deleted = 0
    );
END;





GO
