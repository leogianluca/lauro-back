abort "E2E cleanup may only run in the test environment" unless Rails.env.test?

ids = ARGV.uniq
abort "Pass exact fixture IDs to clean up" if ids.empty?

submissions = DealSubmission.with_discarded.where(id: ids).to_a
abort "One or more fixture IDs were not found" unless submissions.length == ids.length
abort "Refusing to remove a non-discarded or non-E2E submission" unless submissions.all? do |submission|
  submission.discarded_at.present? && submission.submitter_email.match?(/\Aui-deal-\d+@localhost\.invalid\z/)
end

submissions.each do |submission|
  submission.images.purge
  submission.documents.purge
  submission.destroy!
end

puts "Removed #{submissions.length} discarded E2E submissions and their attachments"
