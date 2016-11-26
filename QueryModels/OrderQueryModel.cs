using System;

namespace MixERP.Purchases.QueryModels
{
    public class OrderQueryModel
    {
        public int UserId { get; set; }
        public int OfficeId { get; set; }
        public string Supplier { get; set; }
        public DateTime From { get; set; }
        public DateTime To { get; set; }
        public DateTime ExpectedFrom { get; set; }
        public DateTime ExpectedTo { get; set; }
        public long Id { get; set; }
        public string ReferenceNumber { get; set; }
        public string Terms { get; set; }
        public string InternalMemo { get; set; }
        public string PostedBy { get; set; }
        public string Office { get; set; }
    }
}