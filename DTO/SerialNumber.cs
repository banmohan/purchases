using System;
using Frapid.Mapper.Decorators;

namespace MixERP.Purchases.DTO
{
    [TableName("inventory.serial_numbers")]
    [PrimaryKey("serial_number_id")]
    public class SerialNumbers
    {
        public long SerialNumberId { get; set; }
        public int ItemId { get; set; }
        public int UnitId { get; set; }
        public int StoreId { get; set; }
        public string TransactionType { get; set; }
        public long CheckoutId { get; set; }
        public string BatchNumber { get; set; }
        public string SerialNumber { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public bool Deleted { get; set; }
    }
}