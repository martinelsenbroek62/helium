class ApplicationMailer < ActionMailer::Base
  default from: (ENV['DEFAULT_FROM']||="\"VEIC Sustainability Survey\" <carbonsurvey@veic.org>"),
    content_transfer_encoding: 'quoted-printable'

  layout 'mailer'

  def mail(args={})
    if ENV['OVERRIDE_EMAIL'].present?
      args[:to] = ENV['OVERRIDE_EMAIL']
      args.delete(:bcc)
      args.delete(:cc)
    end

    if ENV['EMAIL_ENABLED'].present?
      super(args)
    end
  end
end
