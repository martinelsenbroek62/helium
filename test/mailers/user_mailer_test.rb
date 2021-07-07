require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "invite_user_to_survey" do
    mail = UserMailer.invite_user_to_survey
    assert_equal "Invitation to Household Sustainability Survey", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "reset_password" do
    mail = UserMailer.reset_password
    assert_equal "Reset password", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
