# frozen_string_literal: true

class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache (Redis in production)
  if ENV["REDIS_URL"]
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
      url: ENV["REDIS_URL"],
      pool: { size: 5, timeout: 1 }
    )
  end

  # Disable throttling in test environment (except for rack_attack_spec)
  # The rack_attack_spec will enable it explicitly
  if Rails.env.test?
    Rack::Attack.enabled = false
  end

  ### Throttle Rules ###

  # Limit login attempts: 5 requests per 15 minutes per IP
  throttle("logins/ip", limit: 5, period: 15.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Limit login attempts by email: 5 per 15 minutes
  throttle("logins/email", limit: 5, period: 15.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize email
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # Limit password reset requests: 3 per hour per IP
  throttle("password_resets/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  # Limit password reset by email: 3 per hour
  throttle("password_resets/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # General API rate limit: 100 requests per minute per IP
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  ### Blocklist Rules ###

  # Block requests with suspicious patterns
  blocklist("block/sql_injection") do |req|
    # Block obvious SQL injection attempts
    req.query_string =~ /(\%27)|(\')|(\-\-)|(\%23)|(#)/i
  end

  ### Custom Responses ###

  # Return 429 Too Many Requests with helpful message
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = Time.zone.now

    retry_after = (match_data[:period] - (now.to_i % match_data[:period])).to_s

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after
      },
      [ { error: "Rate limit exceeded. Try again later.", retry_after: retry_after.to_i }.to_json ]
    ]
  end

  # Log blocked requests
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    Rails.logger.warn("[Rack::Attack] Throttled #{req.ip} on #{req.path}")
  end
end
