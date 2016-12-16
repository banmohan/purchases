using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.DataAccess.Extensions;
using Frapid.Framework.Extensions;
using MixERP.Purchases.ViewModels;
using Npgsql;

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
                                @SupplierId, @PriceTypeId, @ShipperId, @Details
                            ;";

            using (var connection = new NpgsqlConnection(connectionString))
            {
                using (var command = new NpgsqlCommand(sql, connection))
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

                    using (var details = this.GetDetails(model.Details))
                    {
                        command.Parameters.AddWithNullableValue("@Details", details, "purchase.purchase_detail_type");
                    }

                    connection.Open();
                    var awaiter = await command.ExecuteScalarAsync().ConfigureAwait(false);
                    return awaiter.To<long>();
                }
            }
        }

        public DataTable GetDetails(IEnumerable<PurchaseDetailType> details)
        {
            var table = new DataTable();
            table.Columns.Add("StoreId", typeof(int));
            table.Columns.Add("ItemId", typeof(int));
            table.Columns.Add("Quantity", typeof(decimal));
            table.Columns.Add("UnitId", typeof(int));
            table.Columns.Add("Price", typeof(decimal));
            table.Columns.Add("Discount", typeof(decimal));
            table.Columns.Add("Tax", typeof(decimal));
            table.Columns.Add("ShippingCharge", typeof(decimal));

            foreach (var detail in details)
            {
                var row = table.NewRow();
                row["StoreId"] = detail.StoreId;
                row["ItemId"] = detail.ItemId;
                row["Quantity"] = detail.Quantity;
                row["UnitId"] = detail.UnitId;
                row["Price"] = detail.Price;
                row["Discount"] = detail.Discount;
                row["Tax"] = detail.Tax;
                row["ShippingCharge"] = detail.ShippingCharge;

                table.Rows.Add(row);
            }

            return table;
        }
    }
}