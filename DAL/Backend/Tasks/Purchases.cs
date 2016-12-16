using System;
using System.Threading.Tasks;
using Frapid.Configuration.Db;
using Frapid.Mapper.Database;
using MixERP.Purchases.DAL.Backend.Tasks.PurchaseEntry;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.DAL.Backend.Tasks
{
    public static class Purchases
    {
        private static IPurchaseEntry LocateService(string tenant)
        {
            string providerName = DbProvider.GetProviderName(tenant);
            var type = DbProvider.GetDbType(providerName);

            if (type == DatabaseType.PostgreSQL)
            {
                return new PostgreSQL();
            }

            if (type == DatabaseType.SqlServer)
            {
                return new SqlServer();
            }

            throw new NotImplementedException();
        }

        public static async Task<long> PostAsync(string tenant, Purchase model)
        {
            var entry = LocateService(tenant);

            return await entry.PostAsync(tenant, model).ConfigureAwait(false);
        }
    }
}