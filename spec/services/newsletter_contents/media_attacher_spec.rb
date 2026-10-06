require "rails_helper"

RSpec.describe NewsletterContents::MediaAttacher do
  it "rejects an image over the shared 25 MB limit" do
    submission = DealSubmission.new
    image = double(
      "upload",
      content_type: "image/png",
      original_filename: "property.png",
      size: InvestmentCards::MediaAttacher::MAX_IMAGE_SIZE + 1
    )

    expect {
      described_class.new(submission, images: [ image ], documents: []).call
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors.attribute_names).to include(:images)
    }
  end

  it "rejects a document over the shared 50 MB limit" do
    submission = DealSubmission.new
    document = double(
      "upload",
      content_type: "application/pdf",
      original_filename: "offering.pdf",
      size: InvestmentCards::MediaAttacher::MAX_DOCUMENT_SIZE + 1
    )

    expect {
      described_class.new(submission, images: [], documents: [ document ]).call
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors.attribute_names).to include(:documents)
    }
  end

  it "rejects an image below the shared minimum dimensions" do
    submission = DealSubmission.new
    image = Tempfile.new([ "small-image", ".png" ])
    image.binmode
    image.write(Vips::Image.black(100, 100).write_to_buffer(".png"))
    image.close
    upload = Rack::Test::UploadedFile.new(image.path, "image/png")

    expect {
      described_class.new(submission, images: [ upload ], documents: []).call
    }.to raise_error(ActiveRecord::RecordInvalid) { |error|
      expect(error.record.errors.attribute_names).to include(:images)
    }
  ensure
    image&.unlink
  end
end
