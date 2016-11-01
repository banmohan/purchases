DROP FUNCTION IF EXISTS purchase.get_price_type_id_by_price_type_code(_price_type_code national character varying(24));

CREATE FUNCTION purchase.get_price_type_id_by_price_type_code(_price_type_code national character varying(24))
RETURNS integer
AS
$$
BEGIN
    RETURN purchase.price_types.price_type_id
    FROM purchase.price_types
    WHERE purchase.price_types.price_type_code = _price_type_code;
END
$$
LANGUAGE plpgsql;