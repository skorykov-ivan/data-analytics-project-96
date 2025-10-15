with last_visits as (
    select
        visitor_id,
        max(visit_date) as last_date
    from sessions
    where medium != 'organic'
    group by visitor_id    
),

tbl_aggr as (
    select
        date(lv.last_date) as visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        count(distinct s.visitor_id) as visitors_count,
        count(distinct l.lead_id) as leads_count,
        count(distinct s.visitor_id) filter (where status_id = 142) as purchases_count,
        sum(amount) as revenue
    from last_visits as lv
    inner join sessions as s on lv.visitor_id = s.visitor_id and
                                    lv.last_date = s.visit_date
    left join leads as l on lv.visitor_id = l.visitor_id and
                            lv.last_date <= l.created_at
    group by date(lv.last_date), s.source, s.medium, s.campaign
),

tbl_ads as(
    select
        date(campaign_date) as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads as vk
    group by utm_source, utm_medium, utm_campaign, date(campaign_date)
    
    union
    select
    
        date(campaign_date) as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads as ya
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
left join tbl_ads as ads on t_ag.visit_date = ads.campaign_date and
                            t_ag.utm_source = ads.utm_source and
                            t_ag.utm_medium = ads.utm_medium and
                            t_ag.utm_campaign = ads.utm_campaign

order by t_ag.revenue desc nulls last, t_ag.visit_date, t_ag.visitors_count desc, t_ag.utm_source, t_ag.utm_medium, t_ag.utm_campaign
limit 15;
