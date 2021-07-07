class Organizations::ProductsController < OrganizationsController
  def create
    rows = params[:upload][:file].read.split("\n").map do |row|
      row = row.split(",").map(&:strip)

      {
        focus_area: row[0],
        category_name: row[1],
        product_type: row[2],
        name: row[3],
        description: row[4],
        reimbursement_percentage: row[5]
      }
    end

    rows.each do |row|
      product = _organization.products.where(focus_area:row[:focus_area], category_name:row[:category_name], product_type:row[:product_type], name:row[:name]).first_or_initialize
      product.description = row[:description]
      product.reimbursement_percentage = row[:reimbursement_percentage]
      product.save!
    end

    redirect_to :back
  end

  def update
    _product.assign_attributes(params_for(Product))

    if params[:product] && params[:product][:set_program_id]
      program_id = params[:product][:set_program_id].to_i

      # _product.set_program_id = Program.find(program_id).id
      _product.update_column(:program_id, program_id)
    end

    _product.save!

    redirect_to organization_products_path
  end

  def destroy
    _product.destroy
    redirect_to organization_products_path
  end

  def upload

  end
end
