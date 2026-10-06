class NewsletterMailer < ApplicationMailer
  def edition
    @edition = params[:edition]
    @subscriber = params[:subscriber]
    @delivery = params[:delivery]
    rendered_html = NewsletterCampaigns::HtmlRenderer.new(@edition).call
    @body_html = NewsletterCampaigns::LinkTracker.new(rendered_html, @delivery).call
    signed_token = @subscriber.signed_id(purpose: "newsletter_unsubscribe")
    @unsubscribe_url = public_url("/api/v1/newsletter_subscribers/#{signed_token}/unsubscribe")
    @tracking_url = if @delivery
      tracking_token = @delivery.signed_id(purpose: "newsletter_open")
      public_url("/api/v1/newsletter_tracking/#{tracking_token}/open")
    end

    mail(
      to: @subscriber.email,
      from: sender_email,
      reply_to: reply_to_email,
      subject: @edition.metadata["subject"].presence || @edition.title,
      headers: {
        "List-Unsubscribe" => "<#{@unsubscribe_url}>",
        "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click"
      }
    )
  end

  def test_email
    @edition = params[:edition]
    @body_html = NewsletterCampaigns::HtmlRenderer.new(@edition).call
    mail(to: params[:email], subject: "[Teste] #{@edition.metadata["subject"].presence || @edition.title}")
  end

  private

  def public_url(path)
    base_url = ENV["APP_PUBLIC_URL"].presence
    unless base_url
      host = ENV.fetch("APP_HOST", "localhost")
      port = ENV["APP_PORT"].presence
      base_url = "#{ENV.fetch("APP_PROTOCOL", "http")}://#{host}#{port ? ":#{port}" : ""}"
    end
    "#{base_url.chomp("/")}#{path}"
  end

  def sender_email
    configured = @edition.metadata["sender_email"].to_s
    configured.match?(URI::MailTo::EMAIL_REGEXP) ? configured : (ENV["MAILER_FROM"].presence || "from@example.com")
  end

  def reply_to_email
    configured = @edition.metadata["reply_to"].to_s
    configured.match?(URI::MailTo::EMAIL_REGEXP) ? configured : nil
  end
end
