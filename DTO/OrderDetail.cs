using System;
using Frapid.NPoco;

namespace MixERP.Purchases.DTO
{
    [TableName("purchase.order_details")]
    [PrimaryKey("order_detail_id")]
    public class OrderDetail
    {
        public long OrderDetailId { get; set; }
        public long OrderId { get; set; }
        public DateTime ValueDate { get; set; }
        public int ItemId { get; set; }
        public decimal Price { get; set; }
        public decimal DiscountRate { get; set; }
        public decimal ShippingCharge { get; set; }
        public int UnitId { get; set; }
        public decimal Quantity { get; set; }
    }
}