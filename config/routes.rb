Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  if defined?(Rswag)
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end

  devise_for :users,
             path: "api/v1/auth",
             path_names: {
               sign_in: "login",
               sign_out: "logout"
             },
             controllers: {
               sessions: "api/v1/auth/sessions"
             },
             defaults: { format: :json },
             skip: [ :registrations, :passwords ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resource :me, only: :show, controller: :me
      get "health", to: "health#show"
      post "investment_cards/favorites", to: "investment_cards#favorites"
      resources :investment_cards, only: [ :index, :show ], param: :slug do
        member { get "documents/:attachment_id", action: :document }
      end
      resources :newsletter_editions, only: [ :index, :show ], param: :slug
      resources :market_reports, only: [ :index, :show ], param: :slug
      resources :content_pages, only: [ :index, :show ], param: :slug
      resources :site_settings, only: :index
      get "me/favorites", to: "favorites#index"
      resources :investment_cards, only: [] do
        resource :favorite, only: [ :create, :destroy ], controller: :favorites
      end
      resources :leads, only: :create
      resources :deal_submissions, only: :create
      resources :newsletter_subscribers, only: [ :create, :destroy ]
      get "newsletter_subscribers/:id/unsubscribe", to: "newsletter_subscribers#unsubscribe"
      resources :newsletter_metric_events, only: :create
      resources :site_analytics_events, only: :create
      post "newsletter_webhooks/events", to: "newsletter_webhooks#create"
      get "newsletter_tracking/:token/open", to: "newsletter_tracking#open"
      get "newsletter_tracking/:token/click", to: "newsletter_tracking#click"

      namespace :admin do
        resource :dashboard, only: :show, controller: :dashboard
        resource :site_analytics, only: :show, controller: :site_analytics
        resources :investment_cards do
          member do
            patch :publish
            patch :archive
            patch :hide
            patch "show", action: :make_public, as: :make_public
            patch :feature
            patch :unfeature
            patch :mark_expert_curated
            patch :unmark_expert_curated
            get "documents/:attachment_id", action: :document
          end
          member { post :media }
          member { delete "media/:name/:attachment_id", action: :remove_media }
          resources :gallery_items, only: [ :create, :update, :destroy ], controller: :investment_card_media
          resources :media_imports, only: [ :create, :show ], controller: :media_imports do
            member { post :retry }
          end
        end
        resources :newsletter_editions do
          member do
            post :media
            delete "media/:name/:attachment_id", action: :remove_media
            patch :publish
            patch :archive
            patch :hide
            patch "show", action: :make_public, as: :make_public
            post :dispatch, action: :send_campaign
            patch :request_review
            patch :approve
            patch :reject
            patch :schedule
            post :send_test
            get :audience
            patch :audience, action: :set_audience
            get :review
            get :preview
            get :versions
            patch "versions/:version_id/restore", action: :restore_version
            get :metrics
            get "metrics.csv", action: :metrics_export
            get :comments
            post :comments, action: :create_comment
            patch "comments/:comment_id", action: :resolve_comment
          end
          resources :media_imports, only: [ :create, :show ], controller: :media_imports do
            member { post :retry }
          end
        end
        resources :market_reports do
          member { post :media }
          member { delete "media/:name/:attachment_id", action: :remove_media }
          member do
            patch :publish
            patch :archive
            patch :hide
            patch "show", action: :make_public, as: :make_public
          end
        end
        resources :content_pages do
          member { post :media }
          member { delete "media/:name/:attachment_id", action: :remove_media }
          member do
            patch :publish
            patch :archive
            patch :hide
            patch "show", action: :make_public, as: :make_public
          end
        end
        resources :leads, only: [ :index, :show, :update, :destroy ]
        resources :deal_submissions, only: [ :index, :show, :update, :destroy ] do
          member do
            post :convert
            get "attachments/:attachment_id", action: :attachment, as: :attachment
          end
        end
        resources :taxonomy_terms
        resources :users, only: [ :index, :show, :update, :destroy ]
        resources :audit_logs, only: :index
        resources :newsletter_subscribers, only: [ :index, :update, :destroy ] do
          collection { get :export }
        end
        resources :newsletter_contents do
          member do
            patch :publish
            patch :archive
            patch :favorite
            patch :unfavorite
            get :preview
            post :media
            delete "media/:name/:attachment_id", action: :remove_media
          end
        end
        resources :newsletter_templates do
          member do
            patch :activate
            patch :make_default
            post :duplicate
            get :preview
            get :versions
            post :restore_version
          end
        end
        resources :newsletter_segments do
          member do
            post :preview
            post :duplicate
          end
        end
        resources :site_settings, only: [ :index, :create, :update, :destroy ]
      end
    end
  end
end
