require "swagger_helper"

RSpec.describe "Lauro Project API V1", openapi_spec: "v1/swagger.yaml", type: :request do
  path "/api/v1/me" do
    get "Returns the authenticated user profile" do
      tags "Authentication"
      produces "application/json"
      security [ bearerAuth: [] ]
      let(:Authorization) { nil }

      response "401", "authentication required" do
        schema type: :object, properties: { error: { type: :string } }
        run_test!
      end
    end
  end

  path "/api/v1/investment_cards" do
    get "Lists public investment cards" do
      tags "Investment Cards"
      produces "application/json"
      parameter name: :category, in: :query, type: :string, required: false
      parameter name: :asset_type, in: :query, type: :string, required: false
      parameter name: :strategy, in: :query, type: :string, required: false
      parameter name: :city, in: :query, type: :string, required: false
      parameter name: :state, in: :query, type: :string, required: false
      parameter name: :region, in: :query, type: :string, required: false
      parameter name: :expert_curated, in: :query, type: :boolean, required: false
      parameter name: :featured, in: :query, type: :boolean, required: false,
        description: "Filter by manually selected highlights. Residential public cards are limited to three featured items."
      parameter name: :min_price_cents, in: :query, type: :integer, required: false
      parameter name: :max_price_cents, in: :query, type: :integer, required: false
      parameter name: :q, in: :query, type: :string, required: false
      parameter name: :sort, in: :query, type: :string, required: false
      parameter name: :ids, in: :query, type: :string, required: false,
        description: "Comma-separated public card IDs, limited to 100 IDs."
      parameter name: :locale, in: :query, type: :string, required: false,
        enum: ["pt-BR", "en", "es"]
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "cards returned" do
        schema type: :object, required: [ :data, :meta, :errors ], properties: {
          data: { type: :array, items: { type: :object } },
          meta: { type: :object },
          errors: { type: :array }
        }
        run_test!
      end
    end
  end

  path "/api/v1/newsletter_editions" do
    get "Lists published newsletter editions" do
      tags "Newsletter"
      produces "application/json"
      parameter name: :locale, in: :query, type: :string, required: false, enum: ["pt-BR", "en", "es"]
      response "200", "editions returned" do
        schema type: :object, required: [ :data, :meta, :errors ], properties: {
          data: { type: :array, items: { type: :object } },
          meta: { type: :object },
          errors: { type: :array }
        }
        run_test!
      end
    end
  end

  path "/api/v1/market_reports" do
    get "Lists published market reports" do
      tags "Market Reports"
      produces "application/json"
      parameter name: :locale, in: :query, type: :string, required: false, enum: ["pt-BR", "en", "es"]
      response "200", "reports returned" do
        schema type: :object, required: [ :data, :meta, :errors ], properties: {
          data: { type: :array, items: { type: :object } },
          meta: { type: :object },
          errors: { type: :array }
        }
        run_test!
      end
    end
  end

  path "/api/v1/content_pages" do
    get "Lists published institutional pages" do
      tags "Content"
      produces "application/json"
      parameter name: :locale, in: :query, type: :string, required: false, enum: ["pt-BR", "en", "es"]
      response "200", "pages returned" do
        schema type: :object, required: [ :data, :meta, :errors ], properties: {
          data: { type: :array, items: { type: :object } },
          meta: { type: :object },
          errors: { type: :array }
        }
        run_test!
      end
    end
  end

  path "/api/v1/site_settings" do
    get "Returns public frontend settings" do
      tags "Settings"
      produces "application/json"
      response "200", "settings returned" do
        schema type: :object, required: [ :data, :meta, :errors ], properties: {
          data: { type: :object }, meta: { type: :object }, errors: { type: :array }
        }
        run_test!
      end
    end
  end

  path "/api/v1/leads" do
    post "Creates a contact lead" do
      tags "Leads"
      consumes "application/json"
      produces "application/json"
      parameter name: :lead_payload, in: :body, required: true, schema: {
        type: :object,
        required: [ :lead, :consent ],
        properties: {
          lead: { type: :object, required: [ :name, :email ], properties: {
            name: { type: :string },
            email: { type: :string, format: :email },
            phone: { type: :string },
            message: { type: :string },
            source: { type: :string }
          } }
        }
      }

      response "201", "lead created" do
        schema type: :object, required: [ :data, :meta, :errors ], properties: {
          data: { type: :object }, meta: { type: :object }, errors: { type: :array }
        }
        let(:lead_payload) do
          { lead: { name: "OpenAPI Investor", email: "openapi@example.com" }, consent: true }
        end
        run_test!
      end
    end
  end

  path "/api/v1/newsletter_subscribers" do
    post "Subscribes an email to the newsletter" do
      tags "Newsletter"
      consumes "application/json"
      produces "application/json"
      parameter name: :subscriber_payload, in: :body, required: true, schema: {
        type: :object,
        required: [ :subscriber, :consent ],
        properties: {
          subscriber: { type: :object, required: [ :email ], properties: {
            email: { type: :string, format: :email }, source: { type: :string }
          } }
        }
      }

      response "201", "subscriber created" do
        schema type: :object, required: [ :data, :meta, :errors ], properties: {
          data: { type: :object }, meta: { type: :object }, errors: { type: :array }
        }
        let(:subscriber_payload) do
          { subscriber: { email: "openapi-subscriber@example.com" }, consent: true }
        end
        run_test!
      end
    end
  end

  path "/api/v1/newsletter_subscribers/{id}" do
    delete "Unsubscribes a signed newsletter token" do
      tags "Newsletter"
      produces "application/json"
      parameter name: :id, in: :path, required: true, type: :string
      let(:id) { NewsletterSubscriber.create!(email: "openapi-unsubscribe@example.com").signed_id(purpose: "newsletter_unsubscribe") }

      response "200", "subscriber unsubscribed" do
        schema type: :object, required: [ :data, :meta, :errors ], properties: {
          data: { type: :object }, meta: { type: :object }, errors: { type: :array }
        }
        run_test!
      end
    end
  end
end
