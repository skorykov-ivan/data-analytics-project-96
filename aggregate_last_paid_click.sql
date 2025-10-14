with tbl_last_paid_click as (
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
		row_number() over(partition by s.visitor_id order by s.visit_date desc) as rn
	from sessions as s
	left join leads as l on s.visitor_id = l.visitor_id
	left join vk_ads as vk on s.visit_date = vk.campaign_date and
	                         s.source = vk.utm_source and
	                         s.medium = vk.utm_medium and
	                         s.campaign = vk.utm_campaign and
	                         s.content = vk.utm_content
	left join ya_ads as ya on s.visit_date = ya.campaign_date and
	                          s.source = ya.utm_source and
	                          s.medium = ya.utm_medium and
	                          s.campaign = ya.utm_campaign and
	                          s.content = ya.utm_content
	where medium != 'organic'
),

tbl_aggr as (
    select
        date(visit_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        count(visitor_id) filter(where created_at is not null) as leads_count,
        count(visitor_id) filter (where status_id = 142) as purchases_count,
        sum(amount) filter (where status_id = 142) as revenue
from tbl_last_paid_click as tlpc
group by date(visit_date), utm_source, utm_medium, utm_campaign
),

tbl_ads as(
    select
        cast(vk.campaign_date as date) as campaign_date,
        vk.utm_source,
        vk.utm_medium,
        vk.utm_campaign,
        sum(vk.daily_spent) as total_cost
    from vk_ads as vk
    group by vk.utm_source, vk.utm_medium, vk.utm_campaign, cast(vk.campaign_date as date)
    union
    select
        cast(ya.campaign_date as date) as campaign_date,
        ya.utm_source,
        ya.utm_medium,
        ya.utm_campaign,
        sum(ya.daily_spent) as total_cost
    from ya_ads as ya
    group by ya.utm_source, ya.utm_medium, ya.utm_campaign, cast(ya.campaign_date as date)
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

where ads.total_cost is not null
order by t_ag.visit_date, t_ag.visitors_count desc nulls last, t_ag.utm_source, t_ag.utm_medium, t_ag.utm_campaign, t_ag.revenue nulls last
limit 15;
