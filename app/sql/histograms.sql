with drb_stats as (
    select min(value::float) as min,
           max(value::float) as max,
           stddev(value::float) as avg
      from results r, surveys s
      where r.survey_id = s.id
      and s.valid_survey = true
      and s.complete = true
      and key = %{key}
),
histogram as (
   select
          width_bucket(value::float, min, 50, 15) as bucket,
          int4range(min(value::float)::int, max(value::float)::int, '[]') as range,
          count(*) as freq
     from results r, drb_stats, surveys s
     where r.survey_id = s.id
     and s.valid_survey = true
     and s.complete = true
     and s.master_id = %{master_id}
     and key = %{key}
 group by bucket
 order by bucket
)

select bucket,
  range,
  freq,
  repeat('*', (freq::float / max(freq) over() * 30)::int) as bar
from histogram
;
