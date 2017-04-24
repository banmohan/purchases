DROP FUNCTION IF EXISTS purchase.get_item_cost_price(_office_id integer, _item_id integer, _supplier_id bigint, _unit_id integer);

CREATE FUNCTION purchase.get_item_cost_price(_office_id integer, _item_id integer, _supplier_id bigint, _unit_id integer)
RETURNS numeric(30, 6)
AS
$$
    DECLARE _price              numeric(30, 6);
    DECLARE _costing_unit_id    integer;
    DECLARE _factor             numeric(30, 6);
    DECLARE _includes_tax       boolean;
    DECLARE _tax_rate           decimal(30, 6);
BEGIN
	SELECT inventory.items.cost_price_includes_tax INTO _includes_tax
	FROM inventory.items
	WHERE inventory.items.item_id = _item_id;

	SELECT
        purchase.supplierwise_cost_prices.price,
		purchase.supplierwise_cost_prices.unit_id
    INTO
        _price,
        _costing_unit_id
	FROM purchase.supplierwise_cost_prices
	WHERE NOT purchase.supplierwise_cost_prices.deleted
	AND purchase.supplierwise_cost_prices.supplier_id = _supplier_id
	AND purchase.supplierwise_cost_prices.item_id = _item_id;

	
	IF(_price IS NULL) THEN
        --Pick the catalog price which matches all these fields:
        --Item, Customer Type, Price Type, and Unit.
        --This is the most effective price.
		SELECT 
			purchase.item_cost_prices.price, 
			 purchase.item_cost_prices.unit_id
        INTO
            _price,
            _costing_unit_id
		FROM purchase.item_cost_prices
		WHERE purchase.item_cost_prices.item_id = _item_id
		AND purchase.item_cost_prices.supplier_id = _supplier_id
		AND purchase.item_cost_prices.unit_id = _unit_id
		AND NOT purchase.item_cost_prices.deleted;

		IF(_costing_unit_id IS NULL) THEN
			--We do not have a cost price of this item for the unit supplied.
			--Let's see if this item has a price for other units.
			SELECT 
				 purchase.item_cost_prices.price, 
				 purchase.item_cost_prices.unit_id
			INTO
                _price,
                _costing_unit_id
			FROM purchase.item_cost_prices
			WHERE purchase.item_cost_prices.item_id = _item_id
			AND purchase.item_cost_prices.supplier_id = _supplier_id
			AND NOT purchase.item_cost_prices.deleted;
		END IF;

    
		IF(_price IS NULL) THEN
			--This item does not have cost price defined in the catalog.
			--Therefore, getting the default cost price from the item definition.
			SELECT 
				cost_price, 
				unit_id
			INTO
                _price,
                _costing_unit_id
			FROM inventory.items
			WHERE inventory.items.item_id = _item_id
			AND NOT inventory.items.deleted;
		END IF;
	END IF;

    IF(_includes_tax) THEN
        _tax_rate       := finance.get_sales_tax_rate(_office_id);
        _price          := _price / ((100 + _tax_rate)/ 100);
    END IF;

        --Get the unitary conversion factor if the requested unit does not match with the price defition.
    _factor             := inventory.convert_unit(_unit_id, _costing_unit_id);
    RETURN _price * _factor;
END
$$
LANGUAGE plpgsql;


--SELECT purchase.get_item_cost_price(1, 6, 1, 7);
