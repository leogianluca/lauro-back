module NewsletterContents
  class MediaAttacher
    require "vips"

    IMAGE_TYPES = InvestmentCards::MediaAttacher::IMAGE_TYPES
    DOCUMENT_TYPES = InvestmentCards::MediaAttacher::DOCUMENT_TYPES
    EXTENSIONS = InvestmentCards::MediaAttacher::EXTENSIONS
    MAX_IMAGE_SIZE = InvestmentCards::MediaAttacher::MAX_IMAGE_SIZE
    MAX_DOCUMENT_SIZE = InvestmentCards::MediaAttacher::MAX_DOCUMENT_SIZE
    MIN_IMAGE_WIDTH = InvestmentCards::MediaAttacher::MIN_IMAGE_WIDTH
    MIN_IMAGE_HEIGHT = InvestmentCards::MediaAttacher::MIN_IMAGE_HEIGHT

    def initialize(content, images:, documents:)
      @content = content
      @images = Array(images).compact
      @documents = Array(documents).compact
    end

    def call
      validate_files!
      ActiveRecord::Base.transaction do
        @content.images.attach(@images) if @images.any?
        @content.documents.attach(@documents) if @documents.any?
      end
      @content
    end

    private

    def validate_files!
      @images.each { |file| validate_file(file, IMAGE_TYPES, MAX_IMAGE_SIZE, :images, image: true) }
      @documents.each { |file| validate_file(file, DOCUMENT_TYPES, MAX_DOCUMENT_SIZE, :documents) }
    end

    def validate_file(file, accepted_types, max_size, field, image: false)
      invalid!(field, "has an unsupported file type") unless accepted_types.include?(file.content_type)

      extension = File.extname(file.original_filename.to_s).downcase
      invalid!(field, "has an extension incompatible with its file type") unless EXTENSIONS.fetch(file.content_type, []).include?(extension)
      invalid!(field, "is too large") if file.respond_to?(:size) && file.size > max_size
      validate_dimensions(file, field) if image
    end

    def validate_dimensions(file, field)
      image = if file.respond_to?(:path) && file.path.present?
        Vips::Image.new_from_file(file.path)
      else
        Vips::Image.new_from_buffer(file.read, "")
      end
      invalid!(field, "must be at least #{MIN_IMAGE_WIDTH}x#{MIN_IMAGE_HEIGHT} pixels") if image.width < MIN_IMAGE_WIDTH || image.height < MIN_IMAGE_HEIGHT
    rescue Vips::Error
      invalid!(field, "could not be analyzed as a valid image")
    ensure
      file.rewind if file.respond_to?(:rewind)
    end

    def invalid!(field, message)
      raise ActiveRecord::RecordInvalid.new(@content.tap { |record| record.errors.add(field, message) })
    end
  end
end
