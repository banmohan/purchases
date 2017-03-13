using System.Web.Mvc;
using Frapid.Dashboard;
using Frapid.DataAccess.Models;

namespace MixERP.Purchases.Controllers.Backend.Setup
{
    public class SupplierController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/setup/suppliers")]
        [MenuPolicy]
        [AccessPolicy("inventory", "suppliers", AccessTypeEnum.Read)]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Setup/Suppliers.cshtml", this.Tenant));
        }
    }
}