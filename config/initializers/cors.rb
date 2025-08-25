Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins Rails.env.development? ? 'http://localhost:3000' : ENV['FRONTEND_URL']
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end