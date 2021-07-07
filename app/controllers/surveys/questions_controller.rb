class Surveys::QuestionsController < SurveysController
  protect_from_forgery except: :answer

  def update
    if params[:question] && params[:question][:answer]
      _question.update(answer:params[:question][:answer])
    end

    redirect_to :back
  end

  def answer
    if params[:question] && params[:question][:answer]
      _question.update(answer:params[:question][:answer])
      _survey.update(has_started:true)

      if _question.position == 1
        _survey.update(started_at: Time.now)
      end
    end

    respond_to do |format|
      format.html { redirect_to request.referrer + '#question_' + _question.id.to_s }
      format.js  { render json: _question.group.questions.as_json(methods: [:visible]) }
    end
  end
end
