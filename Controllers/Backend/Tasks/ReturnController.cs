using System.Threading.Tasks;
using System.Web.Mvc;
using Frapid.ApplicationState.Cache;
using Frapid.Dashboard;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.Controllers.Backend.Tasks
{
    public class ReturnController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/tasks/return/checklist/{tranId}")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/return")]
        public ActionResult CheckList(long tranId)
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Return/CheckList.cshtml", this.Tenant), tranId);
        }

        [Route("dashboard/purchase/tasks/return")]
        [MenuPolicy]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Return/Index.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/return/new")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/return")]
        public ActionResult New()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Return/New.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/return/new")]
        [HttpPost]
        public async Task<ActionResult> PostAsync(PurchaseReturn model)
        {
            if (!this.ModelState.IsValid)
            {
                return this.InvalidModelState();
            }

            var meta = await AppUsers.GetCurrentAsync().ConfigureAwait(true);

            model.UserId = meta.UserId;
            model.OfficeId = meta.OfficeId;
            model.LoginId = meta.LoginId;

            long tranId = await DAL.Backend.Tasks.PurchaseReturns.PostAsync(this.Tenant, model).ConfigureAwait(true);
            return this.Ok(tranId);
        }
    }
}