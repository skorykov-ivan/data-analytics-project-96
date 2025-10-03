select distinct
    s.visitor_id,
    s.visit_date,
    s.source,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from sessions as s
left join leads as l using(visitor_id)
where cast(visit_date as date) = cast(created_at as date) or
	  l.created_at is null
order by l.amount desc nulls last, s.visit_date, s.source;