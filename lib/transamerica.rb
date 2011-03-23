module Transamerica
  class Board
    attr_accessor :cities

    DIRECTIONS = {
      :l  => [-1, 0],
      :lu => [-1, -1],
      :ld => [-1, 1],
      :r  => [1, 0],
      :ru => [1, -1],
      :rd => [1, 1],
    }

    def initialize(cols, rows)
      @cities = {}
      @hqs    = {}
      @adjacency = {}

      @grid = Array.new(cols)
      (0..cols).each do |x|
        @grid[x] = Array.new(rows)
        (0..rows).each do |y|
          @grid[x][y] = Node.new(x, y)
        end
      end
    end

    def add_city(pos, city)
      @cities[city] = pos
      city.pos = at(pos)
      at(pos).city = city
    end

    def add_hq(pos, player_id)
      @hqs[player_id] = pos
      at(pos).hq = player_id
    end

    def add_rail(pos)
      dir  = pos.last
      from = at(pos)
      to   = at_adjusted(pos)

      adjacency(from) << dir
      adjacency(to)   << opposite_direction(dir)
    end

    def adjacency(node_or_position)
      pos = node_or_position
      pos = node_or_position.pos if node_or_position.is_a?(Node)
      @adjacency[pos] ||= []
    end

    def at(x, y=nil)
      x, y, dir = *x if !y
      return nil if x < 0 || y < 0
      return if !@grid[x]
      @grid[x][y]
    end

    def at_adjusted(pos)
      x, y, dir = *pos
      return unless from = at(x, y)
      adjust_x, adjust_y = DIRECTIONS[dir]
      at(x + adjust_x, y + adjust_y)
    end

    def opposite_direction(direction)
      adjustment = DIRECTIONS[direction]
      opposite   = adjustment.map { |i| i * -1 } 
      DIRECTIONS.invert[opposite]
    end

    def connected?(node, player_id)
      hq_location = @hqs[player_id]
      stack = [at(hq_location)]
      track = {}
      while current = stack.pop
        next if track[current]
        track[current] = true

        return true if current == node
        adjacency(current).each do |direction|
          stack << at_adjusted(current.pos + [direction])
        end
      end
    end
  end

  class Node
    attr_accessor :x, :y, :hq, :city
    def initialize(x, y)
      @x = x
      @y = y
    end

    def has_hq?
      !hq.nil?
    end

    def pos
      [x, y]
    end
  end

  class City
    attr_accessor :name, :color, :pos

    def initialize(name, color)
      @name  = name
      @color = color
    end
  end

  class Bot
    attr_accessor :id
    def initialize(id)
      @id = id
    end

    def inspect
      "Bot #{id}"
    end
  end

  class SetupError < Exception
  end

  class PlayerError < Exception
    attr_accessor :player

    def initialize(player, message=nil)
      @player = player
      super "Wrong action from #{player}: #{message}"
    end
  end

  class Engine
    attr_accessor :board, :players, :current, :winner

    def initialize(board, players)
      @board   = board
      @players = players
      @current = 0
    end

    def cities_per_color
      @cities ||= board.cities.keys.group_by(&:color)
    end

    def objectives
      @objectives ||= {}.tap do |o|
        cities_per_color.each do |color, cities|
          raise SetupError if cities.size < players.size
          players.each { |p| o[p] ||= []; o[p] << cities.pop }
          cities.clear if cities.size < players.size
        end
      end
    end

    def setup
      players.each do |player|
        pos = player.position_hq(board, objectives[player])
        raise PlayerError.new(player, "node already has a HQ") if board.at(pos).has_hq?
        board.add_hq(pos, player.id)
      end
    end

    def step
      player = players[current]
      rails  = player.play(board.dup, objectives[player])
      raise PlayerError.new(player, "must return an array of rails") unless rails.is_a?(Array)
      raise PlayerError.new(player, "must place at least one rail")  unless rails.size > 0
      raise PlayerError.new(player, "can place two rails max")       if rails.size > 2

      rails.each do |pos|
        raise PlayerError.new(player, "invalid play: #{pos.inspect}. return an array of rails like [[x, y, :direction]]") \
          unless pos.is_a?(Array) && pos.size == 3 && [0, 1].all? { |x| pos[x].is_a?(Numeric) } && pos[2].is_a?(Symbol)
        raise PlayerError.new(player, "wrong direction: #{pos[2]}. allowed are: #{Board::DIRECTIONS.keys.inspect}") \
          unless Board::DIRECTIONS.keys.include? pos[2]
        raise PlayerError.new(player, "play #{pos.inspect} is outside the board") \
          unless from = board.at(pos)
        raise PlayerError.new(player, "play #{pos.inspect} goes outside the board") \
          unless to = board.at_adjusted(pos)
        raise PlayerError.new(player, "position #{pos.inspect} already taken") \
          if board.adjacency(from).include? pos.last
        raise PlayerError.new(player, "position #{pos.inspect} not connected to your hq") \
          unless board.connected?(to, player.id) || board.connected?(from, player.id)

        board.add_rail(pos)
        check_winner
      end
    end

    def check_winner
      self.winner = players.detect do |player|
        objectives[player].all? { |city| board.connected?(city.pos, player.id)}
      end
    end
  end
end