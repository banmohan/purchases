using System.Linq;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.DataAccess.Extensions;
using Frapid.Framework.Extensions;
using Npgsql;

namespace MixERP.Purchases.DAL.Backend.Tasks.PurchaseReturn
{
    public sealed class PostgreSQL : IPurchaseReturn
    {
        public async Task<long> PostAsync(string tenant, ViewModels.PurchaseReturn model)
        {
            string connectionString = FrapidDbServer.GetConnectionString(tenant);

            string sql = @"SELECT * FROM purchase.post_return
                            (
                                @TransactionMasterId::bigint, @OfficeId::integer, @UserId::integer, @LoginId::bigint, 
                                @ValueDate::date, @BookDate::date, 
                                @StoreId::integer, @CostCenterId::integer, @SupplierId::integer, @PriceTypeId::integer, @ShipperId::integer,
                                @ReferenceNumber::national character varying(24), @StatementReference::text, ARRAY[{0}], @InvoiceDiscount
                            );";

            sql = string.Format(sql, new PurchaseEntry.PostgreSQL().GetParametersForDetails(model.Details));

            using (var connection = new NpgsqlConnection(connectionString))
            {
                using (var command = new NpgsqlCommand(sql, connection))
                {
                    command.Parameters.AddWithNullableValue("@TransactionMasterId", model.TransactionMasterId);
                    command.Parameters.AddWithNullableValue("@OfficeId", model.OfficeId);
                    command.Parameters.AddWithNullableValue("@UserId", model.UserId);
                    command.Parameters.AddWithNullableValue("@LoginId", model.LoginId);
                    command.Parameters.AddWithNullableValue("@ValueDate", model.ValueDate);
                    command.Parameters.AddWithNullableValue("@BookDate", model.BookDate);
                    command.Parameters.AddWithNullableValue("@StoreId", model.StoreId);
                    command.Parameters.AddWithNullableValue("@CostCenterId", model.CostCenterId);
                    command.Parameters.AddWithNullableValue("@ReferenceNumber", model.ReferenceNumber);
                    command.Parameters.AddWithNullableValue("@StatementReference", model.StatementReference);
                    command.Parameters.AddWithNullableValue("@SupplierId", model.SupplierId);
                    command.Parameters.AddWithNullableValue("@PriceTypeId", model.PriceTypeId);
                    command.Parameters.AddWithNullableValue("@ShipperId", model.ShipperId);

                    command.Parameters.AddRange(new PurchaseEntry.PostgreSQL().AddParametersForDetails(model.Details).ToArray());

                    command.Parameters.AddWithNullableValue("@InvoiceDiscount", model.Discount);

                    connection.Open();
                    var awaiter = await command.ExecuteScalarAsync().ConfigureAwait(false);
                    return awaiter.To<long>();
                }
            }
        }

    }
}