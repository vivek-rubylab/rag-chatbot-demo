# Rate limiting via Rack::Attack.
#
# Two rules protect the message creation endpoint:
#   1. Per-user throttle  — 20 messages per minute for authenticated users
#   2. Per-IP throttle    — 10 messages per minute for unauthenticated traffic
#
# Limits are intentionally conservative for a public demo with live API keys.
# Adjust RATE_LIMIT_RPM / RATE_LIMIT_ANON_RPM env vars to suit your deployment.
#
# Disabled in test environment to keep tests unaffected.

class Rack::Attack
  RPM      = ENV.fetch("RATE_LIMIT_RPM",      20).to_i
  ANON_RPM = ENV.fetch("RATE_LIMIT_ANON_RPM", 10).to_i

  # Authenticated users identified by their session user_id
  throttle("messages/user", limit: RPM, period: 60) do |req|
    if req.post? && req.path.match?(%r{\A/chats/\d+/messages\z})
      req.session["warden.user.user.key"]&.flatten&.first
    end
  end

  # IP-based fallback (covers unauthenticated or session-less requests)
  throttle("messages/ip", limit: ANON_RPM, period: 60) do |req|
    req.ip if req.post? && req.path.match?(%r{\A/chats/\d+/messages\z})
  end

  # Return 429 JSON so Turbo / JS clients get a machine-readable response
  self.throttled_responder = lambda do |_req|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "Too many requests. Please wait a moment before sending another message." }.to_json]
    ]
  end
end

# Mount the middleware (no-op in test)
Rails.application.config.middleware.use Rack::Attack unless Rails.env.test?
