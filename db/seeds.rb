# Nettoyer la base de données
puts "Cleaning database..."
EventParticipation.destroy_all  # Supprimer d'abord les participations aux événements
Event.destroy_all               # Puis les événements
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
    name: "Sortie longue",
    distance: 15,
    pace: "6:00",
    description: "Sortie endurance à allure modérée",
    level: :intermediate
  },
  {
    name: "Fractionné",
    distance: 8,
    pace: "4:30",
    description: "Session d'entraînement intensive",
    level: :advanced
  },
  {
    name: "Initiation Trail",
    distance: 10,
    pace: "7:00",
    description: "Découverte des sentiers de montagne",
    level: :beginner
  },
  {
    name: "Course tranquille",
    distance: 5,
    pace: "6:30",
    description: "Sortie décontractée entre coureurs",
    level: :beginner
  }
]

puts "\nCreating events..."

# Créer des événements dans chaque ville
CITIES.each do |city|
  EVENT_TYPES.each do |event_type|
    # Événements à venir (2 par type)
    2.times do |i|
      # Ajouter un peu de randomisation aux coordonnées pour disperser les événements
      lat_offset = rand(-0.005..0.005)
      lng_offset = rand(-0.005..0.005)

      creator = User.all.sample
      event = Event.create!(
        creator: creator,
        name: "#{event_type[:name]} ##{i+1}",
        start_date: Time.current + rand(1..30).days,
        location: "#{city[:name]}, #{Faker::Address.street_address}",
        distance: event_type[:distance],
        pace: event_type[:pace],
        description: event_type[:description],
        max_participants: rand(5..15),
        level: event_type[:level],
        status: :upcoming,
        latitude: city[:coords][0] + lat_offset,
        longitude: city[:coords][1] + lng_offset
      )

      # Ajouter des participants aléatoires
      rand(3..10).times do
        user = User.where.not(id: creator.id).sample
        EventParticipation.create(
          user: user,
          event: event
        ) unless event.participants.include?(user)
      end
    end

    # Événements passés (1 par type)
    # Ajouter un peu de randomisation aux coordonnées
    lat_offset = rand(-0.005..0.005)
    lng_offset = rand(-0.005..0.005)

    event = Event.create!(
      creator: User.all.sample,
      name: "#{event_type[:name]} (Passé)",
      start_date: Time.current - rand(1..30).days,
      location: "#{city[:name]}, #{Faker::Address.street_address}",
      distance: event_type[:distance],
      pace: event_type[:pace],
      description: event_type[:description],
      max_participants: rand(5..15),
      level: event_type[:level],
      status: [:completed, :cancelled].sample,
      latitude: city[:coords][0] + lat_offset,
      longitude: city[:coords][1] + lng_offset
    )

    # Ajouter des participants aux événements passés
    rand(3..10).times do
      user = User.all.sample
      EventParticipation.create(
        user: user,
        event: event
      ) unless event.participants.include?(user)
    end
  end
  print "."
end

puts "\nSeeding completed!"
puts "Created #{User.count} users"
puts "Created #{Event.count} events"
puts "Created #{EventParticipation.count} event participations"

# Vérifications finales
puts "\nVérifications :"
puts "Événements à venir : #{Event.upcoming.count}"
puts "Événements passés : #{Event.past.count}"
puts "Événements par niveau :"
Event.group(:level).count.each do |level, count|
  puts "- #{level}: #{count}"
end

puts "\nVérification des coordonnées :"
puts "Événements sans latitude : #{Event.where(latitude: nil).count}"
puts "Événements sans longitude : #{Event.where(longitude: nil).count}"

puts "\nCreating private groups..."

# Créer des groupes privés dans chaque ville
CITIES.each do |city|
  GROUP_TYPES.each do |group_type|
    # Création du groupe privé
    creator = User.all.sample
    private_group = RunningGroup.create!(
      name: "#{group_type[:name]} - #{city[:name]}",
      description: "#{group_type[:description]} à #{city[:name]} - Groupe privé sur invitation",
      level: group_type[:level],
      max_members: rand(5..15),
      location: "#{city[:name]}, #{city[:department]}",
      creator: creator,
      weekly_schedule: ["Lundi 19:00", "Jeudi 18:30", "Samedi 10:00"].sample(2),
      cover_image: GROUP_IMAGES.sample,
      visibility: :private_group
    )

    # Ajouter des membres au groupe privé
    rand(3..8).times do
      user = User.where.not(id: creator.id).sample
      GroupMembership.create(
        user: user,
        running_group: private_group,
        role: rand(10) == 0 ? :admin : :member
      ) unless private_group.members.include?(user)
    end
  end
  print "."
end

# Ajouter l'utilisateur test à quelques groupes privés
test_user = User.find_by(email: "test@example.com")
# Utiliser where au lieu de private_group
private_groups = RunningGroup.limit(3)  # Tous les groupes sont privés maintenant

private_groups.each do |group|
  GroupMembership.create!(
    user: test_user,
    running_group: group,
    role: :member
  ) unless group.members.include?(test_user)
end

puts "\nGroups created!"
puts "Created #{RunningGroup.count} private groups"
puts "Created #{GroupMembership.count} group memberships"
puts "Test user is member of #{test_user.running_groups.count} groups"

puts "\nCreating join requests..."

# Créer quelques demandes d'adhésion pour chaque groupe
RunningGroup.all.each do |group|
  # Sélectionner des utilisateurs qui ne sont pas déjà membres
  non_members = User.where.not(id: group.members.pluck(:id)).sample(rand(2..5))

  non_members.each do |user|
    JoinRequest.create!(
      user: user,
      running_group: group,
      message: Faker::Lorem.sentence,
      status: :pending
    )
  end
  print "."
end

puts "\nJoin requests created!"
puts "Created #{JoinRequest.count} join requests"

# Créer quelques demandes d'adhésion pour l'utilisateur test
non_member_groups = RunningGroup.where.not(id: test_user.running_groups.pluck(:id)).sample(2)
non_member_groups.each do |group|
  JoinRequest.create!(
    user: test_user,
    running_group: group,
    message: "Demande de test",
    status: :pending
  )
end

puts "Test user has #{test_user.join_requests.count} pending join requests"
