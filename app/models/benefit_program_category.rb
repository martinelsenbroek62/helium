class BenefitProgramCategory < ActiveRecord::Base
  belongs_to :benefit_program
  belongs_to :benefit_category
end
