require 'test_helper'

class Mailer::ClaimsMailerTest < ActionMailer::TestCase
  test "email_admins_about_new_claim_submissions" do
    mail = Mailer::ClaimsMailer.email_admins_about_new_claim_submissions
    assert_equal "Email admins about new claim submissions", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "email_outcome_of_claim_to_user" do
    mail = Mailer::ClaimsMailer.email_outcome_of_claim_to_user
    assert_equal "Email outcome of claim to user", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "email_claim_under_review_to_user" do
    mail = Mailer::ClaimsMailer.email_claim_under_review_to_user
    assert_equal "Email claim under review to user", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
