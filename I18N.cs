using System.Collections.Generic;
using System.Globalization;
using Frapid.Configuration;
using Frapid.i18n;

namespace MixERP.Purchases
{
	public sealed class Localize : ILocalize
	{
		public Dictionary<string, string> GetResources(CultureInfo culture)
		{
			string resourceDirectory = I18N.ResourceDirectory;
			return I18NResource.GetResources(resourceDirectory, culture);
		}
	}

	public static class I18N
	{
		public static string ResourceDirectory { get; }

		static I18N()
		{
			ResourceDirectory = PathMapper.MapPath("/Areas/MixERP.Purchases/i18n");
		}

		/// <summary>
		///Purchase
		/// </summary>
		public static string Purchase => I18NResource.GetString(ResourceDirectory, "Purchase");

		/// <summary>
		///Price
		/// </summary>
		public static string Price => I18NResource.GetString(ResourceDirectory, "Price");

		/// <summary>
		///Price Type Code
		/// </summary>
		public static string PriceTypeCode => I18NResource.GetString(ResourceDirectory, "PriceTypeCode");

		/// <summary>
		///Tender
		/// </summary>
		public static string Tender => I18NResource.GetString(ResourceDirectory, "Tender");

		/// <summary>
		///Unit Code
		/// </summary>
		public static string UnitCode => I18NResource.GetString(ResourceDirectory, "UnitCode");

		/// <summary>
		///Posted Date
		/// </summary>
		public static string PostedDate => I18NResource.GetString(ResourceDirectory, "PostedDate");

		/// <summary>
		///Supplier
		/// </summary>
		public static string Supplier => I18NResource.GetString(ResourceDirectory, "Supplier");

		/// <summary>
		///Lead Time In Days
		/// </summary>
		public static string LeadTimeInDays => I18NResource.GetString(ResourceDirectory, "LeadTimeInDays");

		/// <summary>
		///Includes Tax
		/// </summary>
		public static string IncludesTax => I18NResource.GetString(ResourceDirectory, "IncludesTax");

		/// <summary>
		///Internal Memo
		/// </summary>
		public static string InternalMemo => I18NResource.GetString(ResourceDirectory, "InternalMemo");

		/// <summary>
		///Valid Units
		/// </summary>
		public static string ValidUnits => I18NResource.GetString(ResourceDirectory, "ValidUnits");

		/// <summary>
		///Item Id
		/// </summary>
		public static string ItemId => I18NResource.GetString(ResourceDirectory, "ItemId");

		/// <summary>
		///Cost Price
		/// </summary>
		public static string CostPrice => I18NResource.GetString(ResourceDirectory, "CostPrice");

		/// <summary>
		///Transaction Timestamp
		/// </summary>
		public static string TransactionTimestamp => I18NResource.GetString(ResourceDirectory, "TransactionTimestamp");

		/// <summary>
		///Item Type Id
		/// </summary>
		public static string ItemTypeId => I18NResource.GetString(ResourceDirectory, "ItemTypeId");

		/// <summary>
		///Unit Name
		/// </summary>
		public static string UnitName => I18NResource.GetString(ResourceDirectory, "UnitName");

		/// <summary>
		///Cost Price Includes Tax
		/// </summary>
		public static string CostPriceIncludesTax => I18NResource.GetString(ResourceDirectory, "CostPriceIncludesTax");

		/// <summary>
		///Bank Transaction Code
		/// </summary>
		public static string BankTransactionCode => I18NResource.GetString(ResourceDirectory, "BankTransactionCode");

		/// <summary>
		///Change
		/// </summary>
		public static string Change => I18NResource.GetString(ResourceDirectory, "Change");

		/// <summary>
		///Office Id
		/// </summary>
		public static string OfficeId => I18NResource.GetString(ResourceDirectory, "OfficeId");

		/// <summary>
		///Discount Rate
		/// </summary>
		public static string DiscountRate => I18NResource.GetString(ResourceDirectory, "DiscountRate");

		/// <summary>
		///Shipping Charge
		/// </summary>
		public static string ShippingCharge => I18NResource.GetString(ResourceDirectory, "ShippingCharge");

		/// <summary>
		///Check Bank Name
		/// </summary>
		public static string CheckBankName => I18NResource.GetString(ResourceDirectory, "CheckBankName");

		/// <summary>
		///Is Taxable Item
		/// </summary>
		public static string IsTaxableItem => I18NResource.GetString(ResourceDirectory, "IsTaxableItem");

		/// <summary>
		///Purchase Return Id
		/// </summary>
		public static string PurchaseReturnId => I18NResource.GetString(ResourceDirectory, "PurchaseReturnId");

		/// <summary>
		///Shipper Id
		/// </summary>
		public static string ShipperId => I18NResource.GetString(ResourceDirectory, "ShipperId");

		/// <summary>
		///Item
		/// </summary>
		public static string Item => I18NResource.GetString(ResourceDirectory, "Item");

		/// <summary>
		///Item Cost Price Id
		/// </summary>
		public static string ItemCostPriceId => I18NResource.GetString(ResourceDirectory, "ItemCostPriceId");

		/// <summary>
		///Terms
		/// </summary>
		public static string Terms => I18NResource.GetString(ResourceDirectory, "Terms");

		/// <summary>
		///Purchase Id
		/// </summary>
		public static string PurchaseId => I18NResource.GetString(ResourceDirectory, "PurchaseId");

		/// <summary>
		///Supplier Id
		/// </summary>
		public static string SupplierId => I18NResource.GetString(ResourceDirectory, "SupplierId");

		/// <summary>
		///Item Group Name
		/// </summary>
		public static string ItemGroupName => I18NResource.GetString(ResourceDirectory, "ItemGroupName");

		/// <summary>
		///Quotation Id
		/// </summary>
		public static string QuotationId => I18NResource.GetString(ResourceDirectory, "QuotationId");

		/// <summary>
		///Unit
		/// </summary>
		public static string Unit => I18NResource.GetString(ResourceDirectory, "Unit");

		/// <summary>
		///Er Credit
		/// </summary>
		public static string ErCredit => I18NResource.GetString(ResourceDirectory, "ErCredit");

		/// <summary>
		///Audit Ts
		/// </summary>
		public static string AuditTs => I18NResource.GetString(ResourceDirectory, "AuditTs");

		/// <summary>
		///Amount
		/// </summary>
		public static string Amount => I18NResource.GetString(ResourceDirectory, "Amount");

		/// <summary>
		///Price Type Id
		/// </summary>
		public static string PriceTypeId => I18NResource.GetString(ResourceDirectory, "PriceTypeId");

		/// <summary>
		///Brand Id
		/// </summary>
		public static string BrandId => I18NResource.GetString(ResourceDirectory, "BrandId");

		/// <summary>
		///Value Date
		/// </summary>
		public static string ValueDate => I18NResource.GetString(ResourceDirectory, "ValueDate");

		/// <summary>
		///Item Name
		/// </summary>
		public static string ItemName => I18NResource.GetString(ResourceDirectory, "ItemName");

		/// <summary>
		///Price Type Name
		/// </summary>
		public static string PriceTypeName => I18NResource.GetString(ResourceDirectory, "PriceTypeName");

		/// <summary>
		///Photo
		/// </summary>
		public static string Photo => I18NResource.GetString(ResourceDirectory, "Photo");

		/// <summary>
		///Hot Item
		/// </summary>
		public static string HotItem => I18NResource.GetString(ResourceDirectory, "HotItem");

		/// <summary>
		///Bank Instrument Code
		/// </summary>
		public static string BankInstrumentCode => I18NResource.GetString(ResourceDirectory, "BankInstrumentCode");

		/// <summary>
		///Item Type Name
		/// </summary>
		public static string ItemTypeName => I18NResource.GetString(ResourceDirectory, "ItemTypeName");

		/// <summary>
		///Transaction Master Id
		/// </summary>
		public static string TransactionMasterId => I18NResource.GetString(ResourceDirectory, "TransactionMasterId");

		/// <summary>
		///Reference Number
		/// </summary>
		public static string ReferenceNumber => I18NResource.GetString(ResourceDirectory, "ReferenceNumber");

		/// <summary>
		///Item Code
		/// </summary>
		public static string ItemCode => I18NResource.GetString(ResourceDirectory, "ItemCode");

		/// <summary>
		///Check Date
		/// </summary>
		public static string CheckDate => I18NResource.GetString(ResourceDirectory, "CheckDate");

		/// <summary>
		///Check Amount
		/// </summary>
		public static string CheckAmount => I18NResource.GetString(ResourceDirectory, "CheckAmount");

		/// <summary>
		///Expected Delivery Date
		/// </summary>
		public static string ExpectedDeliveryDate => I18NResource.GetString(ResourceDirectory, "ExpectedDeliveryDate");

		/// <summary>
		///Payment Id
		/// </summary>
		public static string PaymentId => I18NResource.GetString(ResourceDirectory, "PaymentId");

		/// <summary>
		///Er Debit
		/// </summary>
		public static string ErDebit => I18NResource.GetString(ResourceDirectory, "ErDebit");

		/// <summary>
		///User Id
		/// </summary>
		public static string UserId => I18NResource.GetString(ResourceDirectory, "UserId");

		/// <summary>
		///Order Id
		/// </summary>
		public static string OrderId => I18NResource.GetString(ResourceDirectory, "OrderId");

		/// <summary>
		///Order Detail Id
		/// </summary>
		public static string OrderDetailId => I18NResource.GetString(ResourceDirectory, "OrderDetailId");

		/// <summary>
		///Tax
		/// </summary>
		public static string Tax => I18NResource.GetString(ResourceDirectory, "Tax");

		/// <summary>
		///Barcode
		/// </summary>
		public static string Barcode => I18NResource.GetString(ResourceDirectory, "Barcode");

		/// <summary>
		///Unit Id
		/// </summary>
		public static string UnitId => I18NResource.GetString(ResourceDirectory, "UnitId");

		/// <summary>
		///Cash Repository Id
		/// </summary>
		public static string CashRepositoryId => I18NResource.GetString(ResourceDirectory, "CashRepositoryId");

		/// <summary>
		///Bank Id
		/// </summary>
		public static string BankId => I18NResource.GetString(ResourceDirectory, "BankId");

		/// <summary>
		///Currency Code
		/// </summary>
		public static string CurrencyCode => I18NResource.GetString(ResourceDirectory, "CurrencyCode");

		/// <summary>
		///Audit User Id
		/// </summary>
		public static string AuditUserId => I18NResource.GetString(ResourceDirectory, "AuditUserId");

		/// <summary>
		///Deleted
		/// </summary>
		public static string Deleted => I18NResource.GetString(ResourceDirectory, "Deleted");

		/// <summary>
		///Preferred Supplier Id
		/// </summary>
		public static string PreferredSupplierId => I18NResource.GetString(ResourceDirectory, "PreferredSupplierId");

		/// <summary>
		///Quantity
		/// </summary>
		public static string Quantity => I18NResource.GetString(ResourceDirectory, "Quantity");

		/// <summary>
		///Check Number
		/// </summary>
		public static string CheckNumber => I18NResource.GetString(ResourceDirectory, "CheckNumber");

		/// <summary>
		///Item Group Id
		/// </summary>
		public static string ItemGroupId => I18NResource.GetString(ResourceDirectory, "ItemGroupId");

		/// <summary>
		///Brand Name
		/// </summary>
		public static string BrandName => I18NResource.GetString(ResourceDirectory, "BrandName");

		/// <summary>
		///Quotation Detail Id
		/// </summary>
		public static string QuotationDetailId => I18NResource.GetString(ResourceDirectory, "QuotationDetailId");

		/// <summary>
		///Checkout Id
		/// </summary>
		public static string CheckoutId => I18NResource.GetString(ResourceDirectory, "CheckoutId");

		/// <summary>
		///Tasks
		/// </summary>
		public static string Tasks => I18NResource.GetString(ResourceDirectory, "Tasks");

		/// <summary>
		///Purchase Entry
		/// </summary>
		public static string PurchaseEntry => I18NResource.GetString(ResourceDirectory, "PurchaseEntry");

		/// <summary>
		///Supplier Payment
		/// </summary>
		public static string SupplierPayment => I18NResource.GetString(ResourceDirectory, "SupplierPayment");

		/// <summary>
		///Purchase Returns
		/// </summary>
		public static string PurchaseReturns => I18NResource.GetString(ResourceDirectory, "PurchaseReturns");

		/// <summary>
		///Purchase Quotations
		/// </summary>
		public static string PurchaseQuotations => I18NResource.GetString(ResourceDirectory, "PurchaseQuotations");

		/// <summary>
		///Purchase Orders
		/// </summary>
		public static string PurchaseOrders => I18NResource.GetString(ResourceDirectory, "PurchaseOrders");

		/// <summary>
		///Purchase Verification
		/// </summary>
		public static string PurchaseVerification => I18NResource.GetString(ResourceDirectory, "PurchaseVerification");

		/// <summary>
		///Supplier Payment Verification
		/// </summary>
		public static string SupplierPaymentVerification => I18NResource.GetString(ResourceDirectory, "SupplierPaymentVerification");

		/// <summary>
		///Purchase Return Verification
		/// </summary>
		public static string PurchaseReturnVerification => I18NResource.GetString(ResourceDirectory, "PurchaseReturnVerification");

		/// <summary>
		///Setup
		/// </summary>
		public static string Setup => I18NResource.GetString(ResourceDirectory, "Setup");

		/// <summary>
		///Suppliers
		/// </summary>
		public static string Suppliers => I18NResource.GetString(ResourceDirectory, "Suppliers");

		/// <summary>
		///Price Types
		/// </summary>
		public static string PriceTypes => I18NResource.GetString(ResourceDirectory, "PriceTypes");

		/// <summary>
		///Cost Prices
		/// </summary>
		public static string CostPrices => I18NResource.GetString(ResourceDirectory, "CostPrices");

		/// <summary>
		///Reports
		/// </summary>
		public static string Reports => I18NResource.GetString(ResourceDirectory, "Reports");

		/// <summary>
		///Account Payables
		/// </summary>
		public static string AccountPayables => I18NResource.GetString(ResourceDirectory, "AccountPayables");

		/// <summary>
		///Top Suppliers
		/// </summary>
		public static string TopSuppliers => I18NResource.GetString(ResourceDirectory, "TopSuppliers");

		/// <summary>
		///Low Inventory Products
		/// </summary>
		public static string LowInventoryProducts => I18NResource.GetString(ResourceDirectory, "LowInventoryProducts");

		/// <summary>
		///Out of Stock Products
		/// </summary>
		public static string OutOfStockProducts => I18NResource.GetString(ResourceDirectory, "OutOfStockProducts");

		/// <summary>
		///Supplier Contacts
		/// </summary>
		public static string SupplierContacts => I18NResource.GetString(ResourceDirectory, "SupplierContacts");

		/// <summary>
		///Access is denied.
		/// </summary>
		public static string AccessIsDenied => I18NResource.GetString(ResourceDirectory, "AccessIsDenied");

		/// <summary>
		///Actions
		/// </summary>
		public static string Actions => I18NResource.GetString(ResourceDirectory, "Actions");

		/// <summary>
		///Add New
		/// </summary>
		public static string AddNew => I18NResource.GetString(ResourceDirectory, "AddNew");

		/// <summary>
		///Add a New Payment Entry
		/// </summary>
		public static string AddNewPaymentEntry => I18NResource.GetString(ResourceDirectory, "AddNewPaymentEntry");

		/// <summary>
		///Add New Purchase Entry
		/// </summary>
		public static string AddNewPurchaseEntry => I18NResource.GetString(ResourceDirectory, "AddNewPurchaseEntry");

		/// <summary>
		///Add New Purchase Order
		/// </summary>
		public static string AddNewPurchaseOrder => I18NResource.GetString(ResourceDirectory, "AddNewPurchaseOrder");

		/// <summary>
		///Add New Purchase Quotation
		/// </summary>
		public static string AddNewPurchaseQuotation => I18NResource.GetString(ResourceDirectory, "AddNewPurchaseQuotation");

		/// <summary>
		///Are you sure?
		/// </summary>
		public static string AreYouSure => I18NResource.GetString(ResourceDirectory, "AreYouSure");

		/// <summary>
		///Bad Request
		/// </summary>
		public static string BadRequest => I18NResource.GetString(ResourceDirectory, "BadRequest");

		/// <summary>
		///Bank
		/// </summary>
		public static string Bank => I18NResource.GetString(ResourceDirectory, "Bank");

		/// <summary>
		///Base Currency
		/// </summary>
		public static string BaseCurrency => I18NResource.GetString(ResourceDirectory, "BaseCurrency");

		/// <summary>
		///Book Date
		/// </summary>
		public static string BookDate => I18NResource.GetString(ResourceDirectory, "BookDate");

		/// <summary>
		///Cannot add item because the price is zero.
		/// </summary>
		public static string CannotAddItemBecausePriceZero => I18NResource.GetString(ResourceDirectory, "CannotAddItemBecausePriceZero");

		/// <summary>
		///Cash
		/// </summary>
		public static string Cash => I18NResource.GetString(ResourceDirectory, "Cash");

		/// <summary>
		///Cash Account Id
		/// </summary>
		public static string CashAccountId => I18NResource.GetString(ResourceDirectory, "CashAccountId");

		/// <summary>
		///Cash Repository
		/// </summary>
		public static string CashRepository => I18NResource.GetString(ResourceDirectory, "CashRepository");

		/// <summary>
		///A cash transaction cannot contain bank transaction details.
		/// </summary>
		public static string CashTransactionCannotContainBankTransactionDetails => I18NResource.GetString(ResourceDirectory, "CashTransactionCannotContainBankTransactionDetails");

		/// <summary>
		///Checklist
		/// </summary>
		public static string Checklist => I18NResource.GetString(ResourceDirectory, "Checklist");

		/// <summary>
		///CheckList Window
		/// </summary>
		public static string CheckListWindow => I18NResource.GetString(ResourceDirectory, "CheckListWindow");

		/// <summary>
		///Checkout
		/// </summary>
		public static string Checkout => I18NResource.GetString(ResourceDirectory, "Checkout");

		/// <summary>
		///Check
		/// </summary>
		public static string Cheque => I18NResource.GetString(ResourceDirectory, "Cheque");

		/// <summary>
		///Clear
		/// </summary>
		public static string Clear => I18NResource.GetString(ResourceDirectory, "Clear");

		/// <summary>
		///Cls
		/// </summary>
		public static string Cls => I18NResource.GetString(ResourceDirectory, "Cls");

		/// <summary>
		///Converted to Base Currency
		/// </summary>
		public static string ConvertedToBaseCurrency => I18NResource.GetString(ResourceDirectory, "ConvertedToBaseCurrency");

		/// <summary>
		///Converted to Home Currency
		/// </summary>
		public static string ConvertedToHomeCurrency => I18NResource.GetString(ResourceDirectory, "ConvertedToHomeCurrency");

		/// <summary>
		///Cost Center
		/// </summary>
		public static string CostCenter => I18NResource.GetString(ResourceDirectory, "CostCenter");

		/// <summary>
		///Credit Exchange Rate
		/// </summary>
		public static string CreditExchangeRate => I18NResource.GetString(ResourceDirectory, "CreditExchangeRate");

		/// <summary>
		///Current Area
		/// </summary>
		public static string CurrentArea => I18NResource.GetString(ResourceDirectory, "CurrentArea");

		/// <summary>
		///Current Branch Office
		/// </summary>
		public static string CurrentBranchOffice => I18NResource.GetString(ResourceDirectory, "CurrentBranchOffice");

		/// <summary>
		///Debit Exchange Rate
		/// </summary>
		public static string DebitExchangeRate => I18NResource.GetString(ResourceDirectory, "DebitExchangeRate");

		/// <summary>
		///Delete
		/// </summary>
		public static string Delete => I18NResource.GetString(ResourceDirectory, "Delete");

		/// <summary>
		///Edit Price
		/// </summary>
		public static string EditPrice => I18NResource.GetString(ResourceDirectory, "EditPrice");

		/// <summary>
		///Enter Discount
		/// </summary>
		public static string EnterDiscount => I18NResource.GetString(ResourceDirectory, "EnterDiscount");

		/// <summary>
		///Enter Quantity
		/// </summary>
		public static string EnterQuantity => I18NResource.GetString(ResourceDirectory, "EnterQuantity");

		/// <summary>
		///Expected Date
		/// </summary>
		public static string ExpectedDate => I18NResource.GetString(ResourceDirectory, "ExpectedDate");

		/// <summary>
		///Expected From
		/// </summary>
		public static string ExpectedFrom => I18NResource.GetString(ResourceDirectory, "ExpectedFrom");

		/// <summary>
		///Expected To
		/// </summary>
		public static string ExpectedTo => I18NResource.GetString(ResourceDirectory, "ExpectedTo");

		/// <summary>
		///Export
		/// </summary>
		public static string Export => I18NResource.GetString(ResourceDirectory, "Export");

		/// <summary>
		///Export This Document
		/// </summary>
		public static string ExportThisDocument => I18NResource.GetString(ResourceDirectory, "ExportThisDocument");

		/// <summary>
		///Export to Doc
		/// </summary>
		public static string ExportToDoc => I18NResource.GetString(ResourceDirectory, "ExportToDoc");

		/// <summary>
		///Export to Excel
		/// </summary>
		public static string ExportToExcel => I18NResource.GetString(ResourceDirectory, "ExportToExcel");

		/// <summary>
		///Export to PDF
		/// </summary>
		public static string ExportToPDF => I18NResource.GetString(ResourceDirectory, "ExportToPDF");

		/// <summary>
		///Final Due Amount (In Base Currency)
		/// </summary>
		public static string FinalDueAmountInBaseCurrency => I18NResource.GetString(ResourceDirectory, "FinalDueAmountInBaseCurrency");

		/// <summary>
		///From
		/// </summary>
		public static string From => I18NResource.GetString(ResourceDirectory, "From");

		/// <summary>
		///Go
		/// </summary>
		public static string Go => I18NResource.GetString(ResourceDirectory, "Go");

		/// <summary>
		///Id
		/// </summary>
		public static string Id => I18NResource.GetString(ResourceDirectory, "Id");

		/// <summary>
		///Instrument Code
		/// </summary>
		public static string InstrumentCode => I18NResource.GetString(ResourceDirectory, "InstrumentCode");

		/// <summary>
		///Invalid Payment Mode
		/// </summary>
		public static string InvalidPaymentMode => I18NResource.GetString(ResourceDirectory, "InvalidPaymentMode");

		/// <summary>
		///Loading items
		/// </summary>
		public static string LoadingItems => I18NResource.GetString(ResourceDirectory, "LoadingItems");

		/// <summary>
		///Memo
		/// </summary>
		public static string Memo => I18NResource.GetString(ResourceDirectory, "Memo");

		/// <summary>
		///Office
		/// </summary>
		public static string Office => I18NResource.GetString(ResourceDirectory, "Office");

		/// <summary>
		///Office Name
		/// </summary>
		public static string OfficeName => I18NResource.GetString(ResourceDirectory, "OfficeName");

		/// <summary>
		///Paid Amount (In Above Currency)
		/// </summary>
		public static string PaidAmountInAboveCurrency => I18NResource.GetString(ResourceDirectory, "PaidAmountInAboveCurrency");

		/// <summary>
		///Paid Currency
		/// </summary>
		public static string PaidCurrency => I18NResource.GetString(ResourceDirectory, "PaidCurrency");

		/// <summary>
		///Payment Checklist #
		/// </summary>
		public static string PaymentChecklist => I18NResource.GetString(ResourceDirectory, "PaymentChecklist");

		/// <summary>
		///Payments
		/// </summary>
		public static string Payments => I18NResource.GetString(ResourceDirectory, "Payments");

		/// <summary>
		///Payment to Supplier
		/// </summary>
		public static string PaymentToSupplier => I18NResource.GetString(ResourceDirectory, "PaymentToSupplier");

		/// <summary>
		///Payment Type
		/// </summary>
		public static string PaymentType => I18NResource.GetString(ResourceDirectory, "PaymentType");

		/// <summary>
		///Payment Verification
		/// </summary>
		public static string PaymentVerification => I18NResource.GetString(ResourceDirectory, "PaymentVerification");

		/// <summary>
		///Please select an item.
		/// </summary>
		public static string PleaseSelectItem => I18NResource.GetString(ResourceDirectory, "PleaseSelectItem");

		/// <summary>
		///Please select an item from the grid.
		/// </summary>
		public static string PleaseSelectItemFromGrid => I18NResource.GetString(ResourceDirectory, "PleaseSelectItemFromGrid");

		/// <summary>
		///Please select a supplier.
		/// </summary>
		public static string PleaseSelectSupplier => I18NResource.GetString(ResourceDirectory, "PleaseSelectSupplier");

		/// <summary>
		///Posted By
		/// </summary>
		public static string PostedBy => I18NResource.GetString(ResourceDirectory, "PostedBy");

		/// <summary>
		///Posted On
		/// </summary>
		public static string PostedOn => I18NResource.GetString(ResourceDirectory, "PostedOn");

		/// <summary>
		///Print
		/// </summary>
		public static string Print => I18NResource.GetString(ResourceDirectory, "Print");

		/// <summary>
		///Purchase Checklist
		/// </summary>
		public static string PurchaseChecklist => I18NResource.GetString(ResourceDirectory, "PurchaseChecklist");

		/// <summary>
		///Purchase Entries
		/// </summary>
		public static string PurchaseEntries => I18NResource.GetString(ResourceDirectory, "PurchaseEntries");

		/// <summary>
		///Purchase Entry Verification
		/// </summary>
		public static string PurchaseEntryVerification => I18NResource.GetString(ResourceDirectory, "PurchaseEntryVerification");

		/// <summary>
		///Purchase Order
		/// </summary>
		public static string PurchaseOrder => I18NResource.GetString(ResourceDirectory, "PurchaseOrder");

		/// <summary>
		///Purchase Order Checklist
		/// </summary>
		public static string PurchaseOrderChecklist => I18NResource.GetString(ResourceDirectory, "PurchaseOrderChecklist");

		/// <summary>
		///Purchase Quotation Checklist
		/// </summary>
		public static string PurchaseQuotationChecklist => I18NResource.GetString(ResourceDirectory, "PurchaseQuotationChecklist");

		/// <summary>
		///Purchase Return
		/// </summary>
		public static string PurchaseReturn => I18NResource.GetString(ResourceDirectory, "PurchaseReturn");

		/// <summary>
		///Purchase Return Checklist
		/// </summary>
		public static string PurchaseReturnChecklist => I18NResource.GetString(ResourceDirectory, "PurchaseReturnChecklist");

		/// <summary>
		///Ref#
		/// </summary>
		public static string ReferenceNumberAbbreviated => I18NResource.GetString(ResourceDirectory, "ReferenceNumberAbbreviated");

		/// <summary>
		///Return
		/// </summary>
		public static string Return => I18NResource.GetString(ResourceDirectory, "Return");

		/// <summary>
		///Save
		/// </summary>
		public static string Save => I18NResource.GetString(ResourceDirectory, "Save");

		/// <summary>
		///Search
		/// </summary>
		public static string Search => I18NResource.GetString(ResourceDirectory, "Search");

		/// <summary>
		///Select Supplier
		/// </summary>
		public static string SelectSupplier => I18NResource.GetString(ResourceDirectory, "SelectSupplier");

		/// <summary>
		///Shipper
		/// </summary>
		public static string Shipper => I18NResource.GetString(ResourceDirectory, "Shipper");

		/// <summary>
		///Show
		/// </summary>
		public static string Show => I18NResource.GetString(ResourceDirectory, "Show");

		/// <summary>
		///Statement Reference
		/// </summary>
		public static string StatementReference => I18NResource.GetString(ResourceDirectory, "StatementReference");

		/// <summary>
		///Store
		/// </summary>
		public static string Store => I18NResource.GetString(ResourceDirectory, "Store");

		/// <summary>
		///Terms & Conditions
		/// </summary>
		public static string TermsConditions => I18NResource.GetString(ResourceDirectory, "TermsConditions");

		/// <summary>
		///This supplier does not have a default currency!
		/// </summary>
		public static string ThisSupplierDoesNotHaveDefaultCurrency => I18NResource.GetString(ResourceDirectory, "ThisSupplierDoesNotHaveDefaultCurrency");

		/// <summary>
		///To
		/// </summary>
		public static string To => I18NResource.GetString(ResourceDirectory, "To");

		/// <summary>
		///Total Due Amount (In Base Currency)
		/// </summary>
		public static string TotalDueAmountInBaseCurrency => I18NResource.GetString(ResourceDirectory, "TotalDueAmountInBaseCurrency");

		/// <summary>
		///View Order
		/// </summary>
		public static string ViewOrder => I18NResource.GetString(ResourceDirectory, "ViewOrder");

		/// <summary>
		///View Payment
		/// </summary>
		public static string ViewPayment => I18NResource.GetString(ResourceDirectory, "ViewPayment");

		/// <summary>
		///View Payments
		/// </summary>
		public static string ViewPayments => I18NResource.GetString(ResourceDirectory, "ViewPayments");

		/// <summary>
		///View Purchase Invoice
		/// </summary>
		public static string ViewPurchaseInvoice => I18NResource.GetString(ResourceDirectory, "ViewPurchaseInvoice");

		/// <summary>
		///View Purchase Orders
		/// </summary>
		public static string ViewPurchaseOrders => I18NResource.GetString(ResourceDirectory, "ViewPurchaseOrders");

		/// <summary>
		///View Purchase Quotation
		/// </summary>
		public static string ViewPurchaseQuotation => I18NResource.GetString(ResourceDirectory, "ViewPurchaseQuotation");

		/// <summary>
		///View Purchase Return
		/// </summary>
		public static string ViewPurchaseReturn => I18NResource.GetString(ResourceDirectory, "ViewPurchaseReturn");

		/// <summary>
		///View Purchase Returns
		/// </summary>
		public static string ViewPurchaseReturns => I18NResource.GetString(ResourceDirectory, "ViewPurchaseReturns");

		/// <summary>
		///View Purchases
		/// </summary>
		public static string ViewPurchases => I18NResource.GetString(ResourceDirectory, "ViewPurchases");

		/// <summary>
		///View Quotation
		/// </summary>
		public static string ViewQuotation => I18NResource.GetString(ResourceDirectory, "ViewQuotation");

		/// <summary>
		///Which Bank?
		/// </summary>
		public static string WhichBank => I18NResource.GetString(ResourceDirectory, "WhichBank");

		/// <summary>
		///You
		/// </summary>
		public static string You => I18NResource.GetString(ResourceDirectory, "You");

	}
}
