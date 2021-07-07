class Organizations::UsersController < OrganizationsController
  layout 'application'

  def create
    user = User.find_by(email: params_for(User)[:email])
    unless user
      user = User.new(params_for(User))
    end

    survey = user.surveys.new
    survey.master = _survey
    survey.save

    user.organization = _organization
    user.save

    redirect_to :back
  end

  def invite
    _survey.surveys.where(allowed_to_submit_answers:true).each do |survey|
      survey.delay.invite_user_to_survey
    end

    flash[:notice] = "Invites are on their way!"
    redirect_to :back
  end

  def reinvite
    survey = _survey.surveys.where(user_id: params[:id]).first

    if survey
      survey.delay.reinvite_user_to_survey
    end

    flash[:notice] = "An invite has been sent."

    redirect_to :back
  end

  def make_admin
    survey = _survey.surveys.where(user_id: params[:id]).first
    user = survey.user
    if user && user.organization_id.blank?
      user.update(organization_id: _organization.id)
      flash[:notice] = "#{user.email} is now an admin"
    else
      user.update(organization_id: nil) unless user == _user
      flash[:notice] = "#{user.email} is not an admin"
    end

    redirect_to :back
  end

  def import
    unless params[:import] && params[:import][:file]
      flash[:error] = "Please attach a CSV file"
      redirect_to :back
      return
    end

    headers = %w{first last email}

    file = params[:import][:file].read.to_s
    file.split("\n").each do |line|
      next unless line =~ /@/i

      row = line.split(",").map(&:strip)
      row = Hash[headers.zip(row)]
      row = {name: "#{row['first']} #{row['last']}", email: row['email']}

      user = User.find_by(email:row[:email])
      unless user
        user = User.create(row)
      end

      user.organization = _organization
      user.save

      # create survey for user now
      unless _survey.users.find_by(email:row[:email])
        survey = user.surveys.new
        survey.master = _survey
        survey.save
      end
    end

    flash[:notice] = "Users have been imported"
    redirect_to :back
  end

  def add_from_organization
    _organization.users.active_employees.each do |user|
      survey = user.surveys.where(master_id:_survey.id).first

      if !survey
        survey = user.surveys.new
      end

      survey.master = _survey
      survey.save
    end

    flash[:notice] = "Employees have been added"
    redirect_to :back
  end

  def attach_meta_data
    rows = params[:import][:file].read.to_s.split("\n")
    rows.map! do |line|
      if line == rows.first
        line = line.downcase # normalize headers
      end

      line.split(",")
    end
    headers = rows.first

    new_rows = []
    rows[1..-1].map do |row|
      new_rows << Hash[headers.zip(row)]
    end

    users = []
    new_rows.each do |row|
      next unless row['email']

      if user = _survey.users.where(email:row['email']).first
        user_field = user.user_fields.where(master_survey_id: _survey.id, organization_id: _organization.id).first_or_create
        user_field.update(data: row)
        users << user_field
      end
    end

    flash[:notice] = "User fields imported"
    redirect_to :back
  end

  def import_historical_records
    _survey.import_historical_records_from(params[:historical_records][:file].path)

    flash[:notice] = "Users and historical records have been imported!"
    redirect_to :back
  end

  def destroy
    user = _survey.users.find(params[:id])

    if user
      user.surveys.where(master_id: _survey.id).first.destroy
    end

    flash[:notice] = "User removed"
    redirect_to :back
  end

  def reset
    _survey.surveys.destroy_all
    flash[:notice] = "All user surveys have been removed"
    redirect_to :back
  end

  def download_data
    require "csv"

    data = []
    data << _survey.questions.reorder('key asc').map(&:text).to_csv
    _survey.surveys.includes(:questions).each do |survey|
      data << survey.questions.reorder('key asc').map(&:answer).to_csv
    end

    send_data data.join("\n"), filename: "#{_survey.name.parameterize}-#{Time.now.stamp('mon-jun-1st-2015')}.csv"
  end

  def download_results
    require "csv"

    headers = _survey.surveys.joins(:results).select('distinct results.key, master_id').map do |row|
      row.key
    end

    rows = []
    _survey.surveys.includes(:results).each do |survey|
      next unless survey.user

      _r = []
      _r << survey.user.email

      headers.each do |header|
        _r << survey.results.select { |result| result.key == header }.first.try(:value)
      end

      rows << _r.join(",")
    end

    headers.unshift("Email")
    data = headers.join(",") + "\n" + rows.join("\n")

    send_data(
      data,
      filename: "#{_survey.name.parameterize}-results-#{Time.now.stamp('mon-jun-1st-2015')}.csv"
    )
  end

  def toggle_open_and_closed_surveys
    if params[:direction] == "open"
      _survey.surveys.where(allowed_to_submit_answers:false).update_all(allowed_to_submit_answers:true)
    end

    if params[:direction]=="close"
      _survey.surveys.where(allowed_to_submit_answers:true).update_all(allowed_to_submit_answers:false)
    end

    redirect_to request.referrer + '#filter'
  end

  def toggle_survey_is_valid
    survey = _survey.surveys.where(user_id: params[:id]).first
    survey.update(valid_survey: (!(survey.valid_survey?)))
    redirect_to (request.referrer + '#filter')
  end

  def allowed_to_submit_answers
    survey = _survey.surveys.where(user_id: params[:id]).first
    survey.update(allowed_to_submit_answers: (!(survey.allowed_to_submit_answers?)))
    redirect_to (request.referrer + '#filter')
  end

  def rerun_calculations
    _survey.surveys.each do |survey|
      survey.delay.copy_update_answers_and_get_results!
    end

    flash[:notice] = "Calculations are being rerun"
    redirect_to :back
  end

  def share_spreadsheet
    survey = _survey.surveys.joins(:user).where('users.email = ?', params[:user_email]).first

    if survey && params[:share_email].present?
      survey.share_spreadsheet_with(params[:share_email])
    end

    redirect_to :back
  end

  def compare
    render layout: false
  end

  def run_results
    _survey.surveys.where(user_id: params[:id]).each do |survey|
      survey.copy_update_answers_and_get_results!
    end

    redirect_to :back
  end
end
