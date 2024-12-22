# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.
Rails.application.config.filter_parameters -= [:token]

Rails.application.config.filter_parameters += [
  :passw, :secret, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  { token: ->(key, value) { key != "expo_push_token" } }
]
