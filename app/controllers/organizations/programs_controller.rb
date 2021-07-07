class Organizations::ProgramsController < OrganizationsController
  def index
  end

  def show
  end

  def new
  end

  def create
    redirect_to [_organization, _organization.programs.create(params_for(Program))]
  end

  def update
    program = _organization.programs.find(params[:id])
    program.update(params_for(Program))
    redirect_to [_organization, program]
  end

  def destroy
    _program.destroy
    redirect_to organization_programs_path(_organization)
  end
end
