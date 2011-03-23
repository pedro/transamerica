Transamerica
============

[Transamerica][1] is a fun board game for 2-6 players.

This is an implementation of the rules of the game so programmers can write
bots to play it, and fight each other.


Game Rules
----------

Ironically I could only find the rules online in portuguese. Let me know if you
find anything.


Bot API
-------

Your bot can be defined in any class. It must respond to two methods:

    def position_hq(board, objective)

    def play(board, objective)

* `objective` is an array of cities you need to visit.

* `board` is a wrapper to game board.

Check for sample bots in the `bots` folder.


Playing games
-------------

Use the transamerica binary:

    transamerica bots/random.rb bots/mine.rb


TODO
----

* Change the API to run bots as new processes, allowing more languages and 
  avoiding simple hacks/security holes.

* Implement the official map

* Support different weight on edges

* Support the colored rails

* Support more command line options: running multiple games, defining who's
  the first player, print a summary, etc.

* Web API, etc


About
-----

Written by Pedro Belo.

Licensed as GPLv2 - once this gets to be the next eSport I'll want my share.

You you like this kind of thing you should probably check out my
[implementation of Flash Duel][2]

[1]: http://en.wikipedia.org/wiki/TransAmerica_(board_game) "Transamerica on Wikipedia"
[2]: https://github.com/pedro/flash-duel                    "Flash Duel"