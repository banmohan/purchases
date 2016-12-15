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
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);


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
    price                                   dbo.money_strict NOT NULL,
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
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
    expected_delivery_date                    date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETDATE()),
    supplier_id                             integer NOT NULL REFERENCES inventory.customers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
    shipper_id                                integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                    national character varying(500),
    internal_memo                           national character varying(500),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE purchase.quotation_details
(
    quotation_detail_id                     bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint NOT NULL REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   dbo.money_strict NOT NULL,
    discount_rate                           dbo.decimal_strict2 NOT NULL DEFAULT(0),    
    tax                                     dbo.money_strict2 NOT NULL DEFAULT(0),    
    shipping_charge                         dbo.money_strict2 NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                dbo.decimal_strict2 NOT NULL
);


CREATE TABLE purchase.orders
(
    order_id                                bigint IDENTITY PRIMARY KEY,
    quotation_id                            bigint REFERENCES purchase.quotations,
    value_date                              date NOT NULL,
    expected_delivery_date                    date NOT NULL,
    transaction_timestamp                   DATETIMEOFFSET NOT NULL DEFAULT(GETDATE()),
    supplier_id                             integer NOT NULL REFERENCES inventory.suppliers,
    price_type_id                           integer NOT NULL REFERENCES purchase.price_types,
    shipper_id                                integer REFERENCES inventory.shippers,
    user_id                                 integer NOT NULL REFERENCES account.users,
    office_id                               integer NOT NULL REFERENCES core.offices,
    reference_number                        national character varying(24),
    terms                                   national character varying(500),
    internal_memo                           national character varying(500),
    audit_user_id                           integer REFERENCES account.users,
    audit_ts                                DATETIMEOFFSET DEFAULT(GETDATE()),
    deleted                                    bit DEFAULT(0)
);

CREATE TABLE purchase.order_details
(
    order_detail_id                         bigint IDENTITY PRIMARY KEY,
    order_id                                bigint NOT NULL REFERENCES purchase.orders,
    value_date                              date NOT NULL,
    item_id                                 integer NOT NULL REFERENCES inventory.items,
    price                                   dbo.money_strict NOT NULL,
    discount_rate                           dbo.decimal_strict2 NOT NULL DEFAULT(0),    
    tax                                     dbo.money_strict2 NOT NULL DEFAULT(0),    
    shipping_charge                         dbo.money_strict2 NOT NULL DEFAULT(0),    
    unit_id                                 integer NOT NULL REFERENCES inventory.units,
    quantity                                dbo.decimal_strict2 NOT NULL
);

CREATE TYPE purchase.purchase_detail_type
AS TABLE
(
    store_id            integer,
    transaction_type    national character varying(2),
    item_id             integer,
    quantity            dbo.decimal_strict2,
    unit_id             integer,
    price               dbo.money_strict,
    discount            dbo.money_strict2,
    tax                 dbo.money_strict2,
    shipping_charge     dbo.money_strict2
);



GO
