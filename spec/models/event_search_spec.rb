require 'spec_helper'

describe Event do
  shared_examples_for "#search" do
    it "returns everything when searching by empty string" do
      event1 = FactoryGirl.create(:event)
      event2 = FactoryGirl.create(:event)
      Event.search("").should =~ [event1, event2]
    end

    it "searches event titles by substring" do
      event1 = FactoryGirl.create(:event, title: "wtfbbq")
      event2 = FactoryGirl.create(:event, title: "zomg!")
      Event.search("zomg").should == [event2]
    end

    it "searches event descriptions by substring" do
      event1 = FactoryGirl.create(:event, description: "wtfbbq")
      event2 = FactoryGirl.create(:event, description: "zomg!")
      Event.search("zomg").should == [event2]
    end

    it "searches event tags by exact match" do
      event1 = FactoryGirl.create(:event, tag_list: ["wtf", "bbq", "zomg"])
      event2 = FactoryGirl.create(:event, tag_list: ["wtf", "bbq", "omg"])
      Event.search("omg").should == [event2]
    end

    it "searches multiple terms" do
      event1 = FactoryGirl.create(:event, title: "wtf")
      event2 = FactoryGirl.create(:event, title: "zomg!")
      event3 = FactoryGirl.create(:event, title: "bbq")
      Event.search("wtf zomg").should =~ [event1, event2]
    end

    it "searches case-insensitively" do
      event1 = FactoryGirl.create(:event, title: "WTFBBQ")
      event2 = FactoryGirl.create(:event, title: "ZOMG!")
      Event.search("zomg").should == [event2]
    end

    it "sorts by start time descending" do
      event2 = FactoryGirl.create(:event, start_time: 1.day.ago)
      event1 = FactoryGirl.create(:event, start_time: 1.day.from_now)
      Event.search("").should == [event1, event2]
    end

    it "can sort by event title" do
      event2 = FactoryGirl.create(:event, title: "zomg")
      event1 = FactoryGirl.create(:event, title: "omg")
      Event.search("", order: "name").should == [event1, event2]
    end

    it "can sort by venue title" do
      event2 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "zomg"))
      event1 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "omg"))
      Event.search("", order: "venue").should == [event1, event2]
    end

    it "can limit to current and upcoming events" do
      event1 = FactoryGirl.create(:event, start_time: 1.year.ago)
      event2 = FactoryGirl.create(:event, start_time: Time.zone.today)
      event3 = FactoryGirl.create(:event, start_time: 1.year.from_now)
      Event.search("", skip_old: true).should == [event3, event2]
    end

    it "can limit number of events" do
      2.times { FactoryGirl.create(:event) }
      Event.search("", limit: 1).length.should == 1
    end
  end

  describe "Sql" do
    around do |example|
      original = Event::SearchEngine.kind
      Event::SearchEngine.kind = :sql
      example.run
      Event::SearchEngine.kind = original
    end

    it_should_behave_like "#search"

    it "searches event urls by substring" do
      event1 = FactoryGirl.create(:event, url: "http://example.com/wtfbbq.html")
      event2 = FactoryGirl.create(:event, url: "http://example.com/zomg.html")
      Event.search("zomg").should == [event2]
    end
  end

  describe "Sunspot" do
    around do |example|
      server_running = begin
        solr = Sunspot::Rails::Server.new
        Process.getpgid(File.read(solr.pid_path).to_i)
      rescue Errno::ESRCH, Errno::ENOENT; end

      if server_running
        original = Event::SearchEngine.kind
        Event::SearchEngine.kind = :sunspot
        example.run
        Event::SearchEngine.kind = original
      else
        pending "Solr not running. Start with `rake sunspot:solr:start RAILS_ENV=test`"
      end
    end

    it_should_behave_like "#search"

    it "searches event urls by substring" do
      skip "figure how to implement selective substring matching in Sunspot"
      event1 = FactoryGirl.create(:event, url: "http://example.com/wtfbbq.html")
      event2 = FactoryGirl.create(:event, url: "http://example.com/zomg.html")
      Event.search("zomg").should == [event2]
    end
  end
end

