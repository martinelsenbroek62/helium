class Organizations::ReimbursementRulesController < OrganizationsController
  def index
  end

  def create
    _organization.reimbursement_rules.create(params_for(ReimbursementRule))
    redirect_to :back
  end

  def update
    rule = _organization.reimbursement_rules.where(id:params[:id]).first
    rule.update(params_for(ReimbursementRule))
    redirect_to organization_reimbursement_rules_path
  end

  def destroy
    _organization.reimbursement_rules.find(params[:id]).destroy
    redirect_to :back
  end

  def import
    rows = params[:upload][:file].read.split("\n").map do |row|
      row = row.strip.split(",").map(&:strip)

      # if @program_name = row[6]
      #   @program = _organizations.programs.where(name: @program_name).first_or_create
      # end

      {
        focus_area: row[0],
        category_name: row[1],
        kind: row[2],
        percentage: row[3],
        focus_area_description: row[4].to_s.gsub(/[^a-z0-9\s]/i, ''),
        category_name_description: row[5].to_s.gsub(/[^a-z0-9\s]/i, ''),
        program_name: row[6]
      }
    end

    rows.each do |row|
      next if row[:focus_area].to_s.downcase=="category" && row[:category_name].to_s.downcase=="type"

      reimbursement_rule = _organization.reimbursement_rules.where(
        focus_area: row[:focus_area],
        category_name: row[:category_name]
      ).first_or_create

      reimbursement_rule.assign_attributes(
        percentage: row[:percentage],
        focus_area_description: row[:focus_area_description],
        category_name_description: row[:category_name_description]
      )

      if row[:program_name]
        program = _organization.programs.where(name: row[:program_name].to_s.strip).first_or_create
        reimbursement_rule.program = program
      end

      reimbursement_rule.save
    end

    redirect_to organization_reimbursement_rules_path(_organization)
  end
end
