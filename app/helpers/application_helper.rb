module ApplicationHelper
  def _organizations
    Organization
  end

  def _sections
    _survey.sections
  end

  def _groups
    _survey.groups
  end

  def _questions
    _survey.questions
  end

  def _organization
    @organization ||= if _user.super_admin?
        (session[:admin_organization_id] && Organization.find(session[:admin_organization_id]) || _user.organization)
      else
        _user.organization
      end
  end

  def _survey
    @_survey ||= _organization.surveys.where(id:params[:survey_id]||params[:id]).first
  end

  def _user
    @_user ||= session[:user_id] && User.find(session[:user_id])
  end

  def _program
    @_program ||= _organization && _organization.programs.where(id:params[:program_id]||params[:id]).first
  end

  def _benefit_program
    @_benefit_program ||= _organization && _organization.benefit_programs.where(id:params[:benefit_program_id]||params[:id]).first
  end

  def _benefit_category
    @_benefit_category ||= _organization && _organization.benefit_categories.where(id:params[:benefit_category_id]||params[:id]).first
  end

  def _logged_in_as
    @_logged_in_as ||= if _user.super_admin? && session[:logged_in_as_id]
      session[:logged_in_as_id] && User.find(session[:logged_in_as_id])
    else
      _user
    end
  end

  def _section
    @_section ||= _sections.where(id:params[:section_id]||params[:id]).first
  end

  def _group
    @group ||= _groups.where(id:params[:group_id]||params[:id]).first
  end

  def _question
    @question ||= _questions.where(id:params[:question_id]||params[:id]).first
  end

  def _rule
    @_rule ||= _survey.rules.where(id:params[:rule_id]||params[:id]).first
  end

  def _message
    @_message ||= _survey.messages.where(id:params[:message_id]||params[:id]).first
  end

  def _claim
    @_claim ||= if (_user.super_admin?)
      Claim.where(id:params[:claim_id]||params[:id]).first
    elsif (_user.super_admin? || _user.organization_admin?)
      Claim.find_by(id: (params[:claim_id]||params[:id]), organization_id: _user.organization_id)
    else
      Claim.find_by(id: (params[:claim_id]||params[:id]), user_id: _user.id)
    end
  end

  def _person
    @_person ||= _organization.users.where(id:params[:person_id]||params[:id]).first
  end

  def _product
    @_product ||= Product.where(id:params[:product_id]||params[:id]).first
  end

  def _reimbursement_rule
    @_reimbursement_rule ||= ReimbursementRule.where(id:params[:reimbursement_rule_id]||params[:id]).first
  end

  def super_admin?
    @super_admin ||= _user && _user.super_admin?
  end

  def organization_admin?
    @organization_admin ||= _user && _user.organization_admin?
  end

  def _page
    @_page ||= _organization.pages.where(slug: params[:id]).first
  end

  def _offer
    @_offer ||= _organization.offers.where(id: params[:id]).first
  end

  def require_super_admin
    unless super_admin?
      render text: "You are not permitted to access this page", status: :unauthorize
    end
  end

  def require_organization_admin
    unless (super_admin? || organization_admin?)
      redirect_to products_path
    end
  end

  def params_for(model)
    if params[model.name.underscore.to_sym]
      params.require(model.name.underscore.to_sym).permit(model.column_names.reject { |column| column =~ /id$/i })
    else
      {}
    end
  end

  def sign_in(user)
    session[:user_id] = user.id
  end

  def number_to_currency(amount, opts={})
    if amount.blank?
      amount = 0
    end

    super(amount, opts)
  end

  # Filters

  def require_user
    unless _user
      redirect_to login_path
      return
    end
  end
end
