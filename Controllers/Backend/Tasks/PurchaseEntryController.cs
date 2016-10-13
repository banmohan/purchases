using System.Threading.Tasks;
using System.Web.Mvc;
using Frapid.ApplicationState.Cache;
using Frapid.Dashboard;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.Controllers.Backend.Tasks
{
    public class PurchaseEntryController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/tasks/purchase-entry/new")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/purchase-entry")]
        public ActionResult New()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/PurchaseEntry/New.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/purchase/checklist/{tranId}")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/purchase-entry")]
        public ActionResult CheckList(long tranId)
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/PurchaseEntry/CheckList.cshtml", this.Tenant), tranId);
        }

        [Route("dashboard/purchase/tasks/purchase-entry")]
        [MenuPolicy]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/PurchaseEntry/Index.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/purchase-entry/new")]
        [HttpPost]
        public async Task<ActionResult> PostAsync(Purchase model)
        {
            if (!ModelState.IsValid)
            {
                return this.InvalidModelState();
            }

            var meta = await AppUsers.GetCurrentAsync();

            model.UserId = meta.UserId;
            model.OfficeId = meta.OfficeId;
            model.LoginId = meta.LoginId;

            long tranId = await DAL.Backend.Tasks.Purchases.PostAsync(this.Tenant, model);
            return this.Ok(tranId);
        }
    }
}