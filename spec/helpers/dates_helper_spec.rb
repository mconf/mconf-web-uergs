# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

include Devise::TestHelpers

describe DatesHelper do
  describe "#formatted_time_ago" do
    it "uses a <span> tag"
    it "uses the correct text"
    it "uses the correct title"
    it "uses the options passed on the arguments"
    it "uses the options for time_ago_in_words passed on the arguments"
  end

  describe "#format_date" do
    context "returns the date formatted to show in a view" do
      it {
        d = DateTime.strptime('05/08/2015 12:00', "%d/%m/%Y %H:%M")
        format_date(d).should eql("05 Aug 12:00")
      }
      it {
        d = DateTime.strptime('01/12/1990 21:00', "%d/%m/%Y %H:%M")
        format_date(d).should eql("01 Dec 21:00")
      }
    end

    context "returns nil if the date is nil" do
      it { format_date(nil).should be_nil }
    end

    context "returns a localized string" do
      it {
        I18n.locale = "pt-br"
        d = DateTime.strptime('05/08/2015 12:00', "%d/%m/%Y %H:%M")
        format_date(d).should eql("05 Ago, 12:00")
      }
    end
  end
end
