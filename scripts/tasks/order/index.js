var model = {
    Title: window.translate("PurchaseOrders"),
    JournalAdviceExpression: function (data) {
        const tranId = data.TranId;
        if (!tranId) {
            return null;
        }

        return tranId;
    },
    DocumentExpression: function (data) {
        const documents = data.Documents;
        if (!documents) {
            return null;
        };

        return documents;
    },
    ChecklistUrlExpression: function (data) {
        const orderId = data.OrderId;
        if (!orderId) {
            return null;
        };

        return "/dashboard/purchase/tasks/order/checklist/" + orderId;
    },
    ExtraButtons: [
        {
            Title: window.translate("ViewPurchaseOrder"),
            Icon: "zoom",
            ClickExpression: function (data) {
                const orderId = data.OrderId;
                if (!orderId) {
                    return null;
                };


                return "showOrder(" + orderId + ");";
            }
        }
    ],
    AddNewButtonText: window.translate("AddNew"),
    AddNewUrl: "/dashboard/purchase/tasks/order/new",
    SearchApi: "/dashboard/purchase/tasks/order/search",
    FormatExpression: function (cell, columnName, originalValue) {
        var value = originalValue;
        columnName = columnName.trim();

        if (!value) {
            return;
        };

        switch (columnName.trim()) {
            case "PostedOn":
                var date = new Date(value);
                value = window.moment(date).format("LLL");
                break;
            case "ValueDate":
            case "ExpectedDate":
                var date = new Date(value);
                value = window.moment(date).format("LL");
                break;
            case "TotalAmount":
                value = window.getFormattedCurrency(value);
                break;
        };

        if (originalValue !== value) {
            cell.attr("title", originalValue);
        };

        cell.text(value);
        cell.attr("data-date", value).addClass("date");
    },
    SortExpression: function (data) {
        return window.Enumerable.From(data)
            .OrderByDescending(function (x) {
                return new Date(x.ValueDate);
            }).ThenByDescending(function (x) {
                return new Date(x.PostedOn);
            }).ToArray();
    },
    Annotation: [
        {
            Text: "From",
            Id: "From",
            CssClass: "date"
        },
        {
            Text: "To",
            Id: "To",
            CssClass: "date"
        },
        {
            Text: "Expected From",
            Id: "ExpectedFrom",
            CssClass: "date"
        },
        {
            Text: "Expected To",
            Id: "ExpectedTo",
            CssClass: "date"
        },
        {
            Text: "Id",
            Id: "Id"
        },
        {
            Text: "Transaction Code",
            Id: "TranCode"
        },
        {
            Text: "Reference Number",
            Id: "ReferenceNumber"
        },
        {
            Text: "Terms",
            Id: "Terms"
        },
        {
            Text: "Memo",
            Id: "Memo"
        },
        {
            Text: "Posted By",
            Id: "PostedBy"
        },
        {
            Text: "Office",
            Id: "Office"
        },
        {
            Text: "Amount",
            Id: "Amount",
            CssClass: "currency"
        },
        {
            Text: "Customer",
            Id: "Customer"
        }
    ]
};

function showOrder(id) {
    $(".modal iframe").attr("src", "/dashboard/reports/source/Areas/MixERP.Purchases/Reports/Order.xml?order_id=" + id);

    setTimeout(function () {
        $(".advice.modal")
            .modal('setting', 'transition', 'horizontal flip')
            .modal("show");

    }, 300);
};

prepareView(model);