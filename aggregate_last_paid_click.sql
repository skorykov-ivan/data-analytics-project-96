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
)

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
order by
    t_ag.revenue desc nulls last, t_ag.visit_date asc,
    t_ag.visitors_count desc, t_ag.utm_source asc,
    t_ag.utm_medium asc, t_ag.utm_campaign asc
limit 15;
