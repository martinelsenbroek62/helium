class UserBalanceByProgram < ActiveRecord::Base
  self.table_name = 'user_balances_by_program'

  belongs_to :user
  belongs_to :benefit_program, foreign_key: :program_id
end
