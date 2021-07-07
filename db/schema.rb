# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180302145222) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "pg_stat_statements"

  create_table "benefit_categories", force: :cascade do |t|
    t.integer  "organization_id"
    t.string   "uuid"
    t.string   "name"
    t.string   "focus_area"
    t.string   "product_type"
    t.string   "percent_to_reimburse"
    t.text     "description"
    t.text     "focus_area_description"
    t.text     "product_type_description"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "benefit_program_id"
    t.text     "category_notes"
    t.text     "eligibility_description"
    t.text     "description_of_exclusions"
    t.string   "benefit_category_image_url"
  end

  create_table "benefit_program_categories", force: :cascade do |t|
    t.string   "uuid"
    t.integer  "benefit_program_id"
    t.integer  "benefit_category_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "benefit_programs", force: :cascade do |t|
    t.string   "uuid"
    t.string   "name"
    t.integer  "organization_id"
    t.text     "description"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "active",          default: true
    t.string   "image"
    t.text     "program_notes"
  end

  create_table "claim_attachments", force: :cascade do |t|
    t.integer  "claim_id"
    t.integer  "user_id"
    t.integer  "organization_id"
    t.string   "kind"
    t.json     "attachment"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "uuid"
  end

  create_table "claims", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "created_by_id"
    t.integer  "user_id"
    t.string   "uuid"
    t.string   "title"
    t.text     "description"
    t.date     "expensed_date"
    t.string   "purchase_amount"
    t.string   "reimbursement_amount"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "approved",              default: false
    t.boolean  "rejected",              default: false
    t.integer  "product_id"
    t.datetime "submitted_at"
    t.string   "rejected_reason"
    t.string   "requesting_amount"
    t.boolean  "paid_out",              default: false
    t.string   "manufacturer"
    t.string   "model_number"
    t.integer  "program_id"
    t.integer  "reimbursement_rule_id"
    t.integer  "benefit_program_id"
    t.integer  "benefit_category_id"
    t.text     "more_info"
    t.boolean  "historical",            default: false
    t.boolean  "locked",                default: false
    t.boolean  "sent_to_payroll",       default: false
    t.string   "approved_claim_note"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "funds", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "organization_id"
    t.float    "amount"
    t.date     "expires_on"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "comment"
    t.integer  "program_id"
    t.integer  "benefit_program_id"
    t.integer  "benefit_category_id"
    t.date     "available_on"
  end

  create_table "groups", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "survey_id"
    t.integer  "section_id"
    t.string   "name"
    t.text     "intro"
    t.integer  "position"
    t.text     "more_info"
    t.text     "template"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "show",              default: true
    t.string   "uuid"
    t.boolean  "trash",             default: false
    t.string   "master_group_uuid"
  end

  add_index "groups", ["organization_id"], name: "index_groups_on_organization_id", using: :btree
  add_index "groups", ["position"], name: "index_groups_on_position", using: :btree
  add_index "groups", ["section_id"], name: "index_groups_on_section_id", using: :btree
  add_index "groups", ["survey_id"], name: "index_groups_on_survey_id", using: :btree
  add_index "groups", ["uuid"], name: "index_groups_on_uuid", using: :btree

  create_table "historical_records", force: :cascade do |t|
    t.integer  "survey_id"
    t.integer  "user_id"
    t.json     "data"
    t.integer  "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "survey_id"
    t.string   "uuid"
    t.string   "subject"
    t.string   "body"
    t.string   "deliver_to"
    t.datetime "delivered_at"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "notes", force: :cascade do |t|
    t.string   "uuid"
    t.integer  "organization_id"
    t.integer  "user_id"
    t.integer  "author_id"
    t.integer  "claim_id"
    t.text     "body"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "offers", force: :cascade do |t|
    t.string   "uuid"
    t.integer  "organization_id"
    t.string   "company"
    t.string   "name"
    t.text     "body"
    t.string   "website"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "cta"
    t.string   "value"
    t.boolean  "published",       default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.text     "organization_styles_template"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.string   "uuid"
    t.json     "logo"
    t.text     "benefit_welcome"
    t.text     "benefit_balance"
    t.text     "benefit_focus_area"
    t.text     "benefit_claims_form"
    t.text     "benefit_about"
    t.string   "contact_name"
    t.string   "contact_phone"
    t.string   "contact_email"
    t.text     "employee_welcome_email_text"
    t.boolean  "has_surveys",                   default: false
    t.boolean  "has_benefits",                  default: false
    t.string   "admin_emails"
    t.text     "benefit_categories_text"
    t.text     "benefit_footer"
    t.text     "benefit_categories_template"
    t.string   "headers_for_claims_export"
    t.string   "headers_for_claims_export_agg"
    t.boolean  "has_offers",                    default: false
    t.text     "email_claim_status_template"
    t.boolean  "has_self_signup",               default: false
    t.string   "signup_slug"
    t.string   "self_signup_password"
  end

  add_index "organizations", ["uuid"], name: "index_organizations_on_uuid", using: :btree

  create_table "pages", force: :cascade do |t|
    t.integer  "organization_id"
    t.string   "title"
    t.string   "slug"
    t.text     "body"
    t.integer  "position"
    t.string   "uuid"
    t.boolean  "published"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "show_in_menu",    default: false
  end

  create_table "products", force: :cascade do |t|
    t.integer  "organization_id"
    t.string   "focus_area"
    t.string   "category_name"
    t.string   "product_type"
    t.string   "name"
    t.string   "description"
    t.string   "image_url"
    t.string   "reimbursement_percentage"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "kind"
    t.string   "manufacturer"
    t.string   "model_number"
    t.integer  "program_id"
    t.integer  "reimbursement_rule_id"
  end

  create_table "programs", force: :cascade do |t|
    t.integer  "organization_id"
    t.string   "uuid"
    t.string   "name"
    t.text     "description"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "available",       default: true
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "questions", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "survey_id"
    t.integer  "section_id"
    t.integer  "group_id"
    t.string   "text"
    t.string   "answer",                default: ""
    t.integer  "position",              default: 0
    t.string   "key"
    t.text     "more_info"
    t.string   "kind"
    t.string   "options"
    t.boolean  "required",              default: false
    t.string   "cell"
    t.string   "units"
    t.string   "placeholder"
    t.text     "template"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "show",                  default: true
    t.string   "uuid"
    t.boolean  "trash",                 default: false
    t.integer  "user_id"
    t.string   "question_identifier"
    t.string   "master_question_uuid"
    t.boolean  "show_previous_answers", default: false
  end

  add_index "questions", ["group_id"], name: "index_questions_on_group_id", using: :btree
  add_index "questions", ["organization_id"], name: "index_questions_on_organization_id", using: :btree
  add_index "questions", ["position"], name: "index_questions_on_position", using: :btree
  add_index "questions", ["section_id"], name: "index_questions_on_section_id", using: :btree
  add_index "questions", ["survey_id"], name: "index_questions_on_survey_id", using: :btree
  add_index "questions", ["user_id"], name: "index_questions_on_user_id", using: :btree
  add_index "questions", ["uuid"], name: "index_questions_on_uuid", using: :btree

  create_table "reimbursement_rules", force: :cascade do |t|
    t.integer  "organization_id"
    t.string   "focus_area"
    t.string   "category_name"
    t.string   "percentage"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.text     "focus_area_description"
    t.text     "category_name_description"
    t.string   "kind"
    t.string   "image_url"
    t.integer  "program_id"
  end

  create_table "results", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "survey_id"
    t.string   "uuid"
    t.string   "key"
    t.string   "value"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "user_id"
  end

  add_index "results", ["user_id"], name: "index_results_on_user_id", using: :btree

  create_table "rules", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "survey_id"
    t.integer  "answer_from_id"
    t.integer  "question_id"
    t.integer  "group_id"
    t.string   "operator"
    t.string   "value"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "uuid"
    t.string   "master_rule_uuid"
  end

  add_index "rules", ["answer_from_id"], name: "index_rules_on_answer_from_id", using: :btree
  add_index "rules", ["group_id"], name: "index_rules_on_group_id", using: :btree
  add_index "rules", ["organization_id"], name: "index_rules_on_organization_id", using: :btree
  add_index "rules", ["question_id"], name: "index_rules_on_question_id", using: :btree
  add_index "rules", ["survey_id"], name: "index_rules_on_survey_id", using: :btree
  add_index "rules", ["uuid"], name: "index_rules_on_uuid", using: :btree

  create_table "sections", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "survey_id"
    t.string   "name"
    t.integer  "position"
    t.text     "more_info"
    t.text     "template"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "uuid"
    t.boolean  "trash",               default: false
    t.text     "start_template"
    t.text     "complete_template"
    t.string   "master_section_uuid"
  end

  add_index "sections", ["organization_id"], name: "index_sections_on_organization_id", using: :btree
  add_index "sections", ["position"], name: "index_sections_on_position", using: :btree
  add_index "sections", ["survey_id"], name: "index_sections_on_survey_id", using: :btree
  add_index "sections", ["uuid"], name: "index_sections_on_uuid", using: :btree

  create_table "surveys", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "user_id"
    t.integer  "master_id"
    t.string   "name"
    t.string   "spreadsheet"
    t.boolean  "has_reached_end",                  default: false
    t.boolean  "complete",                         default: false
    t.text     "start_template"
    t.text     "complete_template"
    t.text     "section_template"
    t.text     "section_start_template"
    t.text     "section_complete_template"
    t.text     "group_template"
    t.text     "question_template"
    t.text     "faq_template"
    t.text     "analytics_template"
    t.text     "report_template"
    t.text     "report_style_template"
    t.text     "report_script_template"
    t.text     "styles_template"
    t.text     "invite_template"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "uuid"
    t.integer  "report_threshold"
    t.integer  "participation_goal"
    t.text     "survey_footer_template"
    t.integer  "finish_number"
    t.boolean  "has_started",                      default: false
    t.datetime "completed_at"
    t.datetime "started_at"
    t.boolean  "allowed_to_submit_answers",        default: true
    t.boolean  "valid_survey",                     default: true
    t.string   "survey_uuid"
    t.integer  "cloned_from_id"
    t.string   "survey_identifier"
    t.text     "survey_results_variables_map"
    t.integer  "survey_year"
    t.date     "finish_date"
    t.text     "survey_notes"
    t.boolean  "create_on_self_signup",            default: false
    t.datetime "finished_updating_from_master_at"
  end

  add_index "surveys", ["master_id"], name: "index_surveys_on_master_id", using: :btree
  add_index "surveys", ["organization_id"], name: "index_surveys_on_organization_id", using: :btree
  add_index "surveys", ["survey_uuid"], name: "index_surveys_on_survey_uuid", using: :btree
  add_index "surveys", ["user_id"], name: "index_surveys_on_user_id", using: :btree
  add_index "surveys", ["uuid"], name: "index_surveys_on_uuid", using: :btree

  create_table "user_fields", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "organization_id"
    t.integer  "master_survey_id"
    t.json     "data"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "user_products", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.integer  "organization_id"
    t.string   "name"
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "uuid"
    t.string   "username"
    t.boolean  "super_admin",                 default: false
    t.boolean  "organization_admin",          default: false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "employee_id"
    t.date     "employee_start_date"
    t.date     "employee_termination_date"
    t.string   "employee_office_location"
    t.string   "employee_state_of_residence"
    t.string   "employee_invite_uuid"
    t.datetime "employee_accepted_invite_at"
    t.string   "saml_idp"
    t.string   "saml_idp_id"
  end

  add_index "users", ["username"], name: "index_users_on_username", using: :btree
  add_index "users", ["uuid"], name: "index_users_on_uuid", using: :btree

end
