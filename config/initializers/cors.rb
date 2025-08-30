Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins case Rails.env
            when 'development'
              'http://localhost:3000'
            when 'test'
              '*'
            else
              ENV['FRONTEND_URL'] || '*'
            end
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end