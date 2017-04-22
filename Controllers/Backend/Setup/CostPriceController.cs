using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Mvc;
using Frapid.ApplicationState.Cache;
using Frapid.Dashboard;
using Frapid.DataAccess.Models;
using MixERP.Purchases.DAL.Backend.Setup;
using MixERP.Purchases.DTO;

namespace MixERP.Purchases.Controllers.Backend.Setup
{
    public class CostPriceController : PurchaseDashboardController
    {
        [Route("dashboard/purchase/setup/cost-prices")]
        [MenuPolicy]
        [AccessPolicy("purchase", "item_cost_price_scrud_view", AccessTypeEnum.Read)]
        public ActionResult Index()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Setup/CostPrices.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/setup/cost-prices/supplier")]
        [MenuPolicy]
        [AccessPolicy("purchase", "supplierwise_cost_prices", AccessTypeEnum.Read)]
        public ActionResult Supplier()
        {
            return this.FrapidView(this.GetRazorView<AreaRegistration>("Setup/SupplierCostPrices.cshtml", this.Tenant));
        }

        [Route("dashboard/purchase/setup/cost-prices/{supplierId}/price-list")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/setup/cost-prices/supplier")]
        [AccessPolicy("purchase", "supplierwise_cost_prices", AccessTypeEnum.Read)]
        public async Task<ActionResult> GetPriceListAsync(int supplierId)
        {
            if (supplierId <= 0)
            {
                return this.Failed(I18N.BadRequest, HttpStatusCode.BadRequest);
            }

            var meta = await AppUsers.GetCurrentAsync().ConfigureAwait(true);

            try
            {
                var result = await CostPrices.GetCostPrice(this.Tenant, meta.OfficeId, supplierId).ConfigureAwait(true);
                return this.Ok(result);
            }
            catch (Exception ex)
            {
                return this.Failed(ex.Message, HttpStatusCode.InternalServerError);
            }
        }

        [Route("dashboard/purchase/setup/cost-prices/{supplierId}/price-list")]
        [MenuPolicy(OverridePath = "/dashboard/purchase/setup/cost-prices/supplier")]
        [AccessPolicy("purchase", "supplierwise_cost_prices", AccessTypeEnum.Execute)]
        [HttpPost]
        public async Task<ActionResult> SetPriceListAsync(int supplierId, IEnumerable<SupplierwiseCostPrice> model)
        {
            if (supplierId <= 0)
            {
                return this.Failed(I18N.BadRequest, HttpStatusCode.BadRequest);
            }

            var meta = await AppUsers.GetCurrentAsync().ConfigureAwait(true);

            try
            {
                await CostPrices.SetPriceList(this.Tenant, meta.UserId, supplierId, model).ConfigureAwait(true);
                return this.Ok();
            }
            catch (Exception ex)
            {
                return this.Failed(ex.Message, HttpStatusCode.InternalServerError);
            }
        }
    }
}