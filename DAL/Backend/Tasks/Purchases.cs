using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.Framework.Extensions;
using MixERP.Purchases.ViewModels;
using Npgsql;

namespace MixERP.Purchases.DAL.Backend.Tasks
{
    public static class Purchases
    {
        public static async Task<long> PostAsync(string tenant, Purchase model)
        {
            string connectionString = FrapidDbServer.GetConnectionString(tenant);

            string sql = @"SELECT * FROM purchase.post_purchase
                            (
                                @OfficeId, @UserId, @LoginId, @ValueDate::date, @BookDate::date, 
                                @CostCenterId, @ReferenceNumber, @StatementReference, 
                                @SupplierId, @PriceTypeId, @ShipperId, ARRAY[{0}]
                            );";

            sql = string.Format(sql, GetParametersForDetails(model.Details));

            using (var connection = new NpgsqlConnection(connectionString))
            {
                using (var command = new NpgsqlCommand(sql, connection))
                {
                    command.Parameters.AddWithValue("@OfficeId", model.OfficeId);
                    command.Parameters.AddWithValue("@UserId", model.UserId);
                    command.Parameters.AddWithValue("@LoginId", model.LoginId);
                    command.Parameters.AddWithValue("@ValueDate", model.ValueDate);
                    command.Parameters.AddWithValue("@BookDate", model.BookDate);
                    command.Parameters.AddWithValue("@CostCenterId", model.CostCenterId);
                    command.Parameters.AddWithValue("@ReferenceNumber", model.ReferenceNumber.Or(""));
                    command.Parameters.AddWithValue("@StatementReference", model.StatementReference.Or(""));
                    command.Parameters.AddWithValue("@SupplierId", model.SupplierId);
                    command.Parameters.AddWithValue("@PriceTypeId", model.PriceTypeId);
                    command.Parameters.AddWithValue("@ShipperId", model.ShipperId);

                    command.Parameters.AddRange(AddParametersForDetails(model.Details).ToArray());

                    connection.Open();
                    var awaiter = await command.ExecuteScalarAsync().ConfigureAwait(false);
                    return awaiter.To<long>();
                }
            }
        }

        public static string GetParametersForDetails(List<PurchaseDetailType> details)
        {
            if (details == null)
            {
                return "NULL::purchase.purchase_detail_type";
            }

            var items = new Collection<string>();
            for (int i = 0; i < details.Count; i++)
            {
                items.Add(string.Format(CultureInfo.InvariantCulture,
                    "ROW(@StoreId{0}, @TransactionType{0}, @ItemId{0}, @Quantity{0}, @UnitId{0},@Price{0}, @Discount{0}, @ShippingCharge{0})::purchase.purchase_detail_type",
                    i.ToString(CultureInfo.InvariantCulture)));
            }

            return string.Join(",", items);
        }

        public static IEnumerable<NpgsqlParameter> AddParametersForDetails(List<PurchaseDetailType> details)
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
                    parameters.Add(new NpgsqlParameter("@Discount" + i, details[i].Discount));
                    parameters.Add(new NpgsqlParameter("@ShippingCharge" + i, details[i].ShippingCharge));
                }
            }

            return parameters;
        }
    }
}