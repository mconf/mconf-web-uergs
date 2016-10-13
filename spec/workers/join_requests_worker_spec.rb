# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

describe JoinRequestsWorker, type: :worker do
  let(:worker) { JoinRequestsWorker }
  let(:senderInv) { JoinRequestInviteSenderWorker }
  let(:senderS) { JoinRequestSenderWorker }
  let(:senderProc) { ProcessedJoinRequestSenderWorker }
  let(:space) { FactoryGirl.create(:space) }
  let(:queue) { Queue::High }
  let(:paramsInv) {{"method"=>:perform, "class"=>senderInv.to_s}}
  let(:paramsS) {{"method"=>:perform, "class"=>senderS.to_s}}
  let(:paramsProc) {{"method"=>:perform, "class"=>senderProc.to_s}}

  describe "#perform" do

    context "enqueues all unnotified invites" do
      let!(:join_request1) { FactoryGirl.create(:space_join_request_invite, group: space) }
      let!(:join_request2) { FactoryGirl.create(:space_join_request_invite, group: space) }
      let!(:join_request3) { FactoryGirl.create(:space_join_request_invite, group: space) }
      before {
        # clear automatically created activities
        RecentActivity.destroy_all

        @activity = [join_request1, join_request2, join_request3].map(&:new_activity)

        @activity[0].update_attribute(:notified, false)
        @activity[1].update_attribute(:notified, nil)
        @activity[2].update_attribute(:notified, true)
      }

      before(:each) { worker.perform }
      it { expect(queue).to have_queue_size_of(2) }
      it { expect(queue).to have_queued(paramsInv, @activity[0].id) }
      it { expect(queue).to have_queued(paramsInv, @activity[1].id) }
      it { expect(queue).not_to have_queued(paramsInv, @activity[2].id) }
    end

    context "enqueues all unnotified requests" do
      let!(:join_request1) { FactoryGirl.create(:space_join_request, group: space) }
      let!(:join_request2) { FactoryGirl.create(:space_join_request, group: space) }
      let!(:join_request3) { FactoryGirl.create(:space_join_request, group: space) }
      before {
        # clear automatically created activities
        RecentActivity.destroy_all

        @activity = [join_request1, join_request2, join_request3].map(&:new_activity)

        @activity[0].update_attribute(:notified, false)
        @activity[1].update_attribute(:notified, nil)
        @activity[2].update_attribute(:notified, true)
      }

      before(:each) { worker.perform }
      it { expect(queue).to have_queue_size_of(2) }
      it { expect(queue).to have_queued(paramsS, @activity[0].id) }
      it { expect(queue).to have_queued(paramsS, @activity[1].id) }
      it { expect(queue).not_to have_queued(paramsS, @activity[2].id) }
    end

    context "for unnotified processed requests" do
      context "enqueues all " do
        let!(:join_request1) { FactoryGirl.create(:space_join_request, group: space, :accepted => true) }
        let!(:join_request2) { FactoryGirl.create(:space_join_request, group: space, :accepted => true) }
        let!(:join_request3) { FactoryGirl.create(:space_join_request, group: space, :accepted => true) }
        before {
          # clear automatically created activities
          RecentActivity.destroy_all

          @activity1 = join_request1.new_activity(:accept)
          @activity2 = join_request2.new_activity(:accept)
          @activity3 = join_request3.new_activity(:accept)
          @activity1.update_attribute(:notified, false)
          @activity2.update_attribute(:notified, nil)
          @activity3.update_attribute(:notified, true)
        }

        before(:each) { worker.perform }
        it { expect(queue).to have_queue_size_of(2) }
        it { expect(queue).to have_queued(paramsProc, @activity1.id) }
        it { expect(queue).to have_queued(paramsProc, @activity2.id) }
        it { expect(queue).not_to have_queued(paramsProc, @activity3.id) }
      end

      context "ignores requests declined by admins" do
        let!(:join_request1) { FactoryGirl.create(:space_join_request, group: space) }
        let!(:join_request2) { FactoryGirl.create(:space_join_request, group: space, :accepted => true) }
        let!(:join_request3) { FactoryGirl.create(:space_join_request, group: space) }
        before {
          join_request1.update_attributes :accepted => false, :processed => true
          join_request3.update_attributes :accepted => false, :processed => true

          # clear automatically created activities
          RecentActivity.destroy_all

          @activity1 = join_request1.new_activity(:decline)
          @activity2 = join_request2.new_activity(:decline)
          @activity3 = join_request3.new_activity(:decline)
        }

        before(:each) { worker.perform }
        it { expect(queue).to have_queue_size_of(1) }
        it { expect(queue).to have_queued(paramsProc, @activity2.id) }
      end

      #
      # Trackables on RecentActivities accept/decline are now join_requests and this is
      # unecessary
      # context "ignores requests that are not owned by join requests" do
      #   let!(:join_request1) { FactoryGirl.create(:space_join_request, group: space, accepted: true) }
      #   let!(:join_request2) { FactoryGirl.create(:space_join_request, group: space, accepted: true) }
      #   let!(:join_request3) { FactoryGirl.create(:space_join_request, group: space, accepted: true) }
      #   before {
      #     # clear automatically created activities
      #     RecentActivity.destroy_all

      #     @activity1 = join_request1.new_activity(:decline)
      #     @activity1.update_attributes(owner: space)
      #     @activity2 = join_request2.new_activity(:decline)
      #     @activity2.update_attributes(owner: space)
      #     @activity3 = join_request3.new_activity(:decline)
      #   }

      #   before(:each) { worker.perform }
      #   it { expect(ProcessedJoinRequestSenderWorker).to have_queue_size_of(1) }
      #   it { expect(ProcessedJoinRequestSenderWorker).to have_queued(@activity3.id) }
      # end

      context "warns introducer about declined invitations" do
        let!(:join_request1) { FactoryGirl.create(:space_join_request, group: space, :request_type => 'invite') }
        let!(:join_request2) { FactoryGirl.create(:space_join_request, group: space, :request_type => 'invite', :accepted => true) }
        let!(:join_request3) { FactoryGirl.create(:space_join_request, group: space, :request_type => 'invite') }
        before {
          join_request1.update_attributes :accepted => false, :processed => true
          join_request3.update_attributes :accepted => false, :processed => true

          # clear automatically created activities
          RecentActivity.destroy_all

          @activity1 = join_request1.new_activity(:decline)
          @activity2 = join_request2.new_activity(:decline)
          @activity3 = join_request3.new_activity(:decline)
        }

        before(:each) { worker.perform }
        it { expect(queue).to have_queue_size_of(3) }
        it { expect(queue).to have_queued(paramsProc, @activity1.id) }
        it { expect(queue).to have_queued(paramsProc, @activity2.id) }
        it { expect(queue).to have_queued(paramsProc, @activity3.id) }
      end
    end
  end

end
