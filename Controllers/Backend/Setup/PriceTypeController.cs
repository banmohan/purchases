using System.Web.Mvc;
using Frapid.Dashboard;

namespace MixERP.Purchases.Controllers.Backend.Setup
{
    public class PriceTypeController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/setup/price-types")]
        [MenuPolicy]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Setup/PriceTypes.cshtml", this.Tenant));
        }
    }
}