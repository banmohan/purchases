window.prepareChecklist({
    TranId: window.tranId,
    Title: window.translate("PaymentChecklist") + window.tranId,
    ViewText: window.translate("ViewPayments"),
    ViewUrl: "/dashboard/purchase/tasks/payment",
    AddNewText: window.translate("AddNewPaymentEntry"),
    AddNewUrl: "/dashboard/purchase/tasks/payment/new",
    ReportPath: "/dashboard/reports/source/Areas/MixERP.Purchases/Reports/Payment.xml?transaction_master_id=" + window.tranId
});
