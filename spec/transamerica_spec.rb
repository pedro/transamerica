module Transamerica
  describe "Transamerica" do
    include Transamerica

    let(:p1)     { Bot.new("p1") }
    let(:p2)     { Bot.new("p2") }
    let(:board)  { Board.new(5, 5) }
    let(:game)   { Engine.new(board, [p1, p2]) }

    let(:sf)     { City.new("SF", :red) }
    let(:la)     { City.new("LA", :red) }

    context "assigning objectives" do
      context "when there are not enough cities" do
        before do
          board.add_city([0, 0], sf)
        end

        it "raises" do
          lambda { game.objectives }.should raise_error(SetupError)
        end
      end

      context "when there are enough cities" do
        before do
          board.add_city([0,0], sf)
          board.add_city([1,0], la)
          game.stub!(:cities_per_color).and_return({ :red => [sf, la] })
        end

        it "gives a city from each color to each user" do
          game.objectives.should == { p1 => [la], p2 => [sf] }
        end
      end
    end

    describe "setup" do
      before do
        game.stub!(:objectives).and_return({
          p1 => [sf],
          p2 => [la],
        })
      end
      
      it "asks each player to position their HQs telling them their objective" do
        p1.should_receive(:position_hq).with(board, [sf]).and_return [0, 0]
        p2.should_receive(:position_hq).with(board, [la]).and_return [1, 0]
        game.setup
      end
      
      it "doesn't allow players to put the HQ on the same place" do
        p1.should_receive(:position_hq).and_return [0, 0]
        p2.should_receive(:position_hq).and_return [0, 0]
        lambda { game.setup }.should raise_error(PlayerError)
      end
    end

    context "gameplay" do
      before do
        board.add_hq([0,0], p1.id)
        board.add_hq([3,0], p2.id)
        board.add_city([4,0], la)
        board.add_city([1,1], sf)
        game.stub!(:objectives).and_return({
          p1 => [sf],
          p2 => [la],
        })
        game.current = 0
      end

      context "rail placement rules" do
        it "must be an array of positions" do
          p1.should_receive(:play).and_return(:wtf => true)
          lambda { game.step }.should raise_error(PlayerError, /must return an array/)
        end

        it "must be specified like [x, y, :direction]" do
          p1.should_receive(:play).and_return([[0, 0]])
          lambda { game.step }.should raise_error(PlayerError, /invalid play/)
        end

        it "only allows certain directions" do
          p1.should_receive(:play).and_return([[0, 0, :wtf]])
          lambda { game.step }.should raise_error(PlayerError, /wrong direction/)
        end

        it "requires at least one rail" do
          p1.should_receive(:play).and_return([])
          lambda { game.step }.should raise_error(PlayerError, /at least one/)
        end

        it "allows 2 rails max" do
          p1.should_receive(:play).and_return([[0, 0, :r], [1, 0, :r], [2, 0, :r]])
          lambda { game.step }.should raise_error(PlayerError, /two rails max/)
        end

        it "makes sure the position of all rails are inside the board" do
          p1.should_receive(:play).and_return([[10, 0, :r]])
          lambda { game.step }.should raise_error(PlayerError, /is outside the board/)
        end

        it "doesn't allow going off the board" do
          p1.should_receive(:play).and_return([[0, 0, :l]])
          lambda { game.step }.should raise_error(PlayerError, /goes outside the board/)
        end

        it "doesn't allow putting rails on an edge already taken" do
          board.add_rail([0, 0, :r])
          p1.should_receive(:play).and_return([[0, 0, :r]])
          lambda { game.step }.should raise_error(PlayerError, /already taken/)
        end

        it "doesn't allow placing rails not connected to the player hq" do
          p1.should_receive(:play).and_return([[2, 0, :l]])
          lambda { game.step }.should raise_error(PlayerError, /not connected/)
        end
      end

      context "winning" do
        before do
          game.stub!(:objectives).and_return({ p1 => [sf, la], p2 => [sf, la] })
        end

        it "starts without a winner" do
          game.winner.should be_nil
        end

        it "doesn't have a winner when a player didn't visit all his objectives" do
          board.add_rail([0, 0, :r])
          board.add_rail([1, 0, :r])
          board.add_rail([2, 0, :r])
          p1.should_receive(:play).and_return([[3, 0, :r]])
          game.step
          game.winner.should be_nil
        end

        it "has a winner when a player visits all cities in his objectives" do
          board.add_rail([0, 0, :r])
          board.add_rail([1, 0, :r])
          board.add_rail([2, 0, :r])
          board.add_rail([3, 0, :r])
          p1.should_receive(:play).and_return([[0, 0, :rd]])
          game.step
          game.winner.should == p1
        end
      end
    end
  end

  describe Board do
    let(:board) { Board.new(3, 3) }

    context "positioning" do
      it "moves left" do
        board.at_adjusted([1, 1, :l]).pos.should == [0, 1]
      end

      it "moves left up" do
        board.at_adjusted([1, 1, :lu]).pos.should == [0, 0]
      end

      it "moves left down" do
        board.at_adjusted([1, 1, :ld]).pos.should == [1, 2]
      end

      it "moves right" do
        board.at_adjusted([1, 1, :r]).pos.should == [2, 1]
      end

      it "moves right up" do
        board.at_adjusted([1, 1, :ru]).pos.should == [1, 0]
      end

      it "moves right down" do
        board.at_adjusted([1, 1, :rd]).pos.should == [2, 2]
      end
    end

    context "opposite directions" do
      it "opposite of left is right" do
        board.opposite_direction(:r).should == :l
      end

      it "opposite of left up is right down" do
        board.opposite_direction(:lu).should == :rd
      end
    end
  end
end
