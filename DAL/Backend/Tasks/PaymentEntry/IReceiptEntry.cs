using System.Threading.Tasks;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.DAL.Backend.Tasks.PaymentEntry
{
    public interface IPaymentEntry
    {
        Task<long> PostAsync(string tenant, Payment model);
    }
}