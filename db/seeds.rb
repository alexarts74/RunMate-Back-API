# Nettoyer la base de données
puts "Cleaning database..."
EventParticipation.destroy_all  # Supprimer d'abord les participations aux événements
GroupEvent.destroy_all         # Puis les événements
GroupMembership.destroy_all    # Puis les adhésions aux groupes
RunningGroup.destroy_all       # Puis les groupes
User.destroy_all

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

puts "\nCreating groups..."


GROUP_TYPES = [
  {
    name: "Les Runners du Mont-Blanc",
    description: "Groupe de trail et course en montagne",
    level: :advanced
  },
  {
    name: "Running Loisir",
    description: "Course à pied pour tous niveaux",
    level: :intermediate
  },
  {
    name: "Débutants Motivés",
    description: "Groupe pour débuter la course à pied",
    level: :beginner
  }
]

GROUP_IMAGES = [
  "https://images.unsplash.com/photo-1552674605-db6ffd4facb5", # Running en groupe
  "https://images.unsplash.com/photo-1571008887538-b36bb32f4571", # Trail
  "https://images.unsplash.com/photo-1486218119243-13883505764c", # Running urbain
  "https://images.unsplash.com/photo-1571902943202-507ec2618e8f", # Course en montagne
  "https://images.unsplash.com/photo-1549576490-b0b4831ef60a"  # Running au lever du soleil
]

EVENT_TYPES = [
  {
    title: "Sortie longue",
    distance: 15,
    pace: "6:00",
    description: "Sortie endurance à allure modérée"
  },
  {
    title: "Fractionné",
    distance: 8,
    pace: "4:30",
    description: "Session d'entraînement intensive"
  },
  {
    title: "Initiation Trail",
    distance: 10,
    pace: "7:00",
    description: "Découverte des sentiers de montagne"
  }
]
# Créer des groupes avec différents statuts
GROUP_TYPES.each do |group_type|
  CITIES.each do |city|
    creator = User.all.sample
    group = RunningGroup.create!(
      name: group_type[:name],
      description: group_type[:description],
      level: group_type[:level],
      max_members: rand(10..20),
      location: "#{city[:name]}, #{city[:department]}",
      creator: creator,
      weekly_schedule: [
        "Lundi 18:00",
        "Mercredi 18:30",
        "Samedi 9:00"
      ].sample(2),
      cover_image: GROUP_IMAGES.sample
    )

    # Ajouter des membres aléatoires
    rand(5..15).times do
      user = User.where.not(id: creator.id).sample
      GroupMembership.create(
        user: user,
        running_group: group,
        role: rand(10) == 0 ? :admin : :member
      ) unless group.members.include?(user)
    end

    EVENT_TYPES.each do |event_type|
      # Événements à venir
      2.times do |i|
        event = GroupEvent.create!(
          running_group: group,
          creator: group.members.sample,
          title: "#{event_type[:title]} ##{i+1}",
          date: Time.current + rand(1..30).days,
          meeting_point: "#{city[:name]}, #{Faker::Address.street_address}",
          distance: event_type[:distance],
          pace: event_type[:pace],
          description: event_type[:description],
          max_participants: rand(5..15),
          status: :scheduled
        )

        # Ajouter des participants
        rand(3..10).times do
          user = group.members.sample
          EventParticipation.create(
            user: user,
            group_event: event
          ) unless event.participants.include?(user)
        end
      end

      1.times do
        event = GroupEvent.create!(
          running_group: group,
          creator: group.members.sample,
          title: "#{event_type[:title]} (Passé)",
          date: Time.current - rand(1..30).days,
          meeting_point: "#{city[:name]}, #{Faker::Address.street_address}",
          distance: event_type[:distance],
          pace: event_type[:pace],
          description: event_type[:description],
          max_participants: rand(5..15),
          status: [:completed, :cancelled].sample
        )

        # Ajouter des participants aux événements passés
        rand(3..10).times do
          user = group.members.sample
          EventParticipation.create(
            user: user,
            group_event: event
          ) unless event.participants.include?(user)
        end
      end
    end
    print "."
  end
end

puts "\nSeeding completed!"
puts "Created #{User.count} users"
puts "Created #{RunningGroup.count} groups"
puts "Created #{GroupMembership.count} group memberships"
puts "Created #{GroupEvent.count} events"
puts "Created #{EventParticipation.count} event participations"

# Vérifications finales
puts "\nVérifications :"
puts "Groupes pleins : #{RunningGroup.where(status: :full).count}"
puts "Événements à venir : #{GroupEvent.upcoming.count}"
puts "Événements passés : #{GroupEvent.past.count}"
