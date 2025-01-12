class User < ApplicationRecord
    attr_accessor :skip_password_validation
    # attr_accessor :expo_push_token

    devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable
    has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
    has_many :received_messages, class_name: 'Message', foreign_key: 'recipient_id', dependent: :destroy
    has_one :runner_profile, dependent: :destroy
    has_many :notifications, dependent: :destroy
    has_many :created_groups, class_name: 'RunningGroup', foreign_key: 'creator_id'
    has_many :group_memberships
    has_many :running_groups, through: :group_memberships
    has_many :created_events, class_name: 'GroupEvent', foreign_key: 'creator_id'
    has_many :event_participations
    has_many :group_events, through: :event_participations
    

    geocoded_by :full_address
    after_validation :geocode, if: :should_geocode?

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true,
                      uniqueness: true,
                      format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, unless: :skip_password_validation
    validates :age, presence: true
    validates :bio, presence: true
    validates :profile_image, presence: true
    validates :authentication_token, presence: true, uniqueness: true
    validates :city, presence: true
    validates :department, presence: true
    validates :country, presence: true

    before_create :generate_authentication_token
    before_validation :ensure_authentication_token, on: :create

    def ensure_authentication_token
        if authentication_token.blank?
            self.authentication_token = generate_authentication_token
            save(validate: false)
        end
        authentication_token
    end

    def destroy_messages
        Message.where('sender_id = ? OR recipient_id = ?', id, id).destroy_all
    end

     def full_address
      [city, department, country].compact.join(', ')
    end

    def should_geocode?
      city_changed? || department_changed? || country_changed?
    end

    def nearby_users(distance_km = 20)
      User.near([latitude, longitude], distance_km, units: :km)
          .where.not(id: id)
    end

    def distance_to_user(other_user)
      return nil unless other_user&.latitude && other_user&.longitude
      distance_to([other_user.latitude, other_user.longitude])
    end

    def as_json(options = {})
      super(options).tap do |json|
        json['expo_push_token'] = read_attribute(:expo_push_token)
        if options[:include_location]
          json['distance'] = options[:distance] if options[:distance]
          json['location'] = {
            city: city,
            department: department,
            postcode: postcode,
            country: country,
            latitude: latitude,
            longitude: longitude
          }
        end
      end
    end

    private

    def generate_authentication_token
        loop do
            token = SecureRandom.hex(20)
            break token unless User.where(authentication_token: token).exists?
        end
    end
end
