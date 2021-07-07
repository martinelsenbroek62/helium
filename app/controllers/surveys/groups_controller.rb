class Surveys::GroupsController < SurveysController
  #
  #
  # before_filter do
  #   if _survey.master
  #     unless _survey.master.allowed_to_submit_answers?
  #       redirect_to survey_report_path(_survey)
  #     end
  #   end
  # end
  #
  #

  def show
    results = _group.questions.map do |q|
      q.xshow?
    end.flatten.uniq

    if results == [false]
      if session[:dir]=='prev'
        redirect_to [:prev, _survey, _section, _group]
      else
        redirect_to [:next, _survey, _section, _group]
      end
    end
  end

  def next
    session[:dir] = 'next'

    _section.groups.where('position > ?', _group.position).each do |group|
      if group.xshow?
        redirect_to [_survey, _section, group]
        return
      end
    end

    if _section.next
      # redirect_to [_survey, _section.next, :start]
      redirect_to [_survey, _section, :complete]
    else
      redirect_to [_survey, :complete]
    end
  end

  def prev
    session[:dir] = 'prev'

    _section.groups.where('position < ?', _group.position).reverse.each do |group|
      if group.xshow?
        redirect_to [_survey, _section, group]
        return
      end
    end

    redirect_to [_survey, _section.prev, _section.prev.groups.last]
  end
end
