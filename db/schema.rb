# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_16_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.uuid "auditable_id", null: false
    t.string "auditable_type", null: false
    t.jsonb "changeset", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "request_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "content_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.jsonb "content_blocks", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.text "excerpt"
    t.string "eyebrow"
    t.jsonb "metadata", default: {}, null: false
    t.string "page_type", default: "institutional", null: false
    t.datetime "published_at"
    t.text "seo_description"
    t.string "seo_title"
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.string "template_key"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public", null: false
    t.index ["discarded_at"], name: "index_content_pages_on_discarded_at"
    t.index ["page_type"], name: "index_content_pages_on_page_type"
    t.index ["slug"], name: "index_content_pages_on_slug", unique: true
    t.index ["status"], name: "index_content_pages_on_status"
    t.index ["visibility"], name: "index_content_pages_on_visibility"
  end

  create_table "deal_submissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address_line1"
    t.string "asset_type"
    t.string "category"
    t.string "city"
    t.string "company_name"
    t.datetime "consented_at"
    t.uuid "converted_investment_card_id"
    t.string "country", default: "US", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.text "internal_notes"
    t.integer "investment_min_cents"
    t.text "message"
    t.jsonb "metadata", default: {}, null: false
    t.integer "price_cents"
    t.string "region"
    t.string "state"
    t.string "status", default: "new", null: false
    t.string "strategy"
    t.string "submitter_email", null: false
    t.string "submitter_name", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["category"], name: "index_deal_submissions_on_category"
    t.index ["converted_investment_card_id"], name: "index_deal_submissions_on_converted_investment_card_id"
    t.index ["discarded_at"], name: "index_deal_submissions_on_discarded_at"
    t.index ["status"], name: "index_deal_submissions_on_status"
    t.index ["submitter_email"], name: "index_deal_submissions_on_submitter_email"
  end

  create_table "favorites", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "investment_card_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["investment_card_id"], name: "index_favorites_on_investment_card_id"
    t.index ["user_id", "investment_card_id"], name: "index_favorites_on_user_id_and_investment_card_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "investment_brokers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "investment_card_media", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "alt_text"
    t.string "caption"
    t.datetime "created_at", null: false
    t.uuid "investment_card_id", null: false
    t.string "kind", default: "gallery", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["investment_card_id", "position"], name: "idx_card_media_position"
    t.index ["investment_card_id"], name: "index_investment_card_media_on_investment_card_id"
  end

  create_table "investment_card_metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "featured", default: false, null: false
    t.uuid "investment_card_id", null: false
    t.string "label", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.uuid "taxonomy_term_id"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["investment_card_id", "position"], name: "idx_card_metrics_position"
    t.index ["investment_card_id"], name: "index_investment_card_metrics_on_investment_card_id"
    t.index ["taxonomy_term_id"], name: "index_investment_card_metrics_on_taxonomy_term_id"
  end

  create_table "investment_cards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "alt_text"
    t.bigint "annual_profit_cents"
    t.string "asset_type"
    t.uuid "asset_type_taxonomy_id"
    t.text "assumptions"
    t.decimal "bathrooms", precision: 5, scale: 2
    t.integer "bedrooms"
    t.jsonb "business_details", default: {}, null: false
    t.decimal "cap_rate_current", precision: 6, scale: 3
    t.decimal "cap_rate_projected", precision: 6, scale: 3
    t.integer "card_level", default: 1, null: false
    t.decimal "cash_on_cash", precision: 6, scale: 3
    t.string "category"
    t.uuid "category_taxonomy_id"
    t.string "city"
    t.string "country", default: "US", null: false
    t.datetime "created_at", null: false
    t.uuid "curated_by_id"
    t.bigint "current_income_cents"
    t.text "description"
    t.datetime "discarded_at"
    t.text "disclaimer"
    t.bigint "down_payment_cents"
    t.decimal "down_payment_percent", precision: 6, scale: 3
    t.jsonb "due_diligence", default: {}, null: false
    t.bigint "ebitda_annual_cents"
    t.decimal "ebitda_margin", precision: 6, scale: 3
    t.bigint "equity_generated_max_cents"
    t.bigint "equity_generated_min_cents"
    t.integer "estimated_months"
    t.decimal "estimated_roi_max", precision: 7, scale: 3
    t.decimal "estimated_roi_min", precision: 7, scale: 3
    t.boolean "expert_curated", default: false, null: false
    t.text "expert_curated_analysis"
    t.text "expert_curated_reason"
    t.string "external_reference"
    t.boolean "featured", default: false, null: false
    t.integer "featured_position"
    t.jsonb "financing", default: {}, null: false
    t.boolean "financing_available", default: false, null: false
    t.boolean "franchise", default: false, null: false
    t.decimal "gross_yield_percent", precision: 7, scale: 3
    t.jsonb "highlights", default: [], null: false
    t.decimal "hpi_10_year_percent", precision: 7, scale: 3
    t.uuid "investment_broker_id"
    t.uuid "investment_company_id"
    t.uuid "investment_location_id"
    t.bigint "investment_max_cents"
    t.bigint "investment_min_cents"
    t.text "investment_profile"
    t.text "investment_thesis"
    t.decimal "investor_participation", precision: 6, scale: 3
    t.decimal "latitude", precision: 10, scale: 7
    t.integer "living_area_sqft"
    t.decimal "longitude", precision: 10, scale: 7
    t.text "market_context"
    t.string "market_status", default: "active", null: false
    t.uuid "market_taxonomy_id"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "noi_current_cents"
    t.bigint "noi_projected_cents"
    t.decimal "occupancy_rate", precision: 6, scale: 3
    t.string "operating_model"
    t.string "owner_involvement"
    t.bigint "owner_salary_annual_cents"
    t.decimal "owner_time_in_business_years", precision: 6, scale: 2
    t.bigint "price_cents"
    t.string "price_currency", default: "USD", null: false
    t.bigint "projected_income_cents"
    t.jsonb "property_details", default: {}, null: false
    t.datetime "published_at"
    t.boolean "quota_available", default: false, null: false
    t.string "region"
    t.text "return_strategy"
    t.jsonb "risks", default: [], null: false
    t.string "sale_reason"
    t.string "sector"
    t.text "seo_description"
    t.string "seo_title"
    t.string "slug", null: false
    t.string "source_name"
    t.string "source_url"
    t.string "state"
    t.string "status", default: "draft", null: false
    t.string "strategy"
    t.uuid "strategy_taxonomy_id"
    t.text "summary"
    t.jsonb "tags", default: [], null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.string "visa_eligibility"
    t.string "visibility", default: "public", null: false
    t.integer "year_built"
    t.string "zip_code"
    t.index ["asset_type"], name: "index_investment_cards_on_asset_type"
    t.index ["asset_type_taxonomy_id"], name: "index_investment_cards_on_asset_type_taxonomy_id"
    t.index ["category"], name: "index_investment_cards_on_category"
    t.index ["category_taxonomy_id"], name: "index_investment_cards_on_category_taxonomy_id"
    t.index ["city"], name: "index_investment_cards_on_city"
    t.index ["discarded_at"], name: "index_investment_cards_on_discarded_at"
    t.index ["expert_curated"], name: "index_investment_cards_on_expert_curated"
    t.index ["featured"], name: "index_investment_cards_on_featured"
    t.index ["featured_position"], name: "index_investment_cards_on_featured_position"
    t.index ["investment_broker_id"], name: "index_investment_cards_on_investment_broker_id"
    t.index ["investment_company_id"], name: "index_investment_cards_on_investment_company_id"
    t.index ["investment_location_id"], name: "index_investment_cards_on_investment_location_id"
    t.index ["market_status"], name: "index_investment_cards_on_market_status"
    t.index ["market_taxonomy_id"], name: "index_investment_cards_on_market_taxonomy_id"
    t.index ["metadata"], name: "index_investment_cards_on_metadata", using: :gin
    t.index ["published_at"], name: "index_investment_cards_on_published_at"
    t.index ["region"], name: "index_investment_cards_on_region"
    t.index ["sector"], name: "index_investment_cards_on_sector"
    t.index ["slug"], name: "index_investment_cards_on_slug", unique: true
    t.index ["status"], name: "index_investment_cards_on_status"
    t.index ["strategy"], name: "index_investment_cards_on_strategy"
    t.index ["strategy_taxonomy_id"], name: "index_investment_cards_on_strategy_taxonomy_id"
    t.index ["tags"], name: "index_investment_cards_on_tags", using: :gin
    t.index ["verified_at"], name: "index_investment_cards_on_verified_at"
    t.index ["visa_eligibility"], name: "index_investment_cards_on_visa_eligibility"
    t.index ["visibility"], name: "index_investment_cards_on_visibility"
    t.index ["zip_code"], name: "index_investment_cards_on_zip_code"
    t.check_constraint "card_level >= 1 AND card_level <= 3", name: "investment_cards_card_level_range"
    t.check_constraint "card_level >= 1 AND card_level <= 3", name: "investment_cards_card_level_valid"
    t.check_constraint "investment_max_cents IS NULL OR investment_max_cents >= 0", name: "investment_cards_maximum_nonnegative"
    t.check_constraint "investment_min_cents IS NULL OR investment_min_cents >= 0", name: "investment_cards_minimum_nonnegative"
    t.check_constraint "jsonb_typeof(due_diligence) = 'object'::text", name: "investment_cards_due_diligence_object"
    t.check_constraint "jsonb_typeof(financing) = 'object'::text", name: "investment_cards_financing_object"
    t.check_constraint "jsonb_typeof(highlights) = 'array'::text", name: "investment_cards_highlights_array"
    t.check_constraint "jsonb_typeof(risks) = 'array'::text", name: "investment_cards_risks_array"
    t.check_constraint "jsonb_typeof(tags) = 'array'::text", name: "investment_cards_tags_array"
    t.check_constraint "price_cents IS NULL OR price_cents >= 0", name: "investment_cards_price_nonnegative"
    t.check_constraint "price_cents IS NULL OR price_cents >= 0", name: "investment_cards_price_valid"
  end

  create_table "investment_companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "sector"
    t.datetime "updated_at", null: false
    t.string "website"
  end

  create_table "investment_locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "country", default: "US", null: false
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "name", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "zip_code"
  end

  create_table "leads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "assigned_to_id"
    t.datetime "consented_at"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email", null: false
    t.text "internal_notes"
    t.uuid "investment_card_id"
    t.text "message"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "phone"
    t.string "source"
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_leads_on_assigned_to_id"
    t.index ["discarded_at"], name: "index_leads_on_discarded_at"
    t.index ["email"], name: "index_leads_on_email"
    t.index ["investment_card_id"], name: "index_leads_on_investment_card_id"
    t.index ["source"], name: "index_leads_on_source"
    t.index ["status"], name: "index_leads_on_status"
    t.check_constraint "status::text = ANY (ARRAY['new'::character varying::text, 'contacted'::character varying::text, 'qualified'::character varying::text, 'disqualified'::character varying::text, 'converted'::character varying::text])", name: "leads_status_allowed"
  end

  create_table "market_report_metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "featured", default: false, null: false
    t.string "label", null: false
    t.uuid "market_report_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.uuid "taxonomy_term_id"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.string "variation"
    t.index ["market_report_id", "position"], name: "idx_report_metrics_position"
    t.index ["market_report_id"], name: "index_market_report_metrics_on_market_report_id"
    t.index ["taxonomy_term_id"], name: "index_market_report_metrics_on_taxonomy_term_id"
  end

  create_table "market_reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "embed_url"
    t.text "excerpt"
    t.string "market_name"
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "metrics", default: {}, null: false
    t.string "period", null: false
    t.datetime "published_at"
    t.string "region"
    t.text "seo_description"
    t.string "seo_title"
    t.string "slug", null: false
    t.string "source_name"
    t.string "source_url"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public", null: false
    t.index ["discarded_at"], name: "index_market_reports_on_discarded_at"
    t.index ["period"], name: "index_market_reports_on_period"
    t.index ["published_at"], name: "index_market_reports_on_published_at"
    t.index ["slug"], name: "index_market_reports_on_slug", unique: true
    t.index ["status"], name: "index_market_reports_on_status"
    t.index ["visibility"], name: "index_market_reports_on_visibility"
  end

  create_table "media_import_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "failed_items", default: 0, null: false
    t.datetime "finished_at"
    t.uuid "investment_card_id"
    t.uuid "newsletter_edition_id"
    t.integer "processed_items", default: 0, null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.integer "total_items", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["investment_card_id"], name: "index_media_import_batches_on_investment_card_id"
    t.index ["newsletter_edition_id"], name: "index_media_import_batches_on_newsletter_edition_id"
    t.index ["status"], name: "index_media_import_batches_on_status"
  end

  create_table "media_import_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "kind", null: false
    t.uuid "media_import_batch_id", null: false
    t.integer "position"
    t.datetime "processed_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["attempts"], name: "index_media_import_items_on_attempts"
    t.index ["media_import_batch_id"], name: "index_media_import_items_on_media_import_batch_id"
    t.index ["status"], name: "index_media_import_items_on_status"
  end

  create_table "newsletter_approval_comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.uuid "newsletter_edition_id", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["newsletter_edition_id"], name: "index_newsletter_approval_comments_on_newsletter_edition_id"
    t.index ["user_id"], name: "index_newsletter_approval_comments_on_user_id"
  end

  create_table "newsletter_contents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "alt_text"
    t.string "category"
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.string "cta_label"
    t.string "cta_target", default: "_self", null: false
    t.string "cta_url"
    t.text "description"
    t.datetime "discarded_at"
    t.date "event_date"
    t.string "event_location"
    t.time "event_time"
    t.string "event_timezone"
    t.boolean "favorite", default: false, null: false
    t.uuid "investment_card_id"
    t.datetime "last_used_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "published_at"
    t.string "registration_url"
    t.string "slug"
    t.string "status", default: "draft", null: false
    t.text "subtitle"
    t.jsonb "tags", default: [], null: false
    t.string "title", null: false
    t.string "tracking_key"
    t.datetime "updated_at", null: false
    t.integer "used_count", default: 0, null: false
    t.index ["content_type"], name: "index_newsletter_contents_on_content_type"
    t.index ["discarded_at"], name: "index_newsletter_contents_on_discarded_at"
    t.index ["favorite"], name: "index_newsletter_contents_on_favorite"
    t.index ["investment_card_id"], name: "index_newsletter_contents_on_investment_card_id"
    t.index ["last_used_at"], name: "index_newsletter_contents_on_last_used_at"
    t.index ["slug"], name: "index_newsletter_contents_on_slug", unique: true
    t.index ["status"], name: "index_newsletter_contents_on_status"
    t.index ["tracking_key"], name: "index_newsletter_contents_on_tracking_key"
    t.check_constraint "content_type::text = ANY (ARRAY['property'::character varying::text, 'article'::character varying::text, 'event'::character varying::text, 'banner'::character varying::text, 'cta'::character varying::text, 'testimonial'::character varying::text])", name: "newsletter_contents_type_allowed"
    t.check_constraint "cta_target::text = ANY (ARRAY['_self'::character varying::text, '_blank'::character varying::text])", name: "newsletter_contents_cta_target_valid"
  end

  create_table "newsletter_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "last_attempt_at"
    t.uuid "newsletter_edition_id", null: false
    t.uuid "newsletter_subscriber_id", null: false
    t.datetime "sent_at"
    t.string "status", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["attempts"], name: "index_newsletter_deliveries_on_attempts"
    t.index ["newsletter_edition_id", "newsletter_subscriber_id"], name: "index_newsletter_deliveries_on_edition_and_subscriber", unique: true
    t.index ["newsletter_edition_id"], name: "index_newsletter_deliveries_on_newsletter_edition_id"
    t.index ["newsletter_subscriber_id"], name: "index_newsletter_deliveries_on_newsletter_subscriber_id"
    t.index ["status"], name: "index_newsletter_deliveries_on_status"
    t.check_constraint "attempts >= 0 AND attempts <= 3", name: "newsletter_deliveries_attempts_valid"
  end

  create_table "newsletter_edition_segments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "newsletter_edition_id", null: false
    t.uuid "newsletter_segment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["newsletter_edition_id", "newsletter_segment_id"], name: "idx_edition_segments_unique", unique: true
    t.index ["newsletter_edition_id"], name: "index_newsletter_edition_segments_on_newsletter_edition_id"
    t.index ["newsletter_segment_id"], name: "index_newsletter_edition_segments_on_newsletter_segment_id"
  end

  create_table "newsletter_edition_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "change_note"
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.uuid "newsletter_edition_id", null: false
    t.jsonb "snapshot", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["created_by_id"], name: "index_newsletter_edition_versions_on_created_by_id"
    t.index ["newsletter_edition_id", "version_number"], name: "idx_edition_versions_unique", unique: true
    t.index ["newsletter_edition_id"], name: "index_newsletter_edition_versions_on_newsletter_edition_id"
  end

  create_table "newsletter_editions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "cta_label"
    t.string "cta_url"
    t.datetime "discarded_at"
    t.date "edition_date"
    t.text "excerpt"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "published_at"
    t.text "seo_description"
    t.string "seo_title"
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "public", null: false
    t.index ["discarded_at"], name: "index_newsletter_editions_on_discarded_at"
    t.index ["published_at"], name: "index_newsletter_editions_on_published_at"
    t.index ["slug"], name: "index_newsletter_editions_on_slug", unique: true
    t.index ["status"], name: "index_newsletter_editions_on_status"
    t.index ["visibility"], name: "index_newsletter_editions_on_visibility"
  end

  create_table "newsletter_metric_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "idempotency_key"
    t.string "link_url"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "newsletter_delivery_id"
    t.uuid "newsletter_edition_id", null: false
    t.datetime "occurred_at", null: false
    t.string "recipient_email"
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_newsletter_metric_events_on_idempotency_key", unique: true
    t.index ["newsletter_delivery_id"], name: "index_newsletter_metric_events_on_newsletter_delivery_id"
    t.index ["newsletter_edition_id", "event_type"], name: "idx_newsletter_metrics_lookup"
    t.index ["newsletter_edition_id"], name: "index_newsletter_metric_events_on_newsletter_edition_id"
    t.check_constraint "event_type::text = ANY (ARRAY['delivered'::character varying::text, 'opened'::character varying::text, 'clicked'::character varying::text, 'bounced'::character varying::text, 'unsubscribed'::character varying::text, 'spam_complaint'::character varying::text])", name: "newsletter_metric_events_type_allowed"
  end

  create_table "newsletter_segments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "conditions", default: [], null: false
    t.integer "contacts_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "logic", default: "and", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["logic"], name: "index_newsletter_segments_on_logic"
  end

  create_table "newsletter_subscribers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "consented_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "source"
    t.string "status", default: "subscribed", null: false
    t.datetime "subscribed_at"
    t.datetime "unsubscribed_at"
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_newsletter_subscribers_on_lower_email", unique: true
    t.index ["email"], name: "idx_newsletter_subscribers_email_unique", unique: true
    t.index ["metadata"], name: "index_newsletter_subscribers_on_metadata", using: :gin
    t.index ["status"], name: "index_newsletter_subscribers_on_status"
  end

  create_table "newsletter_template_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "change_note"
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.uuid "newsletter_template_id", null: false
    t.jsonb "snapshot", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["created_by_id"], name: "index_newsletter_template_versions_on_created_by_id"
    t.index ["newsletter_template_id", "version_number"], name: "idx_template_versions_unique", unique: true
    t.index ["newsletter_template_id"], name: "index_newsletter_template_versions_on_newsletter_template_id"
  end

  create_table "newsletter_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "blocks", default: [], null: false
    t.jsonb "branding", default: {}, null: false
    t.datetime "created_at", null: false
    t.boolean "default_template", default: false, null: false
    t.datetime "discarded_at"
    t.boolean "favorite", default: false, null: false
    t.string "name", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["default_template"], name: "idx_newsletter_templates_one_default", unique: true, where: "((default_template = true) AND (discarded_at IS NULL))"
    t.index ["discarded_at"], name: "index_newsletter_templates_on_discarded_at"
    t.index ["status"], name: "index_newsletter_templates_on_status"
  end

  create_table "site_analytics_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "device_type"
    t.string "event_type", null: false
    t.datetime "occurred_at", null: false
    t.string "path", null: false
    t.string "referrer_host"
    t.string "session_id", null: false
    t.string "target_path"
    t.string "utm_campaign"
    t.string "utm_medium"
    t.string "utm_source"
    t.index ["event_type", "occurred_at", "path"], name: "index_site_analytics_events_for_pages"
    t.index ["occurred_at"], name: "index_site_analytics_events_on_occurred_at"
    t.index ["session_id", "occurred_at"], name: "index_site_analytics_events_for_sessions"
  end

  create_table "site_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category", default: "general", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.boolean "public", default: false, null: false
    t.datetime "updated_at", null: false
    t.jsonb "value", default: {}, null: false
    t.index ["category"], name: "index_site_settings_on_category"
    t.index ["key"], name: "index_site_settings_on_key", unique: true
    t.index ["public"], name: "index_site_settings_on_public"
  end

  create_table "taxonomy_terms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.string "kind", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.uuid "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "active", "position"], name: "idx_taxonomy_terms_listing"
    t.index ["kind", "slug"], name: "index_taxonomy_terms_on_kind_and_slug", unique: true
    t.index ["parent_id"], name: "index_taxonomy_terms_on_parent_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "viewer", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "deal_submissions", "investment_cards", column: "converted_investment_card_id"
  add_foreign_key "favorites", "investment_cards"
  add_foreign_key "favorites", "users"
  add_foreign_key "investment_card_media", "investment_cards"
  add_foreign_key "investment_card_metrics", "investment_cards"
  add_foreign_key "investment_card_metrics", "taxonomy_terms"
  add_foreign_key "investment_cards", "investment_brokers"
  add_foreign_key "investment_cards", "investment_companies"
  add_foreign_key "investment_cards", "investment_locations"
  add_foreign_key "investment_cards", "taxonomy_terms", column: "asset_type_taxonomy_id"
  add_foreign_key "investment_cards", "taxonomy_terms", column: "category_taxonomy_id"
  add_foreign_key "investment_cards", "taxonomy_terms", column: "market_taxonomy_id"
  add_foreign_key "investment_cards", "taxonomy_terms", column: "strategy_taxonomy_id"
  add_foreign_key "investment_cards", "users", column: "curated_by_id"
  add_foreign_key "leads", "investment_cards"
  add_foreign_key "leads", "users", column: "assigned_to_id"
  add_foreign_key "market_report_metrics", "market_reports"
  add_foreign_key "market_report_metrics", "taxonomy_terms"
  add_foreign_key "media_import_batches", "investment_cards"
  add_foreign_key "media_import_batches", "newsletter_editions"
  add_foreign_key "media_import_items", "media_import_batches"
  add_foreign_key "newsletter_approval_comments", "newsletter_editions"
  add_foreign_key "newsletter_approval_comments", "users"
  add_foreign_key "newsletter_contents", "investment_cards"
  add_foreign_key "newsletter_deliveries", "newsletter_editions"
  add_foreign_key "newsletter_deliveries", "newsletter_subscribers"
  add_foreign_key "newsletter_edition_segments", "newsletter_editions"
  add_foreign_key "newsletter_edition_segments", "newsletter_segments"
  add_foreign_key "newsletter_edition_versions", "newsletter_editions"
  add_foreign_key "newsletter_edition_versions", "users", column: "created_by_id"
  add_foreign_key "newsletter_metric_events", "newsletter_deliveries"
  add_foreign_key "newsletter_metric_events", "newsletter_editions"
  add_foreign_key "newsletter_template_versions", "newsletter_templates"
  add_foreign_key "newsletter_template_versions", "users", column: "created_by_id"
  add_foreign_key "taxonomy_terms", "taxonomy_terms", column: "parent_id"
end
