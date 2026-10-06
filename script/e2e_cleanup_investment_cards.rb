abort "E2E cleanup may only run in the test environment" unless Rails.env.test?

ids = ARGV.uniq
abort "Pass exact fixture IDs to clean up" if ids.empty?

cards = InvestmentCard.with_discarded.where(id: ids).to_a
abort "One or more fixture IDs were not found" unless cards.length == ids.length
abort "Refusing to remove a non-discarded or non-E2E card" unless cards.all? do |card|
  card.discarded_at.present? && card.title.match?(/\AE2E partial upload \d+\z/)
end

cards.each do |card|
  card.cover_image.purge
  card.seo_image.purge
  card.gallery_images.purge
  card.documents.purge
  card.destroy!
end

puts "Removed #{cards.length} discarded E2E cards and their attachments"
