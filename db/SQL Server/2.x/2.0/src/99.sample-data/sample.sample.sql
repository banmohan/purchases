DECLARE @user_id					integer;
DECLARE @login_id					bigint;
DECLARE @cost_center_id				integer;
DECLARE @details					purchase.purchase_detail_type;
DECLARE @transaction_master_id		bigint;
DECLARE @office_id					integer								= core.get_office_id_by_office_name('Default');
DECLARE @value_date					date								= finance.get_value_date(@office_id);
DECLARE @book_date					date								= finance.get_value_date(@office_id);
DECLARE @reference_number			national character varying(24)		= 'S001';
DECLARE @statement_reference		national character varying(2000)	= 'Sample purchase data inserted.';
DECLARE @supplier_id				integer								= inventory.get_supplier_id_by_supplier_code('DEF');
DECLARE @price_type_id				integer								= purchase.get_price_type_id_by_price_type_code('RET');
DECLARE @shipper_id					integer								= inventory.get_shipper_id_by_shipper_name('Default');
DECLARE @store_id					integer								= inventory.get_store_id_by_store_name('Store 1');

SELECT TOP 1 @user_id = account.users.user_id
FROM account.users
WHERE account.users.role_id = 9999;

INSERT INTO account.logins(user_id, office_id, browser, ip_address, culture)
SELECT @user_id, @office_id, '', '', '';

SELECT TOP 1 @login_id = account.logins.login_id
FROM account.logins
WHERE account.logins.user_id = @user_id;

INSERT INTO @details
SELECT
	@store_id,
	'Dr',
	item_id,
	100,
	unit_id,
	purchase.get_item_cost_price(@office_id, item_id, @supplier_id, unit_id),
	0,
	0,
	0        
FROM inventory.items;


--TODO
-- EXECUTE purchase.post_purchase
-- 	@office_id,
-- 	@user_id,
-- 	@login_id,
-- 	@value_date,
-- 	@book_date,
-- 	@cost_center_id,
-- 	@reference_number,
-- 	@statement_reference,
-- 	@supplier_id,
-- 	@price_type_id,
-- 	@shipper_id,
-- 	@details,
-- 	@transaction_master_id = @transaction_master_id OUTPUT;