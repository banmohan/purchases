DELETE FROM auth.menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'MixERP.Purchases'
);

DELETE FROM auth.group_menu_access_policy
WHERE menu_id IN
(
    SELECT menu_id FROM core.menus
    WHERE app_name = 'MixERP.Purchases'
);

DELETE FROM core.menus
WHERE app_name = 'MixERP.Purchases';


EXECUTE core.create_app 'MixERP.Purchases', 'Purchase', 'Purchase', '1.0', 'MixERP Inc.', 'December 1, 2015', 'newspaper yellow', '/dashboard/purchase/tasks/entry', NULL;

EXECUTE core.create_menu 'MixERP.Purchases', 'Tasks', 'Tasks', '', 'lightning', '';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseEntry', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'write', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'SupplierPayment', 'Supplier Payment', '/dashboard/purchase/tasks/payment', 'write', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseReturns', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'minus', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseQuotations', 'Purchase Quotations', '/dashboard/purchase/tasks/quotation', 'newspaper', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseOrders', 'Purchase Orders', '/dashboard/purchase/tasks/order', 'file national character varying(1000) outline', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseVerification', 'PurchaseVerification', '/dashboard/purchase/tasks/entry/verification', 'checkmark', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'SupplierPaymentVerification', 'Supplier Payment Verification', '/dashboard/purchase/tasks/payment/verification', 'checkmark', 'Tasks';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseReturnVerification', 'Purchase Return Verification', '/dashboard/purchase/tasks/return/verification', 'minus', 'Tasks';

EXECUTE core.create_menu 'MixERP.Purchases', 'Setup', 'Setup', 'square outline', 'configure', '';
EXECUTE core.create_menu 'MixERP.Purchases', 'Suppliers', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup';
EXECUTE core.create_menu 'MixERP.Purchases', 'PriceTypes', 'Price Types', '/dashboard/purchase/setup/price-types', 'dollar', 'Setup';
EXECUTE core.create_menu 'MixERP.Purchases', 'CostPrices', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'rupee', 'Setup';

EXECUTE core.create_menu 'MixERP.Purchases', 'Reports', 'Reports', '', 'block layout', '';
EXECUTE core.create_menu 'MixERP.Purchases', 'AccountPayables', 'Account Payables', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/AccountPayables.xml', 'spy', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'TopSuppliers', 'Top Suppliers', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/TopSuppliers.xml', 'spy', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchasesByOffice', 'Purchases by Office', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PurchasesByOffice.xml', 'building', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'LowInventoryProducts', 'Low Inventory Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/LowInventory.xml', 'warning', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'OutOfStockProducts', 'Out of Stock Products', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/OutOfStock.xml', 'remove circle', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'SupplierContacts', 'Supplier Contacts', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/SupplierContacts.xml', 'remove circle', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseSummary', 'Purchase Summary', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PurchaseSummary.xml', 'grid layout icon', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'PurchaseDiscountStatus', 'Purchase Discount Status', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PurchaseDiscountStatus.xml', 'shopping basket icon', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'PaymentJournalSummary', 'Payment Journal Summary Report', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/PaymentJournalSummary.xml', 'angle double right icon', 'Reports';
EXECUTE core.create_menu 'MixERP.Purchases', 'AccountPayableVendor', 'Account Payable Vendor Report', '/dashboard/reports/view/Areas/MixERP.Purchases/Reports/AccountPayableVendor.xml', 'external share icon', 'Reports';

DECLARE @office_id integer = core.get_office_id_by_office_name('Default');
EXECUTE auth.create_app_menu_policy
'Admin', 
@office_id, 
'MixERP.Purchases',
'{*}';



GO
