class Organizations::GroupsController < OrganizationsController
  layout 'organizations/surveys'

  def new
  end

  def update
    _group.update(params_for(Group))
    redirect_to :back
  end

  def create
    group = _section.groups.new(params_for(Group))
    group.organization=_organization
    group.survey=_survey
    group.save
    redirect_to [_organization, _survey, _section, group]
  end

  def show
  end

  def destroy
    _survey.groups.where(master_group_uuid: _group.uuid).destroy_all
  end
end
