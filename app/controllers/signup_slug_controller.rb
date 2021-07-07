class SignupSlugController < ApplicationController
  skip_before_filter :require_user
  layout 'users'

  def show
    session.clear
    session[:continue_signup] = false

    @organization = Organization.where(has_self_signup:true, signup_slug: params[:signup_slug]).first
    @user = User.new

    # If org doesn't require password then forward them to to the form
    if @organization.self_signup_password.blank?
      session[:continue_signup] = true
      redirect_to continue_signup_path(signup_slug: params[:signup_slug])
      return
    end

    if request.post?
      if @organization.self_signup_password.present? && (params[:self_signup_password].to_s.strip == @organization.self_signup_password.to_s.strip)
        session[:continue_signup] = true
        redirect_to continue_signup_path(signup_slug: params[:signup_slug])
        return
      else
        @error_msg = "Password is incorrect"
      end
    end
  end

  def continue_signup
    unless session[:continue_signup] == true
      flash[:message] = "Please contact your admin for a password to continue registration."
      redirect_to signup_slug_path(signup_slug: params[:signup_slug])
      return
    end

    @organization = Organization.where(has_self_signup:true, signup_slug: params[:signup_slug]).first
    @user = User.new

    if request.post?
      @user = @organization.users.new(params_for(User))

      if @user.email.to_s.strip.blank?
        @user.errors.add(:email, "Can't be blank")
      end

      if @user.errors.empty?
        @surveys = @organization.surveys.masters.create_on_self_signup
        @user.save

        @surveys.each do |survey|
          user_survey = @user.surveys.new
          user_survey.master = survey
          user_survey.save
          user_survey.delay.invite_user_to_survey
        end

        if @user.save
          sign_in(@user)
          redirect_to root_path
        end
      else
        @error_msg = @user.errors.full_messages.join("<br>")
        render :continue_signup
      end
    end
  end
end
