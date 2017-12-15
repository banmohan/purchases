using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.Configuration.Db;
using Frapid.Mapper;
using Frapid.Mapper.Query.Insert;
using Frapid.Mapper.Query.NonQuery;
using Frapid.Mapper.Query.Select;
using MixERP.Purchases.DTO;

namespace MixERP.Purchases.DAL.Backend.Setup
{
    public static class CostPrices
    {
        public static async Task<IEnumerable<dynamic>> GetCostPrice(string tenant, int officeId, int supplierId)
        {
            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                var sql = new Sql(@"WITH price_list
                                    AS
                                    (
	                                    SELECT * FROM purchase.supplierwise_cost_prices
	                                    WHERE 
                                            (
                                                purchase.supplierwise_cost_prices.supplier_id IS NULL 
                                                OR purchase.supplierwise_cost_prices.supplier_id = @0
                                            )
                                    )
                                    SELECT
	                                    inventory.items.item_id,
	                                    inventory.items.item_code,
	                                    inventory.items.item_name,
	                                    inventory.items.unit_id,
	                                    inventory.get_unit_name_by_unit_id(inventory.items.unit_id) AS unit,
										price_list.is_taxable,
	                                    COALESCE(price_list.price, purchase.get_item_cost_price(@1, inventory.items.item_id, @0, inventory.items.unit_id)) AS price
                                    FROM inventory.items
                                    LEFT JOIN price_list
                                    ON price_list.item_id = inventory.items.item_id
                                    WHERE inventory.items.allow_sales = @2
                                    AND (price_list.supplier_id IS NULL OR price_list.supplier_id = @0);", supplierId, officeId, true);

                return await db.SelectAsync<dynamic>(sql).ConfigureAwait(false);
            }
        }

        public static async Task SetPriceList(string tenant, int userId, int supplierId, IEnumerable<SupplierwiseCostPrice> pricelist)
        {
            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                try
                {
                    await db.BeginTransactionAsync().ConfigureAwait(false);

                    var sql = new Sql("DELETE FROM purchase.supplierwise_cost_prices");
                    sql.Where("supplier_id = @0", supplierId);

                    await db.NonQueryAsync(sql).ConfigureAwait(false);

                    foreach (var price in pricelist)
                    {
                        price.SupplierId = supplierId;
                        price.AuditUserId = userId;
                        price.AuditTs = DateTimeOffset.UtcNow;
                        price.Deleted = false;

                        await db.InsertAsync(price).ConfigureAwait(false);
                    }

                    db.CommitTransaction();
                }
                catch
                {
                    db.RollbackTransaction();
                    throw;
                }
            }
        }
    }
}