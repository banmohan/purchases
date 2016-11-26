using System;

namespace MixERP.Purchases.DTO
{
    public sealed class QuotationResultview
    {
        public long Id { get; set; }
        public string Supplier { get; set; }
        public DateTime ValueDate { get; set; }
        public DateTime ExpectedDate { get; set; }
        public string ReferenceNumber { get; set; }
        public string Terms { get; set; }
        public string InternalMemo { get; set; }
        public string PostedBy { get; set; }
        public string Office { get; set; }
        public string TransactionTs { get; set; }
    }
}