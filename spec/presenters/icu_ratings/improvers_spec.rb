require 'spec_helper'

module IcuRatings
  describe Improvers do
    describe "insufficient data" do
      it "should be unavailable if there are no rating lists" do
        i = Improvers.new({})
        i.available?.should be false
      end

      it "should be unavailable if there is only one rating list" do
        FactoryGirl.create(:icu_rating, list: "2011-09-01", icu_player: FactoryGirl.create(:icu_player))
        i = Improvers.new({})
        i.available?.should be false
      end
    end

    describe "enough data" do
      before(:each) do
        @l1 = "2010-09-01"
        @l2 = "2011-01-01"
        @l3 = "2011-05-01"
        @l4 = "2011-09-01"

        @p1 = FactoryGirl.create(:icu_player)
        FactoryGirl.create(:icu_rating, list: @l1, rating: 1000, icu_player: @p1)
        FactoryGirl.create(:icu_rating, list: @l2, rating: 1500, icu_player: @p1)
        FactoryGirl.create(:icu_rating, list: @l3, rating: 1500, icu_player: @p1)
        FactoryGirl.create(:icu_rating, list: @l4, rating: 2000, icu_player: @p1)

        @p2 = FactoryGirl.create(:icu_player)
        FactoryGirl.create(:icu_rating, list: @l1, rating: 1400, icu_player: @p2)
        FactoryGirl.create(:icu_rating, list: @l2, rating: 1500, icu_player: @p2)
        FactoryGirl.create(:icu_rating, list: @l3, rating: 1600, icu_player: @p2)
        FactoryGirl.create(:icu_rating, list: @l4, rating: 1700, icu_player: @p2)

        FactoryGirl.create(:icu_rating, list: @l1, icu_player: FactoryGirl.create(:icu_player))
        FactoryGirl.create(:icu_rating, list: @l2, icu_player: FactoryGirl.create(:icu_player))
        FactoryGirl.create(:icu_rating, list: @l3, icu_player: FactoryGirl.create(:icu_player))
        FactoryGirl.create(:icu_rating, list: @l4, icu_player: FactoryGirl.create(:icu_player))
      end

      it "default settings" do
        params = {}
        i = Improvers.new(params)
        i.available?.should be true
        i.from.to_s.should == @l1
        i.upto.to_s.should == @l4
        i.rows.size.should == 2
        i.rows.first.player.id.should == @p1.id
        i.rows.first.diff.should == 1000
        i.rows.last.player.id.should == @p2.id
        i.rows.last.diff.should == 300
      end

      it "specific lists" do
        params = { from: @l2, upto: @l3 }
        i = Improvers.new(params)
        i.available?.should be true
        i.from.to_s.should == @l2
        i.upto.to_s.should == @l3
        i.rows.size.should == 2
        i.rows.first.player.id.should == @p2.id
        i.rows.first.diff.should == 100
        i.rows.last.player.id.should == @p1.id
        i.rows.last.diff.should == 0
      end
    end
  end
end
