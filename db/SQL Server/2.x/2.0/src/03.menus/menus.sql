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


EXECUTE core.create_app 'Purchase', 'Purchase', '1.0', 'MixERP Inc.', 'December 1, 2015', 'newspaper yellow', '/dashboard/purchase/tasks/entry', NULL;

EXECUTE core.create_menu 'Purchase', 'Tasks', '', 'lightning', '';
EXECUTE core.create_menu 'Purchase', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'write', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'minus', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Quotation', '/dashboard/purchase/tasks/quotation', 'newspaper', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Orders', '/dashboard/purchase/tasks/order', 'file national character varying(1000) outline', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Verification', '/dashboard/purchase/tasks/entry/verification', 'checkmark', 'Tasks';
EXECUTE core.create_menu 'Purchase', 'Purchase Return Verification', '/dashboard/purchase/tasks/return/verification', 'minus', 'Tasks';

EXECUTE core.create_menu 'Purchase', 'Setup', 'square outline', 'configure', '';
EXECUTE core.create_menu 'Purchase', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup';
EXECUTE core.create_menu 'Purchase', 'Price Types', '/dashboard/purchase/setup/price-types', 'dollar', 'Setup';
EXECUTE core.create_menu 'Purchase', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'rupee', 'Setup';

EXECUTE core.create_menu 'Purchase', 'Reports', '', 'block layout', '';
EXECUTE core.create_menu 'Purchase', 'Top Suppliers', '/dashboard/purchase/reports/purchase-account-statement', 'spy', 'Reports';
EXECUTE core.create_menu 'Purchase', 'Low Inventory Products', '/dashboard/purchase/reports/purchase-account-statement', 'warning', 'Reports';
EXECUTE core.create_menu 'Purchase', 'Out of Stock Products', '/dashboard/purchase/reports/purchase-account-statement', 'remove circle', 'Reports';



DECLARE @office_id integer = core.get_office_id_by_office_name('Default');
EXECUTE auth.create_app_menu_policy
'Admin', 
@office_id, 
'Purchase',
'{*}';



GO
