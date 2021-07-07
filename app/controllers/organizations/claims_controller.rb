class Organizations::ClaimsController < OrganizationsController
  def bulk
    @claims = Claim.where(uuid: (params[:move_claim_ids]||"").split(","))

    case params[:move_to]
    when /payroll/i
      @claims.update_all(
        approved:true,
        rejected:false,
        sent_to_payroll:true,
        paid_out:false
      )
    when /paid/i
      @claims.update_all(
        approved:true,
        rejected:false,
        paid_out:true,
        sent_to_payroll:true,
      )
    when /approved/i
      @claims.update_all(
        approved: true,
        rejected:false,
        paid_out:false,
        sent_to_payroll:false,
      )
    when /reject/i
      @claims.update_all(
        rejected: true,
        approved:false,
        paid_out:false,
        sent_to_payroll:false,
      )
    when /pending/i
      @claims.update_all(
       rejected:false,
       approved:false,
       paid_out:false,
       sent_to_payroll:false,
      )
    end

    redirect_to :back
  end

  def create
    # This is nil sometimes (FIX)
    user = _organization.users.where(id: params[:user_id]).first

    claim = user.claims.new(params_for(Claim))
    claim.organization = _organization
    claim.created_by = _user

    attachments_for_claim(claim)

    if params[:product].present?
      focus_area = params[:product][:focus_area]
      category_name = params[:product][:category_name]
    else
      focus_area = ""
      category_name = ""
    end

    product_name = claim.title
    product = _organization.products.where(focus_area: focus_area, category_name: category_name, name: product_name).first_or_create
    claim.product = product

    # claim.reimbursement_rule =
    # claim.program = claim.reimbursement_rule.program

    claim.save!

    redirect_to claim
  end

  def reimburse
    _claim.assign_attributes(params_for(Claim))

    if params[:send_email] && params[:send_email]=~/true/i
      _claim.send_status_change_email = true
    end

    _claim.save
    redirect_to :back
  end

  def show
  end

  def update
    _claim.assign_attributes(params_for(Claim))

    if params[:send_email] && params[:send_email]=~/true/i
      _claim.send_status_change_email = true
    end

    _claim.save

    attachments_for_claim(_claim)

    if _claim.title.present? && _claim.purchase_amount.present? && _claim.expensed_date.present?
      if _claim.proof_of_purchase.present? && _claim.proof_eligibility.present?
        _claim.update(submitted_at: Time.zone.now)
      end
    end

    redirect_to [_organization, _claim]
  end

  def proof
    render layout: false
  end

  def export
    return unless request.post?

    header_string = params[:export][:headers]
    _organization.update(headers_for_claims_export: header_string)

    template = Liquid::Template.parse(header_string.split(' ').map { |s| "{{#{s}}}"}.join(","))

    _csv = ""
    _csv << header_string.split(" ").map { |s| s.parameterize.titleize }.join(",") << "\n"

    @start_date = (params[:export][:start_date].present? ? Date.parse(params[:export][:start_date]) : 1.year.ago.to_date)
    @end_date = (params[:export][:end_date].present? ? Date.parse(params[:export][:end_date]) : 1.day.from_now.to_date)

    @claims = _organization.claims.where("created_at between ? and ?", @start_date, @end_date).order('created_at desc')
    @claims = @claims.where(params.require(:booleans).permit(:approved, :rejected, :paid_out))

    @claims.each do |claim|
       _csv << template.render(
        'claim' => claim,
        'user' => claim.user,
        'organization'=> claim.organization,
        'category' => claim.benefit_category,
        'program' => claim.try(:benefit_category).try(:primary_benefit_program)
      ) << "\n"
    end

    csv_file_name = "#{_organization.name} #{@start_date}-#{@end_date} Claims.csv"
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_file_name}"
    render text: _csv, content_type: "text/csv"
  end

  def export_agg
    return unless request.post?

    header_string = params[:export][:headers]
    _organization.update(headers_for_claims_export_agg: header_string)

    template = Liquid::Template.parse(header_string.split(' ').map { |s| "{{#{s}}}"}.join(","))

    _csv = ""
    _csv << header_string.split(" ").map { |s| s.parameterize.titleize }.join(",") << "\n"

    @start_date = (params[:export][:start_date].present? ? Date.parse(params[:export][:start_date]) : 1.year.ago.to_date)
    @end_date = (params[:export][:end_date].present? ? Date.parse(params[:export][:end_date]) : 1.day.from_now.to_date)

    @claims = _organization.claims.where('created_at between ? and ?', @start_date, @end_date)
    if params[:booleans]
      @claims = @claims.where(params.require(:booleans).permit(:approved, :rejected, :paid_out))
    end

    @y = @claims.group_by { |c| "#{c.user_id} #{c.primary_benefit_program.try(:id)}" }.map do |user_id, claims|
    # @y = @claims.group_by { |c| c.user_id }.map do |user_id, claims|
      _claim = {}

      claims.map do |claim|
        claim.csv_attributes.map do |k, v|
          _claim[k]||=[]

          if k =~ /_amount/i
            _claim[k] << v.to_f
          elsif k =~ /_at$/
            _claim[k] << v.to_date rescue v
          else
            _claim[k] << v.to_s
          end
        end
      end

      __claim = {}
      _claim.map do |k,v|
        __claim[k] = if k =~/_amount/i
          _claim[k].sum
        else
          _claim[k].uniq.compact.to_sentence.gsub(',', ';')
        end
      end

      __claim
    end

    @y.each do |claim|
       _csv << template.render(
        'claim' => claim
      ) << "\n"
    end

    csv_file_name = "#{_organization.name} #{@start_date}-#{@end_date} Claims.csv"
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_file_name}"
    render text: _csv, content_type: "text/plain"
  end

  private

  # TODO controller concern
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
