class OrganizationsController < ApplicationController
  before_filter :require_organization_admin,  except: [:employee_invitation]
  skip_before_filter :require_user, only: [:employee_invitation]

  def dashboard
    redirect_to organization_claims_path(_organization)
  end

  def show
    redirect_to organization_claims_path(_organization)
    return

    # unless _user.organization
    #   redirect_to surveys_path
    #   return
    # end
    #
    # if _organization.surveys.empty?
    #   redirect_to new_organization_survey_path(_organization)
    # end
  end

  def update
    _organization.update(params_for(Organization))

    if params[:logo]
      _organization.update(logo: Cloudinary::Uploader.upload(params[:logo], resource_type: 'auto'))
    end

    flash[:notice] = "Settings updated"
    redirect_to :back
  end

  def employee_invitation
    session.clear
    @user = User.where(employee_invite_uuid: params[:employee_invite_uuid]).first
    @organization = @user.organization
    @user.employee_accepted_invite_at = Time.zone.now
    # @user.employee_invite_uuid = nil # TODO reset this to expire login link
    @user.save

    session[:user_id] = @user.id
    redirect_to root_path
  end
end
