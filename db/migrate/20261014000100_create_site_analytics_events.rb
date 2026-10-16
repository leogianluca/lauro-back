class CreateSiteAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :site_analytics_events, id: :uuid do |t|
      t.string :event_type, null: false
      t.string :path, null: false
      t.string :target_path
      t.string :session_id, null: false
      t.string :referrer_host
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_campaign
      t.string :device_type
      t.datetime :occurred_at, null: false
    end

    add_index :site_analytics_events, :occurred_at
    add_index :site_analytics_events, [ :event_type, :occurred_at, :path ], name: "index_site_analytics_events_for_pages"
    add_index :site_analytics_events, [ :session_id, :occurred_at ], name: "index_site_analytics_events_for_sessions"
  end
end
