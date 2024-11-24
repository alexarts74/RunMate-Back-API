# Nettoyer la base de données
puts "Cleaning database..."
User.destroy_all
RunnerProfile.destroy_all

# Constantes pour plus de réalisme
CITIES = ["Paris", "Lyon", "Marseille", "Bordeaux", "Lille"]
AVAILABILITIES = ["matin", "après-midi", "soir", "week-end"]
PACES = ["5:00", "5:30", "6:00", "6:30", "7:00"]
OBJECTIVES = RunnerProfile::OBJECTIVES

puts "Creating users and their runner profiles..."

20.times do
  # Créer l'utilisateur
  user = User.create!(
    email: Faker::Internet.unique.email,
    password: "password123",
    name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    age: rand(18..60),
    gender: ["male", "female"].sample,
    location: CITIES.sample,
    bio: Faker::Lorem.paragraph(sentence_count: 2),
    profile_image: Faker::Avatar.image
  )

  # Créer son profil de coureur
  RunnerProfile.create!(
    user: user,
    actual_pace: PACES.sample,
    usual_distance: rand(5..21),
    availability: AVAILABILITIES.sample,
    objective: OBJECTIVES.sample
  )
end

puts "Created #{User.count} users with their runner profiles!"
puts "Created #{RunnerProfile.count} runner profiles!"
