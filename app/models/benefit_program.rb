class BenefitProgram < ActiveRecord::Base
  belongs_to :organization
  has_many :benefit_program_categories
  has_many :benefit_categories, through: :benefit_program_categories
  has_many :claims, through: :benefit_categories
  has_many :funds

  def to_liquid
    self.attributes
  end

  def balance_for_user(user)
    funds_in_program = user.funds.available.where(benefit_program: self).map(&:amount).map(&:to_f).sum
    claims_paid_amount = user.claims.paid_out.where(benefit_category_id: benefit_category_ids).map(&:reimbursement_amount).map(&:to_f).sum

    (funds_in_program - claims_paid_amount)
  end

  def approved_balance_for_user(user)
    # funds_in_program = user.funds.available.where(benefit_program: self).map(&:amount).map(&:to_f).sum
    claims_paid_amount = user.claims.not_rejected_not_paid.where(benefit_category_id: benefit_category_ids).map(&:reimbursement_amount).map(&:to_f).sum

    (claims_paid_amount)
  end

  def to_s
    self.name.present? ? self.name : "Benefit Program"
  end
end
