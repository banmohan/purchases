using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MixERP.Purchases.ViewModels
{
    public sealed class Purchase
    {
        public int OfficeId { get; set; }
        public int UserId { get; set; }
        public long LoginId { get; set; }
        [Required]
        public DateTime ValueDate { get; set; }
        [Required]
        public DateTime BookDate { get; set; }
        public int CostCenterId { get; set; }
        public string ReferenceNumber { get; set; }
        public string StatementReference { get; set; }
        [Required]
        public int SupplierId { get; set; }
        [Required]
        public int PriceTypeId { get; set; }
        public int ShipperId { get; set; }
        [Required]
        public int StoreId { get; set; }

        public decimal Discount { get; set; }

        [Required]
        public List<PurchaseDetailType> Details { get; set; }
    }
}