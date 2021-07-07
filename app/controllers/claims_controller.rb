class ClaimsController < ApplicationController
  layout 'benefits'

  before_filter :handle_invalid_year

  def handle_invalid_year
    if params[:claim]
      if params[:claim][:expensed_date]
        params[:claim][:expensed_date] = (Date.parse(params[:claim][:expensed_date]) rescue params[:claim][:expensed_date])
      end
    end
  end

  def index
  end

  def show
    # _claim.submitted_at = Time.now
    # _claim.approved = true
    # _claim.paid_out = false
    # _claim.rejected = true

    if _claim.rejected?
      render :claim_rejected
      return
    end

    if _claim.approved? && !_claim.paid_out?
      render :claim_under_review
      return
    end

    if _claim.approved? && _claim.paid_out?
      render :claim_approved_and_paid_out
      return
    end

    if _claim.submitted_at.blank?
      render :claim_review_and_submit
      return
    end

      render :claim_review_and_submit
  end

  def edit
    # if _claim.locked? && !_user.super_admin?
    #   flash[:notice] = "This claim can no longer be edited"
    #   redirect_to _claim
    # end
    if _claim.approved? || _claim.paid_out?
      redirect_to _claim
    end
  end

  def create
    if params[:benefit_program] && params[:benefit_program][:id].present?
      @benefit_program = _organization.benefit_programs.where(id:params[:benefit_program][:id]).first
    end

    if params[:benefit_category] && params[:benefit_category][:id].present?
      @benefit_category = _organization.benefit_categories.where(id:params[:benefit_category][:id]).first
    end

    claim = _user.claims.new(params_for(Claim))
    claim.organization = _user.organization
    claim.created_by = _user

    attachments_for_claim(claim)

    claim.benefit_program = @benefit_program
    claim.benefit_category = @benefit_category
    if claim.save
      redirect_to claim
    else
      flash[:error] = claim.errors.full_messages.join
      @the_claim = claim
      render template: "benefit_categories/show"
    end
  end

  def _benefit_category
    if @_claim
      return @_claim.benefit_cateogry
    end

    if @the_claim
      return @the_claim.benefit_category
    end

    BenefitCategory.new
  end
  helper_method :_benefit_category

  def update
    if params[:benefit_program] && params[:benefit_program][:id].present?
      @benefit_program = _organization.benefit_programs.where(id:params[:benefit_program][:id]).first
    end

    if params[:benefit_category] && params[:benefit_category][:id].present?
      @benefit_category = _organization.benefit_categories.where(id:params[:benefit_category][:id]).first
    end

    _claim.assign_attributes(params_for(Claim))

    attachments_for_claim(_claim)

    _claim.benefit_program = @benefit_program if @benefit_program
    _claim.benefit_category = @benefit_category if @benefit_category
    _claim.rejected = false #

    _claim.save

    if _claim.purchase_amount.present? && _claim.expensed_date.present?
      if _claim.proof_of_purchase.present?
        _claim.update(submitted_at: Time.zone.now)
      else
        flash[:notice] = "Your claim is missing information. Please make sure you have attached proof of purchase."
      end
    else
      flash[:notice] = "Your claim is missing information. Please make sure purchase price and expensed date are provided."
    end

    redirect_to (_claim)
  end

  def change_benefit_category
    return unless request.post?

    benefit_category = _organization.benefit_categories.find_by(uuid: params[:benefit_category])
    _claim.update(benefit_category: benefit_category)

    redirect_to edit_claim_path(_claim)
  end

  private

  def attachments_for_claim(claim)
    if params[:attachment_for_proof_of_purchase]
      (params[:attachment_for_proof_of_purchase]||[]).each do |attachment|
        next if attachment.blank?
        document = Cloudinary::Uploader.upload(attachment, resource_type: 'auto')
        claim_attachment = claim.claim_attachments.new(kind: 'proof_of_purchase', user: _user, organization: _user.organization, attachment: document)
        claim_attachment.save
      end
    end

    if params[:attachment_for_proof_of_eligibility]
      (params[:attachment_for_proof_of_eligibility]||[]).each do |attachment|
        next if attachment.blank?
        document = Cloudinary::Uploader.upload(attachment, resource_type: 'auto')
        claim_attachment = claim.claim_attachments.new(kind: 'proof_of_eligibility', user: _user, organization: _user.organization, attachment: document)
        claim_attachment.save
      end
    end
  end
end
