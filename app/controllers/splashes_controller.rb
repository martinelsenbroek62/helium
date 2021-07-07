class SplashesController < ApplicationController
  skip_before_filter :require_user

  layout 'users'

  before_filter do
    if session[:user_id]
      redirect_to root_path # No anonymous surveys for logged in users
    end

    unless initialize_organization_and_survey
      redirect_to login_path
    end
  end

  def show
  end


  # survey = user.surveys.new
  # survey.master = _survey
  # survey.save
  # def setup_spreadsheet_and_user_survey!
  #   copy!
  #   update_from_master!
  # end

  def create_anonymous_survey
    tmp_username = SecureRandom.uuid.split("-").first

    @user = User.create(username: tmp_username)
    # @user_survey = @organization.surveys.new
    # @user_survey.user = @user
    # @user_survey.master = @survey
    # @user_survey.save
    # @user_survey.setup_spreadsheet_and_user_survey!

    @user_survey = @survey.clone_survey!
    @user_survey.user = @user
    @user_survey.save
    sign_in(@user)
    flash[:notice]="Please complete your profile information"

    render json: [@user, @user_survey].to_json
  end

  def initialize_organization_and_survey
    @organization = Organization.find_by(uuid: params[:organization_uuid])
    @survey = Survey.find_by(survey_uuid: params[:survey_uuid])

    @organization && @survey && @survey.master?
  end
end
