# Preview all emails at http://localhost:3000/rails/mailers/mailer/claims_mailer
class Mailer::ClaimsMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/mailer/claims_mailer/email_admins_about_new_claim_submissions
  def email_admins_about_new_claim_submissions
    Mailer::ClaimsMailer.email_admins_about_new_claim_submissions(the_claim)
  end

  # Preview this email at http://localhost:3000/rails/mailers/mailer/claims_mailer/email_outcome_of_claim_to_user
  def email_outcome_of_claim_to_user
    Mailer::ClaimsMailer.email_outcome_of_claim_to_user(the_claim)
  end

  # Preview this email at http://localhost:3000/rails/mailers/mailer/claims_mailer/email_claim_under_review_to_user
  def email_claim_under_review_to_user
    Mailer::ClaimsMailer.email_claim_under_review_to_user(the_claim)
  end

  def the_claim
    User.find_by(email:"jjuillerat@veic.org").claims.last
  end

end
