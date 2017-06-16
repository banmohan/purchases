using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Frapid.ApplicationState.Models;
using Frapid.Configuration;
using Frapid.Configuration.Db;
using Frapid.DataAccess;
using Frapid.Framework.Extensions;
using Frapid.Mapper;
using Frapid.Mapper.Database;
using Frapid.Mapper.Helpers;
using Frapid.Mapper.Query.Insert;
using Frapid.Mapper.Query.NonQuery;
using Frapid.Mapper.Query.Select;
using MixERP.Purchases.DTO;
using MixERP.Purchases.QueryModels;

namespace MixERP.Purchases.DAL.Backend.Tasks
{
    public static class Quotations
    {
        public static async Task<IEnumerable<dynamic>> GetSearchViewAsync(string tenant, int officeId, QuotationSearch search)
        {
            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                var sql = new Sql("SELECT * FROM purchase.quotation_search_view");
                sql.Where("value_date BETWEEN @0 AND @1", search.From, search.To);
                sql.And("expected_date BETWEEN @0 AND @1", search.ExpectedFrom, search.ExpectedTo);
                sql.And("quotation_id::text LIKE @0", search.Id.ToSqlLikeExpression().ToLower());
                sql.And("LOWER(reference_number) LIKE @0", search.ReferenceNumber.ToSqlLikeExpression().ToLower());
                sql.And("LOWER(supplier) LIKE @0", search.Supplier.ToSqlLikeExpression().ToLower());
                sql.And("LOWER(terms) LIKE @0", search.Terms.ToSqlLikeExpression().ToLower());
                sql.And("LOWER(memo) LIKE @0", search.Memo.ToSqlLikeExpression().ToLower());
                sql.And("LOWER(posted_by) LIKE @0", search.PostedBy.ToSqlLikeExpression().ToLower());
                sql.And("LOWER(office) LIKE @0", search.Office.ToSqlLikeExpression().ToLower());

                if (search.Amount > 0)
                {
                    sql.And("total_amount = @0", search.Amount);
                }

                sql.And("office_id IN(SELECT * FROM core.get_office_ids(@0))", officeId);

                return await db.SelectAsync<dynamic>(sql).ConfigureAwait(false);
            }
        }

        public static async Task CancelAsync(string tenant, long id, LoginView meta)
        {
            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                var sql = new Sql("UPDATE purchase.quotations");
                sql.Append("SET");
                sql.Append("cancelled = @0, ", true);
                sql.Append("audit_user_id = @0, ", meta.UserId);
                sql.Append("audit_ts = @0", DateTimeOffset.UtcNow);
                sql.Where("quotation_id = @0", id);

                await db.NonQueryAsync(sql).ConfigureAwait(false);
            }
        }

        public static async Task<long> PostAsync(string tenant, Quotation model)
        {
            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                try
                {
                    await db.BeginTransactionAsync().ConfigureAwait(false);
                    var awaiter = await db.InsertAsync("purchase.quotations", "quotation_id", true, model).ConfigureAwait(false);
                    long quotationId = awaiter.To<long>();

                    foreach (var detail in model.Details)
                    {
                        detail.QuotationId = quotationId;
                        await db.InsertAsync("purchase.quotation_details", "quotation_detail_id", true, detail).ConfigureAwait(false);
                    }

                    db.CommitTransaction();

                    return quotationId;
                }
                catch
                {
                    db.RollbackTransaction();
                    throw;
                }
            }
        }

        public static async Task<List<QuotationResultview>> GetQuotationResultViewAsync(string tenant, QuotationQueryModel query)
        {
            string sql = "SELECT * FROM purchase.get_quotation_view(@0::integer,@1::integer,@2, @3::date,@4::date,@5::date,@6::date,@7::bigint,@8,@9,@10,@11,@12);";

            if (DbProvider.GetDbType(DbProvider.GetProviderName(tenant)) == DatabaseType.SqlServer)
            {
                sql = "SELECT * FROM purchase.get_quotation_view(@0,@1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@11,@12);";
            }

            var awaiter = await
                Factory.GetAsync<QuotationResultview>(tenant, sql, query.UserId, query.OfficeId, query.Supplier.Or(""), query.From, query.To,
                    query.ExpectedFrom, query.ExpectedTo, query.Id, query.ReferenceNumber.Or(""),
                    query.InternalMemo.Or(""), query.Terms.Or(""), query.PostedBy.Or(""), query.Office.Or("")).ConfigureAwait(false);

            return awaiter.OrderBy(x => x.ValueDate).ThenBy(x => x.Supplier).ToList();
        }
    }
}