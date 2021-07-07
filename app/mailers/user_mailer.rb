class UserMailer < ApplicationMailer

  def invite_user_to_survey(survey)
    @survey = survey
    @user = @survey.user

    mail to: @user.email, subject: "Invitation to Household Sustainability Survey"
  end

  def reset_password(user)
    @user = user
    mail to: @user.email
  end

  def send_message_to_user(survey, message)
    @user = survey.user
    @survey = survey
    @message = message

    mail to: @user.email, subject: @message.subject.to_s
  end

  def send_employee_invite(user)
    @user = user
    @organization = @user.organization

    if @user.employee_invite_uuid.blank?
      @user.update(employee_invite_uuid: SecureRandom.uuid)
    end

    mail to:@user.email, subject: "Welcome to Sustainabli!"
  end
end
