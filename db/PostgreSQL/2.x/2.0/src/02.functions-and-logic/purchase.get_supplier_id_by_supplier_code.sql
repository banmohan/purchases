DROP FUNCTION IF EXISTS purchase.get_supplier_id_by_supplier_code(text);

CREATE FUNCTION purchase.get_supplier_id_by_supplier_code(text)
RETURNS bigint
AS
$$
BEGIN
    RETURN
    (
        SELECT
            supplier_id
        FROM
            inventory.suppliers
        WHERE 
            inventory.suppliers.supplier_code=$1
    );
END
$$
LANGUAGE plpgsql;

