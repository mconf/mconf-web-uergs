# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class JoinRequestsWorker < BaseWorker

  # Finds all join requests with pending notifications and sends them
  def self.perform
    request_notifications
    invite_notifications
    processed_request_notifications
    user_added_notifications
  end

  # Goes through all activities for join requests created by admins inviting users to join a space
  # and enqueues a notification for each.
  def self.invite_notifications
    invites = RecentActivity.where trackable_type: 'JoinRequest', key: 'join_request.invite', notified: [nil,false]
    invites.each do |activity|
      Queue::High.enqueue(JoinRequestInviteSenderWorker, :perform, activity.id)
    end
  end

  # Goes through all activities for join requests created by users to join a space and enqueues
  # a notification for each.
  def self.request_notifications
    requests = RecentActivity.where trackable_type: 'JoinRequest', key: 'join_request.request', notified: [nil,false]
    requests.each do |activity|
      Queue::High.enqueue(JoinRequestSenderWorker, :perform, activity.id)
    end
  end

  # Goes through all activities for processed join requests for which the users have not been
  # notified yet, and enqueues a notification for each.
  def self.processed_request_notifications
    requests = RecentActivity.where trackable_type: 'JoinRequest', key: ['join_request.accept', 'join_request.decline'], notified: [nil,false]
    requests = requests.all.reject do |req|
      jr = req.trackable

      # don't generate email for blank join requests, declined user requests or if the owner is not a join request
      !jr.is_a?(JoinRequest) || jr.blank? || (jr.is_request? && !jr.accepted?)
    end

    requests.each do |activity|
      Queue::High.enqueue(ProcessedJoinRequestSenderWorker, :perform, activity.id)
    end
  end

  def self.user_added_notifications
    joins = RecentActivity.where trackable_type: 'JoinRequest', key: ['join_request.no_accept'], notified: [nil, false]

    joins.each do |activity|
      Queue::High.enqueue(JoinRequestUserAddedSenderWorker, :perform, activity.id)
    end
  end
end
