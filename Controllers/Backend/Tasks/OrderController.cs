using System.Threading.Tasks;
using System.Web.Mvc;
using Frapid.ApplicationState.Cache;
using Frapid.Dashboard;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.Controllers.Backend.Tasks
{
    public class OrderController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/tasks/order/checklist/{tranId}")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/order")]
        public ActionResult CheckList(long tranId)
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Order/CheckList.cshtml", this.Tenant), tranId);
        }

        [Route("dashboard/purchase/tasks/order")]
        [MenuPolicy]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Order/Index.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/order/verification")]
        [MenuPolicy]
        public ActionResult Verification()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Order/Verification.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/order/new")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/order")]
        public ActionResult New()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Order/New.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/order/new")]
        [HttpPost]
        public async Task<ActionResult> PostAsync(Purchase model)
        {
            if (!this.ModelState.IsValid)
            {
                return this.InvalidModelState(this.ModelState);
            }

            var meta = await AppUsers.GetCurrentAsync().ConfigureAwait(true);

            model.UserId = meta.UserId;
            model.OfficeId = meta.OfficeId;
            model.LoginId = meta.LoginId;

            long tranId = await DAL.Backend.Tasks.Purchases.PostAsync(this.Tenant, model).ConfigureAwait(true);
            return this.Ok(tranId);
        }
    }
}