using System;

namespace MixERP.Purchases.QueryModels
{
    public sealed class OrderSearch
    {
        public DateTime From { get; set; }
        public DateTime To { get; set; }
        public DateTime ExpectedFrom { get; set; }
        public DateTime ExpectedTo { get; set; }
        public string Id { get; set; }
        public string ReferenceNumber { get; set; }
        public string Supplier { get; set; }
        public string Terms { get; set; }
        public string Memo { get; set; }
        public string PostedBy { get; set; }
        public string Office { get; set; }
        public decimal Amount { get; set; }
    }
}