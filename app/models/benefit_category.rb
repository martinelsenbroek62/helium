class BenefitCategory < ActiveRecord::Base
  belongs_to :organization
  has_many :benefit_program_categories
  has_many :benefit_programs, through: :benefit_program_categories
  # belongs_to :benefit_program
  has_many :claims
  belongs_to :benefit_category
  has_many :benefit_categories

  scope :masters, -> { where(benefit_category_id:nil) }

  def to_liquid
    self.attributes.merge("url" => "/benefit_categories/#{self.id}")
  end

  def primary_benefit_program
    benefit_programs.first || BenefitProgram.new
  end

  def to_s
    self.name.present? ? self.name : "Benefit Category"
  end
end
