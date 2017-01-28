using System;
using System.Linq;
using System.Threading.Tasks;
using Frapid.Configuration.Db;
using Frapid.DataAccess;
using Frapid.Mapper.Database;
using MixERP.Purchases.DAL.Backend.Tasks.PaymentEntry;
using MixERP.Purchases.DTO;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.DAL.Backend.Tasks
{
    public static class Payments
    {
        public static async Task<string> GetHomeCurrencyAsync(string tenant, int officeId)
        {
            const string sql = "SELECT core.get_currency_code_by_office_id(@0);";
            return await Factory.ScalarAsync<string>(tenant, sql, officeId).ConfigureAwait(false);
        }

        public static async Task<decimal> GetExchangeRateAsync(string tenant, int officeId, string sourceCurrencyCode, string destinationCurrencyCode)
        {
            const string sql = "SELECT finance.convert_exchange_rate(@0, @1, @2);";
            return await Factory.ScalarAsync<decimal>(tenant, sql, officeId, sourceCurrencyCode, destinationCurrencyCode).ConfigureAwait(false);
        }

        public static async Task<SupplierTransactionSummary> GetSupplierTransactionSummaryAsync(string tenant, int officeId, int supplierId)
        {
            const string sql = "SELECT * FROM inventory.get_supplier_transaction_summary(@0, @1);";
            return (await Factory.GetAsync<SupplierTransactionSummary>(tenant, sql, officeId, supplierId).ConfigureAwait(false)).FirstOrDefault();
        }


        private static IPaymentEntry LocateService(string tenant)
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


        public static async Task<long> PostAsync(string tenant, Payment model)
        {
            var service = LocateService(tenant);
            return await service.PostAsync(tenant, model).ConfigureAwait(false);
        }
    }
}