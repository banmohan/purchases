-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.x/2.0/src/99.sample-data/sample.sample.sql --<--<--
DO
$$
    DECLARE _office_id              integer = core.get_office_id_by_office_name('Default');
    DECLARE _user_id                integer;
    DECLARE _login_id               bigint;
    DECLARE _value_date             date = finance.get_value_date(_office_id);
    DECLARE _book_date              date = finance.get_value_date(_office_id);
    DECLARE _cost_center_id         integer;
    DECLARE _reference_number       text = 'S001';
    DECLARE _statement_reference    text = 'Sample purchase data inserted.';
    DECLARE _supplier_id            integer = inventory.get_supplier_id_by_supplier_code('DEF');
    DECLARE _price_type_id          integer = purchase.get_price_type_id_by_price_type_code('RET');
    DECLARE _shipper_id             integer = inventory.get_shipper_id_by_shipper_name('Default');
    DECLARE _details                purchase.purchase_detail_type[];
    DECLARE _store_id               integer = inventory.get_store_id_by_store_name('Store 1');
BEGIN
	SELECT account.users.user_id INTO _user_id
	FROM account.users
	WHERE account.users.role_id = 9999
	LIMIT 1;

    INSERT INTO account.logins(user_id, office_id, browser, ip_address, culture)
    SELECT _user_id, _office_id, '', '', '';

    SELECT account.logins.login_id INTO _login_id
    FROM account.logins
    WHERE account.logins.user_id = _user_id
    LIMIT 1;
    
    SELECT 
    ARRAY(
        SELECT ROW(
            _store_id,
            'Dr',
            item_id,
            100,
            unit_id,
            purchase.get_item_cost_price(_office_id, item_id, _supplier_id, unit_id),
            0,
            0,
            0, true)::purchase.purchase_detail_type
            
        FROM inventory.items
    ) INTO _details;

    --TODO
    -- PERFORM purchase.post_purchase
    -- (
    --     _office_id,
    --     _user_id,
    --     _login_id,
    --     _value_date,
    --     _book_date,
    --     _cost_center_id,
    --     _reference_number,
    --     _statement_reference,
    --     _supplier_id,
    --     _price_type_id,
    --     _shipper_id,
    --     _details
    -- );    
END
$$
LANGUAGE plpgsql;


