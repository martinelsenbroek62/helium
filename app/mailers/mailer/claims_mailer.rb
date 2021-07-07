class Mailer::ClaimsMailer < ApplicationMailer
  def email_admins_about_new_claim_submissions(claim)
    @claim = claim
    @organization = @claim.organization
    @admin_emails = @organization.admin_emails.to_s.scan(/\S+[a-z0-9]@[a-z0-9\.]+/im)

    if @admin_emails.present?
      mail to: @admin_emails, subject: "A benefit request has been submitted"
    end
  end

  def email_outcome_of_claim_to_user(claim)
    @claim = claim
    @organization = @claim.organization

    if (@claim.approved == true) && (@claim.paid_out != true)
      mail to: @claim.user.email, subject: "Your benefit request has been approved"

    elsif @claim.rejected?
      mail to: @claim.user.email, subject: "Your benefit request has been rejected"

    elsif @claim.paid_out?
      mail to: @claim.user.email, subject: "Your benefit request has been paid"

    else
      mail to: @claim.user.email, subject: "Your benefit request has been reviewed"

    end
  end

  def email_claim_under_review_to_user(claim)
    @claim = claim
    @organization = @claim.organization

    mail to: @claim.user.email, subject: "Your benefit request has been submitted"
  end
end
