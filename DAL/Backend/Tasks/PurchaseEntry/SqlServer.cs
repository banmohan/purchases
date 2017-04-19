using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.DataAccess.Extensions;
using Frapid.Framework.Extensions;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.DAL.Backend.Tasks.PurchaseEntry
{
    public sealed class SqlServer : IPurchaseEntry
    {
        public async Task<long> PostAsync(string tenant, Purchase model)
        {
            string connectionString = FrapidDbServer.GetConnectionString(tenant);

            string sql = @"EXECUTE purchase.post_purchase
                                @OfficeId, @UserId, @LoginId, @ValueDate, @BookDate, 
                                @CostCenterId, @ReferenceNumber, @StatementReference, 
                                @SupplierId, @PriceTypeId, @ShipperId, @StoreId, @Details, @InvoiceDiscount,
                                @TransactionMasterId OUTPUT
                            ;";

            using (var connection = new SqlConnection(connectionString))
            {
                using (var command = new SqlCommand(sql, connection))
                {
                    command.Parameters.AddWithNullableValue("@OfficeId", model.OfficeId);
                    command.Parameters.AddWithNullableValue("@UserId", model.UserId);
                    command.Parameters.AddWithNullableValue("@LoginId", model.LoginId);
                    command.Parameters.AddWithNullableValue("@ValueDate", model.ValueDate);
                    command.Parameters.AddWithNullableValue("@BookDate", model.BookDate);
                    command.Parameters.AddWithNullableValue("@CostCenterId", model.CostCenterId);
                    command.Parameters.AddWithNullableValue("@ReferenceNumber", model.ReferenceNumber.Or(""));
                    command.Parameters.AddWithNullableValue("@StatementReference", model.StatementReference.Or(""));
                    command.Parameters.AddWithNullableValue("@SupplierId", model.SupplierId);
                    command.Parameters.AddWithNullableValue("@PriceTypeId", model.PriceTypeId);
                    command.Parameters.AddWithNullableValue("@ShipperId", model.ShipperId);
                    command.Parameters.AddWithNullableValue("@StoreId", model.StoreId);

                    using (var details = this.GetDetails(model.Details))
                    {
                        command.Parameters.AddWithNullableValue("@Details", details, "purchase.purchase_detail_type");
                    }

                    command.Parameters.AddWithNullableValue("@InvoiceDiscount", model.Discount);
                    command.Parameters.Add("@TransactionMasterId", SqlDbType.BigInt).Direction = ParameterDirection.Output;

                    connection.Open();
                    await command.ExecuteNonQueryAsync().ConfigureAwait(false);
                    return command.Parameters["@TransactionMasterId"].Value.To<long>();
                }
            }
        }

        public DataTable GetDetails(IEnumerable<PurchaseDetailType> details)
        {
            var table = new DataTable();
            table.Columns.Add("StoreId", typeof(int));
            table.Columns.Add("TransactionType", typeof(string));
            table.Columns.Add("ItemId", typeof(int));
            table.Columns.Add("Quantity", typeof(decimal));
            table.Columns.Add("UnitId", typeof(int));
            table.Columns.Add("Price", typeof(decimal));
            table.Columns.Add("DiscountRate", typeof(decimal));
            table.Columns.Add("Tax", typeof(decimal));
            table.Columns.Add("ShippingCharge", typeof(decimal));

            foreach (var detail in details)
            {
                var row = table.NewRow();
                row["StoreId"] = detail.StoreId;
                row["TransactionType"] = "Dr";//Inventory is increased
                row["ItemId"] = detail.ItemId;
                row["Quantity"] = detail.Quantity;
                row["UnitId"] = detail.UnitId;
                row["Price"] = detail.Price;
                row["DiscountRate"] = detail.DiscountRate;
                row["Tax"] = DBNull.Value;//Tax will be determined on the database level.
                row["ShippingCharge"] = detail.ShippingCharge;

                table.Rows.Add(row);
            }

            return table;
        }
    }
}