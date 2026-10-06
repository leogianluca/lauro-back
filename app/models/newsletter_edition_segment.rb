class NewsletterEditionSegment < ApplicationRecord
  belongs_to :newsletter_edition
  belongs_to :newsletter_segment
  validates :newsletter_segment_id, uniqueness: { scope: :newsletter_edition_id }
end
