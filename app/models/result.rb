class Result < ActiveRecord::Base
  belongs_to :organization
  belongs_to :survey

  before_save do
    self.user_id ||= survey.user_id if survey
  end
end
