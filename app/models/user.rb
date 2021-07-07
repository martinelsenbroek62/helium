class User < ActiveRecord::Base
  belongs_to :organization
  has_many :surveys, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :user_fields, dependent: :destroy
  has_many :historical_records, dependent: :destroy
  has_many :created_claims, foreign_key: :created_by_id, class_name: :Claim, dependent: :nullify
  has_many :funds, dependent: :destroy
  has_many :claims, ->{ where(historical:false) }, dependent: :destroy
  has_many :historical_claims, ->{where(historical:true)}, dependent: :destroy, class_name: :Claim
  has_many :user_products, dependent: :destroy
  has_many :products, through: :user_products
  has_many :notes, dependent: :destroy
  has_many :authored_notes, foreign_key: :author_id, class_name: :Note
  has_many :benefit_programs, through: :funds
  scope :active_employees, -> { where(employee_termination_date: nil) }
  scope :terminated_employees, -> { where.not(employee_termination_date: nil) }

  attr_accessor :password, :password_confirmation

  validates :email, uniqueness: { scope: :organization_id, :message => "is already taken"}

  before_validation do
    if self.password_hash.blank?
      self.password ||= self.uuid.split('-').first
    end

    encrypt_password
  end

  before_save do
    self.email = email.to_s.downcase
    self.name = [self.first_name, self.last_name].join(" ") if first_name_changed? || last_name_changed?
  end

  def to_s
    self.name.present? ? self.name.to_s : self.email.to_s
  end

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = User.encrypt_password(password, password_salt)
    end
  end

  def self.encrypt_password(password="", salt="")
    BCrypt::Engine.hash_secret(password, salt)
  end

  def self.login(email_or_username="", password="")
    user = find_by(email: email_or_username)
    unless user
      user = find_by(username: email_or_username)
    end

    if user && user.password_hash == self.encrypt_password(password, user.password_salt)
      return user
    else
      return nil
    end
  end

  def default_password
    (self.token||=SecureRandom.uuid).to_s.split("-").first
  end

  def nickname
    if nname = name.to_s.split(' ').first
      nname
    else
      email
    end
  end

  def full_name
    return name if self.name.present?
    return [first_name, last_name].compact.reject(&:blank?).join(" ")
  end

  def to_liquid
    attributes.merge(
      'organization' => organization,
      'surveys' => surveys,
      'login_url' => login_url,
      'funds'=>funds
    )
  end

  def send_reset_password
    UserMailer.reset_password(self).deliver
  end

  def login_url
    Rails.application.routes.url_helpers.login_with_token_url(uuid, host: (ENV['DOMAIN']||='localhost:3000'))
  end

  def available_funds
    @available_funds||=funds.where('expires_on is null or expires_on >= current_date').map(&:amount).map(&:to_f).sum - claims_sum
  end
  alias_method :current_balance, :available_funds

  def claims_sum
    @claims_sum||=claims.where(approved:true).map(&:reimbursement_amount).map(&:to_f).sum
  end

  def date_of_last_deposit
    funds.last.try(:created_at)
  end

  def send_employee_invite
    UserMailer.send_employee_invite(self).deliver
  end

  def expensed_date_of_last_claim
    claims.paid_out.where.not(expensed_date:nil).order('expensed_date asc').last.try(:expensed_date)
  end

  def terminated?
    self.employee_termination_date.present?
  end

  def benefit_program_funds
    return @benefit_program_funds if defined?(@benefit_program_funds)

    cls = {}
    claims.paid_out.map do |claim|
      begin
        benefit_program_id = claim.benefit_category.primary_benefit_program.id
        amount = claim.reimbursement_amount.gsub(/[^0-9\.]/, '').to_f
        cls[benefit_program_id] ||= 0
        cls[benefit_program_id] += amount
      rescue
        nil
        # raise claim.inspect
      end
    end

    bp = {}
    funds.each do |fund|
      bp[fund.benefit_program_id] ||= 0
      bp[fund.benefit_program_id] += fund.amount
      bp
    end

    nbp = {}
    bp.each do |key, value|
      name = BenefitProgram.where(id:key).first.try(:name)
      spent = cls[key] || 0
      nbp[name] = {
        id: key,
        amount: value,
        name: name,
        spent: spent,
        balance: value - spent
      }
    end

    @benefit_program_funds = nbp
  end

  def funds_grouped_by_year
    begin
      return self.funds.group_by { |f|
        { available: f.available_on, expires: f.expires_on, benefit_program_id: f.benefit_program_id}
      }.map { |group, the_funds|
        the_amount = the_funds.map(&:amount).map(&:to_f).sum
        if group[:available].present? && group[:expires].present?
          a = group[:available]
          b = group[:expires]
        elsif group[:expires].present? && group[:available].blank?
          a = group[:expires].to_date - 1.year
          b = group[:expires].to_date
        else
          a = 100.years.ago
          b = 100.years.from_now
        end

        bp = BenefitProgram.find(group[:benefit_program_id])
        ids = bp.benefit_category_ids

        the_amount_spent = claims.paid_out.where(benefit_category_id:ids).where('expensed_date between ? and ?', a, b).where.not(reimbursement_amount:nil).map(&:reimbursement_amount_to_f).sum.to_f
        the_amount_remaining = the_amount - the_amount_spent

        begin
          is_expired = group[:expires] + 32.days <= Date.today
        rescue
          is_expired = false
        end

        {
          "expiration_date" => group[:expires],
          "is_expired" => is_expired,
          "available_year" => group[:available].try(:stamp, '2017'),
          "expires_year" => group[:expires].try(:stamp, '2018'),
          "program_name" => (the_funds.first.benefit_program.name rescue ''),
          "amount_total" => ("%.2f" % the_amount),
          "amount_remaining" => ("%.2f" % the_amount_remaining),
          "benefit_program_id" => group[:benefit_program_id]
        }
    }
    rescue
      []
    end
  end
end
