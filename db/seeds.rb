# Nettoyer la base de données
puts "Cleaning database..."
User.destroy_all
RunnerProfile.destroy_all

# Constantes pour plus de réalisme
CITIES = [
  {
    name: "Sallanches",
    department: "Haute-Savoie",
    coords: [45.9340, 6.6300],
    postcode: "74700"
  },
  {
    name: "Chamonix",
    department: "Haute-Savoie",
    coords: [45.9237, 6.8694],
    postcode: "74400"
  },
  {
    name: "Annecy",
    department: "Haute-Savoie",
    coords: [45.8992, 6.1294],
    postcode: "74000"
  },
  {
    name: "Megève",
    department: "Haute-Savoie",
    coords: [45.8567, 6.6174],
    postcode: "74120"
  }
]

PACES = ["5:00", "5:30", "6:00", "6:30", "7:00"]
AVAILABILITIES = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
OBJECTIVES = RunnerProfile::OBJECTIVES

puts "Creating users and their runner profiles..."

# Assurer une meilleure distribution des objectifs
OBJECTIVES.each do |objective|
  CITIES.each do |city|
    3.times do
      # Ajouter un peu de randomisation aux coordonnées pour disperser les coureurs
      lat_offset = rand(-0.01..0.01)
      lng_offset = rand(-0.01..0.01)

      user = User.create!(
        email: Faker::Internet.unique.email,
        password: "password",
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        age: rand(18..60),
        gender: ["male", "female"].sample,
        city: city[:name],
        department: city[:department],
        country: "France",
        postcode: city[:postcode],
        latitude: city[:coords][0] + lat_offset,
        longitude: city[:coords][1] + lng_offset,
        bio: Faker::Lorem.paragraph(sentence_count: 2),
        profile_image: Faker::Avatar.image
      )

      # Créer un tableau de 2-4 disponibilités aléatoires
      random_availabilities = AVAILABILITIES.sample(rand(2..4))

      RunnerProfile.create!(
        user: user,
        actual_pace: PACES.sample,
        usual_distance: rand(5..21),
        availability: random_availabilities.to_json,
        objective: objective
      )

      print "."
    end
  end
end

# Créer un utilisateur de test
test_user = User.create!(
  email: "test@example.com",
  password: "password",
  first_name: "Test",
  last_name: "User",
  age: 30,
  gender: "male",
  city: "Sallanches",
  department: "Haute-Savoie",
  country: "France",
  postcode: "74700",
  latitude: 45.9340,
  longitude: 6.6300,
  bio: "Test user for development",
  profile_image: Faker::Avatar.image
)

RunnerProfile.create!(
  user: test_user,
  actual_pace: "6:00",
  usual_distance: 10,
  availability: ["monday", "wednesday", "saturday"].to_json,
  objective: OBJECTIVES.first
)

puts "\nTest user created:"
puts "Email: test@example.com"
puts "Password: password"
puts "Token: #{test_user.authentication_token}"
puts "Location: Sallanches (#{test_user.latitude}, #{test_user.longitude})"

puts "\nCreated #{User.count} users with their runner profiles!"
puts "Created #{RunnerProfile.count} runner profiles!"

# Vérification finale
puts "\nVérification des géolocalisations..."
non_geocoded = User.where(latitude: nil).count
puts "Utilisateurs sans géolocalisation : #{non_geocoded}"
