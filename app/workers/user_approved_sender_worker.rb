# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class UserApprovedSenderWorker < BaseWorker

  # Sends a notification to the user with id `user_id` that he was approved.
  def self.perform(activity_id)
    activity = RecentActivity.find(activity_id)

    if !activity.notified?
      user_id = activity.trackable_id

      Resque.logger.info "Sending user approved email to #{user_id}"
      AdminMailer.new_user_approved(user_id).deliver

      activity.update_attribute(:notified, true)
    end
  end

end
