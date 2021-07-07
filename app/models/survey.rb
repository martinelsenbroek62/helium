class Survey < ActiveRecord::Base
  include SpreadsheetConcern

  belongs_to :organization
  belongs_to :user
  belongs_to :master, class_name: :Survey

  has_many :sections, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :rules, dependent: :destroy
  has_many :surveys, foreign_key: :master_id, dependent: :destroy
  has_many :users, through: :surveys
  has_many :results, dependent: :destroy
  has_many :historical_records, dependent: :destroy
  has_many :messages, dependent: :destroy

  scope :masters, -> { where(master_id:nil) }
  scope :children, -> { where.not(master_id: nil) }
  scope :finishers, -> { where(complete: true) }
  scope :not_yet_started, -> { where(has_started:false) }
  scope :has_started, -> { where(has_started:true) }
  scope :in_progress, -> { has_started.where(complete: false) }
  scope :complete, -> { where(complete: true) }
  scope :incomplete, -> { where.not(complete: true) }
  scope :valid, -> { where(valid_survey: true) }
  scope :invalid, -> { where.not(valid_survey: true) }
  scope :create_on_self_signup, -> { where(create_on_self_signup: true)}

  scope :for_active_employees, -> { joins(:user).where('users.employee_termination_date is null') }

  after_initialize do
    self.survey_uuid ||= SecureRandom.uuid

    if master?
      self.analytics_template ||= File.read("#{Rails.root}/app/views/surveys/templates/analytics_template.html")
      self.start_template ||= File.read("#{Rails.root}/app/views/surveys/templates/start_template.html")
      self.complete_template ||= File.read("#{Rails.root}/app/views/surveys/templates/complete_template.html")
      self.question_template ||= File.read("#{Rails.root}/app/views/surveys/templates/question_template.html")
      self.group_template ||= File.read("#{Rails.root}/app/views/surveys/templates/group_template.html")
      self.section_template ||= File.read("#{Rails.root}/app/views/surveys/templates/section_template.html")
      self.section_start_template ||= File.read("#{Rails.root}/app/views/surveys/templates/section_start_template.html")
      self.section_complete_template ||= File.read("#{Rails.root}/app/views/surveys/templates/section_complete_template.html")

      self.survey_footer_template ||= File.read("#{Rails.root}/app/views/surveys/templates/survey_footer_template.html")

      self.report_script_template ||= File.read("#{Rails.root}/app/views/surveys/templates/report_script_template.js")
      self.report_style_template ||= File.read("#{Rails.root}/app/views/surveys/templates/report_style_template.css")
      self.report_template ||= File.read("#{Rails.root}/app/views/surveys/templates/report_template.html")
      self.styles_template ||= File.read("#{Rails.root}/app/views/surveys/templates/styles_template.css")
      self.faq_template ||= File.read("#{Rails.root}/app/views/surveys/templates/faq_template.html")

      self.invite_template ||= File.read("#{Rails.root}/app/views/surveys/templates/invite_template.text")
    end
  end

  before_save do
    if complete_changed?
      if complete?
        self.finish_number ||= (finishers_count + 1)
      end
    end
  end

  attr_accessor :only_import_report_questions

  def related_surveys
    if self.user
      self.user.surveys.where(survey_identifier: self.survey_identifier).where.not(id: self.id)
    else
      []
    end
  end

  def variable_map
    begin
      JSON.parse(survey_results_variables_map)
    rescue
      {}
    end
  end

  def related_survey_results
    self.related_surveys.map do |survey|
      data = {"year" => survey.get_survey_year}
      survey.results.map do |result|
        result.slice("key", "value")
      end.map do |result|
        if variable_map.has_key?(result[:key])
          result["key"] = variable_map[result[:key]]
        end

        result
      end.each do |row|
        data[row["key"]] = row["value"]
      end

      {
        name: survey.name,
        year: survey.get_survey_year,
        results: data
      }
    end
  end

  def get_survey_year
    self.survey_year.to_i||=self.created_at.stamp('2015')
  end

  def has_completed_survey?
    questions.remaining.blank?
  end

  def update_all_positions
  end

  def percent_complete
    begin
      (questions.required.where.not(answer:"").count.to_f / (questions.required.count.to_f) * 100).round(0)
    rescue
      0.0
    end
  end

  def invalid
    !valid_survey
  end

  def master?
    master_id.blank?
  end

  def import_historical_records_from(csv_file="tmp/historical.csv", create_user_survey=true)
    return unless master?
    return unless File.exists?(csv_file)

    data = File.read(csv_file).split("\n")
    rows = data.map { |record| record.split(",") }
    headers = rows[0].map(&:underscore)
    records = rows[1..-1].map { |record| Hash[headers.zip(record)] }
    records.each do |record|

      if user = User.where(email: record['email']).first # _or_create # create user if they don't exist
        if user
          if create_user_survey
            surveys.where(user_id: user.id).first_or_create
          end

          unless user.name
            user.update(name: record['full_name'])
          end

          year = record['year']

          historical_record = historical_records.where(
            user_id:    user.id,
            survey_id:  id,
            year: year).first_or_create

          historical_record.update(data: record)
          historical_record
        end
      end
    end
  end

  def update_from_master!
    return if master?

    self.update(
      name: master.name,
      survey_identifier: master.survey_identifier,
      survey_year: master.survey_year
    )

    master.sections.each do |master_section|
      section = self.sections.where(master_section_uuid: master_section.uuid, survey_id: self.id).first_or_create
      section.update_from_master!

      master_section.groups.each do |master_group|
        group = section.groups.where(master_group_uuid: master_group.uuid, survey_id:self.id, section_id:section.id).first_or_create
        group.update_from_master!

        master_group.questions.each do |master_question|
          question = group.questions.where(master_question_uuid: master_question.uuid, survey_id:self.id, section_id:section.id, group_id:group.id).first_or_create
          question.update_from_master!
        end
      end
    end

    questions.each do |question|
      question.get_rules_from_master!
    end

    self.update(finished_updating_from_master_at:Time.now)
  end

  def update_from_master_old!
    return if master?

    self.update(
      name: master.name,
      survey_identifier: master.survey_identifier
    )

    master.sections.each_with_index do |section, section_index|
      _section = self.sections.where(name: section.name, survey_id:id).first_or_create
      _section.assign_attributes(section.attributes.except('id', 'uuid', 'survey_id', 'user_id', 'created_at', 'updated_at'))
      _section.master_section_uuid = section.uuid
      _section.save

      section.groups.each_with_index do |group, group_index|
        _group = _section.groups.where(name: group.name, survey_id:id, section_id:_section.id).first_or_create
        _group.assign_attributes(group.attributes.except('id', 'uuid', 'survey_id', 'section_id', 'user_id', 'created_at', 'updated_at'))
        _group.master_group_uuid = group.uuid
        _group.save

        group.questions.each_with_index do |question, question_index|
          _question = _group.questions.where(key:question.key, section_id:_section.id, survey_id:id,group_id:_group.id).first_or_create
          _question.assign_attributes(question.attributes.except('id', 'uuid', 'survey_id', 'section_id', 'group_id', 'user_id', 'answer', 'created_at', 'update_at').merge('survey_id' => id, 'section_id' => _section.id))
          _question.master_question_uuid = question.uuid
          _question.save
        end
      end
    end

    sections.each do |section|
      section.groups.pub.each_with_index do |group, group_index|
      end
    end

    self.rules.destroy_all
    self.master.rules.each do |rule|
      master_group = nil
      self_group = nil
      master_question = nil
      self_question = nil

      # if rule.group_id.present?
      #   if master_group = Group.find(rule.group_id)
      #     self_group = self.groups.where(name: master_group.name, position:master_group.position).first
      #   end
      # end

      if rule.question_id.present?
        if master_question = Question.find(rule.question_id)
          self_question = self.questions.where(key: master_question.key).first
        end
      end

      master_answer_from = Question.find(rule.answer_from_id)
      self_answer_from = self.questions.where(key: master_answer_from.key).first

      self_rule = self.rules.new(operator:rule.operator, value:rule.value)

      self_rule.group = self_group
      self_rule.question = self_question
      self_rule.answer_from = self_answer_from
      self_rule.master_rule_uuid = rule.uuid
      self_rule.save!
    end
  end

  def template(template_file="")
    # ENV['RENDER_DEFAULT_TEMPLATES'] = 'No'
    if ENV['RENDER_DEFAULT_TEMPLATES'].to_s =~ /yes/i
      if File.exists?("#{Rails.root}/app/views/surveys/templates/#{template_file}")
        return File.read("#{Rails.root}/app/views/surveys/templates/#{template_file}")
      end
    end

    template_file = File.basename(template_file, '.*')

    if respond_to?(template_file)
      if master?
        send(template_file)
      else
        master.send(template_file)
      end
    end
  end

  def to_liquid
    attributes.merge(
      'organization' => organization,
      'user' => user,
      'master' => master,
      'sections' => sections,
      'groups' => groups,
      'questions' => questions,
      'rules' => rules,
      'url' => url,
      'finishers_count' => finishers_count,
      'in_progress_count' => in_progress_count,
      'total_count' => surveys_in_total_count
    ).except(*attributes.keys.grep(/template|_id$/))
  end

  def url
    Rails.application.routes.url_helpers.survey_url(self, host: (ENV['DOMAIN']||='localhost:3000'))
  end

  def finishers_count
    @finishers_count ||= (master? ? self : master.surveys.finishers.count)
  end

  def in_progress_count
    @in_progress_count ||= (master? ? self : master.surveys.in_progress.count)
  end

  def surveys_in_total_count
    @surveys_in_total_count ||= (master? ? self : master.surveys.count)
  end

  def continue_at_question
    if questions.answered.any?
      questions.reorder('updated_at desc').first
    end
  end

  def setup_spreadsheet_and_user_survey!
    copy!
    update_from_master!
  end

  # queued via background job using delay
  # surveys.all.map(&:invite_user_to_survey)
  def invite_user_to_survey
    setup_spreadsheet_and_user_survey!

    UserMailer.invite_user_to_survey(self).deliver
  end

  def reinvite_user_to_survey
    if questions.empty?
      setup_spreadsheet_and_user_survey!
    end

    UserMailer.invite_user_to_survey(self).deliver
  end

  def send_message_to_user(message=nil)
    return unless message

    UserMailer.send_message_to_user(self, message).deliver
  end

  def self.regional_averages
    data = File.read("#{Rails.root}/data/RegionalAverages.csv").split("\n")
    headers = data[0].split(",").map(&:downcase)
    _regional_averages = {}

    data[1..-1].map do |row|
      row = Hash[headers.zip(row.split(",").map(&:strip))]
      _regional_averages[row['region'].to_s.downcase] ||= {'year'=>row['year']}
      _regional_averages[row['region'].to_s.downcase][row['characteristic']] = row['value (metric tons co2e/year)']
    end

    _regional_averages
  end

  def clone_survey!
    master_survey = self.master? ? self : self.master

    new_survey = Survey.new
    new_survey.master_id = master_survey.id
    new_survey.organization = master_survey.organization
    new_survey.save
    new_survey.copy!
    new_survey.update_from_master!
    new_survey
  end

  def attr
    self.attributes.reject { |k,v| k=~/template/i }
  end
end
