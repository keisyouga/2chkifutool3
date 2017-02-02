# 同局面検索
# unzip -c 2chkifu.zip | perl test-find 'G.........G.........G'

use strict;
use warnings;

use utf8;
use ShogiBoard;

binmode(STDIN, ':encoding(cp932) :crlf');
binmode(STDERR, ':utf8');
binmode(STDOUT, ':utf8');

#----------------------------------------
# global variable
#----------------------------------------
my %gameinfo = ();
my $num_game = 0;
my @query;
my $mode;
my $fh_bin;
my $fh_info;
my $BINFILENAME = '2chkifu.bin';
my $INFOFILENAME = '2chkifu.info';

#----------------------------------------
# main
#----------------------------------------
{

	if (@ARGV) {
		$_ = $ARGV[0];
		if (/^-move/) {
			$mode = 'move';
			shift @ARGV;
			for (@ARGV) {
				utf8::decode $_;
				$_ = unify_number($_);
			}
			@query = @ARGV;
		}
		elsif (/^-board/) {
			$mode = 'board';
			shift @ARGV;
			@query = @ARGV;
		}
		elsif (/^-mkdb/) {
			$mode = 'mkdb';
			open($fh_bin, '>>', $BINFILENAME)
				or die "cannot open >> $BINFILENAME, $!";
			open($fh_info, '>> :utf8', $INFOFILENAME)
				or die "cannot open >> $INFOFILENAME, $!";
		}
		elsif (/^-help/) {
			usage();
			exit;
		} else {
			$mode = 'board';
			@query = @ARGV;
		}
	} else {
		# usage
		usage();
		exit;
	}
	print STDERR "mode:$mode\n";
	print STDERR "query:@query\n";

	# 2chkifu.bin 2chkifu.info があればそれを読む
	if ($mode eq 'board'
			and (open($fh_bin, '<', $BINFILENAME))
			and (open($fh_info, '< :utf8', $INFOFILENAME))) {
#		print STDERR $BINFILENAME, $INFOFILENAME, "\n";
		my $b16;
		my $infoline = <$fh_info>;
		( $gameinfo{tesuu}, $gameinfo{startingdate},
			$gameinfo{sente}, $gameinfo{gote}, $gameinfo{kisen},
			$gameinfo{komaoti}, $gameinfo{filename}) = split(/\t/, $infoline);
		my $num_moves;
		my $game = new ShogiBoard;
		set_komaoti($game);

		while (read($fh_bin, $b16, 2)) {
			if ($b16 eq "\x00\x00") {
				$infoline = <$fh_info>;
				last if !$infoline;

				( $gameinfo{tesuu}, $gameinfo{startingdate},
					$gameinfo{sente}, $gameinfo{gote}, $gameinfo{kisen},
					$gameinfo{komaoti}, $gameinfo{filename}) = split(/\t/, $infoline);
				$game = new ShogiBoard;
				set_komaoti($game);
				$num_moves = 0;
				next;
			}

			$game->move_16bit($b16);
			$num_moves++;

			if (compare_board($game, @query)) {
				print $num_moves . ":";
				display_info();
			}

		}
		exit;
	}

	my $buf = '';
	# 標準入力から棋譜を読む
	while (my $line = <STDIN>) {
		#print $line;

		# unzip -c で `inflating: ファイル名' が出力されるのを想定している
		if ($line =~ /inflating:(.*)$/) {
			do_1ki2($buf);
			%gameinfo = ();
			$gameinfo{filename} = $1;
			$buf = '';
		}

		# unzip -p でも動くように
		if (!$gameinfo{filename} and $line =~ /^開始日時：/) {
			do_1ki2($buf);
			%gameinfo = ();
			$buf = '';
		}
		$buf = $buf . $line;
	}
	# 最後の棋譜
	do_1ki2($buf);
}

sub set_komaoti {
	my ($game) = @_;

	if ($gameinfo{komaoti} =~ /^平手/) {
		return 1;
	}
	elsif ($gameinfo{komaoti} =~ /^香落/) {
		$game->set_piece(11, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^角落/) {
		$game->set_piece(22, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^飛車落/) {
		$game->set_piece(82, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^飛香落/) {
		$game->set_piece(82, '_');
		$game->set_piece(11, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^二枚落/) {
		$game->set_piece(82, '_');
		$game->set_piece(22, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^四枚落/) {
		$game->set_piece(82, '_');
		$game->set_piece(22, '_');
		$game->set_piece(11, '_');
		$game->set_piece(91, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^六枚落/) {
		$game->set_piece(82, '_');
		$game->set_piece(22, '_');
		$game->set_piece(11, '_');
		$game->set_piece(91, '_');
		$game->set_piece(21, '_');
		$game->set_piece(81, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^六枚落/) {
		$game->set_piece(82, '_');
		$game->set_piece(22, '_');
		$game->set_piece(11, '_');
		$game->set_piece(91, '_');
		$game->set_piece(21, '_');
		$game->set_piece(81, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^右香落/) {
		$game->set_piece(91, '_');
	}
	elsif ($gameinfo{komaoti} =~ /^三枚落/) {
		$game->set_piece(82, '_');
		$game->set_piece(22, '_');
		$game->set_piece(11, '_');
	} else {
		# TODO:
		print STDERR "komaoti: ", $gameinfo{komaoti}, "\n";

		return 0;
	}
	return 1;
}

# /^開始日時：/ で区切られた文字列に対する処理
sub do_1ki2 {
	my ($buf) = @_;

	my $str = ki2_1game($buf);
	$str = unify_number($str);
	$str =~ tr/ 　//d;
	my @record = ();
	$str =~ s/[▲△][^▲△]*/push(@record, $&)/eg;
#	print "$_\n" for (@record);

	$num_game++ if @record;

	if ($mode eq 'move') {
		if (@record) {
			my $i = compare_move(\@record, \@query);
			# 一致した
			if ($i > 0) {
				display_info();
				print "\t";
				print $record[$i];
				print "\n";
			}
		}
	} elsif ($mode eq 'board') {
		my $game = new ShogiBoard;
		return if !set_komaoti($game);
		for my $i (0 .. $#record) {
			$game->move_ki2($record[$i]);
			if (compare_board($game, @query)) {
				print $i + 1 . ":";
				display_info();
				print "\t";
				print $record[$i];
				print "\n";
			}
		}
	}
	elsif ($mode eq 'mkdb') {
		my $game = new ShogiBoard;
		return if !set_komaoti($game);
		for my $i (0 .. $#record) {
			$game->move_ki2($record[$i]);
			my $data = $game->get_16bitmove;
			print $fh_bin $data;
		}
		if (@record) {
			print $fh_info scalar @record;
			print $fh_info "\t";
			display_info($fh_info);
			print $fh_info "\n";
			print $fh_bin "\x00\x00";

			print STDERR $num_game, "\n" if ($num_game % 1000 == 0);
		}
	}
}

# $ki2data : 1局分のki2形式文字列
# 指し手を1つの文字列にして返す
# %gameinfo に情報をセットする
sub ki2_1game {
	my ($ki2data) = @_;

	my $str = '';

	$gameinfo{komaoti} = '平手';
	for (split($/, $ki2data)) {
		#print "<$_>\n";
		if (/^\*/) { next; }
		elsif (/^開始日時：(.*)$/) {
			$gameinfo{startingdate} = $1;
		}
		elsif (/^先手：(.*)$/) {
			$gameinfo{sente} = $1;
		}
		elsif (/^後手：(.*)$/) {
			$gameinfo{gote} = $1;
		}
		elsif (/^上手：(.*)$/) {
			$gameinfo{uwate} = $1;
		}
		elsif (/^下手：(.*)$/) {
			$gameinfo{sitate} = $1;
		}
		elsif (/棋戦：(.*)$/) {
			$gameinfo{kisen} = $1;
		}
		elsif (/^手合割：(.*)$/) {
			$gameinfo{komaoti} = $1;
		}
		elsif (/：/) {
			# 無視
			next;
		}
		elsif (/^消費時間/) {
			# 無視
			next;
		}
		elsif (/まで/) {
			# 「まで」が行頭にこないファイルもある
			last;
		}
		# 指し手
		$str .= $_;
	}
	return $str;
}

sub unify_number {
	my ($numstr) = @_;
	$numstr =~ tr/１２３４５６７８９０一二三四五六七八九〇/12345678901234567890/;
	return $numstr;
}

sub compare_board {
	my ($game) = shift;
	my @query = @_;

	for (@query) {
		if ($game->{board} !~ /$_/) {
			return 0;
		}
	}
	return 1;
}

sub compare_move {
	my ($a, $b) = @_;
	my $i;

	for ($i = 0; $i < scalar @$b; $i++) {
#		print "$a->[$i], $b->[$i]\n";
		if (!$a->[$i] or $a->[$i] !~ $b->[$i]) {
			return 0;
		}
	}
	return $i;
}

sub display_info {
	my ($fh) = @_;
	if (!$fh) {
		$fh = \*STDOUT;
	}
	print($fh exists $gameinfo{startingdate} ? $gameinfo{startingdate} : '');
	print($fh "\t");
	print($fh exists $gameinfo{sente} ? $gameinfo{sente} : $gameinfo{sitate});
	print($fh "\t");
	print($fh exists $gameinfo{gote} ? $gameinfo{gote} : $gameinfo{uwate});
	print($fh "\t");
	print($fh exists $gameinfo{kisen} ? $gameinfo{kisen} : '');
	print($fh "\t");
	print($fh exists $gameinfo{komaoti} ? $gameinfo{komaoti} : '平手');
	print($fh "\t");
	print($fh exists $gameinfo{filename} ? $gameinfo{filename} : '');
}

sub usage {
	print "usage:\n  unzip -c 2chkifu.zip | perl $0 <query> ...\n";
}
