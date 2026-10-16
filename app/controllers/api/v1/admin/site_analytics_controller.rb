module Api
  module V1
    module Admin
      class SiteAnalyticsController < BaseController
        def show
          return render_error(code: "forbidden", message: "Admin access is required.", status: :forbidden) unless current_user.admin?

          days = params[:days].to_i
          days = 30 unless [ 7, 30, 90 ].include?(days)
          report_zone = Time.find_zone!("America/Sao_Paulo")
          end_date = report_zone.today
          start_date = end_date - (days - 1)
          start_time = start_date.in_time_zone(report_zone).beginning_of_day
          end_time = (end_date + 1).in_time_zone(report_zone).beginning_of_day
          events = SiteAnalyticsEvent.where(occurred_at: start_time...end_time)
          page_views = events.where(event_type: "page_view")
          clicks = events.where(event_type: "navigation_click")
          first_page_views = page_views
            .select("DISTINCT ON (session_id) session_id, utm_source, utm_campaign, referrer_host, device_type")
            .reorder(Arel.sql("session_id, occurred_at ASC, id ASC"))
          sessions = SiteAnalyticsEvent.from("(#{first_page_views.to_sql}) site_analytics_events")
          daily_counts = page_views
            .group("DATE(occurred_at AT TIME ZONE 'UTC' AT TIME ZONE 'America/Sao_Paulo')")
            .count
            .transform_keys(&:to_s)

          render_success(data: {
            days: days,
            start_date: start_date.iso8601,
            end_date: end_date.iso8601,
            time_zone: "America/Sao_Paulo",
            page_views: page_views.count,
            sessions: sessions.count,
            navigation_clicks: clicks.count,
            direct_sessions: sessions.where("NULLIF(utm_source, '') IS NULL AND NULLIF(referrer_host, '') IS NULL").count,
            top_pages: ranked(page_views, :path),
            top_destinations: ranked(clicks, :target_path),
            sources: ranked(sessions, :utm_source),
            campaigns: ranked(sessions, :utm_campaign),
            referrers: ranked(sessions, :referrer_host),
            devices: ranked(sessions, :device_type),
            daily: (start_date..end_date).map { |day| { date: day.iso8601, count: daily_counts.fetch(day.iso8601, 0) } }
          })
        end

        private

        def ranked(scope, column)
          scope.where.not(column => [ nil, "" ]).group(column).order(Arel.sql("COUNT(*) DESC")).limit(10).count.map do |label, count|
            { label: label, count: count }
          end
        end
      end
    end
  end
end
