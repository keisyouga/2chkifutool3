use strict;
use warnings;
use utf8;
use ShogiBoard;

my $game = new ShogiBoard();
$game->display_board;

$game->move({from => 77, to => 76, piece => 'P'});
$game->display_board;
$game->move({from => 33, to => 34, piece => 'p'});
$game->display_board;
$game->move({from => 88, to => 22, piece => 'B', promote => 1});
$game->display_board;
$game->move({from => 31, to => 22, piece => 's'});
$game->display_board;
$game->move({from => '00', to => 45, piece => 'B', drop => 1});
$game->display_board;
$game->move({from => 61, to => 52, piece => 'g'});
$game->display_board;
