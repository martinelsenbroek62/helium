class Group < ActiveRecord::Base
  belongs_to :organization
  belongs_to :survey
  belongs_to :section

  has_many :questions, dependent: :destroy
  has_many :rules, dependent: :destroy

  default_scope -> { order('position asc') }
  scope :pub, -> { where(trash:false) }

  def update_from_master!
    attrs = Group.where(uuid: self.master_group_uuid).first.attributes.except('id', 'uuid', 'master_group_uuid','survey_id', 'section_id', 'user_id', 'created_at', 'updated_at')
    self.update(attrs)
  end

  def xshow?
    return false if questions.empty?

    if rules.empty?
      return true
    end

    rules_applied = rules.map do |rule|
      rule.evaluate!
    end.flatten.uniq == [true]

    puts "[rules: #{rules_applied}]"
    return rules_applied
  end

  def next
    section.groups.where('trash = false and position > ?', position).first
  end

  def prev
    section.groups.where('trash = false and position < ?', position).last
  end

  def percent_complete
    (questions.required.where.not(answer:"").count.to_f / questions.required.count.to_f) * 100
  end

  def to_liquid
    attributes.merge(
      'organization' => organization,
      'section' => section,
      'questions' => questions,
      'rules' => rules,
      'url' => url,
      'next' => self.next,
      'prev' => self.prev,
      'more_info' => get_more_info
    )
  end

  def url
    Rails.application.routes.url_helpers.survey_section_group_url(survey, section, self, host: (ENV['DOMAIN']||='localhost:3000'))
  end

  def get_more_info
    Liquid::Template.parse(more_info).render('survey'=>survey, 'section' => section, 'group' => self).to_s.html_safe
  end
end
