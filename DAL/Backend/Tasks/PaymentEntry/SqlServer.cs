using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.DataAccess.Extensions;
using Frapid.Framework.Extensions;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.DAL.Backend.Tasks.PaymentEntry
{
    public sealed class SqlServer : IPaymentEntry
    {
        public async Task<long> PostAsync(string tenant, Payment model)
        {
            string connectionString = FrapidDbServer.GetConnectionString(tenant);
            const string sql = @"EXECUTE purchase.post_supplier_payment
                                    @ValueDate, @BookDate,
                                    @UserId, @OfficeId, @LoginId, @SupplierId, 
                                    @CurrencyCode, @CashAccountId, @Amount, 
                                    @ExchangeRateDebit, @ExchangeRateCredit, 
                                    @ReferenceNumber, @StatementReference, 
                                    @CostCenterId, @CashRepositoryId, 
                                    @PostedDate, @BankId, @BankInstrumentCode, @BankTranCode,
                                    @TransactionMasterId OUTPUT
                                ;";


            using (var connection = new SqlConnection(connectionString))
            {
                using (var command = new SqlCommand(sql, connection))
                {
                    command.Parameters.AddWithNullableValue("@ValueDate", model.ValueDate);
                    command.Parameters.AddWithNullableValue("@BookDate", model.BookDate);
                    command.Parameters.AddWithNullableValue("@UserId", model.UserId);
                    command.Parameters.AddWithNullableValue("@OfficeId", model.OfficeId);
                    command.Parameters.AddWithNullableValue("@LoginId", model.LoginId);
                    command.Parameters.AddWithNullableValue("@SupplierId", model.SupplierId);
                    command.Parameters.AddWithNullableValue("@CurrencyCode", model.CurrencyCode);
                    command.Parameters.AddWithNullableValue("@CashAccountId", model.CashAccountId);
                    command.Parameters.AddWithNullableValue("@Amount", model.Amount);
                    command.Parameters.AddWithNullableValue("@ExchangeRateDebit", model.DebitExchangeRate);
                    command.Parameters.AddWithNullableValue("@ExchangeRateCredit", model.CreditExchangeRate);

                    command.Parameters.AddWithNullableValue("@ReferenceNumber", model.ReferenceNumber);
                    command.Parameters.AddWithNullableValue("@StatementReference", model.StatementReference);


                    command.Parameters.AddWithNullableValue("@CostCenterId", model.CostCenterId);
                    command.Parameters.AddWithNullableValue("@CashRepositoryId", model.CashRepositoryId);
                    command.Parameters.AddWithNullableValue("@PostedDate", model.PostedDate);
                    command.Parameters.AddWithNullableValue("@BankId", model.BankAccountId);

                    command.Parameters.AddWithNullableValue("@BankInstrumentCode", model.BankInstrumentCode);
                    command.Parameters.AddWithNullableValue("@BankTranCode", model.BankTransactionCode);

                    command.Parameters.Add("@TransactionMasterId", SqlDbType.BigInt).Direction = ParameterDirection.Output;

                    connection.Open();
                    await command.ExecuteNonQueryAsync().ConfigureAwait(false);

                    return command.Parameters["@TransactionMasterId"].Value.To<long>();
                }
            }
        }
    }
}