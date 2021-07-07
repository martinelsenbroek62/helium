class Organizations::QuestionsController < OrganizationsController
  layout 'organizations/surveys'

  def show
  end

  def create
    question = _group.questions.new(params_for(Question))
    question.survey = _survey
    question.section = _section
    question.organization = _organization
    question.save

    redirect_to [_organization, _survey, _section, _group]
  end

  def update
    _question.update(params_for(Question))
    redirect_to request.referer + '#edit_question_' + _question.id.to_s
  end

  def destroy
    _survey.surveys.each do |survey|
      survey.questions.where(
        question_identifier: _question.question_identifier
      ).destroy_all
    end

    _question.destroy
    redirect_to [_organization, _survey, _section, _group]
  end
end
