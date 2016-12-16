using System.Threading.Tasks;

namespace MixERP.Purchases.DAL.Backend.Tasks.PurchaseReturn
{
    internal interface IPurchaseReturn
    {
        Task<long> PostAsync(string tenant, ViewModels.PurchaseReturn model);
    }
}