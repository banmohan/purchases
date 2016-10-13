DROP VIEW IF EXISTS purchase.item_cost_price_scrud_view;

CREATE VIEW purchase.item_cost_price_scrud_view
AS
SELECT
    purchase.item_cost_prices.item_cost_price_id,
    purchase.item_cost_prices.item_id,
    inventory.items.item_code || ' (' || inventory.items.item_name || ')' AS item,
    purchase.item_cost_prices.unit_id,
    inventory.units.unit_code || ' (' || inventory.units.unit_name || ')' AS unit,
    purchase.item_cost_prices.supplier_id,
    inventory.suppliers.supplier_code || ' (' || inventory.suppliers.supplier_name || ')' AS supplier,
    purchase.item_cost_prices.lead_time_in_days,
    purchase.item_cost_prices.includes_tax,
    purchase.item_cost_prices.price
FROM purchase.item_cost_prices
INNER JOIN inventory.items
ON inventory.items.item_id = purchase.item_cost_prices.item_id
INNER JOIN inventory.units
ON inventory.units.unit_id = purchase.item_cost_prices.unit_id
INNER JOIN inventory.suppliers
ON inventory.suppliers.supplier_id = purchase.item_cost_prices.supplier_id
WHERE NOT purchase.item_cost_prices.deleted;
