EXECUTE dbo.drop_schema 'purchase';
GO
CREATE SCHEMA purchase;
GO


--TODO: CREATE UNIQUE INDEXES

CREATE TABLE purchase.price_types
(
    price_type_id                           integer IDENTITY PRIMARY KEY,
    price_type_code                         national character varying(24) NOT NULL,
    price_type_name                         national character varying(500) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE UNIQUE INDEX price_types_price_type_code_uix
ON purchase.price_types(price_type_code)
WHERE deleted = 0;

CREATE UNIQUE INDEX price_types_price_type_name_uix
ON purchase.price_types(price_type_name)
WHERE deleted = 0;

CREATE TABLE purchase.item_cost_prices
(   
    item_cost_price_id                      bigint IDENTITY PRIMARY KEY,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    supplier_id                             integer REFERENCES inventory.suppliers,
    lead_time_in_days                       integer NOT NULL DEFAULT(0),
    includes_tax                            bit NOT NULL
                                            CONSTRAINT item_cost_prices_includes_tax_df   
                                            DEFAULT(0),
    price                                   decimal(30, 6) NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                 bit DEFAULT(0)
);

CREATE UNIQUE INDEX item_cost_prices_item_id_unit_id_supplier_id
ON purchase.item_cost_prices(item_id, unit_id, supplier_id)
WHERE deleted = 0;



CREATE TABLE purchase.supplierwise_cost_prices
(
	cost_price_id							bigint IDENTITY PRIMARY KEY,
	supplier_id								integer NOT NULL REFERENCES inventory.suppliers,
	unit_id									integer NOT NULL REFERENCES inventory.units,
	price									numeric(30, 6),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                 bit DEFAULT(0)
);

CREATE TABLE purchase.purchases
(
    purchase_id                             bigint IDENTITY PRIMARY KEY,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    price_type_id                            integer NOT NULL REFERENCES purchase.price_types
);


CREATE TABLE purchase.purchase_returns
(
    purchase_return_id                      bigint IDENTITY PRIMARY KEY,
    purchase_id                             bigint NOT NULL REFERENCES purchase.purchases,
    checkout_id                             bigint NOT NULL REFERENCES inventory.checkouts,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers   
);


CREATE TABLE purchase.quotations
(
    quotation_id                            bigint IDENTITY PRIMARY KEY,
    value_date                              date NOT NULL,
    expected_delivery_date                  date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETUTCDATE()),
    supplier_id                             integer NOT NULL REFERENCES inventory.customers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
    shipper_id                              integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                   national character varying(500),
    internal_memo                           national character varying(500),
 	taxable_total 							numeric(30, 6) NOT NULL DEFAULT(0),
	discount 								numeric(30, 6) NOT NULL DEFAULT(0),
	tax_rate 								numeric(30, 6) NOT NULL DEFAULT(0),
	tax 									numeric(30, 6) NOT NULL DEFAULT(0),
	nontaxable_total 						numeric(30, 6) NOT NULL DEFAULT(0),
	audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                 bit DEFAULT(0)
);

CREATE TABLE purchase.quotation_details
(
    quotation_detail_id                     bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint NOT NULL REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   decimal(30, 6) NOT NULL,
	discount_rate							decimal(30, 6) NOT NULL,
    discount                           		decimal(30, 6) NOT NULL DEFAULT(0),    
	is_taxed 								bit NOT NULL,
    shipping_charge                         decimal(30, 6) NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                decimal(30, 6) NOT NULL
);


CREATE TABLE purchase.orders
(
    order_id                                bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    expected_delivery_date                  date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETUTCDATE()),
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
    shipper_id                              integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                   national character varying(500),
    internal_memo                           national character varying(500),
	taxable_total 							numeric(30, 6) NOT NULL DEFAULT(0),
	discount 								numeric(30, 6) NOT NULL DEFAULT(0),
	tax_rate 								numeric(30, 6) NOT NULL DEFAULT(0),
	tax 									numeric(30, 6) NOT NULL DEFAULT(0),
	nontaxable_total 						numeric(30, 6) NOT NULL DEFAULT(0),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETUTCDATE()),
    deleted                                 bit DEFAULT(0)
);

CREATE TABLE purchase.order_details
(
    order_detail_id                         bigint IDENTITY PRIMARY KEY,
    order_id                                bigint NOT NULL REFERENCES purchase.orders,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   decimal(30, 6) NOT NULL,
	discount_rate							decimal(30, 6) NOT NULL,
    discount                          		decimal(30, 6) NOT NULL DEFAULT(0),    
	is_taxed 								bit NOT NULL,
    shipping_charge                         decimal(30, 6) NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                decimal(30, 6) NOT NULL
);

CREATE TABLE purchase.supplier_payments
(
    payment_id                              bigint IDENTITY PRIMARY KEY,
    transaction_master_id                   bigint NOT NULL REFERENCES finance.transaction_master,
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    currency_code                           national character varying(12) NOT NULL REFERENCES core.currencies,
    er_debit                                numeric(30, 6) NOT NULL,
    er_credit                               numeric(30, 6) NOT NULL,
    cash_repository_id                      integer NULL REFERENCES finance.cash_repositories,
    posted_date                             date NULL,
    tender                                  numeric(30, 6),
    change                                  numeric(30, 6),
    amount                                  numeric(30, 6),
    bank_id					                integer REFERENCES finance.bank_accounts,
	bank_instrument_code			        national character varying(500),
	bank_transaction_code			        national character varying(500),
	check_number                            national character varying(100),
    check_date                              date,
    check_bank_name                         national character varying(1000),
    check_amount                            numeric(30, 6)
);

CREATE INDEX supplier_payments_transaction_master_id_inx
ON purchase.supplier_payments(transaction_master_id);

CREATE INDEX supplier_payments_supplier_id_inx
ON purchase.supplier_payments(supplier_id);

CREATE INDEX supplier_payments_currency_code_inx
ON purchase.supplier_payments(currency_code);

CREATE INDEX supplier_payments_cash_repository_id_inx
ON purchase.supplier_payments(cash_repository_id);

CREATE INDEX supplier_payments_posted_date_inx
ON purchase.supplier_payments(posted_date);

CREATE TYPE purchase.purchase_detail_type
AS TABLE
(
    store_id            integer,
    transaction_type    national character varying(2),
    item_id             integer,
    quantity            decimal(30, 6),
    unit_id             integer,
    price               decimal(30, 6),
    discount_rate       decimal(30, 6),
    discount       		decimal(30, 6),
    shipping_charge     decimal(30, 6),
	is_taxed			bit
);



GO
