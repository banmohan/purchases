using System;
using Frapid.DataAccess;
using Frapid.Mapper.Decorators;

namespace MixERP.Purchases.DTO
{
    [TableName("purchase.supplierwise_cost_prices")]
    [PrimaryKey("cost_price_id", AutoIncrement = true)]
    public sealed class SupplierwiseCostPrice : IPoco
    {
        public long CostPriceId { get; set; }
        public int ItemId { get; set; }
        public int SupplierId { get; set; }
        public int UnitId { get; set; }
        public decimal? Price { get; set; }
        public int? AuditUserId { get; set; }
        public DateTimeOffset? AuditTs { get; set; }
        public bool? Deleted { get; set; }
    }
}