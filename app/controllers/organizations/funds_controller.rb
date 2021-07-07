class Organizations::FundsController < OrganizationsController
  def create
    if params[:user_id]
      user = _organization.users.find(params[:user_id])
      fund = user.funds.new(params_for(Fund))

      # if params[:fund] && params[:fund][:program_id]
      #   fund.program = _organization.programs.find(params[:fund][:program_id])
      # end

      if params[:benefit_program] && params[:benefit_program][:name].present?
        @benefit_program = _organization.benefit_programs.where(name: params[:benefit_program][:name]).first
      end

      fund.benefit_program = @benefit_program
      fund.organization = _organization
      fund.save
    end

    redirect_to :back
  end

  def destroy
    _organization.funds.find(params[:id]).destroy
    redirect_to :back
  end
end
