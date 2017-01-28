using System;
using System.ComponentModel.DataAnnotations;

namespace MixERP.Purchases.ViewModels
{
    public sealed class Payment
    {
        public int OfficeId { get; set; }
        public int UserId { get; set; }
        public long LoginId { get; set; }

        [Required]
        public int SupplierId { get; set; }

        [Required]
        public string CurrencyCode { get; set; }

        [Required]
        public decimal Amount { get; set; }

        [Required]
        public decimal DebitExchangeRate { get; set; }

        [Required]
        public decimal CreditExchangeRate { get; set; }

        public string ReferenceNumber { get; set; }
        public string StatementReference { get; set; }
        public int CostCenterId { get; set; }

        public int? CashAccountId { get; set; }
        public int? CashRepositoryId { get; set; }
        public DateTime? PostedDate { get; set; }
        public long? BankAccountId { get; set; }
        public string BankInstrumentCode { get; set; }
        public string BankTransactionCode { get; set; }
    }
}