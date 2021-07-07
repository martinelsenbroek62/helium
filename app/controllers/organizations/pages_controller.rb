class Organizations::PagesController < OrganizationsController
  def create
    @page = _organization.pages.new(params_for(Page))
    @page.save

    redirect_to [_organization, @page]
  end

  def show
  end

  def update
    _page.update(params_for(Page))
    redirect_to [_organization, _page]
  end

  def destroy
    _page.destroy
    redirect_to organization_pages_path(_organization)
  end
end
