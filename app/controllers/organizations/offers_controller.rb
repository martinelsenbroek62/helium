class Organizations::OffersController < ApplicationController
  def create
    offer = _organization.offers.new(params_for(Offer))
    offer.save
    redirect_to organization_offers_path(_organization)
  end

  def update
    _offer.update(params_for(Offer))
    redirect_to organization_offers_path(_organization)
  end

  def destroy
    _offer.destroy
    redirect_to organization_offers_path(_organization)
  end
end
