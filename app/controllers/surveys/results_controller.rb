class Surveys::ResultsController < SurveysController
  def index
    respond_to do |format|
      format.json
    end
  end
end
