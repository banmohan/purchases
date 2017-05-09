using System;
using Frapid.Mapper.Decorators;

namespace MixERP.Purchases.DTO
{
    [TableName("inventory.serial_numbers_view")]
    public class SerialNumberView
    {
        public long SerialNumberId { get; set; }
        public int ItemId { get; set; }
        public string ItemName { get; set; }
        public int UnitId { get; set; }
        public string UnitCode { get; set; }
        public int StoreId { get; set; }
        public string StoreName { get; set; }
        public string TransactionType { get; set; }
        public long CheckoutId { get; set; }
        public long TransactionMasterId { get; set; }
        public string BatchNumber { get; set; }
        public string SerialNumber { get; set; }
        public DateTime? ExpiryDate { get; set; }
    }
}