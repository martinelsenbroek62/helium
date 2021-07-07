class Organizations::RulesController < OrganizationsController
  def create
    answer_from = _survey.questions.where(text: params[:rule][:answer_from]).first
    group_id = params[:rule][:group_id]
    question_id = params[:rule][:question_id]

    rule = _survey.rules.new(params_for(Rule))
    rule.organization = _organization
    rule.answer_from = answer_from
    rule.group_id = group_id
    rule.question_id = question_id
    rule.save

    redirect_to :back
  end

  def update
    _rule.update(params_for(Rule))
    redirect_to :back
  end

  def destroy
    _rule.destroy
    redirect_to :back
  end
end
