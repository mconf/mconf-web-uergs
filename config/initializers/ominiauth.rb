Rails.application.config.middleware.use OmniAuth::Builder do
  # Put your moodle id, secret key and URL here
  # See https://github.com/mconf/omniauth-moodle/blob/master/README.md
  provider :moodle, 'your client id', 'your secret key', scope: 'user_info', site: 'https://yourmoodlewebsite.com'
end
