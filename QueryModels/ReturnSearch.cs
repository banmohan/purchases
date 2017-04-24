using System;

namespace MixERP.Purchases.QueryModels
{
    public sealed class ReturnSearch
    {
        public DateTime From { get; set; }
        public DateTime To { get; set; }
        public string TranId { get; set; }
        public string TranCode { get; set; }
        public string ReferenceNumber { get; set; }
        public string StatementReference { get; set; }
        public string PostedBy { get; set; }
        public string Office { get; set; }
        public string Status { get; set; }
        public string VerifiedBy { get; set; }
        public string Reason { get; set; }
        public decimal Amount { get; set; }
        public string Supplier { get; set; }
    }
}