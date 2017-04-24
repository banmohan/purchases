IF OBJECT_ID('purchase.get_item_cost_price') IS NOT NULL
DROP FUNCTION purchase.get_item_cost_price;

GO

CREATE FUNCTION purchase.get_item_cost_price(@office_id integer, @item_id integer, @supplier_id bigint, @unit_id integer)
RETURNS numeric(30, 6)
AS  
BEGIN
    DECLARE @price              numeric(30, 6);
    DECLARE @costing_unit_id    integer;
    DECLARE @factor             numeric(30, 6);
    DECLARE @includes_tax       bit;
    DECLARE @tax_rate           decimal(30, 6);

	SELECT
		@includes_tax	= inventory.items.cost_price_includes_tax
	FROM inventory.items
	WHERE inventory.items.item_id = @item_id;

	SELECT
		@price				= purchase.supplierwise_cost_prices.price,
		@costing_unit_id	=  purchase.supplierwise_cost_prices.unit_id
	FROM purchase.supplierwise_cost_prices
	WHERE purchase.supplierwise_cost_prices.deleted = 0
	AND purchase.supplierwise_cost_prices.supplier_id = @supplier_id
	AND purchase.supplierwise_cost_prices.item_id = @item_id;

	
	IF(@price IS NULL)
	BEGIN
		--Pick the catalog price which matches all these fields:
		--Item, Customer Type, Price Type, and Unit.
		--This is the most effective price.
		SELECT 
			@price = purchase.item_cost_prices.price, 
			@costing_unit_id = purchase.item_cost_prices.unit_id
		FROM purchase.item_cost_prices
		WHERE purchase.item_cost_prices.item_id = @item_id
		AND purchase.item_cost_prices.supplier_id = @supplier_id
		AND purchase.item_cost_prices.unit_id = @unit_id
		AND purchase.item_cost_prices.deleted = 0;

		IF(@costing_unit_id IS NULL)
		BEGIN
			--We do not have a cost price of this item for the unit supplied.
			--Let's see if this item has a price for other units.
			SELECT 
				@price = purchase.item_cost_prices.price, 
				@costing_unit_id = purchase.item_cost_prices.unit_id
			FROM purchase.item_cost_prices
			WHERE purchase.item_cost_prices.item_id = @item_id
			AND purchase.item_cost_prices.supplier_id = @supplier_id
			AND purchase.item_cost_prices.deleted = 0;
		END;

    
		IF(@price IS NULL)
		BEGIN
			--This item does not have cost price defined in the catalog.
			--Therefore, getting the default cost price from the item definition.
			SELECT 
				@price = cost_price, 
				@costing_unit_id = unit_id
			FROM inventory.items
			WHERE inventory.items.item_id = @item_id
			AND inventory.items.deleted = 0;
		END;
	END;

    IF(@includes_tax = 1)
    BEGIN
        SET @tax_rate = finance.get_sales_tax_rate(@office_id);
        SET @price = @price / ((100 + @tax_rate)/ 100);
    END;

        --Get the unitary conversion factor if the requested unit does not match with the price defition.
    SET @factor = inventory.convert_unit(@unit_id, @costing_unit_id);
    RETURN @price * @factor;
END;


GO


--SELECT purchase.get_item_cost_price(1, 1, 1, 5);
