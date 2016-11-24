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


SELECT * FROM core.create_app('Purchase', 'Purchase', '1.0', 'MixERP Inc.', 'December 1, 2015', 'newspaper yellow', '/dashboard/purchase/tasks/entry', NULL::text[]);

SELECT * FROM core.create_menu('Purchase', 'Tasks', '', 'lightning', '');
SELECT * FROM core.create_menu('Purchase', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'write', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'minus', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Quotation', '/dashboard/purchase/tasks/quotation', 'newspaper', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Orders', '/dashboard/purchase/tasks/order', 'file text outline', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Verification', '/dashboard/purchase/tasks/entry/verification', 'checkmark', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Return Verification', '/dashboard/purchase/tasks/return/verification', 'minus', 'Tasks');

SELECT * FROM core.create_menu('Purchase', 'Setup', 'square outline', 'configure', '');
SELECT * FROM core.create_menu('Purchase', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup');
SELECT * FROM core.create_menu('Purchase', 'Price Types', '/dashboard/purchase/setup/price-types', 'dollar', 'Setup');
SELECT * FROM core.create_menu('Purchase', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'rupee', 'Setup');

SELECT * FROM core.create_menu('Purchase', 'Reports', '', 'block layout', '');
SELECT * FROM core.create_menu('Purchase', 'Top Suppliers', '/dashboard/purchase/reports/purchase-account-statement', 'spy', 'Reports');
SELECT * FROM core.create_menu('Purchase', 'Low Inventory Products', '/dashboard/purchase/reports/purchase-account-statement', 'warning', 'Reports');
SELECT * FROM core.create_menu('Purchase', 'Out of Stock Products', '/dashboard/purchase/reports/purchase-account-statement', 'remove circle', 'Reports');


SELECT * FROM auth.create_app_menu_policy
(
    'Admin', 
    core.get_office_id_by_office_name('Default'), 
    'Purchase',
    '{*}'::text[]
);

