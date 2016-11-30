using Frapid.Mapper.Decorators;

namespace MixERP.Purchases.DTO
{
    [TableName("purchase.item_view")]
    public sealed class ItemView
    {
        public int ItemId { get; set; }
        public string ItemCode { get; set; }
        public string ItemName { get; set; }
        public string Barcode { get; set; }
        public int ItemGroupId { get; set; }
        public string ItemGroupName { get; set; }
        public int ItemTypeId { get; set; }
        public string ItemTypeName { get; set; }
        public int BrandId { get; set; }
        public string BrandName { get; set; }
        public int PreferredSupplierId { get; set; }
        public int UnitId { get; set; }
        public string ValidUnits { get; set; }
        public string UnitCode { get; set; }
        public string UnitName { get; set; }
        public bool HotItem { get; set; }
        public decimal CostPrice { get; set; }
        public string Photo { get; set; }
    }
}