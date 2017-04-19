using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.DataAccess.Extensions;
using Frapid.Framework.Extensions;
using MixERP.Purchases.ViewModels;
using Npgsql;

namespace MixERP.Purchases.DAL.Backend.Tasks.PurchaseEntry
{
    public sealed class PostgreSQL : IPurchaseEntry
    {
        public async Task<long> PostAsync(string tenant, Purchase model)
        {
            string connectionString = FrapidDbServer.GetConnectionString(tenant);

            string sql = @"SELECT * FROM purchase.post_purchase
                            (
                                @OfficeId, @UserId, @LoginId, @ValueDate::date, @BookDate::date, 
                                @CostCenterId, @ReferenceNumber, @StatementReference, 
                                @SupplierId, @PriceTypeId, @ShipperId, @StoreId, ARRAY[{0}], @InvoiceDiscount
                            );";

            sql = string.Format(sql, this.GetParametersForDetails(model.Details));

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
                    command.Parameters.AddWithNullableValue("@StoreId", model.StoreId);

                    command.Parameters.AddRange(this.AddParametersForDetails(model.Details).ToArray());

                    command.Parameters.AddWithNullableValue("@InvoiceDiscount", model.Discount);

                    connection.Open();
                    var awaiter = await command.ExecuteScalarAsync().ConfigureAwait(false);
                    return awaiter.To<long>();
                }
            }
        }

        public string GetParametersForDetails(List<PurchaseDetailType> details)
        {
            if (details == null)
            {
                return "NULL::purchase.purchase_detail_type";
            }

            var items = new Collection<string>();
            for (int i = 0; i < details.Count; i++)
            {
                items.Add(string.Format(CultureInfo.InvariantCulture,
                    "ROW(@StoreId{0}, @TransactionType{0}, @ItemId{0}, @Quantity{0}, @UnitId{0},@Price{0}, @DiscountRate{0}, @Tax{0}, @ShippingCharge{0})::purchase.purchase_detail_type",
                    i.ToString(CultureInfo.InvariantCulture)));
            }

            return string.Join(",", items);
        }

        public IEnumerable<NpgsqlParameter> AddParametersForDetails(List<PurchaseDetailType> details)
        {
            var parameters = new List<NpgsqlParameter>();

            if (details != null)
            {
                for (int i = 0; i < details.Count; i++)
                {
                    parameters.Add(new NpgsqlParameter("@StoreId" + i, details[i].StoreId));
                    parameters.Add(new NpgsqlParameter("@TransactionType" + i, "Dr")); //Inventory is increased
                    parameters.Add(new NpgsqlParameter("@ItemId" + i, details[i].ItemId));
                    parameters.Add(new NpgsqlParameter("@Quantity" + i, details[i].Quantity));
                    parameters.Add(new NpgsqlParameter("@UnitId" + i, details[i].UnitId));
                    parameters.Add(new NpgsqlParameter("@Price" + i, details[i].Price));
                    parameters.Add(new NpgsqlParameter("@DiscountRate" + i, details[i].DiscountRate));
                    parameters.Add(new NpgsqlParameter("@Tax" + i, DBNull.Value));//Tax will be determined on the database level.
                    parameters.Add(new NpgsqlParameter("@ShippingCharge" + i, details[i].ShippingCharge));
                }
            }

            return parameters;
        }
    }
}