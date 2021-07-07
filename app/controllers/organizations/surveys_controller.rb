class Organizations::SurveysController < OrganizationsController
  layout 'application'
  
  def show
    render :preview
  end

  def create
    redirect_to [_organization, _organization.surveys.create(params_for(Survey))]
  end

  def clone
    return unless request.post?

    survey = _organization.surveys.new
    survey.master_id = _survey.id
    survey.update_from_master!
    survey.update(master_id:nil, cloned_from_id: _survey.id, name:"#{_survey.name} (cloned)")

    if params[:include_users]
      _survey.users.each do |user|
        s = user.surveys.new
        s.master = survey
        s.save
      end
    end

    redirect_to [_organization, survey]
  end

  def move_to
    return unless request.post?

    organization = Organization.find(params[:move_to_organization_id])
    if organization
      _survey.update(organization_id: organization.id)
      session[:admin_organization_id] = organization.id
      redirect_to organization_survey_path(organization, _survey)
    end
  end

  def push_changes_to
    _survey.surveys.each do |survey|
      survey.delay.update_from_master!
    end

    flash[:notice] = "Changes have been pushed"
    redirect_to :back
  end


  def update
    _survey.update(params_for(Survey))
    redirect_to :back
  end

  def deploy_changes
    _survey.surveys.each do |survey|
      survey.delay.update_from_master!
    end

    flash[:notice] = "Surveys updated"
    redirect_to :back
  end

  def upload
    return unless request.post?

    unless params[:survey] && params[:survey][:spreadsheet]
      flash[:error] = "Please attach a spreadsheet."
      redirect_to :back
      return
    end

    unless File.exists?("#{Rails.root}/tmp/spreadsheets")
      FileUtils.mkdir_p("#{Rails.root}/tmp/spreadsheets")
    end

    @file = params[:survey][:spreadsheet]
    @_survey = _survey
    @_survey.spreadsheet = "#{Rails.root}/tmp/spreadsheets/#{@_survey.id}-#{File.basename(@file.original_filename)}"

    File.open(@_survey.spreadsheet, "wb") do |f|
      f.write(@file.read)
    end

    @_survey.save
    @_survey.upload!

    flash[:notice] = "Spreadsheet uploaded and questions imported."
    redirect_to :back
  end

  def import
    _survey.import!
    _survey.update_all_positions

    redirect_to preview_organization_survey_path(_organization, _survey)
  end

  def report
  end

  def import_report_questions
    _survey.only_import_report_questions = true
    _survey.import!
    flash[:notice] = "Report Questions Have Been Imported"

    _survey.surveys.all.each do |survey|
      survey.delay.update_from_master!
    end

    redirect_to :back
  end

  def reset
    _survey.sections.each do |section|
      section.destroy
    end

    flash[:notice] = "Survey has been reset"
    redirect_to :back
  end

  def restore_template
    available = _survey.attributes.keys.grep(/template/i).map(&:to_s)

    if params[:template].to_s.in?(available)
      _survey.update(params[:template] => nil)
    end

    flash[:notice] = "Template restored"
    redirect_to :back
  end

  def search_questions
    questions = _survey.questions.where('text ~* ?', params[:term]).where.not(group_id: params[:not_in_group]).map do |question|
      {
        label: "#{question.text}",
        id: question.id
      }
    end

    render json: questions
  end

  def destroy
    _survey.destroy

    redirect_to root_path
  end
end
