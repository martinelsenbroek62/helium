class Organizations::MessagesController < OrganizationsController
  layout 'application'

  def show
  end

  def create
    message = _survey.messages.new(params_for(Message))
    message.organization = _organization

    if message.save
      flash[:notice] = "Message saved"
      redirect_to [_organization, _survey, message]
      return
    else
      redirct_to :back
    end
  end

  def update
    _message.update(params_for(Message))
    flash[:notice] = "Message updated"
    redirect_to :back
  end

  def deliver
    message = _survey.messages.find(params[:id])

    if message
      case params[:deliver_to]
      when 'everyone'
        surveys = _survey.surveys.all
      when 'in_progress'
        surveys = _survey.surveys.in_progress
      when 'not_yet_started'
        surveys = _survey.surveys.not_yet_started
      when 'complete'
        surveys = _survey.surveys.complete
      when 'invalid'
        surveys = _survey.surveys.invalid
      end

      surveys.for_active_employees.each do |survey|
        survey.delay.send_message_to_user(message)
      end

      message.update(deliver_to: params[:deliver_to], delivered_at: Time.now)

      flash[:notice] = "Message queued for delivery"
    end

    redirect_to :back
  end

  def destroy
    _message.destroy
    redirect_to :back
  end
end
