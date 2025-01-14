users_data = [
  {
    fields: {
      email: "user1@example.com",
      password: "pw1234",
      name: "John Daily",
      admin: false
    }
  },
  {
    fields: {
      email: "user2@example.com",
      password: "pw1234",
      name: "Eldrick Woods",
      admin: true
    }
  },
  {
    fields: {
      email: "user3@example.com",
      password: "pw1234",
      name: "Nelly Korda",
      admin: false
    }
  },
  {
    fields: {
      email: "user4@example.com",
      password: "pw1234",
      name: "Rory McIlroy",
      admin: false
    }
  }
]

# Seed the users
users_data.each do |user_data|
  fields = user_data[:fields] # Access the fields using a symbol
  
  User.create!(
    email: fields[:email], # Use symbols here
    password: fields[:password],
    name: fields[:name],
    admin: fields[:admin]
  )
end