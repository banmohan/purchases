using System.Web.Mvc;
using Frapid.Dashboard.Extensions;

namespace MixERP.Purchases.Extensions
{
    public static class PartialViewExtensions
    {
        public static MvcHtmlString PartialView(this HtmlHelper helper, string path, string tenant)
        {
            return helper.PartialView<AreaRegistration>(path, tenant);
        }

        public static MvcHtmlString DashboardPartialView(this HtmlHelper helper, string path, string tenant)
        {
            return helper.PartialView<Frapid.Dashboard.AreaRegistration>(path, tenant);
        }

        public static MvcHtmlString FinancePartialView(this HtmlHelper helper, string path, string tenant)
        {
            return helper.PartialView<Finance.AreaRegistration>(path, tenant);
        }

        public static MvcHtmlString InventoryPartialView(this HtmlHelper helper, string path, string tenant)
        {
            return helper.PartialView<Inventory.AreaRegistration>(path, tenant);
        }

        public static MvcHtmlString InventoryPartialView(this HtmlHelper helper, string path, string tenant, object model)
        {
            return helper.PartialView<Inventory.AreaRegistration>(path, tenant, model);
        }

        public static MvcHtmlString PartialView(this HtmlHelper helper, string path, string tenant, object model)
        {
            return helper.PartialView<AreaRegistration>(path, tenant, model);
        }

        public static MvcHtmlString FinancePartialView(this HtmlHelper helper, string path, string tenant, object model)
        {
            return helper.PartialView<Finance.AreaRegistration>(path, tenant, model);
        }
    }
}