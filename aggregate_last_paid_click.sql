select
	date(s.visit_date) as visit_date,
	count(distinct s.visitor_id) as visitors_count,
	s.source as utm_source,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	coalesce(sum(vk.daily_spent), 0) + coalesce(sum(ya.daily_spent), 0) as total_cost,
	count(distinct l.lead_id) as leads_count,
	count(*) filter(where l.status_id = 142) as purchases_count,
	coalesce(sum(l.amount), 0) as revenue
from sessions as s
left join leads as l on s.visitor_id = l.visitor_id
left join vk_ads as vk on date(s.visit_date) = vk.campaign_date and
                         s.source = vk.utm_source and
                         s.medium = vk.utm_medium and
                         s.campaign = vk.utm_campaign and
                         s.content = vk.utm_content
left join ya_ads as ya on date(s.visit_date) = ya.campaign_date and
                          s.source = ya.utm_source and
                          s.medium = ya.utm_medium and
                          s.campaign = ya.utm_campaign and
                          s.content = ya.utm_content
where medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
group by date(s.visit_date), s.source, s.medium, s.campaign
order by visit_date, visitors_count desc, utm_source, utm_medium, utm_campaign, revenue desc nulls last limit 15;




