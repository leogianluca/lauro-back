module InvestmentCards
  class MediaAttacher
    require "vips"

    MAX_IMAGE_SIZE = 25.megabytes
    MAX_DOCUMENT_SIZE = 50.megabytes
    MIN_IMAGE_WIDTH = 320
    MIN_IMAGE_HEIGHT = 180
    IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze
    DOCUMENT_TYPES = %w[application/pdf application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet].freeze
    EXTENSIONS = {
      "image/jpeg" => %w[.jpg .jpeg],
      "image/png" => [ ".png" ],
      "image/webp" => [ ".webp" ],
      "application/pdf" => [ ".pdf" ],
      "application/vnd.ms-excel" => [ ".xls" ],
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => [ ".xlsx" ]
    }.freeze

    def initialize(card, attributes)
      @card = card
      @attributes = attributes
    end

    def call
      validate_files!
      ActiveRecord::Base.transaction do
        attach_single(:cover_image)
        attach_single(:seo_image)
        attach_many(:gallery_images)
        attach_many(:documents)
      end
      @card
    end

    private

    def attach_single(name)
      file = @attributes[name]
      @card.public_send(name).attach(file) if file.present?
    end

    def attach_many(name)
      files = Array(@attributes[name]).compact
      @card.public_send(name).attach(files) if files.any?
    end

    def validate_files!
      validate_file(@attributes[:cover_image], IMAGE_TYPES, MAX_IMAGE_SIZE, :cover_image)
      validate_file(@attributes[:seo_image], IMAGE_TYPES, MAX_IMAGE_SIZE, :seo_image)
      Array(@attributes[:gallery_images]).compact.each { |file| validate_file(file, IMAGE_TYPES, MAX_IMAGE_SIZE, :gallery_images) }
      Array(@attributes[:documents]).compact.each { |file| validate_file(file, DOCUMENT_TYPES, MAX_DOCUMENT_SIZE, :documents) }
    end

    def validate_file(file, accepted_types, max_size, field)
      return if file.blank?

      unless accepted_types.include?(file.content_type)
        raise ActiveRecord::RecordInvalid.new(@card.tap { |record| record.errors.add(field, "has an unsupported file type") })
      end

      extension = File.extname(file.original_filename.to_s).downcase
      unless EXTENSIONS.fetch(file.content_type, []).include?(extension)
        raise ActiveRecord::RecordInvalid.new(@card.tap { |record| record.errors.add(field, "has an extension incompatible with its file type") })
      end

      validate_image_dimensions!(file, field) if accepted_types == IMAGE_TYPES

      return unless file.respond_to?(:size) && file.size > max_size

      raise ActiveRecord::RecordInvalid.new(@card.tap { |record| record.errors.add(field, "is too large") })
    end

    def validate_image_dimensions!(file, field)
      image = if file.respond_to?(:path) && file.path.present?
        Vips::Image.new_from_file(file.path)
      else
        Vips::Image.new_from_buffer(file.read, file.content_type)
      end

      return if image.width >= MIN_IMAGE_WIDTH && image.height >= MIN_IMAGE_HEIGHT

      raise ActiveRecord::RecordInvalid.new(@card.tap do |record|
        record.errors.add(field, "must be at least #{MIN_IMAGE_WIDTH}x#{MIN_IMAGE_HEIGHT} pixels")
      end)
    rescue Vips::Error
      raise ActiveRecord::RecordInvalid.new(@card.tap do |record|
        record.errors.add(field, "could not be analyzed as a valid image")
      end)
    ensure
      file.rewind if file.respond_to?(:rewind)
    end
  end
end
