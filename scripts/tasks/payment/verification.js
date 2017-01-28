window.prepareVerification({
    Title: window.translate("PaymentVerification"),
    AddNewText: window.translate("AddNew"),
    AddNewUrl: "/dashboard/purchase/tasks/payment/new",
    Book: "Purchase Payment",
    ChecklistUrl: "/dashboard/purchase/tasks/payment/checklist/{tranId}",
    AdviceButtons: [
        {
            Title: window.translate("ViewPayment"),
            Href: "javascript:void(0);",
            OnClick: "showReceipt({tranId});"
        }
    ]
});

function showPayment(tranId) {
    $(".advice.modal iframe").attr("src", "/dashboard/reports/source/Areas/MixERP.Purchases/Reports/Payment.xml?transaction_master_id=" + tranId);

    setTimeout(function () {
        $(".advice.modal")
            .modal('setting', 'transition', 'horizontal flip')
            .modal("show");

    }, 300);
};