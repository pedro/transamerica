class SequentialBot
  def position_hq(board, objectives)
    begin
      place = pick_random(board)
    end while place.has_hq?
    @path = [place.pos]
    puts "hq at #{@path.inspect}"
    @path.first
  end

  def play(board, objectives)
    @path.reverse.each do |pos|
      directions_to_try = Transamerica::Board::DIRECTIONS.keys - board.adjacency(pos)
      directions_to_try.each do |dir|
        move = pos + [dir]
        next unless new_place = board.at_adjusted(move)
        @path << new_place.pos
        puts "going for #{move.inspect}"
        return [move]
      end
    end
  end
  def pick_random(board)
    board.at(rand(board.cols), rand(board.rows))
  end
end