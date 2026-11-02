class LeadNotificationMailer < ApplicationMailer
  def self.recipient
    configured = ENV["LEAD_NOTIFICATION_EMAIL"].presence || ENV["MAILER_FROM"].presence
    configured if configured&.match?(URI::MailTo::EMAIL_REGEXP) && !configured.end_with?("@example.com")
  end

  def interest
    lead = params[:lead]
    card = lead.investment_card
    title = card.title.to_s.tr("\r\n", " ")
    message = [ "Novo interesse: #{title}", "Nome: #{lead.name}", "E-mail: #{lead.email}",
      "Telefone: #{lead.phone.presence || 'Não informado'}", "", lead.message.to_s ].join("\n")

    mail(to: self.class.recipient, reply_to: lead.email, subject: "Interesse em #{title}") do |format|
      format.text { render plain: message }
    end
  end
end
