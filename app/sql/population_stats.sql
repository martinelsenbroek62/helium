select key,
  avg(value::float),
  max(value::float),
  min(value::float)
from results r, surveys s
where s.master_id = %{master_id}
and r.survey_id = s.id
and s.valid_survey = true
and s.complete = true
group by key
