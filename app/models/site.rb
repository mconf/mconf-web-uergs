# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class Site < ActiveRecord::Base

  # Returns the current (default) site
  def self.current
    first || create
  end

  def signature_in_html
    if signature
      return signature.gsub(/\r\n?/,'<br>')
    else
      return ""
    end
  end

  # HTTP protocol based on SSL setting
  def protocol
    "http#{ ssl? ? 's' : nil }"
  end

  # Domain http url considering protocol
  # e.g. http://server.org
  def domain_with_protocol
    "#{protocol}://#{domain}"
  end

  # Nice formatted email address for the Site
  def email_with_name
    "#{name} <#{email}>"
  end

  # Indicates whether event related pages should be shown or not.
  # Events are only shown if they are enabled in the site and also if their routes
  # were loaded. This prevents the application from breaking when enabling the
  # event module and before restarting the application to load the routes.
  def show_events?
    read_attribute(:events_enabled) && configatron.events.routes_loaded
  end

end
