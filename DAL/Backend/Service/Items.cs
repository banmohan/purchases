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
        public static async Task<IEnumerable<ItemView>> GetItemsAsync(string tenant)
        {
            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                var sql = new Sql("SELECT * FROM purchase.item_view");
                return await db.SelectAsync<ItemView>(sql).ConfigureAwait(false);
            }
        }

        public static async Task<decimal> GetCostPriceAsync(string tenant, int itemId, int supplierId, int unitId)
        {
            const string sql = "SELECT purchase.get_item_cost_price(@0, @1, @2);";
            return await Factory.ScalarAsync<decimal>(tenant, sql, itemId, supplierId, unitId).ConfigureAwait(false);
        }
    }
}