/*

SQL: Ecommerce Project - BigQuery Console Sample Dataset

Skills used: Joins, CTEs, Aggregate Functions, Transforming Data Types.

*/


-- Query 01: calculate total visit, pageview, transaction and revenue for Jan, Feb and March 2017 order by month
#standardSQL
select
    substr(_table_suffix, 1, 6) as month,
    sum(totals.visits) as visits,
    sum(totals.pageviews) as pageviews,
    sum(totals.transactions) as transactions,
    round(sum(totals.totalTransactionRevenue * power(10, -6)), 2) as revenue
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
where _table_suffix between '20170101' and '20170331'
group by month
order by month asc;


-- Query 02: Bounce rate per traffic source in July 2017
#standardSQL
select
    trafficSource.source as source,
    sum(totals.visits) as total_visits,
    sum(totals.bounces) as total_no_of_bounces,
    cast(sum(totals.bounces) as float64) / cast(sum(totals.visits) as float64) * 100 as bounce_rate
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
where _table_suffix between '20170701' and '20170731'
group by source
order by total_visits desc;


-- Query 3: Revenue by traffic source by week, by month in June 2017
#standardSQL
select
    'Month' as time_type,
    format_datetime("%Y%m", date_trunc(parse_date("%Y%m%d", _table_suffix), month)) as time,
    trafficSource.source as source,
    round(sum(totals.totalTransactionRevenue * power(10, -6)), 2) as revenue
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
where _table_suffix between '20170601' and '20170630'
group by source, time
union all 
select
    'Week' as time_type,
    format_datetime("%Y%U", date_trunc(parse_date("%Y%m%d", _table_suffix), isoweek)) as time,
    trafficSource.source as source,
    round(sum(totals.totalTransactionRevenue * power(10, -6)), 2) as revenue
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
where _table_suffix between '20170601' and '20170630'
group by source, time
order by revenue desc;


--Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017. Note: totals.transactions >=1 for purchaser and totals.transactions is null for non-purchaser
#standardSQL
with non_pay as(
    select
        substr(_table_suffix, 1, 6) as month,
        sum(totals.pageviews)/count(distinct fullVisitorID) as avg_pageview_non_purchase,
    from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    where _table_suffix between '20170601' and '20170731'
        and totals.transactions is null
    group by month),
pay as(
     select
        substr(_table_suffix, 1, 6) as month,
        sum(totals.pageviews)/count(distinct fullVisitorID) as avg_pageview_purchase,
    from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    where _table_suffix between '20170601' and '20170731'
        and totals.transactions >= 1
    group by month)
select * from pay
inner join non_pay
    using (month)
order by month;


-- Query 05: Average number of transactions per user that made a purchase in July 2017
#standardSQL
select
    substr(_table_suffix, 1, 6) as month,
    sum(totals.transactions)/count(distinct fullVisitorID) as avg_total_transations_per_user
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
where _table_suffix between '20170701' and '20170731'
       and totals.transactions >= 1
group by month;


-- Query 06: Average amount of money spent per session
#standardSQL
select
    substr(_table_suffix, 1, 6) as month,
    cast(sum(totals.totalTransactionRevenue)/sum(totals.visits) as string format '9.99EEEE') as avg_revenue_by_user_per_visit
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
where _table_suffix between '20170701' and '20170731'
       and totals.transactions is not null
group by month;


-- Query 07: Products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017
#standardSQL
with hits_id as (
    select
        distinct hits.transaction.transactionId as id
    from `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        unnest (hits) hits,
        unnest (hits.product) product
    where _table_suffix between '20170701' and '20170731'
        and product.productRevenue is not null
        and product.v2ProductName = "YouTube Men's Vintage Henley")
select
    product.v2ProductName as other_purchased_products,
    sum(product.productQuantity) as quantity
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    unnest (hits) hits,
    unnest (hits.product) product
where _table_suffix between '20170701' and '20170731'
    and hits.transaction.transactionId in (select * from hits_id)
    and product.v2ProductName != "YouTube Men's Vintage Henley"
    and product.productRevenue is not null
group by other_purchased_products
order by quantity desc;


--Query 08: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.
#standardSQL
with raw as (
    select
        substr(_table_suffix, 1, 6) as month,
        product.v2ProductName as name,
        hits.eCommerceAction.action_type as type
    from `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        unnest (hits) hits,
        unnest (hits.product) product
    where _table_suffix between '20170101' and '20170331'
    ),
product_view as (
    select
        month,
        count(name) as num_product_view
    from raw
    where type = '2'
    group by month),
addtocart as (
    select
        month,
        count(name) as num_addtocart
    from raw
    where type = '3'
    group by month),
purchase as (
    select
        month,
        count(name) as num_purchase
    from raw
    where type = '6'
    group by month)
select 
    v.month,
    v.num_product_view,
    a.num_addtocart,
    p.num_purchase,
    round(a.num_addtocart/v.num_product_view*100, 2) as add_to_cart_rate,
    round(p.num_purchase/v.num_product_view*100, 2) as purchase_rate
from product_view as v
inner join addtocart as a using (month)
inner join purchase as p using (month)
order by month;