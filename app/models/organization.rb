class Organization < ActiveRecord::Base
  has_many :users
  has_many :surveys
  has_many :messages
  has_many :claims
  has_many :funds
  has_many :products
  has_many :reimbursement_rules
  has_many :programs
  has_many :benefit_programs
  has_many :benefit_categories
  has_many :notes
  has_many :pages
  has_many :offers

  default_scope { where.not(id: [1,2,3,4,5,6])}

  after_initialize do
    self.headers_for_claims_export ||= "user.id user.email claim.id claim.title"
    self.benefit_welcome = self.benefit_welcome.present? ? self.benefit_welcome : File.read("#{Rails.root}/app/views/surveys/templates/benefits_home.html")
    self.benefit_categories_template = self.benefit_categories_template.present? ? self.benefit_categories_template : File.read("#{Rails.root}/app/views/surveys/templates/benefit_categories.html")
    self.benefit_claims_form = self.benefit_claims_form.present? ? self.benefit_claims_form : File.read("#{Rails.root}/app/views/surveys/templates/benefit_claims_form.html")
    self.email_claim_status_template = self.email_claim_status_template.present? ? self.email_claim_status_template : File.read("#{Rails.root}/app/views/templates/email_claim_status_template.liquid")
  end

  def to_liquid
    attributes.merge('users' => users, 'surveys' => surveys)
  end

  def logo_url

    return 'https://placehold.it/150x150' unless logo.present?

    logo['secure_url']
  end

  def template(file)
    unless self.benefit_welcome.present?
      file_path = "#{Rails.root}/app/views/surveys/templates/#{file}"
      if File.exists?(file_path)
        File.read(file_path)
      else
        ""
      end
    else
      self.benefit_welcome
    end
  end
end
