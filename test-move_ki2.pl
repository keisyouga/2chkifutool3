
use strict;
use warnings;
use utf8;
use ShogiBoard;

my $game = new ShogiBoard();
$game->display_board;
print "\n";

$game->move_ki2('▲７六歩');
$game->display_board;
$game->move_ki2('△３四歩');
$game->display_board;
$game->move_ki2('▲２二角成');
$game->display_board;
$game->move_ki2('△同　銀');
$game->display_board;
$game->move_ki2('▲４五角');
$game->display_board;
$game->move_ki2('△５二金右');
$game->display_board;
