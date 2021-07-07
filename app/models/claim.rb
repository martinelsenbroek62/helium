class Claim < ActiveRecord::Base
  belongs_to :organization
  belongs_to :created_by, class_name: :User
  belongs_to :user
  belongs_to :product
  belongs_to :reimbursement_rule
  has_many :claim_attachments, dependent: :destroy
  belongs_to :program
  belongs_to :benefit_program
  belongs_to :benefit_category
  has_many :benefit_programs, through: :benefit_category
  has_many :notes, dependent: :destroy

  scope :approved, ->{where(approved:true, paid_out:false) }
  scope :paid_out, ->{where(paid_out:true)}
  scope :not_rejected_not_paid, ->{where(rejected:false, paid_out:false)}

  delegate :percent_to_reimburse, :focus_area, :product_type, :primary_benefit_program,
    to: :benefit_category, allow_nil: true

  attr_accessor :reimbursement_percentage, :send_status_change_email, :url

  validate :claim_is_in_correct_century

  after_initialize do
    self.uuid ||= SecureRandom.uuid
  end

  before_save do
    self.purchase_amount = self.purchase_amount.to_s.gsub(/[^0-9\.]/, '').strip
    self.requesting_amount = self.requesting_amount.to_s.gsub(/[^0-9\.]/, '').strip
    self.reimbursement_amount = self.reimbursement_amount.to_s.gsub(/[^0-9\.]/, '').strip
    assign_remimbursement_rule_to_claim
  end

  def claim_is_in_correct_century
    if self.expensed_date.present?
      if self.expensed_date < 100.years.ago
        errors.add(:expensed_date, "is too old to be valid")
      end
    end
  end

  def assign_remimbursement_rule_to_claim
    if product && product.reimbursement_rule
      self.reimbursement_rule = product.reimbursement_rule
      if self.reimbursement_rule && self.reimbursement_rule.program_id.present?
        self.program_id = self.reimbursement_rule.program_id
      else
        self.program_id = nil
      end
    else
      self.program_id = self.product.try(:program_id)
    end
  end

  def status
    return "Historical" if historical?
    return "Paid" if paid_out?
    return "Payroll" if sent_to_payroll?
    return "Rejected" if rejected?
    return "Incomplete" if incomplete?

    approved? ? "Approved" : "Under Review"
  end

  def status_sort_by(status="")
    status_number = {
      "Under Review" => 1,
      "Incomplete" => 0.5,
      "Approved" => 2,
      "Payroll" => 2.5,
      "Paid" => 3,
      "Rejected" => 4,
      "Historical" => 5,
    }[status]

    unless status_number
      return 99
    else
      return status_number
    end
  end

  def incomplete?
    if proof_of_purchase.blank?
      return true
    end

    if expensed_date.blank? || purchase_amount.blank?
      return true
    end
  end

  def category
    [product.try(:category_name), product.try(:focus_area)].compact.reject(&:blank?).join(",")
  end

  def available_funds
    @available_funds||=user.available_funds
  end

  def available_funds_to_reimburse
    if available_funds >= purchase_amount.gsub(/[^0-9\.]/, '').to_f
      purchase_amount.gsub(/[^0-9\.]/, '').to_f
    else
      available_funds
    end
  end

  def reimbursement_percentage
    product.reimbursement_rule_percentage
  end

  def submitted?
    submitted_at.present?
  end

  def proof_of_purchase
    claim_attachments.where(kind: 'proof_of_purchase').first
  end

  def proof_of_eligibility
    claim_attachments.where(kind: 'proof_of_eligibility').first
  end
  alias_method :proof_eligibility, :proof_of_eligibility

  def proof_of_purchase_url
    return '' unless proof_of_purchase.present?

    proof_of_purchase['secure_url'].to_s
  end

  def proof_of_purchase_content_type
    return '' unless proof_of_purchase.present?

    if proof_of_purchase['resource_type'] == "image"
      "image"
    else
      File.extname(File.basename(proof_of_purchase_url)).upcase.to_s
    end
  end

  def proof_of_eligibility_url
    return '' unless proof_of_eligibility.present?

    proof_of_eligibility['secure_url'].to_s
  end

  def proof_of_eligibility_content_type
    return '' unless proof_of_eligibility.present?

    if proof_of_eligibility['resource_type'] == "image"
      "image"
    else
      File.extname(File.basename(proof_of_eligibility_url)).upcase.to_s
    end
  end

  attr_accessor :set_locked
  before_update do
    if(status =~ /review|reject/i)
      self.locked = false
    else
      self.locked = true
    end

    if [true,false].include?(set_locked)
      self.locked = self.set_locked
    end

    true
  end

  def should_be_locked?
    return true if historical?

    if status =~ /review|reject/i
      false
    else
      true
    end
  end

  def under_review?
    self.submitted_at.present? && !approved? && !rejected?
  end

  def before_under_review?
    self.submitted_at.blank? && !historical? && !rejected?
  end

  def self.by_status(status)
    if status =~ /sent_to_payroll/i
      return where(sent_to_payroll:true, paid_out:false)
    end

    if status =~ /approve/i
      return where(approved:true, paid_out:false, sent_to_payroll:false)
    end

    if status =~ /reject/i
      return where(rejected:true)
    end

    if status =~ /pending/i
      return where(rejected:false,approved:false)
    end

    if status =~ /paid/i
      return where(paid_out: true)
    end

    where.not(id:nil)
  end

  after_create do
    self.delay.email_admins_about_new_claim_submissions unless historical?
    self.delay.email_claim_under_review_to_user
  end

  after_update do
    if self.send_status_change_email && !historical?
      # (submitted_at_changed?) ? self.delay.email_claim_under_review_to_user : nil
      (claim_status_changed?) ? self.delay.email_outcome_of_claim_to_user : nil
    end
  end

  def email_admins_about_new_claim_submissions
    Mailer::ClaimsMailer.email_admins_about_new_claim_submissions(self).deliver
  end

  def email_claim_under_review_to_user
    Mailer::ClaimsMailer.email_claim_under_review_to_user(self).deliver
  end

  def email_outcome_of_claim_to_user
    Mailer::ClaimsMailer.email_outcome_of_claim_to_user(self).deliver
  end

  def claim_status_changed?
    (approved_changed? || rejected_changed? || paid_out_changed?)
  end

  def to_liquid
    self.attributes.merge('url' => url)
  end

  def amount_to_reimburse_as_percent
    (percent_to_reimburse.to_f/100.to_f)
  end

  def available_amount_to_reimburse
    (purchase_amount.to_f * amount_to_reimburse_as_percent)
  end

  def requesting_amount_is_valid?
    # return false
    @requesting_amount_is_valid ||= requesting_amount.to_f <= available_amount_to_reimburse
  end

  def requesting_amount_available_in_program_balance?
    # return true
    @requesting_amount_available_in_program_balance ||= user_program_balance >= requesting_amount.to_f
  end

  def reimbursement_amount_to_f
    self.reimbursement_amount.gsub(/[^0-9\.]/, '').to_f
  end

  def user_program_balance(user_funds_grouped_by_year=nil)
    begin
      bpid = benefit_category.primary_benefit_program.id

      if user_funds_grouped_by_year
        funds_for_claim = user_funds_grouped_by_year
      else
        funds_for_claim = self.user.funds_grouped_by_year
      end

      funds_for_claim = funds_for_claim.select { |grp| grp["benefit_program_id"].to_s==bpid.to_s }.first

      if funds_for_claim
        return funds_for_claim["amount_remaining"].to_f
      else
        return 0
      end
    rescue
      0
    end
  end

  def csv_attributes
    attrs = self.attributes.dup

    user.attributes.each { |k,v| attrs["user_#{k}"] = v } if user
    organization.attributes.each { |k,v| attrs["organization_#{k}"] = v } if organization

    if self.benefit_category.present?
      self.benefit_category.attributes.each { |k,v| attrs["category_#{k}"] = v }
      if self.benefit_category.primary_benefit_program.present?
        self.benefit_category.primary_benefit_program.attributes.each { |k, v| attrs["program_#{k}"] = v }
      end
    end

    attrs
  end

  def self.unified_historical_claims(email=nil)
    CSV.read("#{Rails.root}/data/VEIC_Benefits/unfiledClaims_06262017.csv", headers:true).map do |row|
      row.to_hash
      row["Reimbursement Amount"] = row["Reimbursement Amount"].to_f
      row["Expense Date"] = Date.parse(row["Expense Date"])
      row
    end.select do |row|
      if email
        row["Email"] == email
      else
        row
      end
    end
  end

  def self.import_historical_claims
    CSV.read("#{Rails.root}/data/VEIC_Benefits/allclaims_06262017.csv", headers: true).map do |row|
      puts row.to_hash

      if user = User.find_by(email: row["Email"])
        program = BenefitProgram.find(row["Program ID"])
        category = BenefitCategory.find(row["Category ID"].to_i)

        {
          user: user,
          program: program,
          category: category,
          row: row
        }

        Claim.where(
          organization: user.organization,
          user: user,
          benefit_category: category,
          expensed_date: row["Claim Date"],
          reimbursement_amount: row["Reimbursement Amount"],
          more_info: row["more_info"],
          approved: true,
          paid_out:true,
          historical:true
        ).first_or_initialize
      end
    end
  end
end
