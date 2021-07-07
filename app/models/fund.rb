class Fund < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user
  belongs_to :program
  belongs_to :benefit_program
  belongs_to :benefit_category

  scope :for_active_employees, -> { joins(:user).where('users.employee_termination_date is ?', nil) }
  scope :available, ->{ where('expires_on is null or expires_on >= current_date') }
  scope :unavailable, ->{ where('expires_on < current_date') }

  after_initialize do
    # self.available_on ||= self.created_at
  end

  def expired?
    expires_on && expires_on <= Time.zone.now
  end

  def to_liquid
    attributes.merge(
      'expires_on_year' => (expires_on.stamp('2018') rescue ''),
      'available_on_year' => (available_on.stamp('2018') rescue ''),
      'is_available' => (expires_on >= Date.today rescue ''),
      'has_expired' => (expires_on <= Date.today rescue ''),
      'remaining_balance_for_year' => (remaining_balance_for_year rescue '0.00'),
      'program_name' => (benefit_program.name rescue '')
    )
  end

  def remaining_balance_for_year
    if available_on.present? && expires_on.present?
      a = available_on
      b = expires_on
    elsif expires_on.present? && available_on.blank?
      a = (expires_on - 1.year).beginning_of_year
      b = expires_on
    else # This fund never expires
      a = 100.years.ago
      b = 100.years.from_now
    end

    return '%.2f' % (self.amount.to_f - self.user.claims.paid_out.where('expensed_date between ? and ?', a, b).where.not(reimbursement_amount:nil).map(&:reimbursement_amount_to_f).sum.to_f)
  end

  def self.available_between(expensed_date=nil)
    where('expires_on >= ? or expires_on is null', expensed_date)
  end

  def self.available_between_amount(expensed_date=nil)
    available_between(expensed_date).map(&:amount).map(&:to_f).sum
  end
end
