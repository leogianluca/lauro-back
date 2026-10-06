module DealSubmissions
  class ConvertToInvestmentCard
    def initialize(submission, user:)
      @submission = submission
      @user = user
    end

    def call
      raise ArgumentError, "Only accepted submissions can be converted" unless @submission.accepted?
      return @submission.converted_investment_card if @submission.converted_investment_card.present?

      DealSubmission.transaction do
        card = InvestmentCard.create!(
          title: @submission.title,
          summary: @submission.message.presence || "Oportunidade submetida para análise.",
          description: @submission.message,
          category: @submission.category.presence || "residential",
          asset_type: @submission.asset_type,
          strategy: @submission.strategy.presence || "under_review",
          city: @submission.city,
          state: @submission.state,
          region: @submission.region,
          country: @submission.country.presence || "US",
          zip_code: @submission.zip_code,
          address_line1: @submission.address_line1,
          price_cents: @submission.price_cents,
          investment_min_cents: @submission.investment_min_cents,
          source_name: @submission.company_name.presence || @submission.submitter_name,
          status: :draft,
          visibility: :private,
          card_level: 1,
          market_status: :active,
          category_taxonomy: taxonomy_term("category", @submission.category),
          asset_type_taxonomy: taxonomy_term("asset_type", @submission.asset_type),
          strategy_taxonomy: taxonomy_term("strategy", @submission.strategy),
          market_taxonomy: taxonomy_term("market", @submission.city),
          disclaimer: "Aguardando revisão e validação interna.",
          metadata: { "submission_id" => @submission.id, "submitted_by" => @submission.submitter_email }
        )
        card.documents.attach(@submission.documents.blobs) if @submission.documents.attached?
        card.gallery_images.attach(@submission.images.blobs) if @submission.images.attached?
        @submission.update!(converted_investment_card: card)
        card
      end
    end

    private

    def taxonomy_term(kind, value)
      TaxonomyTerm.find_by(kind:, slug: value.to_s.parameterize(separator: "_"))
    end
  end
end
