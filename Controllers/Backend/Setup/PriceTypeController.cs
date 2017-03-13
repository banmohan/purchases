using System.Web.Mvc;
using Frapid.Dashboard;
using Frapid.DataAccess.Models;

namespace MixERP.Purchases.Controllers.Backend.Setup
{
    public class PriceTypeController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/setup/price-types")]
        [MenuPolicy]
        [AccessPolicy("purchase", "price_types", AccessTypeEnum.Read)]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Setup/PriceTypes.cshtml", this.Tenant));
        }
    }
}