--------- 10 таблица - cpu, cpl, cppu, roi
with rank_date as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        row_number() over (
            partition by s.visitor_id order by s.visit_date desc
        ) as rn
    from sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    where s.medium != 'organic'
),

tbl_aggr as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        date(visit_date) as visit_date,
        count(distinct visitor_id) as visitors_count,
        count(distinct lead_id) as leads_count,
        count(distinct visitor_id) filter (
            where status_id = 142
        ) as purchases_count,
        sum(amount) as revenue
    from rank_date
    where rn = 1
    group by date(visit_date), utm_source, utm_medium, utm_campaign
),

tbl_ads as (
    select
        date(campaign_date) as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by utm_source, utm_medium, utm_campaign, date(campaign_date)

    union

    select
        date(campaign_date) as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by utm_source, utm_medium, utm_campaign, date(campaign_date)
),

aggregate_last_paid_click as (
    select
        t_ag.visit_date,
        t_ag.visitors_count,
        t_ag.utm_source,
        t_ag.utm_medium,
        t_ag.utm_campaign,
        ads.total_cost,
        t_ag.leads_count,
        t_ag.purchases_count,
        t_ag.revenue
    from tbl_aggr as t_ag
    left join tbl_ads as ads
        on
            t_ag.visit_date = ads.campaign_date
            and t_ag.utm_source = ads.utm_source
            and t_ag.utm_medium = ads.utm_medium
            and t_ag.utm_campaign = ads.utm_campaign
    where t_ag.utm_source in ('yandex', 'vk')
    order by
        t_ag.revenue desc nulls last, t_ag.visit_date asc,
        t_ag.visitors_count desc, t_ag.utm_source asc,
        t_ag.utm_medium asc, t_ag.utm_campaign asc
)

select
    utm_source,
    round(sum(total_cost) / sum(visitors_count), 2) as cpu,
    round(sum(total_cost) / sum(leads_count), 2) as cpl,
    round(sum(total_cost) / sum(purchases_count), 2) as cppu,
    round((sum(revenue) - sum(total_cost)) / sum(total_cost) * 100, 2) as roi
from aggregate_last_paid_click
group by utm_source;
--------- 11 таблица - cpu, cpl, cppu, roi по utm_campaign + 90% закрытие лидов
with rank_date as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        row_number() over (
            partition by s.visitor_id order by s.visit_date desc
        ) as rn
    from sessions as s
    left join leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    where s.medium != 'organic'
),

tbl_aggr as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        date(visit_date) as visit_date,
        count(distinct visitor_id) as visitors_count,
        count(distinct lead_id) as leads_count,
        count(distinct visitor_id) filter (
            where status_id = 142
        ) as purchases_count,
        sum(amount) as revenue
    from rank_date
    where rn = 1
    group by date(visit_date), utm_source, utm_medium, utm_campaign
),

tbl_ads as (
    select
        date(campaign_date) as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by utm_source, utm_medium, utm_campaign, date(campaign_date)

    union

    select
        date(campaign_date) as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by utm_source, utm_medium, utm_campaign, date(campaign_date)
),

aggregate_last_paid_click as (
    select
        t_ag.visit_date,
        t_ag.visitors_count,
        t_ag.utm_source,
        t_ag.utm_medium,
        t_ag.utm_campaign,
        ads.total_cost,
        t_ag.leads_count,
        t_ag.purchases_count,
        t_ag.revenue
    from tbl_aggr as t_ag
    left join tbl_ads as ads
        on
            t_ag.visit_date = ads.campaign_date
            and t_ag.utm_source = ads.utm_source
            and t_ag.utm_medium = ads.utm_medium
            and t_ag.utm_campaign = ads.utm_campaign
    where t_ag.utm_source in ('yandex', 'vk')
    order by
        t_ag.revenue desc nulls last, t_ag.visit_date asc,
        t_ag.visitors_count desc, t_ag.utm_source asc,
        t_ag.utm_medium asc, t_ag.utm_campaign asc
),

tbl_cost_revenue_utm_campaign as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(visitors_count) as visitors_count,
        sum(leads_count) as leads_count,
        sum(purchases_count) as purchases_count,
        coalesce(sum(total_cost), 0) as total_cost,
        coalesce(sum(revenue), 0) as revenue
    from aggregate_last_paid_click
    group by utm_source, utm_medium, utm_campaign
    having coalesce(sum(total_cost), 0) > 0
    order by
        visitors_count desc,
        leads_count desc,
        purchases_count desc
),

tbl_last_clicks as (
    select
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        lead_id,
        created_at,
        amount,
        closing_reason,
        status_id,
        date(created_at) - date(visit_date) as diff_lids_day --для подсчёта
    --закрытия 90% закрытия лидов
    from rank_date
    where rn = 1 and utm_source in ('yandex', 'vk')
),

tbl_leads_90perc as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        percentile_disc(0.9) within group (order by diff_lids_day
        ) as close_leads_90perc -- тут считаем закрытие 90% лидов
    from tbl_last_clicks
    where status_id = 142
    group by utm_source, utm_medium, utm_campaign
)

select
    tcruc.utm_source,
    tcruc.utm_medium,
    tcruc.utm_campaign,
    tcruc.visitors_count,
    tcruc.leads_count,
    tcruc.purchases_count,
    tcruc.total_cost,
    tcruc.revenue,
    row_number()
        over (order by (tcruc.revenue - tcruc.total_cost) desc
        ) as place,
    case
        when tcruc.visitors_count = 0 then 0
        else round(tcruc.total_cost / tcruc.visitors_count, 2)
    end as cpu,
    case
        when tcruc.leads_count = 0 then 0
        else round(tcruc.total_cost / tcruc.leads_count, 2)
    end as cpl,
    case
        when tcruc.purchases_count = 0 then 0
        else round(tcruc.total_cost / tcruc.purchases_count, 2)
    end as cppu,
    case
        when tcruc.total_cost = 0 then 0 else round(
            (
                tcruc.revenue - tcruc.total_cost
            ) / tcruc.total_cost * 100, 2
        )
    end as roi,
    (tcruc.revenue - tcruc.total_cost) as net_profit,
    coalesce(tl90.close_leads_90perc, 0) as close_leads_90perc,
    sum(tl90.close_leads_90perc) over () / count(
        case when tl90.close_leads_90perc != 0 then 1 end) over (
    ) as middle_90_perc
from tbl_cost_revenue_utm_campaign as tcruc
left join tbl_leads_90perc as tl90
    on
        tcruc.utm_source = tl90.utm_source
        and tcruc.utm_medium = tl90.utm_medium
        and tcruc.utm_campaign = tl90.utm_campaign
order by net_profit desc;
