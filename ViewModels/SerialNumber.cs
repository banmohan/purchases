using System.Collections.Generic;

namespace MixERP.Purchases.ViewModels
{
    public class SerialNumber
    {
        public List<CheckoutInfo> CheckoutInfos { get; set; }
        public List<DTO.SerialNumberView> SerialNumberViews { get; set; }
    }

    public class CheckoutInfo
    {
        public int ItemId { get; set; }
        public string ItemName { get; set; }
        public int UnitId { get; set; }
        public string UnitName { get; set; }
        public int Quantity { get; set; }
        public long CheckoutId { get; set; }
        public int StoreId { get; set; }
        public string StoreName { get; set; }
        public string TransactionType { get; set; }
    }
}