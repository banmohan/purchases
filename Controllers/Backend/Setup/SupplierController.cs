using System.Web.Mvc;
using Frapid.Dashboard;

namespace MixERP.Purchases.Controllers.Backend.Setup
{
    public class SupplierController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/setup/suppliers")]
        [MenuPolicy]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Setup/Suppliers.cshtml", this.Tenant));
        }
    }
}