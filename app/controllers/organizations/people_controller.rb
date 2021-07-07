class Organizations::PeopleController < OrganizationsController
  def index
  end

  def show
  end

  def new
    @user = _organization.users.new
  end

  def edit
    @user = _organization.users.where(id: params[:id]).first
  end

  def update
    @user = _organization.users.where(id: params[:id]).first
    @user.assign_attributes(params_for(User))
    @user.employee_id = params[:user][:employee_id]

    if @user.save
      redirect_to organization_person_path(@user.organization, @user)
    else
      render :edit
    end
  end

  def create
    @user = _organization.users.new(params_for(User))
    @user.employee_id = params[:user][:employee_id]

    if @user.save
      redirect_to organization_person_path(@user.organization, @user)
    else
      render :new
    end
  end

  def deposit
    return unless request.post?

    if params[:benefit_program] && params[:benefit_program][:name].present?
      @benefit_program = _organization.benefit_programs.where(name: params[:benefit_program][:name]).first
    end

    fund_params = params_for(Fund)

    _organization.users.active_employees.each do |user|
      fund = user.funds.new(fund_params)
      fund.organization = _organization
      fund.benefit_program = @benefit_program
      fund.save
    end

    flash[:notice] = "Funds deposited"
    redirect_to organization_people_path(_organization)
  end

  def upload
    return unless request.post?

    file = params[:upload] && params[:upload][:file].read
    rows = file.split("\n").map do |line|
      next if (line =~ /first name/i && line =~ /last name/i)
      next if line.to_s.strip.blank?
      
      row = line.split(",").map(&:strip)
      atr = {
        first_name: row[0],
        last_name: row[1],
        email: row[2].to_s.downcase,
        amount: row[3].to_s.gsub(/[^0-9\.-]/, ''),
        available_on: row[4],
        expires_on: row[5],
        comment: row[6],
        program_name: row[7]
      }
    end.compact

    rows.each do |row|
      user = _organization.users.where(email: row[:email]).first_or_initialize
      next if user.terminated?

      user.assign_attributes(row.slice(:first_name, :last_name))
      if user.new_record?
        user.password = 'password' # SecureRandom.uuid.to_s[0..5]
      end

      fund = _organization.funds.new
      fund.amount = row[:amount]
      fund.expires_on = row[:expires_on]
      fund.save

      if row[:program_name]
        program = _organization.benefit_programs.where(name: row[:program_name].to_s.strip).first_or_create
        fund.benefit_program = program
      end

      user.funds << fund
      user.save
    end

    redirect_to organization_people_path(_organization)
  end

  def import
    return unless request.post?

    file = params[:upload] && params[:upload][:file].read
    rows = file.split("\n").map do |line|
      next if line =~ /first_name/i
      row = line.split(",").map(&:strip)

      atr = {
        first_name: row[0],
        last_name: row[1],
        employee_id: row[2],
        email: row[3].to_s.downcase,
        employee_office_location:row[4],
        employee_state_of_residence:row[5],
        employee_start_date:row[6],
        employee_termination_date:row[7],
        saml_idp:row[8],
        saml_idp_id:row[9]
      }
    end.compact

    rows.each do |row|
      user = _organization.users.where(email: row[:email]).first_or_initialize
      user.assign_attributes(row)
      if user.new_record?
        user.password = 'pwd4sustainabli123' # SecureRandom.uuid.to_s[0..5] # TODO - reset
      end

      user.name = [row[:first_name], row[:last_name]].join(" ")
      user.assign_attributes(row)
      user.save
    end

    flash[:notice] = "Employees added"
    redirect_to organization_people_path(_organization)
  end

  def destroy
    user = _organization.users.find(params[:id])
    user.destroy
    redirect_to organization_people_path(_organization)
  end

  def reset_password
    user = _organization.users.find(params[:id])
    user.delay.send_reset_password
    flash[:notice] = "A password reset email has been sent"
    redirect_to :back
  end

  def send_invite
    user = _organization.users.find(params[:id])
    user.delay.send_employee_invite

    flash[:notice] = "Invite sent"
    redirect_to :back
  end

  def invitations
    return unless request.post?

    _organization.users.where(employee_accepted_invite_at:nil).each do |user|
      user.delay.send_employee_invite
    end

    flash[:notice] = "Invites are on the way"
    redirect_to :back
  end
end
