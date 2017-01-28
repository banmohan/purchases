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
		///Amount
		/// </summary>
		public static string Amount => I18NResource.GetString(ResourceDirectory, "Amount");

		/// <summary>
		///Are you sure?
		/// </summary>
		public static string AreYouSure => I18NResource.GetString(ResourceDirectory, "AreYouSure");

		/// <summary>
		///Book Date
		/// </summary>
		public static string BookDate => I18NResource.GetString(ResourceDirectory, "BookDate");

		/// <summary>
		///Cannot add item because the price is zero.
		/// </summary>
		public static string CannotAddItemBecausePriceZero => I18NResource.GetString(ResourceDirectory, "CannotAddItemBecausePriceZero");

		/// <summary>
		///CheckList Window
		/// </summary>
		public static string CheckListWindow => I18NResource.GetString(ResourceDirectory, "CheckListWindow");

		/// <summary>
		///Checklist
		/// </summary>
		public static string Checklist => I18NResource.GetString(ResourceDirectory, "Checklist");

		/// <summary>
		///Checkout
		/// </summary>
		public static string Checkout => I18NResource.GetString(ResourceDirectory, "Checkout");

		/// <summary>
		///Clear
		/// </summary>
		public static string Clear => I18NResource.GetString(ResourceDirectory, "Clear");

		/// <summary>
		///Cls
		/// </summary>
		public static string Cls => I18NResource.GetString(ResourceDirectory, "Cls");

		/// <summary>
		///Cost Center
		/// </summary>
		public static string CostCenter => I18NResource.GetString(ResourceDirectory, "CostCenter");

		/// <summary>
		///Cost Prices
		/// </summary>
		public static string CostPrices => I18NResource.GetString(ResourceDirectory, "CostPrices");

		/// <summary>
		///Current Area
		/// </summary>
		public static string CurrentArea => I18NResource.GetString(ResourceDirectory, "CurrentArea");

		/// <summary>
		///Current Branch Office
		/// </summary>
		public static string CurrentBranchOffice => I18NResource.GetString(ResourceDirectory, "CurrentBranchOffice");

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
		///Expected Delivery Date
		/// </summary>
		public static string ExpectedDeliveryDate => I18NResource.GetString(ResourceDirectory, "ExpectedDeliveryDate");

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
		///From
		/// </summary>
		public static string From => I18NResource.GetString(ResourceDirectory, "From");

		/// <summary>
		///Id
		/// </summary>
		public static string Id => I18NResource.GetString(ResourceDirectory, "Id");

		/// <summary>
		///Internal Memo
		/// </summary>
		public static string InternalMemo => I18NResource.GetString(ResourceDirectory, "InternalMemo");

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
		///Office Id
		/// </summary>
		public static string OfficeId => I18NResource.GetString(ResourceDirectory, "OfficeId");

		/// <summary>
		///Office Name
		/// </summary>
		public static string OfficeName => I18NResource.GetString(ResourceDirectory, "OfficeName");

		/// <summary>
		///Please select an item.
		/// </summary>
		public static string PleaseSelectItem => I18NResource.GetString(ResourceDirectory, "PleaseSelectItem");

		/// <summary>
		///Please select an item from the grid.
		/// </summary>
		public static string PleaseSelectItemFromGrid => I18NResource.GetString(ResourceDirectory, "PleaseSelectItemFromGrid");

		/// <summary>
		///Posted By
		/// </summary>
		public static string PostedBy => I18NResource.GetString(ResourceDirectory, "PostedBy");

		/// <summary>
		///Posted On
		/// </summary>
		public static string PostedOn => I18NResource.GetString(ResourceDirectory, "PostedOn");

		/// <summary>
		///Price Types
		/// </summary>
		public static string PriceTypes => I18NResource.GetString(ResourceDirectory, "PriceTypes");

		/// <summary>
		///Print
		/// </summary>
		public static string Print => I18NResource.GetString(ResourceDirectory, "Print");

		/// <summary>
		///Purchase
		/// </summary>
		public static string Purchase => I18NResource.GetString(ResourceDirectory, "Purchase");

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
		///Purchase Orders
		/// </summary>
		public static string PurchaseOrders => I18NResource.GetString(ResourceDirectory, "PurchaseOrders");

		/// <summary>
		///Purchase Quotation Checklist
		/// </summary>
		public static string PurchaseQuotationChecklist => I18NResource.GetString(ResourceDirectory, "PurchaseQuotationChecklist");

		/// <summary>
		///Purchase Quotations
		/// </summary>
		public static string PurchaseQuotations => I18NResource.GetString(ResourceDirectory, "PurchaseQuotations");

		/// <summary>
		///Purchase Return
		/// </summary>
		public static string PurchaseReturn => I18NResource.GetString(ResourceDirectory, "PurchaseReturn");

		/// <summary>
		///Purchase Return Checklist
		/// </summary>
		public static string PurchaseReturnChecklist => I18NResource.GetString(ResourceDirectory, "PurchaseReturnChecklist");

		/// <summary>
		///Purchase Return Verification
		/// </summary>
		public static string PurchaseReturnVerification => I18NResource.GetString(ResourceDirectory, "PurchaseReturnVerification");

		/// <summary>
		///Purchase Returns
		/// </summary>
		public static string PurchaseReturns => I18NResource.GetString(ResourceDirectory, "PurchaseReturns");

		/// <summary>
		///Reference Number
		/// </summary>
		public static string ReferenceNumber => I18NResource.GetString(ResourceDirectory, "ReferenceNumber");

		/// <summary>
		///Ref#
		/// </summary>
		public static string ReferenceNumberAbbreviated => I18NResource.GetString(ResourceDirectory, "ReferenceNumberAbbreviated");

		/// <summary>
		///Return
		/// </summary>
		public static string Return => I18NResource.GetString(ResourceDirectory, "Return");

		/// <summary>
		///Search
		/// </summary>
		public static string Search => I18NResource.GetString(ResourceDirectory, "Search");

		/// <summary>
		///Shipper
		/// </summary>
		public static string Shipper => I18NResource.GetString(ResourceDirectory, "Shipper");

		/// <summary>
		///Show
		/// </summary>
		public static string Show => I18NResource.GetString(ResourceDirectory, "Show");

		/// <summary>
		///Store
		/// </summary>
		public static string Store => I18NResource.GetString(ResourceDirectory, "Store");

		/// <summary>
		///Supplier
		/// </summary>
		public static string Supplier => I18NResource.GetString(ResourceDirectory, "Supplier");

		/// <summary>
		///Suppliers
		/// </summary>
		public static string Suppliers => I18NResource.GetString(ResourceDirectory, "Suppliers");

		/// <summary>
		///Terms
		/// </summary>
		public static string Terms => I18NResource.GetString(ResourceDirectory, "Terms");

		/// <summary>
		///Terms & Conditions
		/// </summary>
		public static string TermsConditions => I18NResource.GetString(ResourceDirectory, "TermsConditions");

		/// <summary>
		///To
		/// </summary>
		public static string To => I18NResource.GetString(ResourceDirectory, "To");

		/// <summary>
		///User Id
		/// </summary>
		public static string UserId => I18NResource.GetString(ResourceDirectory, "UserId");

		/// <summary>
		///Value Date
		/// </summary>
		public static string ValueDate => I18NResource.GetString(ResourceDirectory, "ValueDate");

		/// <summary>
		///View Order
		/// </summary>
		public static string ViewOrder => I18NResource.GetString(ResourceDirectory, "ViewOrder");

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
		///You
		/// </summary>
		public static string You => I18NResource.GetString(ResourceDirectory, "You");

		/// <summary>
		///Bad Request
		/// </summary>
		public static string BadRequest => I18NResource.GetString(ResourceDirectory, "BadRequest");

		/// <summary>
		///Payment to Supplier
		/// </summary>
		public static string PaymentToSupplier => I18NResource.GetString(ResourceDirectory, "PaymentToSupplier");

		/// <summary>
		///Payment Verification
		/// </summary>
		public static string PaymentVerification => I18NResource.GetString(ResourceDirectory, "PaymentVerification");

		/// <summary>
		///View Payment
		/// </summary>
		public static string ViewPayment => I18NResource.GetString(ResourceDirectory, "ViewPayment");

		/// <summary>
		///Payment Checklist #
		/// </summary>
		public static string PaymentChecklist => I18NResource.GetString(ResourceDirectory, "PaymentChecklist");

		/// <summary>
		///View Payments
		/// </summary>
		public static string ViewPayments => I18NResource.GetString(ResourceDirectory, "ViewPayments");

		/// <summary>
		///Add a New Payment Entry
		/// </summary>
		public static string AddNewPaymentEntry => I18NResource.GetString(ResourceDirectory, "AddNewPaymentEntry");

		/// <summary>
		///Payments
		/// </summary>
		public static string Payments => I18NResource.GetString(ResourceDirectory, "Payments");

		/// <summary>
		///Select Supplier
		/// </summary>
		public static string SelectSupplier => I18NResource.GetString(ResourceDirectory, "SelectSupplier");

		/// <summary>
		///Total Due Amount (In Base Currency)
		/// </summary>
		public static string TotalDueAmountInBaseCurrency => I18NResource.GetString(ResourceDirectory, "TotalDueAmountInBaseCurrency");

		/// <summary>
		///Base Currency
		/// </summary>
		public static string BaseCurrency => I18NResource.GetString(ResourceDirectory, "BaseCurrency");

		/// <summary>
		///Paid Currency
		/// </summary>
		public static string PaidCurrency => I18NResource.GetString(ResourceDirectory, "PaidCurrency");

		/// <summary>
		///Paid Amount (In Above Currency)
		/// </summary>
		public static string PaidAmountInAboveCurrency => I18NResource.GetString(ResourceDirectory, "PaidAmountInAboveCurrency");

		/// <summary>
		///Debit Exchange Rate
		/// </summary>
		public static string DebitExchangeRate => I18NResource.GetString(ResourceDirectory, "DebitExchangeRate");

		/// <summary>
		///Converted to Home Currency
		/// </summary>
		public static string ConvertedToHomeCurrency => I18NResource.GetString(ResourceDirectory, "ConvertedToHomeCurrency");

		/// <summary>
		///Credit Exchange Rate
		/// </summary>
		public static string CreditExchangeRate => I18NResource.GetString(ResourceDirectory, "CreditExchangeRate");

		/// <summary>
		///Converted to Base Currency
		/// </summary>
		public static string ConvertedToBaseCurrency => I18NResource.GetString(ResourceDirectory, "ConvertedToBaseCurrency");

		/// <summary>
		///Final Due Amount (In Base Currency)
		/// </summary>
		public static string FinalDueAmountInBaseCurrency => I18NResource.GetString(ResourceDirectory, "FinalDueAmountInBaseCurrency");

		/// <summary>
		///Payment Type
		/// </summary>
		public static string PaymentType => I18NResource.GetString(ResourceDirectory, "PaymentType");

		/// <summary>
		///Cash
		/// </summary>
		public static string Cash => I18NResource.GetString(ResourceDirectory, "Cash");

		/// <summary>
		///Bank
		/// </summary>
		public static string Bank => I18NResource.GetString(ResourceDirectory, "Bank");

		/// <summary>
		///Cash Account Id
		/// </summary>
		public static string CashAccountId => I18NResource.GetString(ResourceDirectory, "CashAccountId");

		/// <summary>
		///Cash Repository
		/// </summary>
		public static string CashRepository => I18NResource.GetString(ResourceDirectory, "CashRepository");

		/// <summary>
		///Which Bank?
		/// </summary>
		public static string WhichBank => I18NResource.GetString(ResourceDirectory, "WhichBank");

		/// <summary>
		///Posted Date
		/// </summary>
		public static string PostedDate => I18NResource.GetString(ResourceDirectory, "PostedDate");

		/// <summary>
		///Instrument Code
		/// </summary>
		public static string InstrumentCode => I18NResource.GetString(ResourceDirectory, "InstrumentCode");

		/// <summary>
		///Bank Transaction Code
		/// </summary>
		public static string BankTransactionCode => I18NResource.GetString(ResourceDirectory, "BankTransactionCode");

		/// <summary>
		///Statement Reference
		/// </summary>
		public static string StatementReference => I18NResource.GetString(ResourceDirectory, "StatementReference");

		/// <summary>
		///Save
		/// </summary>
		public static string Save => I18NResource.GetString(ResourceDirectory, "Save");

		/// <summary>
		///Go
		/// </summary>
		public static string Go => I18NResource.GetString(ResourceDirectory, "Go");

		/// <summary>
		///Invalid Payment Mode
		/// </summary>
		public static string InvalidPaymentMode => I18NResource.GetString(ResourceDirectory, "InvalidPaymentMode");

		/// <summary>
		///A cash transaction cannot contain bank transaction details.
		/// </summary>
		public static string CashTransactionCannotContainBankTransactionDetails => I18NResource.GetString(ResourceDirectory, "CashTransactionCannotContainBankTransactionDetails");

		/// <summary>
		///This supplier does not have a default currency!
		/// </summary>
		public static string ThisSupplierDoesNotHaveDefaultCurrency => I18NResource.GetString(ResourceDirectory, "ThisSupplierDoesNotHaveDefaultCurrency");

		/// <summary>
		///Please select a supplier.
		/// </summary>
		public static string PleaseSelectSupplier => I18NResource.GetString(ResourceDirectory, "PleaseSelectSupplier");

		/// <summary>
		///Check
		/// </summary>
		public static string Cheque => I18NResource.GetString(ResourceDirectory, "Cheque");

	}
}
