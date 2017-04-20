using System;
using System.Collections.Generic;
using Frapid.Mapper.Decorators;

namespace MixERP.Purchases.DTO
{
    [TableName("purchase.orders")]
    [PrimaryKey("order_id")]
    public class Order
    {
        public long OrderId { get; set; }
        public long? QuotationId { get; set; }
        public DateTime ValueDate { get; set; }
        public DateTime ExpectedDeliveryDate { get; set; }
        public DateTimeOffset TransactionTimestamp { get; set; }
        public int SupplierId { get; set; }
        public int PriceTypeId { get; set; }
        public int? ShipperId { get; set; }
        public int UserId { get; set; }
        public int OfficeId { get; set; }
        public string ReferenceNumber { get; set; }
        public string Terms { get; set; }
        public string InternalMemo { get; set; }
        public decimal TaxableTotal { get; set; }
        public decimal Discount { get; set; }
        public decimal TaxRate { get; set; }
        public decimal Tax { get; set; }
        public decimal NontaxableTotal { get; set; }
        public int AuditUserId { get; set; }
        public DateTimeOffset AuditTs { get; set; }
        public bool Deleted { get; set; }

        [Ignore]
        public List<OrderDetail> Details { get; set; }
    }
}