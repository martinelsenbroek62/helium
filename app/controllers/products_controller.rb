class ProductsController < ApplicationController
  layout 'benefits'

  before_action do
    unless _user.super_admin?
      if (_organization.has_surveys? && !_organization.has_benefits?)
        redirect_to surveys_path
      end

      if (!_organization.has_surveys && !_organization.has_benefits?)
        render file: 'organizations/unavailable', layout: 'users'
      end
    end
  end

  def focus_area
    if params[:filter].present?
      redirect_to new_claim_path(filter: params[:filter])
    end
  end

  def saved
    return unless request.post?

    if _user.products.include?(_product)
      _user.user_products.where(product_id:_product.id).destroy_all
    else
      _user.products << _product
    end

    redirect_to :back
  end
end
