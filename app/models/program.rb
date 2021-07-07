class Program < ActiveRecord::Base
  belongs_to :organization
  has_many :claims, dependent: :nullify
  has_many :funds, dependent: :nullify
  has_many :reimbursement_rules, dependent: :nullify
  has_many :products, dependent: :nullify
end
