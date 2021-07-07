class Admin::OrganizationsController < AdminController
  def index
  end

  def new
  end

  def create
    organization = Organization.new(params_for(Organization))
    organization.save
    session[:admin_organization_id] = organization.id
    flash[:notice] = "Organization added"

    redirect_to edit_organization_path(organization)
  end

  def change_to
    organization = Organization.find(params[:id])
    session[:admin_organization_id] = organization.id

    redirect_to organization_path(organization)
  end

  def user_merge
    if request.post?
      emails = []
      params[:from].each_with_index do |email, index|
        next if email.blank?

        user_from = User.find_by(email: params[:from][index])
        user_to = User.find_by(email: params[:to][index])

        Claim.where(user_id: user_from.id).update_all(user_id: user_to.id, organization_id: user_to.organization_id)
        ClaimAttachment.where(user_id: user_from.id).update_all(user_id: user_to.id, organization_id: user_to.organization_id)
        Fund.where(user_id: user_from.id).update_all(user_id: user_to.id, organization_id: user_to.organization_id)
        HistoricalRecord.where(user_id: user_from.id).update_all(user_id: user_to.id)
        Survey.where(user_id: user_from.id).update_all(user_id: user_to.id, organization_id: user_to.organization_id)
        Question.where(user_id: user_from.id).update_all(user_id: user_to.id, organization_id: user_to.organization_id)
        Result.where(user_id: user_from.id).update_all(user_id: user_to.id, organization_id: user_to.organization_id)
        Note.where(user_id: user_from.id).update_all(user_id: user_to.id, organization_id: user_to.organization_id)
        UserField.where(user_id: user_from.id).update_all(user_id: user_to.id, organization_id: user_to.organization_id)

        user_from.update_column(:email, "#{user_from.email}.bak")
      end

      render text: "All done!", layout: false
    end
  end
end
