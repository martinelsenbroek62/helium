class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ApplicationHelper

  before_filter :go_to_url_after_login
  before_filter :require_user

  before_filter :redirect_to_sustainabli_domains

  def redirect_to_sustainabli_domains
    if request.host == "qa-pathways.herokuapp.com"
      redirect_to "https://qa.sustainabli.co"
      return
    end

    if request.host == "pathways.veic.org"
      redirect_to "https://www.sustainabli.co"
      return
    end
  end

  def go_to_url_after_login
    if not session[:user_id]
      session[:url] = request.path
    end
  end
end
