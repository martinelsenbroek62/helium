class Question < ActiveRecord::Base
  belongs_to :organization
  belongs_to :survey
  belongs_to :user

  belongs_to :section
  belongs_to :group
  has_many :rules, dependent: :destroy

  default_scope -> { order('position asc') }

  scope :pub, -> { where(trash:false) }
  scope :required, -> { where(required:true, show: true) } # TODO if required and blank... on Home Energy section...
  scope :answered, -> { where.not(answer:"") }
  scope :remaining, -> { required.where(answer:"") }

  before_save do
    self.user_id ||= survey.user_id if survey
    if self.kind =~ /number|integer/i
      self.answer = self.answer.gsub(/[^0-9\.]/, '')
    end
  end

  before_save do
    if answer_changed?
      if kind =~ /checkbox|multiple|radio/i
        self.answer = answer_before_type_cast.join(' || ') if answer_before_type_cast.is_a?(Array)
      end
    end
  end

  after_save do
    if answer_changed?
    end
  end

  def update_from_master!
    attrs = Question.where(uuid: master_question_uuid).first.attributes.except('id', 'uuid', 'master_question_uuid', 'survey_id', 'section_id', 'group_id', 'user_id', 'answer', 'created_at', 'updated_at')
    self.update(attrs)
  end

  def get_rules_from_master!
    return if self.survey.master?

    self.rules.destroy_all # Delete all first

    master_question = Question.where(uuid: master_question_uuid).first
    return unless master_question

    master_question.rules.map do |master_rule|
      rule = self.rules.where(master_rule_uuid: master_rule.uuid, question_id: self.id).first_or_initialize
      rule.assign_attributes(master_rule.attributes.except(
        'id', 'uuid', 'master_rule_uuid',
        'survey_id', 'section_id', 'group_id', 'created_at', 'updated_at', 'answer_from_id'
      ))

      rule.survey_id = self.survey_id
      rule.question_id = self.id

      answer_from = Question.find(master_rule.answer_from_id)
      rule.answer_from_id = Question.where(master_question_uuid: answer_from.uuid, survey_id: survey_id).first.id
      rule.save
    end
  end

  def answer_as_array
    answer.split('|').map(&:strip)
  end

  def xshow_without_group?
    rules.map do |rule|
      rule.evaluate!
    end.flatten.uniq == [true]
  end

  def xshow?
    if group.present? and !group.xshow?
      self.update(show:false)
      return false
    end

    if rules.empty?
      self.update(show:true)
      return true
    end

    result_of_rules = rules.map do |rule|
      rule.evaluate!
    end.flatten.uniq == [true]

    self.update(show:result_of_rules)

    return result_of_rules
  end
  alias_method :visible, :xshow?

  def next
    if next_question = group.questions.where('trash = false and position > ?', position).first
      return next_question
    else
      nil
    end
  end

  def to_liquid
    attributes.merge(
      'organization' => organization,
      'survey' => survey,
      'section' => section,
      'group' => group,
      'rules' => rules,
      'visible' => xshow?,
      'url' => url,
      'group_url' => group_url,
      'more_info' => get_more_info,
      'previous_answers' => (previous_answers rescue []),
      'required' => required?
    )
  end

  def previous_answers
    return [] unless self.show_previous_answers?

    @survey_identifier = self.survey.survey_identifier
    Question.where(
      user_id: user.id,
      question_identifier: self.question_identifier
    ).where.not(survey_id: self.survey_id).reject do |q|
      q.survey.survey_identifier != @survey_identifier
    end.map do |q|
      q.answer
    end.compact.reject(&:blank?).last
  end

  def url
    Rails.application.routes.url_helpers.answer_survey_question_path(survey, self, host: (ENV['DOMAIN']||='localhost:3000'))
  end

  def group_url
    Rails.application.routes.url_helpers.survey_section_group_path(survey, section, group, host: (ENV['DOMAIN']||='localhost:3000')) rescue ''
  end

  def get_more_info
    Liquid::Template.parse(more_info).render('survey'=>survey, 'section' => section, 'group' => group, 'question' => self).to_s.html_safe
  end

  def master_survey_question
    @master_survey_question ||= survey.master.questions.where(key: key, cell: cell).first
  end

  def update_question_identifier_from_master_survey_question
    if master_survey_question
      self.update_column(:question_identifier, master_survey_question.question_identifier)
    end
  end
end
