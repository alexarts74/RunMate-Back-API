# Nettoyer la base de données
puts "Cleaning database..."
User.destroy_all
RunnerProfile.destroy_all

# Constantes pour plus de réalisme
CITIES = ["Paris", "Lyon", "Marseille", "Bordeaux", "Lille"]
PACES = ["5:00", "5:30", "6:00", "6:30", "7:00"]
AVAILABILITIES = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
OBJECTIVES = RunnerProfile::OBJECTIVES

puts "Creating users and their runner profiles..."

# Assurer une meilleure distribution des objectifs
OBJECTIVES.values.each do |objective|
  CITIES.each do |city|
    3.times do
      user = User.create!(
        email: Faker::Internet.unique.email,
        password: "toto",
        name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        age: rand(18..60),
        gender: ["male", "female"].sample,
        location: city,
        bio: Faker::Lorem.paragraph(sentence_count: 2),
        profile_image: Faker::Avatar.image,
        authentication_token: Devise.friendly_token
      )

      # Créer un tableau de 2-4 disponibilités aléatoires
      random_availabilities = AVAILABILITIES.sample(rand(2..4))

      RunnerProfile.create!(
        user: user,
        actual_pace: PACES.sample,
        usual_distance: rand(5..21),
        availability: random_availabilities.to_json, # Convertir en JSON
        objective: objective
      )
    end
  end
end

test_user = User.first
puts "Test user token: #{test_user.authentication_token}"

puts "Created #{User.count} users with their runner profiles!"
puts "Created #{RunnerProfile.count} runner profiles!"
