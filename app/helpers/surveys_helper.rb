module SurveysHelper
  include Rails.application.routes.url_helpers
  include ActionView::Context
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper

  def input_for(question)
    question = Question.find(question['id'])

    case question.kind.to_s
    when /select/i
      _render('surveys/form_fields/select', question:question)
    when /radio/i
      _render('surveys/form_fields/radio', question:question)
    when /multiple|checkbox/i
      _render('surveys/form_fields/checkboxes', question:question)
    when /integer|number/i
      _render('surveys/form_fields/number', question:question)
    when /range/i
      _render('surveys/form_fields/range', question:question)
    else
      _render('surveys/form_fields/text', question:question)
    end
  end
  alias_method :input,:input_for

  def _render(partial, locals={})
    return ApplicationController.new.render_to_string(
      partial: partial,
      locals: locals,
      layout: false
    ).to_s.html_safe
  end
end

Liquid::Template.register_filter(SurveysHelper)
