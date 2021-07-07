class Organizations::BenefitProgramsController < ApplicationController
  def create
    redirect_to [_organization, _organization.benefit_programs.create(params_for(BenefitProgram))]
  end

  def update
    p = _organization.benefit_programs.find(params[:id])
    p.update(params_for(BenefitProgram))
    redirect_to [p.organization, p]
  end
end
