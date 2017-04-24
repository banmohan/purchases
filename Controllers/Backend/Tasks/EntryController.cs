using System;
using System.Net;
using System.Threading.Tasks;
using System.Web.Mvc;
using Frapid.ApplicationState.Cache;
using Frapid.Dashboard;
using MixERP.Purchases.ViewModels;
using Frapid.Areas.CSRF;
using Frapid.DataAccess.Models;
using MixERP.Purchases.QueryModels;

namespace MixERP.Purchases.Controllers.Backend.Tasks
{
    [AntiForgery]
    public class EntryController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/tasks/entry/checklist/{tranId}")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/entry")]
        [AccessPolicy("purchase", "purchases", AccessTypeEnum.Read)]
        public ActionResult CheckList(long tranId)
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Entry/CheckList.cshtml", this.Tenant), tranId);
        }

        [Route("dashboard/purchase/tasks/entry")]
        [MenuPolicy]
        [AccessPolicy("purchase", "purchases", AccessTypeEnum.Read)]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Entry/Index.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/entry/search")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/entry")]
        [AccessPolicy("purchase", "purchases", AccessTypeEnum.Read)]
        [HttpPost]
        public async Task<ActionResult> SearchAsync(PurchaseSearch search)
        {
            var meta = await AppUsers.GetCurrentAsync().ConfigureAwait(true);

            try
            {
                var result = await DAL.Backend.Tasks.Purchases.GetSearchViewAsync(this.Tenant, meta.OfficeId, search).ConfigureAwait(true);
                return this.Ok(result);
            }
            catch (Exception ex)
            {
                return this.Failed(ex.Message, HttpStatusCode.InternalServerError);
            }
        }

        [Route("dashboard/purchase/tasks/entry/verification")]
        [MenuPolicy]
        [AccessPolicy("purchase", "purchases", AccessTypeEnum.Verify)]
        public ActionResult Verification()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Entry/Verification.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/entry/new")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/entry")]
        [AccessPolicy("purchase", "purchases", AccessTypeEnum.Read)]
        public ActionResult New()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Entry/New.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/entry/new")]
        [HttpPost]
        [AccessPolicy("purchase", "purchases", AccessTypeEnum.Create)]
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

            try
            {
                long tranId = await DAL.Backend.Tasks.Purchases.PostAsync(this.Tenant, model).ConfigureAwait(true);
                return this.Ok(tranId);
            }
            catch (Exception ex)
            {
                return this.Failed(ex.Message, HttpStatusCode.InternalServerError);
            }
        }
    }
}