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
SELECT * FROM core.create_menu('Purchase', 'Purchase Entry', '/dashboard/purchase/tasks/entry', 'user', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Returns', '/dashboard/purchase/tasks/return', 'ticket', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Quotation', '/dashboard/purchase/tasks/quotation', 'food', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Orders', '/dashboard/purchase/tasks/orders', 'keyboard', 'Tasks');
SELECT * FROM core.create_menu('Purchase', 'Purchase Verification', '/dashboard/purchase/tasks/entry/verification', 'keyboard', 'Tasks');

SELECT * FROM core.create_menu('Purchase', 'Setup', 'square outline', 'configure', '');
SELECT * FROM core.create_menu('Purchase', 'Suppliers', '/dashboard/purchase/setup/suppliers', 'users', 'Setup');
SELECT * FROM core.create_menu('Purchase', 'Price Types', '/dashboard/purchase/setup/price-types', 'users', 'Setup');
SELECT * FROM core.create_menu('Purchase', 'Cost Prices', '/dashboard/purchase/setup/cost-prices', 'users', 'Setup');

SELECT * FROM core.create_menu('Purchase', 'Reports', '', 'configure', '');
SELECT * FROM core.create_menu('Purchase', 'Top Suppliers', '/dashboard/purchase/reports/purchase-account-statement', 'money', 'Reports');
SELECT * FROM core.create_menu('Purchase', 'Low Inventory Products', '/dashboard/purchase/reports/purchase-account-statement', 'money', 'Reports');
SELECT * FROM core.create_menu('Purchase', 'Out of Stock Products', '/dashboard/purchase/reports/purchase-account-statement', 'money', 'Reports');


SELECT * FROM auth.create_app_menu_policy
(
    'Admin', 
    core.get_office_id_by_office_name('Default'), 
    'Purchase',
    '{*}'::text[]
);

