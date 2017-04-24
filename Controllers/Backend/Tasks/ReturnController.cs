using System;
using System.Net;
using System.Threading.Tasks;
using System.Web.Mvc;
using Frapid.ApplicationState.Cache;
using Frapid.Areas.CSRF;
using Frapid.Dashboard;
using Frapid.DataAccess.Models;
using MixERP.Purchases.DAL.Backend.Tasks;
using MixERP.Purchases.QueryModels;
using MixERP.Purchases.ViewModels;

namespace MixERP.Purchases.Controllers.Backend.Tasks
{
    [AntiForgery]
    public class ReturnController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/tasks/return/checklist/{tranId}")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/return")]
        [AccessPolicy("purchase", "purchase_returns", AccessTypeEnum.Read)]
        public ActionResult CheckList(long tranId)
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Return/CheckList.cshtml", this.Tenant), tranId);
        }

        [Route("dashboard/purchase/tasks/return")]
        [MenuPolicy]
        [AccessPolicy("purchase", "purchase_returns", AccessTypeEnum.Read)]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Return/Index.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/return/search")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/return")]
        [AccessPolicy("purchase", "purchase_returns", AccessTypeEnum.Read)]
        [HttpPost]
        public async Task<ActionResult> SearchAsync(ReturnSearch search)
        {
            var meta = await AppUsers.GetCurrentAsync().ConfigureAwait(true);

            try
            {
                var result = await PurchaseReturns.GetSearchViewAsync(this.Tenant, meta.OfficeId, search).ConfigureAwait(true);
                return this.Ok(result);
            }
            catch (Exception ex)
            {
                return this.Failed(ex.Message, HttpStatusCode.InternalServerError);
            }
        }

        [Route("dashboard/purchase/tasks/return/verification")]
        [MenuPolicy]
        [AccessPolicy("purchase", "purchase_returns", AccessTypeEnum.Read)]
        public ActionResult Verification()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Return/Verification.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/return/new")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/return")]
        [AccessPolicy("purchase", "purchase_returns", AccessTypeEnum.Read)]
        public ActionResult New()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Tasks/Return/New.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/tasks/return/new")]
        [HttpPost]
        [AccessPolicy("purchase", "purchase_returns", AccessTypeEnum.Create)]
        public async Task<ActionResult> PostAsync(PurchaseReturn model)
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
                long tranId = await PurchaseReturns.PostAsync(this.Tenant, model).ConfigureAwait(true);
                return this.Ok(tranId);
            }
            catch (Exception ex)
            {
                return this.Failed(ex.Message, HttpStatusCode.InternalServerError);
            }
        }
    }
}