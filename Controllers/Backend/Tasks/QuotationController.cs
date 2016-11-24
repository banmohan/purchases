using System.Threading.Tasks;
using System.Web.Mvc;
using Frapid.ApplicationState.Cache;
using Frapid.Dashboard;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.Controllers.Backend.Tasks
{
    public class QuotationController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/tasks/quotation/checklist/{tranId}")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/quotation")]
        public ActionResult CheckList(long tranId)
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Quotation/CheckList.cshtml", this.Tenant), tranId);
        }

        [Route("dashboard/purchase/tasks/quotation")]
        [MenuPolicy]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Quotation/Index.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/quotation/verification")]
        [MenuPolicy]
        public ActionResult Verification()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Quotation/Verification.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/quotation/new")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/quotation")]
        public ActionResult New()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Quotation/New.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/quotation/new")]
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