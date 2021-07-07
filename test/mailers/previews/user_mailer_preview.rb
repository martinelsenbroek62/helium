# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/invite_user_to_survey
  def invite_user_to_survey
    UserMailer.invite_user_to_survey(Survey.last)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/reset_password
  def reset_password
    UserMailer.reset_password(User.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/send_message_to_user
  def send_message_to_user
    UserMailer.send_message_to_user(Survey.last, Message.last)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/send_employee_invite
  def send_employee_invite
    UserMailer.send_employee_invite(User.first)
  end

end
