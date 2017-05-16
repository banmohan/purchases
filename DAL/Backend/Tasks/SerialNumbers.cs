using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Frapid.ApplicationState.Models;
using Frapid.Configuration;
using Frapid.Configuration.Db;
using Frapid.DataAccess;
using Frapid.Mapper.Query.Insert;
using Frapid.Mapper.Query.Select;

namespace MixERP.Purchases.DAL.Backend.Tasks
{
    public static class SerialNumbers
    {
        public static async Task<ViewModels.SerialNumber> GetDetails(string tenant, long transactionMasterId)
        {
            const string checkoutSql = @"SELECT item_id, item_name, unit_id, unit_name, FLOOR(quantity) AS quantity, checkout_id, store_id, store_name, transaction_type
                                FROM inventory.checkout_detail_view WHERE transaction_master_id = @0;";
            var checkouts = await Factory.GetAsync<ViewModels.CheckoutInfo>(tenant, checkoutSql, transactionMasterId)
                .ConfigureAwait(false);

            if (checkouts == null)
            {
                return null;
            }

            const string detailSql = @"SELECT * FROM inventory.serial_numbers_view
                                WHERE transaction_master_id = @0;";

            var details = await Factory.GetAsync<DTO.SerialNumberView>(tenant, detailSql, transactionMasterId)
                .ConfigureAwait(false);

            return new ViewModels.SerialNumber
            {
                CheckoutInfos = checkouts.ToList(),
                SerialNumberViews = details.ToList()
            };

        }

        public static async Task<bool> Post(string tenant, LoginView meta, List<DTO.SerialNumbers> model)
        {
            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                try
                {
                    const string sql = @"SELECT serial_number_id FROM inventory.serial_numbers
                            WHERE item_id=@0 AND unit_id=@1 AND batch_number=@2 AND serial_number=@3;";

                    await db.BeginTransactionAsync().ConfigureAwait(false);

                    foreach (var serial in model)
                    {
                        var item = await db.ScalarAsync<long?>(sql, serial.ItemId, serial.UnitId, serial.BatchNumber, serial.SerialNumber)
                            .ConfigureAwait(false);
                        if (item != null)
                        {
                            continue;
                        }

                        serial.Deleted = false;

                        await db.InsertAsync("inventory.serial_numbers", "serial_number_id", serial);
                    }

                    db.CommitTransaction();
                }
                catch (Exception)
                {
                    db.RollbackTransaction();
                    throw;
                }
            }

            return true;
        }
    }
}