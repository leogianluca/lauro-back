require "rails_helper"

RSpec.describe "Favorites", type: :request do
  it "allows an authenticated user to favorite and unfavorite a public card" do
    user = create(:user, :viewer)
    card = create(:investment_card, :published)
    headers = auth_headers_for(user)

    post "/api/v1/investment_cards/#{card.id}/favorite", headers: headers

    expect(response).to have_http_status(:created)
    expect(user.favorites.exists?(investment_card: card)).to be(true)

    post "/api/v1/investment_cards/#{card.id}/favorite", headers: headers

    expect(response).to have_http_status(:created)
    expect(user.favorites.where(investment_card: card).count).to eq(1)

    delete "/api/v1/investment_cards/#{card.id}/favorite", headers: headers

    expect(response).to have_http_status(:ok)
    expect(user.favorites.exists?(investment_card: card)).to be(false)
  end

  it "lists the current user's favorites" do
    user = create(:user, :viewer)
    favorite = create(:favorite, user: user, investment_card: create(:investment_card, :published))
    create(:favorite, investment_card: create(:investment_card, :published))

    get "/api/v1/me/favorites", headers: auth_headers_for(user)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", 0, "id")).to eq(favorite.investment_card_id)
  end

  it "returns only public fields and reports editorial fallback locale" do
    user = create(:user, :viewer)
    card = create(:investment_card, :published, address_line1: "123 Private Street", metadata: { internal_note: "staff only" })
    create(:favorite, user: user, investment_card: card)

    get "/api/v1/me/favorites?locale=es", headers: auth_headers_for(user)

    expect(response).to have_http_status(:ok)
    public_card = json_response.dig("data", 0)
    expect(public_card.dig("locale", "requested_locale")).to eq("es")
    expect(public_card.dig("locale", "fallback_used")).to be(true)
    expect(public_card).not_to include("metadata", "status", "visibility", "address_line1", "curated_by_id")
    expect(json_response.dig("meta", "locale", "fallback_count")).to eq(1)
  end

  it "does not expose favorites that are no longer publicly visible" do
    user = create(:user, :viewer)
    hidden_card = create(:investment_card, :published, visibility: "private")
    create(:favorite, user: user, investment_card: hidden_card)

    get "/api/v1/me/favorites", headers: auth_headers_for(user)

    expect(response).to have_http_status(:ok)
    expect(json_response.fetch("data")).to be_empty
  end

  it "allows an owner to remove a favorite after its card is no longer public" do
    user = create(:user, :viewer)
    card = create(:investment_card, :published)
    own_favorite = create(:favorite, user: user, investment_card: card)
    other_favorite = create(:favorite, investment_card: card)
    card.update!(visibility: "private")

    delete "/api/v1/investment_cards/#{card.id}/favorite", headers: auth_headers_for(user)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "favorited")).to be(false)
    expect(user.favorites.exists?(own_favorite.id)).to be(false)
    expect(Favorite.exists?(other_favorite.id)).to be(true)
  end

  it "requires authentication" do
    get "/api/v1/me/favorites"

    expect(response).to have_http_status(:unauthorized)
  end
end
