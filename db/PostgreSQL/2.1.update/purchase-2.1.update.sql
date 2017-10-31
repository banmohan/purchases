-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/01.types-domains-tables-and-constraints/tables-and-constraints.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/02.functions-and-logic/purchase.post_supplier_payment.sql --<--<--
DROP FUNCTION IF EXISTS purchase.post_supplier_payment
(
    _user_id                                    integer, 
    _office_id                                  integer, 
    _login_id                                   bigint,
    _supplier_id                                integer, 
    _currency_code                              national character varying(12), 
    _cash_account_id                            integer,
    _amount                                     public.money_strict, 
    _exchange_rate_debit                        public.decimal_strict, 
    _exchange_rate_credit                       public.decimal_strict,
    _reference_number                           national character varying(24), 
    _statement_reference                        national character varying(128), 
    _cost_center_id                             integer,
    _cash_repository_id                         integer,
    _posted_date                                date,
    _bank_id                                    integer,
    _bank_instrument_code                       national character varying(128),
    _bank_tran_code                             national character varying(128)
);

DROP FUNCTION IF EXISTS purchase.post_supplier_payment
(
	_value_date									date,
	_book_date									date,
    _user_id                                    integer, 
    _office_id                                  integer, 
    _login_id                                   bigint,
    _supplier_id                                integer, 
    _currency_code                              national character varying(12), 
    _cash_account_id                            integer,
    _amount                                     public.money_strict, 
    _exchange_rate_debit                        public.decimal_strict, 
    _exchange_rate_credit                       public.decimal_strict,
    _reference_number                           national character varying(24), 
    _statement_reference                        national character varying(128), 
    _cost_center_id                             integer,
    _cash_repository_id                         integer,
    _posted_date                                date,
    _bank_id                                    integer,
    _bank_instrument_code                       national character varying(128),
    _bank_tran_code                             national character varying(128)
);

CREATE FUNCTION purchase.post_supplier_payment
(
	_value_date									date,
	_book_date									date,
    _user_id                                    integer, 
    _office_id                                  integer, 
    _login_id                                   bigint,
    _supplier_id                                integer, 
    _currency_code                              national character varying(12),
    _cash_account_id                            integer,
    _amount                                     public.money_strict, 
    _exchange_rate_debit                        public.decimal_strict, 
    _exchange_rate_credit                       public.decimal_strict,
    _reference_number                           national character varying(24), 
    _statement_reference                        national character varying(128), 
    _cost_center_id                             integer,
    _cash_repository_id                         integer,
    _posted_date                                date,
    _bank_id                                    integer,
    _bank_instrument_code                       national character varying(128),
    _bank_tran_code                             national character varying(128)
)
RETURNS bigint
AS
$$
    DECLARE _book                               text;
    DECLARE _transaction_master_id              bigint;
    DECLARE _base_currency_code                 national character varying(12);
    DECLARE _local_currency_code                national character varying(12);
    DECLARE _supplier_account_id                integer;
    DECLARE _debit                              public.money_strict2;
    DECLARE _credit                             public.money_strict2;
    DECLARE _lc_debit                           public.money_strict2;
    DECLARE _lc_credit                          public.money_strict2;
    DECLARE _is_cash                            boolean;
	DECLARE _bank_account_id					integer;
BEGIN
	_bank_account_id					    := finance.get_account_id_by_bank_account_id(_bank_id);    

    IF(finance.can_post_transaction(_login_id, _user_id, _office_id, _book, _value_date) = false) THEN
        RETURN 0;
    END IF;

    IF(_cash_repository_id > 0) THEN
        IF(_posted_date IS NOT NULL OR _bank_id IS NOT NULL OR COALESCE(_bank_instrument_code, '') != '' OR COALESCE(_bank_tran_code, '') != '') THEN
            RAISE EXCEPTION 'Invalid bank transaction information provided.'
            USING ERRCODE='P5111';
        END IF;
        _is_cash                            := true;
    END IF;

    _book                                   := 'Purchase Payment';
    
    _supplier_account_id                    := inventory.get_account_id_by_supplier_id(_supplier_id);    
    _local_currency_code                    := core.get_currency_code_by_office_id(_office_id);
    _base_currency_code                     := inventory.get_currency_code_by_supplier_id(_supplier_id);

    IF(_local_currency_code = _currency_code AND _exchange_rate_debit != 1) THEN
        RAISE EXCEPTION 'Invalid exchange rate. % % %', _local_currency_code, _currency_code, _exchange_rate_debit
        USING ERRCODE='P3055';
    END IF;

    IF(_local_currency_code = _base_currency_code AND _exchange_rate_credit != 1) THEN
        RAISE EXCEPTION 'Invalid exchange rate. % % %', _base_currency_code, _currency_code, _exchange_rate_debit
        USING ERRCODE='P3055';
    END IF;
        
    _debit                                  := _amount;
    _lc_debit                               := _amount * _exchange_rate_debit;

    _credit                                 := _amount * (_exchange_rate_debit/ _exchange_rate_credit);
    _lc_credit                              := _amount * _exchange_rate_debit;
    
    INSERT INTO finance.transaction_master
    (
        transaction_master_id, 
        transaction_counter, 
        transaction_code, 
        book, 
        value_date, 
        book_date, 
        user_id, 
        login_id, 
        office_id, 
        cost_center_id, 
        reference_number, 
        statement_reference
    )
    SELECT 
        nextval(pg_get_serial_sequence('finance.transaction_master', 'transaction_master_id')), 
        finance.get_new_transaction_counter(_value_date), 
        finance.get_transaction_code(_value_date, _office_id, _user_id, _login_id),
        _book,
        _value_date,
        _book_date,
        _user_id,
        _login_id,
        _office_id,
        _cost_center_id,
        _reference_number,
        _statement_reference;


    _transaction_master_id := currval(pg_get_serial_sequence('finance.transaction_master', 'transaction_master_id'));

    --Debit
    IF(_is_cash) THEN
        INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
        SELECT _transaction_master_id, _office_id, _value_date, _book_date, 'Cr', _cash_account_id, _statement_reference, _cash_repository_id, _currency_code, _debit, _local_currency_code, _exchange_rate_debit, _lc_debit, _user_id;
    ELSE
        INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
        SELECT _transaction_master_id, _office_id, _value_date, _book_date, 'Cr', _bank_account_id, _statement_reference, NULL, _currency_code, _debit, _local_currency_code, _exchange_rate_debit, _lc_debit, _user_id;        
    END IF;

    --Credit
    INSERT INTO finance.transaction_details(transaction_master_id, office_id, value_date, book_date, tran_type, account_id, statement_reference, cash_repository_id, currency_code, amount_in_currency, local_currency_code, er, amount_in_local_currency, audit_user_id)
    SELECT _transaction_master_id, _office_id, _value_date, _book_date, 'Dr', _supplier_account_id, _statement_reference, NULL, _base_currency_code, _credit, _local_currency_code, _exchange_rate_credit, _lc_credit, _user_id;
    
    
    INSERT INTO purchase.supplier_payments(transaction_master_id, supplier_id, currency_code, amount, er_debit, er_credit, cash_repository_id, posted_date, bank_id, bank_instrument_code, bank_transaction_code)
    SELECT _transaction_master_id, _supplier_id, _currency_code, _amount,  _exchange_rate_debit, _exchange_rate_credit, _cash_repository_id, _posted_date, _bank_account_id, _bank_instrument_code, _bank_tran_code;

    PERFORM finance.auto_verify(_transaction_master_id, _office_id);
    RETURN _transaction_master_id;
END
$$
LANGUAGE plpgsql;


-- SELECT * FROM purchase.post_supplier_payment
-- (
--     1, --_user_id                                    integer, 
--     1, --_office_id                                  integer, 
--     1, --_login_id                                   bigint,
--     1, --_supplier_id                                integer, 
--     'USD', --_currency_code                              national character varying(12), 
--     1,--    _cash_account_id                            integer,
--     100, --_amount                                     public.money_strict, 
--     1, --_exchange_rate_debit                        public.decimal_strict, 
--     1, --_exchange_rate_credit                       public.decimal_strict,
--     '', --_reference_number                           national character varying(24), 
--     '', --_statement_reference                        national character varying(128), 
--     1, --_cost_center_id                             integer,
--     1, --_cash_repository_id                         integer,
--     NULL, --_posted_date                                date,
--     NULL, --_bank_account_id                            bigint,
--     NULL, -- _bank_instrument_code                       national character varying(128),
--     NULL -- _bank_tran_code                             national character varying(128),
-- );

-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/03.menus/menus.sql --<--<--


-->-->-- src/Frapid.Web/Areas/MixERP.Purchases/db/PostgreSQL/2.1.update/src/99.ownership.sql --<--<--
DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_tables 
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND tableowner <> 'frapid_db_user'
    LOOP
        EXECUTE 'ALTER TABLE '|| this.schemaname || '.' || this.tablename ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT oid::regclass::text as mat_view
    FROM   pg_class
    WHERE  relkind = 'm'
    LOOP
        EXECUTE 'ALTER TABLE '|| this.mat_view ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'ALTER '
        || CASE WHEN p.proisagg THEN 'AGGREGATE ' ELSE 'FUNCTION ' END
        || quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' 
        || pg_catalog.pg_get_function_identity_arguments(p.oid) || ') OWNER TO frapid_db_user;' AS sql
    FROM   pg_catalog.pg_proc p
    JOIN   pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE  NOT n.nspname = ANY(ARRAY['pg_catalog', 'information_schema'])
    LOOP        
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_views
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND viewowner <> 'frapid_db_user'
    LOOP
        EXECUTE 'ALTER VIEW '|| this.schemaname || '.' || this.viewname ||' OWNER TO frapid_db_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'ALTER SCHEMA ' || nspname || ' OWNER TO frapid_db_user;' AS sql FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname <> 'information_schema'
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;



DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'frapid_db_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT      'ALTER TYPE ' || n.nspname || '.' || t.typname || ' OWNER TO frapid_db_user;' AS sql
    FROM        pg_type t 
    LEFT JOIN   pg_catalog.pg_namespace n ON n.oid = t.typnamespace 
    WHERE       (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) 
    AND         NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
    AND         typtype NOT IN ('b')
    AND         n.nspname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_tables 
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND tableowner <> 'report_user'
    LOOP
        EXECUTE 'GRANT SELECT ON TABLE '|| this.schemaname || '.' || this.tablename ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT oid::regclass::text as mat_view
    FROM   pg_class
    WHERE  relkind = 'm'
    LOOP
        EXECUTE 'GRANT SELECT ON TABLE '|| this.mat_view  ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;

DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'GRANT EXECUTE ON '
        || CASE WHEN p.proisagg THEN 'AGGREGATE ' ELSE 'FUNCTION ' END
        || quote_ident(n.nspname) || '.' || quote_ident(p.proname) || '(' 
        || pg_catalog.pg_get_function_identity_arguments(p.oid) || ') TO report_user;' AS sql
    FROM   pg_catalog.pg_proc p
    JOIN   pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE  NOT n.nspname = ANY(ARRAY['pg_catalog', 'information_schema'])
    LOOP        
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT * FROM pg_views
    WHERE NOT schemaname = ANY(ARRAY['pg_catalog', 'information_schema'])
    AND viewowner <> 'report_user'
    LOOP
        EXECUTE 'GRANT SELECT ON '|| this.schemaname || '.' || this.viewname ||' TO report_user;';
    END LOOP;
END
$$
LANGUAGE plpgsql;


DO
$$
    DECLARE this record;
BEGIN
    IF(CURRENT_USER = 'report_user') THEN
        RETURN;
    END IF;

    FOR this IN 
    SELECT 'GRANT USAGE ON SCHEMA ' || nspname || ' TO report_user;' AS sql FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname <> 'information_schema'
    LOOP
        EXECUTE this.sql;
    END LOOP;
END
$$
LANGUAGE plpgsql;


