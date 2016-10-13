using System.Web.Mvc;
using Frapid.Dashboard;

namespace MixERP.Purchases.Controllers.Backend.Setup
{
    public class CostPriceController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/setup/cost-prices")]
        [MenuPolicy]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Setup/CostPrices.cshtml", this.Tenant));
        }
    }
}