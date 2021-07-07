-- select value,
--   ntile((select count(*)::integer from results)/5) over (order by value desc) percentile
-- from results;
--

select cume, max(value::float) AS max_value
from (
   select value::float
        , ntile(100) over (order by value::float) as cume
   from results r, surveys s
   where r.survey_id = s.id
   and s.valid_survey = true
   and s.master_id = %{master_id}
   and s.valid_survey = true
   and s.complete = true
   and key = %{key}
   ) as tmp
group by cume
order by cume;
