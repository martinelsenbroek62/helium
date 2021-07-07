--
-- misc views for working tableau
--

create or replace view user_balances_by_program as (
  with a as (
    select user_id, benefit_program_id,
      sum(amount::varchar::money) over (partition by user_id, benefit_program_id) total_funds_deposited_by_program
    from funds
  ),

  b as (
    select user_id, benefit_category_id,
      sum(requesting_amount::varchar::money) over (partition by user_id, benefit_category_id) total_spent_on_claims_by_category
    from claims
  ),
  c as (
    select bp.name program_name, bc.name category_name, bp.id benefit_program_id, bc.id benefit_category_id from benefit_programs bp, benefit_categories bc, benefit_program_categories bpc
    where bp.id = bpc.benefit_program_id
    and bc.id =bpc.benefit_category_id
  )

  select distinct user_id, program_id, program_name, funds_by_prog, max amount_spent, remaining_balance from (
    select
      user_id,benefit_program_id program_id, benefit_category_id category_id,
      total_funds_deposited_by_program funds_by_prog,
      total_spent_on_claims_by_category spent_by_category, category_name, program_name,
      max,
      (total_funds_deposited_by_program - max) as remaining_balance
    from (
      select
        *, max(total_spent_on_claims_by_category) over (partition by user_id, benefit_program_id)
      from (
        select
          a.user_id, a.benefit_program_id, a.total_funds_deposited_by_program,
          b.benefit_category_id, b.total_spent_on_claims_by_category,
          c.category_name, c.program_name
        from a, b, c
        where a.benefit_program_id = c.benefit_program_id
        and b.benefit_category_id = c.benefit_category_id
        and a.user_id = b.user_id
        -- and a.user_id in (12, 11)
      ) t1
    )t2
  )t3
);

create or replace view survey_view as (
  select
    -- organizations
      o.id organization_id,
      o.name organization_name,
      o.updated_at organization_updated_at,
      o.has_surveys organization_has_surveys,
      o.has_benefits organization_has_benefits,
    -- users
      u.id user_id,
      u.name user_name,
      u.email user_email,
      u.employee_accepted_invite_at user_employee_accepted_invite_at,
      u.employee_id user_employee_id,
      u.employee_office_location user_employee_office_location,
      u.employee_start_date user_employee_start_date,
      u.employee_state_of_residence user_state_or_residence,
      u.employee_termination_date user_employee_termination_date,
      u.first_name user_first_name,
      u.last_name user_last_name,
    -- surveys
      s.id survey_id,
      s.name survey_name,
      s.complete survey_complete,
      s.completed_at survey_completed_at,
      s.created_at survey_create,
      s.finish_number survey_finish_number,
      s.has_reached_end survey_has_reached_end,
      s.has_started survey_has_started,
      s.started_at survey_started_at,
      s.valid_survey survey_valid_survey,
      s.finish_date survey_finish_date,
      s.survey_year survey_survey_year,
    -- questions
      q.id question_id,
      q.text question_text,
      q.answer question_answer,
      q.cell question_cell,
      q.key question_key,
      q.kind question_kind,
      q.question_identifier question_question_identifier,
      q.created_at question_created_at,
      q.group_id question_group_id,
    -- groups
      g.id group_id,
      g.name group_name,
    -- sections
      c.id section_id,
      c.name sesction_name
  from  organizations o,
        surveys s,
        users u,
        questions q,
        groups g,
        sections c
  where o.id = u.organization_id
  and u.id = s.user_id
  and s.id = q.survey_id
  and s.id = c.survey_id
  and s.id = g.survey_id
  and q.group_id = g.id
  and q.section_id = c.id
)
;

create or replace view benefits_view as (
    select
    -- claim attachments
      a.id claim_attachment_id,
      a.attachment claim_attachment_attachment,
      a.created_at claim_attachment_created_at,
      a.updated_at claim_attachment_updated_at,
      a.kind claim_attachment_kind,
      a.uuid claim_attachment_uuid,
    -- claims
      c.id claim_id,
      c.approved claim_approved,
      c.expensed_date claim_expensed_date,
      c.title claim_title,
      c.created_at claim_created_at,
      c.updated_at claim_updated_at,
      c.created_by_id claim_created_by_id,
      c.description claim_description,
      c.manufacturer claim_manufacturer,
      c.model_number claim_model_number,
      c.paid_out claim_paid_out,
      c.purchase_amount claim_purchase_amount,
      c.submitted_at claim_submitted_at,
      c.reimbursement_amount claim_reimbursement_amount,
      c.rejected claim_rejected,
      c.rejected_reason claim_rejected_reason,
      c.requesting_amount claim_requesting_amount,
    --funds
      f.amount fund_amount,
      f.comment fund_comment,
      f.created_at fund_created_at,
      f.updated_at fund_updated_at,
      f.expires_on fund_expires_on,
      f.id fund_id,
    -- organizations
      o.id organiaztion_id,
      o.name organiaztion_name,
      o.admin_emails organiaztion_admin_emails,
      o.contact_email organiaztion_contact_email,
      o.contact_name organiaztion_contact_name,
      o.contact_phone organiaztion_phone,
      o.created_at organiaztion_created_at,
      o.has_benefits organiaztion_has_benefits,
      o.has_surveys organiaztion_has_surveys,
    -- benefit_programs
      bp.id benefit_program_id,
      bp.uuid benefit_program_uuid,
      bp.name benefit_program_name,
      bp.description benefit_program_description,
      bp.created_at benefit_program_created_at,
      bp.updated_at benefit_program_updated_at,
      bp.start_date benefit_program_start_date,
      bp.end_date benefit_program_end_date,
      bp.active benefit_program_active,
      bp.image benefit_program_image,
    -- benefit_categories
      bc.id benefit_category_id,
      bc.uuid benefit_category_uuid,
      bc.name benefit_category_name,
      bc.focus_area benefit_category_focus_area,
      bc.product_type benefit_category_product_type,
      bc.percent_to_reimburse benefit_category_percent_to_reimburse,
      bc.description benefit_category_description,
      bc.focus_area_description benefit_category_focus_area_description,
      bc.product_type_description benefit_category_product_type_description,
      bc.created_at benefit_category_created_at,
      bc.updated_at benefit_category_updated_at,
    -- users
      u.id user_id,
      u.name user_name,
      u.email user_email,
      u.employee_accepted_invite_at user_employee_accepted_invite_at,
      u.employee_id user_employee_id,
      u.employee_office_location user_employee_office_location,
      u.employee_start_date user_employee_start_date,
      u.employee_state_of_residence user_state_or_residence,
      u.employee_termination_date user_employee_termination_date,
      u.first_name user_first_name,
      u.last_name user_last_name
    from
      organizations o,
      users u,
      funds f,
      claims c,
      claim_attachments a,
      benefit_programs bp,
      benefit_categories bc,
      benefit_program_categories bpc
    where o.id = u.organization_id
    and   u.id = c.user_id
    and   u.id = f.user_id
    and   c.id = a.claim_id
    and   bp.id=bpc.benefit_program_id
    and   bc.id = bpc.benefit_category_id
    and   c.benefit_category_id = bc.id
  )
;

-- Benefits view but includes every user regardless of number of claims submitted
create or replace view benefit_users_view as (
  select u.*, b.*
  from users u
  left outer join benefits_view b on (u.id  = b.user_id)
);

-- Calendar view
create or replace view calendar_view as (
  select generate_series::date as date
  from  generate_series('1-1-2010'::timestamp, '1-1-2020'::timestamp, '1 day')
)
;

-- View of claims table that converts monetary amounts from string to decimal-money value
create or replace view claims_values_view as (
   SELECT claims.id,
    claims.organization_id,
    claims.user_id,
    claims.description,
    claims.expensed_date,
    claims.created_at,
    claims.updated_at,
    claims.approved,
    claims.rejected,
    claims.submitted_at,
    claims.rejected_reason,
    claims.paid_out,
    claims.manufacturer,
    claims.model_number,
    claims.benefit_program_id,
    claims.benefit_category_id,
    claims.more_info,
    claims.historical,
    claims.locked,
    claims.sent_to_payroll,
    claims.approved_claim_note,
    claims.purchase_amount::money::numeric::double precision AS purchase_amount,
    claims.reimbursement_amount::money::numeric::double precision AS reimbursement_amount,
    claims.requesting_amount::money::numeric::double precision AS requesting_amount
   FROM claims
)
;
