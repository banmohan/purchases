window.loadDatepicker();
var exchangeRateLocalized = window.translate("ExchangeRateWithValue");

var receiptTypeDiv = $("#ReceiptType");

//Variables
var homeCurrency = "";

receiptTypeDiv.find(".button").click(function () {
    toggleTransactionType($(this));
});


$("#GoButton").off("click").on("click", function () {
    function getSupplierInfo(supplierId) {
        function request() {
            var url = "/dashboard/purchase/tasks/payment/supplier/transaction-summary/{supplierId}";
            url = url.replace("{supplierId}", supplierId);

            return window.getAjaxRequest(url);
        };

        const ajax = request();


        ajax.success(function (response) {
            const due = response.OfficeDueAmount;
            const supplierCurrency = response.CurrencyCode;

            if (!supplierCurrency) {
                window.displayMessage(window.translate("ThisSupplierDoesNotHaveDefaultCurrency"));
            };

            $("#DueAmountInputText").val(due);
            $("#CurrencyInputText").val(supplierCurrency);
        });

    };

    function getCurrencyInfo() {
        function request() {
            const url = "/dashboard/purchase/tasks/payment/home-currency";
            return window.getAjaxRequest(url);
        };

        const ajax = request();

        ajax.done(function (response) {
            homeCurrency = response;
            getExchangeRates();
            $("#AmountInputText").focus();
        });

        ajax.fail(function (xhr) {
            window.logAjaxErrorMessage(xhr);
        });
    };


    const supplierId = $("#SupplierIdSelect").val();
    if (!supplierId) {
        window.displayMessage(window.translate("PleaseSelectSupplier"));
        return;
    };


    getCurrencyInfo();
    getSupplierInfo(supplierId);
});

$(document).ready(function () {
    $("#receipt").appendTo("#home");
    loadCurrencies();
    loadSuppliers();
    loadCashRepositories();
    loadBankAccounts();
    loadCostCenters();
    loadCashAccounts();
});

//Control Events

$("#SaveButton").off("click").on("click", function () {
    function request(model) {
        const url = "/dashboard/purchase/tasks/payment/new";

        const data = JSON.stringify(model);

        return window.getAjaxRequest(url, "POST", data);
    };

    function getModel() {
        const model = window.serializeForm($(".receipt.form"));
        model.SupplierId = $("#SupplierIdSelect").val();

        return model;
    };

    const model = getModel();

    $("#SaveButton").addClass("loading");
    const ajax = request(model);

    ajax.success(function (id) {
        $("#SaveButton").removeClass("loading");
        window.location = `/dashboard/purchase/tasks/payment/checklist/${id}`;
    });

    ajax.fail(function (xhr) {
        $("#SaveButton").removeClass("loading");
        window.logAjaxErrorMessage(xhr);
    });
});

$("#CurrencyCodeSelect").off("change").on("change", function () {
    getExchangeRates();
});

function getExchangeRates() {
    if (exchangeRateLocalized) {
        $("label[for='DebitExchangeRateInputText']").html(window.stringFormat(exchangeRateLocalized,
            $("#CurrencyCodeSelect").val(), homeCurrency));
        $("label[for='CreditExchangeRateInputText']").html(window.stringFormat(exchangeRateLocalized, homeCurrency,
            $("#CurrencyInputText").val()));
    };

    updateExchangeRate($("#DebitExchangeRateInputText"), $("#CurrencyCodeSelect").val(), homeCurrency);
    updateExchangeRate($("#CreditExchangeRateInputText"), homeCurrency, $("#CurrencyInputText").val());
}

function updateExchangeRate(associatedControl, sourceCurrencyCode, destinationCurrencyCode) {
    function request() {
        var url = "/dashboard/purchase/tasks/payment/exchange-rate/{sourceCurrencyCode}/{destinationCurrencyCode}";
        url = url.replace("{sourceCurrencyCode}", sourceCurrencyCode);
        url = url.replace("{destinationCurrencyCode}", destinationCurrencyCode);

        return window.getAjaxRequest(url);
    };

    if (!sourceCurrencyCode || !destinationCurrencyCode) {
        return;
    };

    const ajax = request();

    ajax.success(function (response) {
        associatedControl.val(response).trigger("change");
    });
};

$("#AmountInputText").keyup(function () {
    updateTotal();
});

$("#DebitExchangeRateInputText").keyup(function () {
    updateTotal();
});

$("#CreditExchangeRateInputText").keyup(function () {
    updateTotal();
});

function updateTotal() {
    if ($("#CurrencyCodeSelect").val() === homeCurrency) {
        $("#DebitExchangeRateInputText").val("1");
    };

    if ($("#CurrencyInputText").val() === homeCurrency) {
        $("#CreditExchangeRateInputText").val("1");
    };

    const due = parseFloat($("#DueAmountInputText").val() || 0);
    const amount = parseFloat($("#AmountInputText").val() || 0);
    const er = parseFloat($("#DebitExchangeRateInputText").val() || 0);
    const er2 = parseFloat($("#CreditExchangeRateInputText").val()) || 0;

    const toHomeCurrency = amount * er;

    $("#AmountInHomeCurrencyInputText").val(toHomeCurrency);

    const toBase = toHomeCurrency * er2;

    const remainingDue = due - toBase;

    $("#BaseAmountInputText").val(toBase);

    $("#FinalDueAmountInputText").val(remainingDue);

    $("#FinalDueAmountInputText").removeClass("alert-danger");

    if (remainingDue < 0) {
        $("#FinalDueAmountInputText").addClass("alert-danger");
    };
};

var toggleTransactionType = function (e) {
    if (e.attr("id") === "BankButton") {
        if (!$("#BankFormGroup").is(":visible")) {
            $("#BankFormGroup").show(500);
            $("#CashFormGroup").hide();
            $("#CashButton").removeClass("active");
            $("#BankButton").addClass("active");
            loadCashRepositories();
            return;
        };
    };

    if (e.attr("id") === "CashButton") {
        if (!$("#CashFormGroup").is(":visible")) {
            $("#CashFormGroup").show(500);
            $("#BankFormGroup").hide();
            loadBankAccounts();
            loadCostCenters();
            $("#PostedDateTextBox").val("");
            $("#BankInstrumentCodeInputText").val("");
            $("#BankTransactionCodeInputText").val("");
            $("#CashButton").addClass("active");
            $("#BankButton").removeClass("active");
            return;
        };
    };
};

function loadCostCenters() {
    const url = "/api/forms/finance/cost-centers/display-fields";
    const target = $("#CostCenterIdSelect");
    window.ajaxDataBind(url, target, null, "Key", "Value");
};

function loadCurrencies() {
    const url = "/api/forms/core/currencies/lookup-fields";
    const target = $("#CurrencyCodeSelect");
    window.ajaxDataBind(url, target, null, "Key", "Value");
};

function loadSuppliers() {
    const url = "/api/forms/inventory/suppliers/display-fields";
    const target = $("#SupplierIdSelect");
    window.ajaxDataBind(url, target, null, "Key", "Value");
};

function loadCashRepositories() {
    const url = "/api/forms/finance/cash-repositories/display-fields";
    const target = $("#CashRepositoryIdSelect");
    window.ajaxDataBind(url, target, null, "Key", "Value");
};

function loadCashAccounts() {
    const url = "/api/views/finance/cash-account-selector-view/display-fields";
    const target = $("#CashAccountIdSelect");
    window.ajaxDataBind(url, target, null, "Key", "Value");
};

function loadBankAccounts() {
    const url = "/api/forms/finance/bank-accounts/display-fields";
    const target = $("#BankAccountIdSelect");
    window.ajaxDataBind(url, target, null, "Key", "Value");
};

window.overridePath = "/dashboard/purchase/tasks/payment";