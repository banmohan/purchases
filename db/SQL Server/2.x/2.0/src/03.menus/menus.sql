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


EXECUTE core.create_app 'Purchase', 'Purchase', 'Purchase', '1.0', 'MixERP Inc.', 'December 1, 2015', 'newspaper yellow', '/dashboard/purchase/tasks/entry', NULL;

EXECUTE core.create_menu 'Purchase', 'Tasks', 'Tasks', '', 'lightning', '';
EXECUTE core.create_menu 'Purchase', 'PurchaseEntry', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'write', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'SupplierPayment', 'Supplier Payment', '/dashboard/purchase/tasks/payment', 'write', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'PurchaseReturns', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'minus', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'PurchaseQuotations', 'Purchase Quotations', '/dashboard/purchase/tasks/quotation', 'newspaper', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'PurchaseOrders', 'Purchase Orders', '/dashboard/purchase/tasks/order', 'file national character varying(1000) outline', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'PurchaseVerification', 'PurchaseVerification', '/dashboard/purchase/tasks/entry/verification', 'checkmark', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'SupplierPaymentVerification', 'Supplier Payment Verification', '/dashboard/purchase/tasks/payment/verification', 'checkmark', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'PurchaseReturnVerification', 'Purchase Return Verification', '/dashboard/purchase/tasks/return/verification', 'minus', 'Tasks';

EXECUTE core.create_menu 'Purchase', 'Setup', 'Setup', 'square outline', 'configure', '';
EXECUTE core.create_menu 'Purchase', 'Suppliers', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup';
EXECUTE core.create_menu 'Purchase', 'PriceTypes', 'Price Types', '/dashboard/purchase/setup/price-types', 'dollar', 'Setup';
EXECUTE core.create_menu 'Purchase', 'CostPrices', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'rupee', 'Setup';

EXECUTE core.create_menu 'Purchase', 'Reports', 'Reports', '', 'block layout', '';
EXECUTE core.create_menu 'Purchase', 'AccountPayables', 'Account Payables', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/AccountPayables.xml', 'spy', 'Reports';
EXECUTE core.create_menu 'Purchase', 'TopSuppliers', 'Top Suppliers', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/TopSuppliers.xml', 'spy', 'Reports';
EXECUTE core.create_menu 'Purchase', 'LowInventoryProducts', 'Low Inventory Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/LowInventory.xml', 'warning', 'Reports';
EXECUTE core.create_menu 'Purchase', 'OutOfStockProducts', 'Out of Stock Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/OutOfStock.xml', 'remove circle', 'Reports';
EXECUTE core.create_menu 'Purchase', 'SupplierContacts', 'Supplier Contacts', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/SupplierContacts.xml', 'remove circle', 'Reports';



DECLARE @office_id integer = core.get_office_id_by_office_name('Default');
EXECUTE auth.create_app_menu_policy
'Admin', 
@office_id, 
'Purchase',
'{*}';



GO
