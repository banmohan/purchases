using Frapid.Dashboard.Controllers;

namespace MixERP.Purchases.Controllers
{
    public class PurchaseDashboardController : DashboardController
    {
        public PurchaseDashboardController()
        {
            ViewBag.PurchaseLayoutPath = this.GetLayoutPath();
        }

        private string GetLayoutPath()
        {
            return this.GetRazorView<AreaRegistration>("Layout.cshtml", this.Tenant);
        }
    }
}