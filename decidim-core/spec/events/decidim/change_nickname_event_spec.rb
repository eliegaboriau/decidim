# frozen_string_literal: true

require "spec_helper"

describe Decidim::ChangeNicknameEvent do
  include_context "when a simple event"

  let(:event_name) { "decidim.events.change_nickname_event" }
  let(:resource) { create :user }
  let(:author) { resource }

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title).to include("<p><strong> Your nickname has been modified </strong></p> Go to your profile to see the modification")
    end
  end
end
