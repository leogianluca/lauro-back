module MediaImports
  class ProcessBatch
    require "vips"

    IMAGE_TYPES = InvestmentCards::MediaAttacher::IMAGE_TYPES
    DOCUMENT_TYPES = InvestmentCards::MediaAttacher::DOCUMENT_TYPES

    def initialize(batch)
      @batch = batch
      @record = batch.investment_card || batch.newsletter_edition
    end

    def call
      @batch.update!(status: :processing, started_at: Time.current)
      @batch.items.pending.order(:position).find_each { |item| process_item(item) }
      @batch.refresh_progress!
      @batch.update!(status: final_status, finished_at: Time.current)
      @batch
    rescue StandardError
      @batch.update!(status: :failed, finished_at: Time.current)
      raise
    end

    private

    def process_item(item)
      item.increment!(:attempts)
      validate_item!(item)
      attach_item(item)
      item.update!(status: :processed, processed_at: Time.current, error_message: nil)
    rescue StandardError => error
      item.update!(status: :failed, error_message: error.message)
    ensure
      @batch.refresh_progress!
    end

    def validate_item!(item)
      content_type = item.file.blob.content_type
      accepted = item.gallery_image? ? IMAGE_TYPES : DOCUMENT_TYPES
      raise "unsupported file type" unless accepted.include?(content_type)

      max_size = item.gallery_image? ? InvestmentCards::MediaAttacher::MAX_IMAGE_SIZE : InvestmentCards::MediaAttacher::MAX_DOCUMENT_SIZE
      raise "file is too large" if item.file.blob.byte_size > max_size

      extension = File.extname(item.file.blob.filename.to_s).downcase
      raise "file extension does not match content type" unless InvestmentCards::MediaAttacher::EXTENSIONS.fetch(content_type, []).include?(extension)

      validate_image_dimensions!(item) if item.gallery_image?
    end

    def validate_image_dimensions!(item)
      image = Vips::Image.new_from_buffer(item.file.blob.download, "")
      return if image.width >= InvestmentCards::MediaAttacher::MIN_IMAGE_WIDTH && image.height >= InvestmentCards::MediaAttacher::MIN_IMAGE_HEIGHT

      raise "image must be at least #{InvestmentCards::MediaAttacher::MIN_IMAGE_WIDTH}x#{InvestmentCards::MediaAttacher::MIN_IMAGE_HEIGHT} pixels"
    rescue Vips::Error
      raise "image could not be analyzed as a valid image"
    end

    def attach_item(item)
      attachment = item.file.blob
      if item.gallery_image?
        (@record.is_a?(NewsletterEdition) ? @record.images : @record.gallery_images).attach(attachment)
      else
        @record.documents.attach(attachment)
      end
    end

    def final_status
      @batch.failed_items.zero? ? :completed : :completed_with_errors
    end
  end
end
