class TestUserSeed
  def self.seed
    puts "Seeding test users..."

    # Create 4 test users for the golf group
    users = [
      {
        name: "Vik Ristic",
        email: "vik.ristic@gmail.com",
        password: "password123",
        admin: true
      },
      {
        name: "Friend One",
        email: "friend1@example.com",
        password: "password123",
        admin: false
      },
      {
        name: "Friend Two",
        email: "friend2@example.com",
        password: "password123",
        admin: false
      },
      {
        name: "Friend Three",
        email: "friend3@example.com",
        password: "password123",
        admin: false
      }
    ]

    users.each do |user_data|
      user = User.create!(user_data)
      user.ensure_authentication_token!
      puts "Created user: #{user.name} (#{user.email})"
    end

    puts "User seeding completed!"
  end
end
