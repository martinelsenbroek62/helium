class Organizations::BenefitCategoriesController < ApplicationController
  def edit
  end

  def update
    c = _organization.benefit_categories.find(params[:id])
    c.update(params_for(BenefitCategory))
    redirect_to :back
  end

  def index
    @benefit_category = _organization.benefit_categories.order(id:params[:benefit_category][:id])
    respond_todo |format|
      format.html
      format.csv { send_data @benefit_category.to_csv }    
  end

  def create
    benefit_category = BenefitCategory.create(params_for(BenefitCategory).merge(
      organization_id:_organization.id
    ))
    _benefit_program.benefit_categories << benefit_category
    redirect_to [_organization, _benefit_program]
  end

  def destroy
    _organization.benefit_categories.find(params[:id]).destroy
    redirect_to :back
  end

  def upload
    rows = params[:upload][:file].read.split("\n").map do |row|
      next if row =~ /percent to reimburse/i
      next if row =~ /^category/i
      next if line.to_s.strip.blank?


      row = row.strip.split(",").map(&:strip)
      {
        name: row[0],
        focus_area: row[1],
        product_type: row[2],
        percent_to_reimburse: row[3],
        description: row[4],
        focus_area_description: row[5],
        product_type_description: row[6],
        program_name: row[7],
        eligibility_description: row[8],
        description_of_exclusions: row[9],
        benefit_category_image_url: row[10],
      }
    end.compact

    rows.each do |row|
      benefit_category = _organization.benefit_categories.where(
        # organization_id: _organization.id,
        # benefit_program_id: _benefit_program.id,
        name: row[:name],
        focus_area: row[:focus_area],
        product_type: row[:product_type]
      ).first_or_create

      _benefit_program.benefit_categories << benefit_category unless _benefit_program.benefit_categories.include?(benefit_category)

      benefit_category.update(row.except(:program_name))
    end

    redirect_to [_organization, _benefit_program]
  end
end
