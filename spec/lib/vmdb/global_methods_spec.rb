require "spec_helper"
require 'vmdb_helper'

describe Vmdb::GlobalMethods do
  before do
    _, @server, _ = EvmSpecHelper.create_guid_miq_server_zone
    class TestClass
      include Vmdb::GlobalMethods
    end
  end

  after do
    Object.send(:remove_const, :TestClass)
  end

  subject { TestClass.new }

  context "#get_timezone_offset" do
    context "for a server" do
      it "with a system default" do
        stub_server_configuration(:server => {:timezone => "Eastern Time (US & Canada)"})

        Timecop.freeze(Time.utc(2013, 1, 1)) do
          subject.get_timezone_offset.should == -5.hours
        end
      end

      it "without a system default" do
        stub_server_configuration({})
        subject.get_timezone_offset.should == 0.hours
      end
    end

    context "for a user" do
      it "who doesn't exist" do
        subject.get_timezone_offset(nil).should == 0.hours
      end

      it "with a timezone" do
        user = FactoryGirl.create(:user, :settings => {:display => {:timezone => "Pacific Time (US & Canada)"}})
        Timecop.freeze(Time.utc(2013, 1, 1)) do
          subject.get_timezone_offset(user).should == -8.hours
        end
      end

      context "without a timezone" do
        it "with a system default" do
          user = FactoryGirl.create(:user)
          stub_server_configuration(:server => {:timezone => "Eastern Time (US & Canada)"})

          Timecop.freeze(Time.utc(2013, 1, 1)) do
            subject.get_timezone_offset(user).should == -5.hours
          end
        end

        it "with a system default and nil user" do
          stub_server_configuration(:server => {:timezone => "Eastern Time (US & Canada)"})
          Timecop.freeze(Time.utc(2013, 1, 1)) do
            subject.get_timezone_offset(nil).should == -5.hours
          end
        end

        it "without a system default" do
          user = FactoryGirl.create(:user)
          stub_server_configuration({})

          subject.get_timezone_offset(user).should == 0.hours
        end
      end
    end
  end

  context "#get_timezone_for_userid" do
    context "for a user" do
      it "who doesn't exist" do
        subject.get_timezone_for_userid("missing").should == "UTC"
      end

      it "who is nil with system default" do
        stub_server_configuration(:server => {:timezone => "Eastern Time (US & Canada)"})
        subject.get_timezone_for_userid(nil).should == "Eastern Time (US & Canada)"
      end

      it "with a timezone" do
        user = FactoryGirl.create(:user, :settings => {:display => {:timezone => "Pacific Time (US & Canada)"}})
        subject.get_timezone_for_userid(user).should == "Pacific Time (US & Canada)"
      end

      # currently only used in 1 place
      it "with name lookup" do
        user = FactoryGirl.create(:user, :settings => {:display => {:timezone => "Pacific Time (US & Canada)"}})
        subject.get_timezone_for_userid(user.userid).should == "Pacific Time (US & Canada)"
      end

      context "without a timezone" do
        it "with a system default" do
          stub_server_configuration(:server => {:timezone => "Eastern Time (US & Canada)"})

          user = FactoryGirl.create(:user)
          subject.get_timezone_for_userid(user).should == "Eastern Time (US & Canada)"
        end

        it "without a system default" do
          stub_server_configuration({})

          user = FactoryGirl.create(:user)
          subject.get_timezone_for_userid(user).should eq("UTC")
        end
      end
    end
  end
end
