using System.Web.Mvc;
using Frapid.Dashboard;
using Frapid.DataAccess.Models;

namespace MixERP.Purchases.Controllers.Backend.Setup
{
    public class CostPriceController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/setup/cost-prices")]
        [MenuPolicy]
        [AccessPolicy("purchase", "item_cost_price_scrud_view", AccessTypeEnum.Read)]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Setup/CostPrices.cshtml", this.Tenant));
        }
    }
}