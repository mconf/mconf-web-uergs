Rails.application.config.middleware.use OmniAuth::Builder do
  provider :moodle, "mconf_web", 'cad8465a05e6174c2ec4f8df6a532fce0ef05eb6402fe85c', scope: 'user_info', site: 'http://10.0.3.185'
end
