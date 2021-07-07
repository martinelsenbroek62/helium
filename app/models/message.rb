class Message < ActiveRecord::Base
  belongs_to :survey
  belongs_to :organization

  def to_liquid
    {}.merge('organization' => organization, 'survey' => survey, 'user' => survey.user)
  end
end
