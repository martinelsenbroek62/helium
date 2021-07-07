class SurveysController < ApplicationController
  layout :get_layout
  helper_method :_survey

  def get_layout
    'benefits'
  end

  before_action do
    unless _user.super_admin?
      if (_organization.has_benefits? && !_organization.has_surveys?)
        redirect_to products_path
      end

      if (!_organization.has_surveys && !_organization.has_benefits?)
        render file: 'organizations/unavailable', layout: 'users'
      end
    end
  end

  def index
    if _user.surveys.any?
      if _user.surveys.count <= 1
        redirect_to _user.surveys.first
        return
      end
    end
  end

  def footprint
    if _user.surveys.any?
      redirect_to survey_report_path(_user.surveys.last)
    else
      redirect_to no_footprint_path
    end
  end

  def finish
    section = _survey.sections.where('lower(name) = ?','goals').first
    group = section.groups.first
    redirect_to [_survey, section, group]
  end

  def start
    redirect_to [_survey, _survey.sections.first, _survey.sections.first.groups.first]
  end

  def complete
    _survey.update(has_reached_end:true)

    @remaining_questions = _survey.questions.remaining.all.select { |q| q.xshow? }
    if @remaining_questions.empty?
      _survey.update(has_reached_end:true, complete:true, completed_at: Time.now)
    end
  end

  def _survey
    @_survey ||= _user.surveys.where(id:params[:survey_id]||params[:id]).first
  end
end
