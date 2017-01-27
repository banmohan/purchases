DELETE FROM auth.menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'Purchase'
);

DELETE FROM auth.group_menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'Purchase'
);

DELETE FROM core.menus
WHERE app_name = 'Purchase';


SELECT * FROM core.create_app('Purchase', 'Purchase', 'Purchase', '1.0', 'MixERP Inc.', 'December 1, 2015', 'newspaper yellow', '/dashboard/purchase/tasks/entry', NULL::text[]);

SELECT * FROM core.create_menu('Purchase', 'Tasks', 'Tasks', '', 'lightning', '');
SELECT * FROM core.create_menu('Purchase', 'PurchaseEntry', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'write', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'SupplierPayment', 'Supplier Payment', '/dashboard/purchase/tasks/payment', 'write', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'PurchaseReturns', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'minus', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'PurchaseQuotations', 'Purchase Quotations', '/dashboard/purchase/tasks/quotation', 'newspaper', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'PurchaseOrders', 'Purchase Orders', '/dashboard/purchase/tasks/order', 'file text outline', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'PurchaseVerification', 'Purchase Verification', '/dashboard/purchase/tasks/entry/verification', 'checkmark', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'SupplierPaymentVerification', 'Supplier Payment Verification', '/dashboard/purchase/tasks/payment/verification', 'checkmark', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'PurchaseReturnVerification', 'Purchase Return Verification', '/dashboard/purchase/tasks/return/verification', 'minus', 'Tasks');

SELECT * FROM core.create_menu('Purchase', 'Setup', 'Setup', 'square outline', 'configure', '');
SELECT * FROM core.create_menu('Purchase', 'Suppliers', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup');
SELECT * FROM core.create_menu('Purchase', 'PriceTypes', 'Price Types', '/dashboard/purchase/setup/price-types', 'dollar', 'Setup');
SELECT * FROM core.create_menu('Purchase', 'CostPrices', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'rupee', 'Setup');

SELECT * FROM core.create_menu('Purchase', 'Reports', 'Reports', '', 'block layout', '');
SELECT * FROM core.create_menu('Purchase', 'AccountPayables', 'Account Payables', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/AccountPayables.xml', 'spy', 'Reports');
SELECT * FROM core.create_menu('Purchase', 'TopSuppliers', 'Top Suppliers', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/TopSuppliers.xml', 'spy', 'Reports');
SELECT * FROM core.create_menu('Purchase', 'LowInventoryProducts', 'Low Inventory Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/LowInventory.xml', 'warning', 'Reports');
SELECT * FROM core.create_menu('Purchase', 'OutOfStockProducts', 'Out of Stock Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/OutOfStock.xml', 'remove circle', 'Reports');
SELECT * FROM core.create_menu('Purchase', 'SupplierContacts', 'Supplier Contacts', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/SupplierContacts.xml', 'remove circle', 'Reports');


SELECT * FROM auth.create_app_menu_policy
(
    'Admin', 
    core.get_office_id_by_office_name('Default'), 
    'Purchase',
    '{*}'::text[]
);

