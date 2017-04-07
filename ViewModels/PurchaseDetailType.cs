using System.ComponentModel.DataAnnotations;

namespace MixERP.Purchases.ViewModels
{
    public sealed class PurchaseDetailType
    {
        [Required]
        public int StoreId { get; set; }
        [Required]
        public int ItemId { get; set; }
        [Required]
        public decimal Quantity { get; set; }
        [Required]
        public int UnitId { get; set; }
        [Required]
        public decimal Price { get; set; }
        public decimal DiscountRate { get; set; }
        public decimal Tax { get; set; }
        public decimal ShippingCharge { get; set; }
    }
}