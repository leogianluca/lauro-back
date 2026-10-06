require "rails_helper"
require "tempfile"

RSpec.describe "Admin media imports", type: :request do
  include ActiveJob::TestHelper

  def write_image(tempfile, format)
    tempfile.binmode
    tempfile.write(Vips::Image.black(640, 360).write_to_buffer(format))
    tempfile.close
  end

  it "queues and processes multiple gallery files as one batch" do
    editor = create(:user, :editor)
    card = create(:investment_card)
    first = Tempfile.new([ "first", ".jpg" ])
    second = Tempfile.new([ "second", ".png" ])
    write_image(first, ".jpg[Q=80]")
    write_image(second, ".png")

    perform_enqueued_jobs do
      post "/api/v1/admin/investment_cards/#{card.id}/media_imports",
           params: {
             kind: "gallery_image",
             files: [
               Rack::Test::UploadedFile.new(first.path, "image/jpeg"),
               Rack::Test::UploadedFile.new(second.path, "image/png")
             ]
           },
           headers: auth_headers_for(editor)
    end

    expect(response).to have_http_status(:accepted)
    batch = MediaImportBatch.last
    expect(batch).to be_completed
    expect(batch.processed_items).to eq(2)
    expect(card.reload.gallery_images.attachments.size).to eq(2)
  ensure
    first&.unlink
    second&.unlink
  end

  it "rejects an empty import" do
    editor = create(:user, :editor)
    card = create(:investment_card)

    post "/api/v1/admin/investment_cards/#{card.id}/media_imports",
         params: { kind: "gallery_image", files: [] },
         headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "uses the same batch flow for newsletter images" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition)
    image = Tempfile.new([ "newsletter", ".png" ])
    write_image(image, ".png")

    perform_enqueued_jobs do
      post "/api/v1/admin/newsletter_editions/#{edition.id}/media_imports",
           params: {
             kind: "gallery_image",
             files: [ Rack::Test::UploadedFile.new(image.path, "image/png") ]
           },
           headers: auth_headers_for(editor)
    end

    expect(response).to have_http_status(:accepted)
    expect(MediaImportBatch.last.newsletter_edition).to eq(edition)
    expect(edition.reload.images.attachments.size).to eq(1)
  ensure
    image&.unlink
  end

  it "keeps valid files processed when another file fails validation" do
    editor = create(:user, :editor)
    card = create(:investment_card)
    valid = Tempfile.new([ "valid", ".png" ])
    invalid = Tempfile.new([ "invalid", ".pdf" ])
    write_image(valid, ".png")
    invalid.write("not-an-image")
    invalid.close

    perform_enqueued_jobs do
      post "/api/v1/admin/investment_cards/#{card.id}/media_imports",
           params: { kind: "gallery_image", files: [
             Rack::Test::UploadedFile.new(valid.path, "image/png"),
             Rack::Test::UploadedFile.new(invalid.path, "image/png")
           ] }, headers: auth_headers_for(editor)
    end

    batch = MediaImportBatch.last
    expect(response).to have_http_status(:accepted)
    expect(batch).to be_completed_with_errors
    expect(batch.processed_items).to eq(1)
    expect(batch.failed_items).to eq(1)
  ensure
    valid&.unlink
    invalid&.unlink
  end

  it "blocks retries after the per-file limit" do
    editor = create(:user, :editor)
    card = create(:investment_card)
    batch = card.media_import_batches.create!(total_items: 1)
    item = batch.items.create!(kind: :gallery_image, position: 1, status: :failed, attempts: 3, error_message: "invalid")
    item.file.attach(io: StringIO.new("invalid"), filename: "invalid.png", content_type: "image/png")

    post "/api/v1/admin/investment_cards/#{card.id}/media_imports/#{batch.id}/retry", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:conflict)
    expect(json_response.dig("errors", 0, "code")).to eq("retry_limit_reached")
  end
end
