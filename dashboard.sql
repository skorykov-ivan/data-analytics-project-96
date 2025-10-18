--------- 1 таблица по дням + 3 таблица по месяцам с фильтром в superset
select
    visit_date,
    utm_source,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_answ
group by visit_date, utm_source
order by
    visit_date asc, visitors_count desc, leads_count desc, purchases_count desc;
--------- 1.1 таблица по дням (без оплаты за рекламу)
select
    visit_date,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_free
group by visit_date
order by visitors_count desc, leads_count desc, purchases_count desc;
--------- 2 таблица по дням недели
select
    utm_source,
    extract(isodow from visit_date) as sort,
    to_char(visit_date, 'Day') as wkd,
    case extract(isodow from visit_date)
        when 1 then 'Понедельник'
        when 2 then 'Вторник'
        when 3 then 'Среда'
        when 4 then 'Четверг'
        when 5 then 'Пятница'
        when 6 then 'Суббота'
        when 7 then 'Воскресенье'
    end as russian_day,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_answ
group by wkd, extract(isodow from visit_date), utm_source
order by
    extract(isodow from visit_date), visitors_count desc, leads_count desc;
--------- 2.1 таблица по дням недели (без оплаты за рекламу)
select
    utm_source,
    extract(isodow from visit_date) as sort,
    to_char(visit_date, 'Day') as wkd,
    case extract(isodow from visit_date)
        when 1 then 'Понедельник'
        when 2 then 'Вторник'
        when 3 then 'Среда'
        when 4 then 'Четверг'
        when 5 then 'Пятница'
        when 6 then 'Суббота'
        when 7 then 'Воскресенье'
    end as russian_day,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_free
group by wkd, extract(isodow from visit_date), utm_source
order by
    extract(isodow from visit_date) asc, visitors_count desc, leads_count desc;
--------- 3.1 таблица по месяцам (без оплаты за рекламу)
select
    visit_date,
    utm_source,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_free
group by visit_date, utm_source
order by visitors_count desc, leads_count desc, purchases_count desc;
--------- 4.1 таблица - воронка (без оплаты рекламы)
select
    'Пользователи' as stage,
    sum(visitors_count) as count_all
from tbl_free

union all

select
    'Лиды' as stage,
    sum(leads_count) as leads_count
from tbl_free

union all

select
    'Покупатели' as stage,
    sum(purchases_count) as purchases_count
from tbl_free;
--------- 4 таблица - воронка + 5 и 6 таблицы
--------- воронки с фильтрами where тут по = 'yandex' / 'vk''
select
    'Пользователи' as stage,
    sum(visitors_count) as count_all
from tbl_answ

union all

select
    'Лиды' as stage,
    sum(leads_count) as leads_count
from tbl_answ

union all

select
    'Покупатели' as stage,
    sum(purchases_count) as purchases_count
from tbl_answ;
--------- 7 таблица - расходы и доходы по дням недели
select
    extract(isodow from visit_date) as sort,
    to_char(visit_date, 'Day') as wkd,
    case extract(isodow from visit_date)
        when 1 then 'Понедельник'
        when 2 then 'Вторник'
        when 3 then 'Среда'
        when 4 then 'Четверг'
        when 5 then 'Пятница'
        when 6 then 'Суббота'
        when 7 then 'Воскресенье'
    end as russian_day,
    sum(total_cost) as total_cost,
    sum(case when revenue is null then 0 else revenue end) as revenue
from tbl_answ
group by wkd, extract(isodow from visit_date)
order by extract(isodow from visit_date);
--------- 8 таблица - расходы по разным каналам в динамике
select
    visit_date,
    utm_source,
    sum(total_cost) as daily_spent
from tbl_answ
group by visit_date, utm_source
having sum(total_cost) > 0
order by visit_date asc, daily_spent desc;

--------- 9 таблица - затраты на рекл \ прибыль
select
    utm_source,
    sum(total_cost) as total_cost,
    sum(revenue) as revenue
from tbl_answ
group by utm_source
order by sum(total_cost) desc, sum(revenue) desc limit 4;

--------- 10 таблица - cpu, cpl, cppu, roi
select
    utm_source,
    round(sum(total_cost) / sum(visitors_count), 2) as cpu,
    round(sum(total_cost) / sum(leads_count), 2) as cpl,
    round(sum(total_cost) / sum(purchases_count), 2) as cppu,
    round((sum(revenue) - sum(total_cost)) / sum(total_cost) * 100, 2) as roi
from tbl_answ
group by utm_source;
--------- 11 таблица - cpu, cpl, cppu, roi по utm_campaign
,
tbl_cost_revenue_utm_campaign as (
	select
	    utm_source,
	    utm_medium,
	    utm_campaign,
	    sum(visitors_count) as visitors_count,
	    sum(leads_count) as leads_count,
	    sum(purchases_count) as purchases_count,
	    sum(case when total_cost is null then 0 else total_cost end) as total_cost,
	    sum(case when revenue is null then 0 else revenue end) as revenue
	from tbl_answ
	group by utm_source, utm_medium, utm_campaign
	having sum(case when total_cost is null then 0 else total_cost end) > 0
	order by
	    visitors_count desc,
	    leads_count desc,
	    purchases_count desc
)

select
    utm_source,
    utm_medium,
    utm_campaign,
    visitors_count,
    leads_count,
    purchases_count,
    total_cost,
    revenue,
    case
    	when visitors_count = 0 then 0
    	else round(total_cost / visitors_count, 2)
    end as cpu,
    case
    	when leads_count = 0 then 0
    	else round(total_cost / leads_count, 2)
    end as cpl,
    case
    	when purchases_count = 0 then 0
    	else round(total_cost / purchases_count, 2)
    end as cppu,
    case
    	when total_cost = 0 then 0
    	else round((revenue - total_cost) / total_cost * 100, 2)
    end as roi,
    (revenue - total_cost) as net_profit
from tbl_cost_revenue_utm_campaign
order by net_profit desc;
--------- Основная таблица для запросов с платной рекламой
--------- нет пометки'(без оплаты за рекламу)'
with tbl_answ as (
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
	        s.source as utm_source,
	        s.medium as utm_medium,
	        s.campaign as utm_campaign,
	        date(lv.last_date) as visit_date,
	        count(distinct s.visitor_id) as visitors_count,
	        count(distinct l.lead_id) as leads_count,
	        count(distinct s.visitor_id) filter (
	            where l.status_id = 142
	        ) as purchases_count,
	        sum(l.amount) as revenue
	    from last_visits as lv
	    inner join sessions as s
	        on lv.visitor_id = s.visitor_id and lv.last_date = s.visit_date
	    left join leads as l
	        on lv.visitor_id = l.visitor_id and lv.last_date <= l.created_at
	    group by date(lv.last_date), s.source, s.medium, s.campaign
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
	where t_ag.utm_source in ('yandex', 'vk')
	order by
	    t_ag.revenue desc nulls last, t_ag.visit_date asc,
	    t_ag.visitors_count desc, t_ag.utm_source asc,
	    t_ag.utm_medium asc, t_ag.utm_campaign asc
)

select *
from tbl_answ
--------- Основная таблица для запросов без оплаты за рекламу
--------- с пометкой '(без оплаты за рекламу)'
with tbl_free as (
	with last_visits as (
	    select
	        visitor_id,
	        max(visit_date) as last_date
	    from sessions
	    where source in ('google', 'organic')
	    group by visitor_id
	)
	
	select
	    date(lv.last_date) as visit_date,
	    s.source as utm_source,
	    count(distinct s.visitor_id) as visitors_count,
	    count(distinct l.lead_id) as leads_count,
	    count(distinct s.visitor_id) filter (
		    where l.status_id = 142
		) as purchases_count,
	    sum(l.amount) as revenue
	from last_visits as lv
	inner join sessions as s
	    on lv.visitor_id = s.visitor_id and lv.last_date = s.visit_date
	left join leads as l
	    on lv.visitor_id = l.visitor_id and lv.last_date <= l.created_at
	group by date(lv.last_date), s.source
)

select *
from tbl_free