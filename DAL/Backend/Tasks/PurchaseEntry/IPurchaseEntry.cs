using System.Threading.Tasks;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.DAL.Backend.Tasks.PurchaseEntry
{
    public interface IPurchaseEntry
    {
        Task<long> PostAsync(string tenant, Purchase model);
    }
}