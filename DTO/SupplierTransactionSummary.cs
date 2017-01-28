namespace MixERP.Purchases.DTO
{
    public sealed class SupplierTransactionSummary
    {
        public string CurrencyCode { get; set; }
        public string CurrencySymbol { get; set; }
        public decimal TotalDueAmount { get; set; }
        public decimal OfficeDueAmount { get; set; }
    }
}