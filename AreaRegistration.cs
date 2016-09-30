using System.Web.Mvc;
using Frapid.Areas;

namespace MixERP.Purchases
{
    public class AreaRegistration : FrapidAreaRegistration
    {
        public override string AreaName => "MixERP.Purchases";

        public override void RegisterArea(AreaRegistrationContext context)
        {
            context.Routes.LowercaseUrls = true;
            context.Routes.MapMvcAttributeRoutes();
        }
    }
}