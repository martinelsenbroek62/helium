class AdminController < ApplicationController
  before_filter :require_super_admin
end
