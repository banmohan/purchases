using System.Web.Mvc;

namespace MixERP.Purchases.Controllers.Backend.Tasks
{
    public sealed class ConsoleController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/tasks/console")]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Console/Index.cshtml", this.Tenant));
        }
    }
}