Rails.application.config.middleware.use OmniAuth::Builder do

  # Put your oauth2 configurations in setup_conf.yml and they will be used here
  # Example:
  #   oauth2:
  #     moodle:
  #       client_id: 'your client id'
  #       secret_key: 'your secret_key'
  #       site: 'https://yourmoodlewebsite.com'
  # See https://github.com/mconf/omniauth-moodle/blob/master/README.md
  configatron.oauth2.to_hash.each do |name, info|
    provider name.to_sym, info[:client_id], info[:secret_key], scope: 'user_info', site: info[:site]
  end

end
