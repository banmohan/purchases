using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.DataAccess.Extensions;
using Frapid.Framework.Extensions;

namespace MixERP.Purchases.DAL.Backend.Tasks.PurchaseReturn
{
    public sealed class SqlServer : IPurchaseReturn
    {
        public async Task<long> PostAsync(string tenant, ViewModels.PurchaseReturn model)
        {
            string connectionString = FrapidDbServer.GetConnectionString(tenant);

            string sql = @"EXECUTE purchase.post_return
                                @TransactionMasterId, @OfficeId, @UserId, @LoginId, @ValueDate, @BookDate, 
                                @StoreId, @CostCenterId, @SupplierId, @PriceTypeId, @ShipperId,
                                @ReferenceNumber, @StatementReference, @Details, @InvoiceDiscount, @TranMasterId OUTPUT;";

            sql = string.Format(sql, new PurchaseEntry.PostgreSQL().GetParametersForDetails(model.Details));

            using (var connection = new SqlConnection(connectionString))
            {
                using (var command = new SqlCommand(sql, connection))
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

                    using (var details = PurchaseEntry.SqlServer.GetDetails(model.Details))
                    {
                        command.Parameters.AddWithNullableValue("@Details", details, "purchase.purchase_detail_type");
                    }

                    command.Parameters.AddWithNullableValue("@InvoiceDiscount", model.Discount);
                    command.Parameters.Add("@TranMasterId", SqlDbType.BigInt).Direction = ParameterDirection.Output;

                    connection.Open();
                    await command.ExecuteNonQueryAsync().ConfigureAwait(false);
                    return command.Parameters["@TranMasterId"].Value.To<long>();
                }
            }
        }
    }
}