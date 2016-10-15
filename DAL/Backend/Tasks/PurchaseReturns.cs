using System.Linq;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.Framework.Extensions;
using MixERP.Purchases.ViewModels;
using Npgsql;

namespace MixERP.Purchases.DAL.Backend.Tasks
{
    public static class PurchaseReturns
    {
        public static async Task<long> PostAsync(string tenant, PurchaseReturn model)
        {
            string connectionString = FrapidDbServer.GetConnectionString(tenant);

            string sql = @"SELECT * FROM purchase.post_return
                            (
                                @TransactionMasterId, @OfficeId, @UserId, @LoginId, @ValueDate, @BookDate, 
                                @CostCenterId, @SupplierId, @PriceTypeId, @ShipperId,
                                @ReferenceNumber, @StatementReference, ARRAY[{0}]
                            );";

            sql = string.Format(sql, Purchases.GetParametersForDetails(model.Details));

            using (var connection = new NpgsqlConnection(connectionString))
            {
                using (var command = new NpgsqlCommand(sql, connection))
                {
                    command.Parameters.AddWithValue("@TransactionMasterId", model.TransactionMasterId);
                    command.Parameters.AddWithValue("@OfficeId", model.OfficeId);
                    command.Parameters.AddWithValue("@UserId", model.UserId);
                    command.Parameters.AddWithValue("@LoginId", model.LoginId);
                    command.Parameters.AddWithValue("@ValueDate", model.ValueDate);
                    command.Parameters.AddWithValue("@BookDate", model.BookDate);
                    command.Parameters.AddWithValue("@CostCenterId", model.CostCenterId);
                    command.Parameters.AddWithValue("@ReferenceNumber", model.ReferenceNumber);
                    command.Parameters.AddWithValue("@StatementReference", model.StatementReference);
                    command.Parameters.AddWithValue("@SupplierId", model.SupplierId);
                    command.Parameters.AddWithValue("@PriceTypeId", model.PriceTypeId);
                    command.Parameters.AddWithValue("@ShipperId", model.ShipperId);

                    command.Parameters.AddRange(Purchases.AddParametersForDetails(model.Details).ToArray());

                    connection.Open();
                    var awaiter = await command.ExecuteScalarAsync().ConfigureAwait(false);
                    return awaiter.To<long>();
                }
            }
        }
    }
}