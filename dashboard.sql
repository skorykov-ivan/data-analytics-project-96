
----------------------------------------------------- 1 таблица по дням
select
    visit_date,
    utm_source,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count,
    sum(total_cost) as total_cost,
    sum(revenue) as revenue
from tbl_answ
group by visit_date, utm_source
order by visit_date, visitors_count desc, leads_count desc, purchases_count desc;

----------------------------------------------------- 2 таблица по дням недели
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
    utm_source,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_answ
group by wkd, extract(isodow from visit_date), utm_source
order by extract(isodow from visit_date), visitors_count desc, leads_count desc;

----------------------------------------------------- 3 таблица по месяцам
select
    case date_part('month', visit_date)
        when 1 then 'Январь'
        when 2 then 'Февраль'
        when 3 then 'Март'
        when 4 then 'Апрель'
        when 5 then 'Май'
        when 6 then 'Июнь'
        when 7 then 'Июль'
        when 8 then 'Август'
        when 9 then 'Сентябрь'
        when 10 then 'Октябрь'
        when 11 then 'Ноябрь'
        when 12 then 'Декабрь'
    end as rus_month,
    to_char(visit_date, 'Month') as month,
    utm_source,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_answ
group by month, date_part('month', visit_date), utm_source
order by date_part('month', visit_date), leads_count desc, visitors_count desc limit 10;

----------------------------------------------------- 4 таблица по неделям
select
    extract(week from visit_date) as week,
    utm_source,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_answ
group by week, utm_source
order by week, sum(visitors_count) desc;

----------------------------------------------------- 5 таблица - топ-10 откликов по категориям
select
    row_number() over(order by sum(visitors_count) desc) as rn,
	  utm_source,
	  utm_medium,
  	utm_campaign,
    sum(visitors_count) as visitors_count,
    sum(leads_count) as leads_count,
    sum(purchases_count) as purchases_count
from tbl_answ
group by utm_source, utm_medium, utm_campaign limit 10;

----------------------------------------------------- 7 таблица - воронка
    select
        'Пользователи' as stage,
        sum(visitors_count) as count
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

----------------------------------------------------- 8 таблица - расходы по разным каналам в динамике
select
    visit_date,
    utm_source,
    sum(total_cost) as daily_spent
from tbl_answ
group by visit_date, utm_source
having sum(total_cost) > 0
order by visit_date, daily_spent desc;

----------------------------------------------------- 9 таблица - затраты на рекл \ прибыль
select
    utm_source,
    sum(total_cost) as total_cost,
    sum(revenue) as revenue
from tbl_answ
group by utm_source
order by sum(total_cost) desc, sum(revenue) desc limit 4;

----------------------------------------------------- 10 таблица - cpu, cpl, cppu, roi
select
    utm_source,
    round(sum(total_cost) / sum(visitors_count), 2) as cpu,
    round(sum(total_cost) / sum(leads_count), 2) as cpl,
    round(sum(total_cost) / sum(purchases_count), 2) as cppu,
    round((sum(revenue) - sum(total_cost)) / sum(total_cost) * 100, 2) as roi
from tbl_answ
group by utm_source;
