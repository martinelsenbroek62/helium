class Surveys::SectionsController < SurveysController

  def index
    render :index
  end

  def start
  end

  def complete
    _survey.delay.copy_update_answers_and_get_results!
    render :complete
  end

  def show
    redirect_to [_survey, _section, _section.groups.first]
  end

  def info
    render json: _section.as_json(methods: [:percent_complete])
  end
end
