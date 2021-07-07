class Organizations::SectionsController < OrganizationsController
  layout 'organizations/surveys'

  def show
  end

  def create
    section = _sections.new(params_for(Section))
    section.survey = _survey
    section.organization = _organization
    section.save
    redirect_to [_organization, _survey, section]
  end

  def update
    _section.update(params_for(Section))
    redirect_to :back
  end

  def destroy
    _survey.sections.where(master_section_uuid: _section.uuid).destroy_all
  end
end
