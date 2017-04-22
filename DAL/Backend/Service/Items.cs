using System.Collections.Generic;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.Configuration.Db;
using Frapid.DataAccess;
using Frapid.Mapper;
using Frapid.Mapper.Query.Select;
using MixERP.Purchases.DTO;

namespace MixERP.Purchases.DAL.Backend.Service
{
    public static class Items
    {
        public static async Task<IEnumerable<ItemView>> GetItemsAsync(string tenant, int officeId)
        {
            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                var sql = new Sql("SELECT *, finance.get_sales_tax_rate(@0) AS sales_tax_rate FROM purchase.item_view;", officeId);
                return await db.SelectAsync<ItemView>(sql).ConfigureAwait(false);
            }
        }

        public static async Task<decimal> GetCostPriceAsync(string tenant, int officeId, int itemId, int supplierId, int unitId)
        {
            const string sql = "SELECT purchase.get_item_cost_price(@0, @1, @2, @3);";
            return await Factory.ScalarAsync<decimal>(tenant, sql, officeId, itemId, supplierId, unitId).ConfigureAwait(false);
        }
    }
}