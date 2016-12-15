IF OBJECT_ID('purchase.get_item_cost_price') IS NOT NULL
DROP FUNCTION purchase.get_item_cost_price;

GO

CREATE FUNCTION purchase.get_item_cost_price(@item_id integer, @supplier_id bigint, @unit_id integer)
RETURNS dbo.money_strict2
AS  
BEGIN
    DECLARE @price              dbo.money_strict2;
    DECLARE @costing_unit_id    integer;
    DECLARE @factor             decimal(30, 6);

    --Fist pick the catalog price which matches all these fields:
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

        --Get the unitary conversion factor if the requested unit does not match with the price defition.
    SET @factor = inventory.convert_unit(@unit_id, @costing_unit_id);
    RETURN @price * @factor;
END;



--SELECT * FROM purchase.get_item_cost_price(6, 1, 7);


GO
