module BenefitsHelper
  def benefits_proof_of_purchase_help_text
       " Most common examples are receipts or copies of paid invoices. Please <strong><a href='mailto:help@sustainabli.co'>Contact Us</a></strong> if these proof of purchase items are not available or appropriate.".html_safe
    end

  def benefits_proof_of_eligibility_help_text
    " Examples include: a picture of the product/appliance ENERGY STAR logo, a receipt with adequate description of what was purchased (e.g., composting bin), a product specification sheet, a home energy audit report. Please contact us if you have questions about your proof of eligibility. ".html_safe
  end

  def benefits_when_did_you_make_this_purchase_help_text
    "You must submit for reimbursement within 1 year of purchase".html_safe
  end

  def total_balance_for_program(benefit_category, total)
    x = benefit_category.benefit_program_ids
    x = BenefitProgramCategory.where(benefit_program_id: x).map(&:benefit_category_id).uniq
    x = _user.claims.paid_out.where(benefit_category_id: x).map(&:reimbursement_amount).map(&:to_f).sum
    total - x
  end
end
