using System;
using Frapid.Mapper.Decorators;

namespace MixERP.Purchases.DTO
{
    [TableName("purchase.quotation_details")]
    [PrimaryKey("quotation_detail_id")]
    public class QuotationDetail
    {
        public long QuotationDetailId { get; set; }
        public long QuotationId { get; set; }
        public DateTime ValueDate { get; set; }
        public int ItemId { get; set; }
        public decimal Quantity { get; set; }
        public int UnitId { get; set; }
        public decimal Price { get; set; }
        public decimal DiscountRate { get; set; }
        public decimal Discount { get; set; }
        public bool IsTaxed { get; set; }
        public decimal ShippingCharge { get; set; }
    }
}