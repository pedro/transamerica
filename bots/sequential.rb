class SequentialBot
  def position_hq(board, objectives)
    begin
      place = pick_random(board)
    end while place.has_hq?
    place.pos
  end

  def play(board, objectives)
    @my_direction ||= :r
    @last_node    ||= board.hqs[self.id]
    @directions_tried = 0

    adjust_direction while !new_place = board.at_adjusted(move)
    current_move = move 
    @last_node = new_place.pos
    return [current_move]
  end

  def adjust_direction
    case @my_direction
      when :r
        @my_direction = :ld
      when :ld
        @my_direction = :l
      when :l
        @my_direction = :rd
      when :rd
        @my_direction = :r
    end
  end

  def move
    @last_node + [@my_direction]
  end

  def pick_random(board)
    board.at(rand(board.cols), rand(board.rows))
  end
end