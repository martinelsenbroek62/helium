class PagesController < ApplicationController
  layout 'benefits'

  def show
    unless _page
      flash[:notice] = "Page is not available"
      redirect_to root_path
      return
    end


    if _page && !_page.published?
      flash[:notice] = "Page is not available"
      redirect_to root_path
      return
    end
  end
end
