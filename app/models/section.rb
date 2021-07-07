class Section < ActiveRecord::Base
  belongs_to :organization
  belongs_to :survey
  has_many :groups, dependent: :destroy
  has_many :questions, dependent: :destroy

  default_scope -> { order('position asc') }
  scope :pub, -> { where(trash:false) }

  def next
    survey.sections.where('trash = false and position > ?', position).first
  end

  def prev
    survey.sections.where('trash = false and position < ?', position).last
  end

  def update_from_master!
    attrs = Section.where(uuid: master_section_uuid).first.attributes.except('id', 'uuid', 'master_section_uuid', 'survey_id', 'user_id', 'created_at', 'updated_at')
    self.update(attrs)
  end

  def percent_complete
    begin
      pc = ((questions.required.answered.count.to_f / questions.required.count ) * 100).round(0) || 0
      if pc.is_a?(Numeric)
        pc
      else
        0
      end
    rescue
      0
    end
  end

  def to_liquid
    attributes.merge(
      'organization' => organization,
      'survey' => survey,
      'groups' => groups,
      'questions' => questions,
      'percent_complete' => percent_complete,
      'next' => self.next,
      'prev' => self.prev,
      'url' => url
    )
  end

  def url
    Rails.application.routes.url_helpers.survey_section_url(survey, self, host: (ENV['DOMAIN']||='localhost:3000'))
  end

  def template(template_file="")
    # ENV['RENDER_DEFAULT_TEMPLATES'] = "No"
    if ENV['RENDER_DEFAULT_TEMPLATES'].to_s =~ /yes/i
      if File.exists?("#{Rails.root}/app/views/surveys/templates/#{template_file}")
        return File.read("#{Rails.root}/app/views/surveys/templates/#{template_file}")
      end
    end


    template_file = File.basename(template_file, '.*')

    if respond_to?(template_file)
      uniq_template = send(template_file)

      if uniq_template.present?
        return uniq_template
      else
        return survey.template("section_#{template_file}.html")
      end
    end
  end
end
