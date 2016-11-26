using System;
using System.Net;
using System.Threading.Tasks;
using System.Web.Mvc;
using Frapid.ApplicationState.Cache;
using Frapid.Dashboard;
using MixERP.Purchases.DAL.Backend.Tasks;
using MixERP.Purchases.DTO;
using MixERP.Purchases.QueryModels;

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

        [Route("dashboard/purchase/tasks/order/view")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/tasks/order")]
        public async Task<ActionResult> ViewAsync(OrderQueryModel query)
        {
            try
            {
                var meta = await AppUsers.GetCurrentAsync().ConfigureAwait(false);

                query.UserId = meta.UserId;
                query.OfficeId = meta.OfficeId;

                var model = await Orders.GetOrderResultViewAsync(this.Tenant, query).ConfigureAwait(true);
                return this.Ok(model);
            }
            catch (Exception ex)
            {
                return this.Failed(ex.Message, HttpStatusCode.InternalServerError);
            }
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
        public async Task<ActionResult> PostAsync(Order model)
        {
            if (!this.ModelState.IsValid)
            {
                return this.InvalidModelState(this.ModelState);
            }

            var meta = await AppUsers.GetCurrentAsync().ConfigureAwait(true);

            model.UserId = meta.UserId;
            model.OfficeId = meta.OfficeId;
            model.AuditUserId = meta.UserId;
            model.AuditTs = DateTimeOffset.UtcNow;
            model.TransactionTimestamp = DateTimeOffset.UtcNow;

            try
            {
                long tranId = await Orders.PostAsync(this.Tenant, model).ConfigureAwait(true);
                return this.Ok(tranId);
            }
            catch (Exception ex)
            {
                return this.Failed(ex.Message, HttpStatusCode.InternalServerError);
            }
        }
    }
}