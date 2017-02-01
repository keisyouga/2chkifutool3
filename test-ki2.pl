
use strict;
use warnings;
use utf8;
use ShogiBoard;

my $game = new ShogiBoard();
$game->display_board;
print "\n";

open(my $fh, '< :encoding(cp932)', $ARGV[0]) or die 'cannot open < $ARGV[0]';

my @record;
for my $str (<$fh>) {
	@record = ();
	if ($str =~ /：/) { next; }
	if ($str =~ /^\*/) { next; }
	$str =~ s/[▲△][^▲△]*/push(@record, $&)/eg;

	for my $r (@record) {
		print "continue..."; getc;
		print "$r\n";
		$game->move_ki2($r);
		$game->display_board; 
	}
}
