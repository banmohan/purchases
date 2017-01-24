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
		///Actions
		/// </summary>
		public static string Actions => I18NResource.GetString(ResourceDirectory, "Actions");

		/// <summary>
		///Add New Purchase Order
		/// </summary>
		public static string AddNewPurchaseOrder => I18NResource.GetString(ResourceDirectory, "AddNewPurchaseOrder");

		/// <summary>
		///Add  New Purchase Quotation
		/// </summary>
		public static string AddNewPurchaseQuotation => I18NResource.GetString(ResourceDirectory, "AddNewPurchaseQuotation");

		/// <summary>
		///Amount
		/// </summary>
		public static string Amount => I18NResource.GetString(ResourceDirectory, "Amount");

		/// <summary>
		///Book Date
		/// </summary>
		public static string BookDate => I18NResource.GetString(ResourceDirectory, "BookDate");

		/// <summary>
		///CheckList Window
		/// </summary>
		public static string CheckListWindow => I18NResource.GetString(ResourceDirectory, "CheckListWindow");

		/// <summary>
		///Checklist
		/// </summary>
		public static string Checklist => I18NResource.GetString(ResourceDirectory, "Checklist");

		/// <summary>
		///Cost Center
		/// </summary>
		public static string CostCenter => I18NResource.GetString(ResourceDirectory, "CostCenter");

		/// <summary>
		///Cost Prices
		/// </summary>
		public static string CostPrices => I18NResource.GetString(ResourceDirectory, "CostPrices");

		/// <summary>
		///CurrentArea
		/// </summary>
		public static string CurrentArea => I18NResource.GetString(ResourceDirectory, "CurrentArea");

		/// <summary>
		///Current Branch Office
		/// </summary>
		public static string CurrentBranchOffice => I18NResource.GetString(ResourceDirectory, "CurrentBranchOffice");

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
		///Export Doc
		/// </summary>
		public static string ExportDoc => I18NResource.GetString(ResourceDirectory, "ExportDoc");

		/// <summary>
		///Export Document
		/// </summary>
		public static string ExportDocument => I18NResource.GetString(ResourceDirectory, "ExportDocument");

		/// <summary>
		///Export Excel
		/// </summary>
		public static string ExportExcel => I18NResource.GetString(ResourceDirectory, "ExportExcel");

		/// <summary>
		///Export PDF
		/// </summary>
		public static string ExportPDF => I18NResource.GetString(ResourceDirectory, "ExportPDF");

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
		public static string Loadingitems => I18NResource.GetString(ResourceDirectory, "Loadingitems");

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
		///Please Select Item From Grid.
		/// </summary>
		public static string PleaseSelectItemGrid => I18NResource.GetString(ResourceDirectory, "PleaseSelectItemGrid");

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
		///Purchase Entries
		/// </summary>
		public static string PurchaseEntries => I18NResource.GetString(ResourceDirectory, "PurchaseEntries");

		/// <summary>
		///Purchase Entry Verification
		/// </summary>
		public static string PurchaseEntryVerification => I18NResource.GetString(ResourceDirectory, "PurchaseEntryVerification");

		/// <summary>
		///Purchase Orders
		/// </summary>
		public static string PurchaseOrders => I18NResource.GetString(ResourceDirectory, "PurchaseOrders");

		/// <summary>
		///Purchase Quotations
		/// </summary>
		public static string PurchaseQuotations => I18NResource.GetString(ResourceDirectory, "PurchaseQuotations");

		/// <summary>
		///Purchase Return Verification
		/// </summary>
		public static string PurchaseReturnVerification => I18NResource.GetString(ResourceDirectory, "PurchaseReturnVerification");

		/// <summary>
		///Purchase Returns
		/// </summary>
		public static string PurchaseReturns => I18NResource.GetString(ResourceDirectory, "PurchaseReturns");

		/// <summary>
		///Ref#
		/// </summary>
		public static string ReferenceNumberAbbreviated => I18NResource.GetString(ResourceDirectory, "ReferenceNumberAbbreviated");

		/// <summary>
		///Reference Number
		/// </summary>
		public static string ReferenceNumber => I18NResource.GetString(ResourceDirectory, "ReferenceNumber");

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
		///View Quotation
		/// </summary>
		public static string ViewQuotation => I18NResource.GetString(ResourceDirectory, "ViewQuotation");

		/// <summary>
		///You
		/// </summary>
		public static string You => I18NResource.GetString(ResourceDirectory, "You");

		/// <summary>
		///Clear
		/// </summary>
		public static string Clear => I18NResource.GetString(ResourceDirectory, "Clear");

		/// <summary>
		///CLS
		/// </summary>
		public static string CLS => I18NResource.GetString(ResourceDirectory, "CLS");

		/// <summary>
		///CHECKOUT
		/// </summary>
		public static string CHECKOUT => I18NResource.GetString(ResourceDirectory, "CHECKOUT");

		/// <summary>
		///View Purchases
		/// </summary>
		public static string ViewPurchases => I18NResource.GetString(ResourceDirectory, "ViewPurchases");

		/// <summary>
		///Add New Purchase Entry
		/// </summary>
		public static string AddNewPurchaseEntry => I18NResource.GetString(ResourceDirectory, "AddNewPurchaseEntry");

		/// <summary>
		///Add New
		/// </summary>
		public static string AddNew => I18NResource.GetString(ResourceDirectory, "AddNew");

		/// <summary>
		///Return
		/// </summary>
		public static string Return => I18NResource.GetString(ResourceDirectory, "Return");

		/// <summary>
		///View Purchase Orders
		/// </summary>
		public static string ViewPurchaseOrders => I18NResource.GetString(ResourceDirectory, "ViewPurchaseOrders");

		/// <summary>
		///View Purchase Quotation
		/// </summary>
		public static string ViewPurchaseQuotation => I18NResource.GetString(ResourceDirectory, "ViewPurchaseQuotation");

		/// <summary>
		///View Purchase Returns
		/// </summary>
		public static string ViewPurchaseReturns => I18NResource.GetString(ResourceDirectory, "ViewPurchaseReturns");

		/// <summary>
		///Purchase Return
		/// </summary>
		public static string PurchaseReturn => I18NResource.GetString(ResourceDirectory, "PurchaseReturn");

		/// <summary>
		///Please select an item.
		/// </summary>
		public static string PleaseSelectItem => I18NResource.GetString(ResourceDirectory, "PleaseSelectItem");

	}
}
