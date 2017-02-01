use strict;
use warnings;

package ShogiBoard;

use utf8;
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

#----------------------------------------
# variables

# 16bit に入れるために駒の種類に数字をつけておく
my %PIECE_TO_NUMBER = (
	'P' => 1,
	'L' => 2,
	'N' => 3,
	'S' => 4,
	'G' => 5,
	'B' => 6,
	'R' => 7,
	'K' => 8,
	'T' => 9,
	'A' => 10,
	'I' => 11,
	'V' => 12,
	'H' => 13,
	'D' => 14,
	'p' => 15,
	'l' => 16,
	'n' => 17,
	's' => 18,
	'g' => 19,
	'b' => 20,
	'r' => 21,
	'k' => 22,
	't' => 23,
	'a' => 24,
	'i' => 25,
	'v' => 26,
	'h' => 27,
	'd' => 28, 
); 
my %NUMBER_TO_PIECE = (
	1	=> 'P',
	2	=> 'L',
	3	=> 'N',
	4	=> 'S',
	5	=> 'G',
	6	=> 'B',
	7	=> 'R',
	8	=> 'K',
	9	=> 'T',
	10	=> 'A',
	11	=> 'I',
	12	=> 'V',
	13	=> 'H',
	14	=> 'D',
	15	=> 'p',
	16	=> 'l',
	17	=> 'n',
	18	=> 's',
	19	=> 'g',
	20	=> 'b',
	21	=> 'r',
	22	=> 'k',
	23	=> 't',
	24	=> 'a',
	25	=> 'i',
	26	=> 'v',
	27	=> 'h',
	28 	=> 'd',
);

my $BOARD_INITIAL = 
'lnsgkgsnl/' .
'_r_____b_/' .
'ppppppppp/' .
'_________/' .
'_________/' .
'_________/' .
'PPPPPPPPP/' .
'_B_____R_/' .
'LNSGKGSNL';

# 駒の動きリスト
# +18 +8 -2 -12 -22
# +19 +9 -1 -11 -21
# +20 +10 0 -10 -20
# +21 +11 +1 -9 -19
# +22 +12 +2 -8 -18
# 1回の動き
my %CANMOVES1 = (
	'P' => [-1],
	'p' => [1],

	'N' => [8, -12],
	'n' => [-8, 12],

	'S' => [9, -1, -11, -9, 11],
	's' => [-9, 1, 11, 9, -11],

	'G' => [9, -1, -11, 10, -10, 1],
	'T' => [9, -1, -11, 10, -10, 1],
	'A' => [9, -1, -11, 10, -10, 1],
	'I' => [9, -1, -11, 10, -10, 1],
	'V' => [9, -1, -11, 10, -10, 1],

	'g' => [-9, 1, 11, -10, 10, -1],
	't' => [-9, 1, 11, -10, 10, -1],
	'a' => [-9, 1, 11, -10, 10, -1],
	'i' => [-9, 1, 11, -10, 10, -1],
	'v' => [-9, 1, 11, -10, 10, -1],

	'K' => [9, 10, 11, -1, 1, -11, -10, -9],
	'k' => [9, 10, 11, -1, 1, -11, -10, -9], 

	# 直進する動きと重複しない分のみ
	'H' => [-10, -1, 1, 10],
	'h' => [-10, -1, 1, 10],
	'D' => [-11, -9 ,9, 11],
	'd' => [-11, -9 ,9, 11],
	
);
# 直進する動き
my %CANMOVES2 = (
	'L' => [-1],
	'l' => [1],

	'B' => [-11, -9 ,9, 11],
	'b' => [-11, -9 ,9, 11],
	'H' => [-11, -9 ,9, 11],
	'h' => [-11, -9 ,9, 11],

	'R' => [-10, -1, 1, 10],
	'r' => [-10, -1, 1, 10],
	'D' => [-10, -1, 1, 10],
	'd' => [-10, -1, 1, 10],
);

#----------------------------------------
# functions

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {
		%args,
	};
	bless $self, $class;

	$self->_initialize();
	return $self;
}

sub _initialize {
	my $self = shift;

	$self->{board} = $BOARD_INITIAL;
	$self->{komadai} = '';
}

sub display_board {
	my $self = shift; 

	# 盤面
	for my $y (1..9) {
		print "P$y";
		for my $x (1..9) {
			my $piece = $self->get_piece((10 - $x) . $y);
			if (!$piece) {
				#print ' ' . $piece;
				print ' * ';
			} else {
				# TODO: convert to csa piece name
				print " $piece ";
			}
		}
		# コピーしたとき行末のスペースが削られることがあるので
		# | を表示してる
		print "|\n";
	}

	# 持ち駒
	# TODO: format komadai
	print "P+";
	print $self->{komadai}=~ m/[A-Z]/g;
	print "\n";
	print "P-";
	print $self->{komadai} =~ m/[a-z]/g;
	print "\n";
}

sub _rev {
	my ($piece) = @_;

	$piece =~ tr/PLNSGBRKplnsgbrkTAIVGHDKtaivghdk/TAIVGHDKtaivghdkPLNSGBRKplnsgbrk/;
	return $piece;
}

sub _is_promoted {
	my ($piece) = @_;

	return $piece =~ /[TAIVHDtaivhd]/;
}

# $piece の符号をひっくり返す
sub _opposite {
	my ($piece) = @_;
	$piece =~ tr/A-Za-z/a-zA-Z/;
	return $piece;
}

# 実際に駒を動かす
sub move {
	my $self = shift; 
	my ($mvref) = @_;

#	print STDERR %$mvref, "\n";

	my $from = $mvref->{from};
	my $to = $mvref->{to};
	my $piece = $mvref->{piece};

	# drop
	# cannot take/promote
	if ($mvref->{drop}) { 
		my $i = index($self->{komadai}, $piece);
		if ($i < 0) {
			die "move: dropping $piece";
		}
		substr($self->{komadai}, $i, 1, '');
		$self->set_piece($to, $piece);
	} else {

		# promote
		if ($mvref->{promote}) {
			$piece = _rev($piece);
		}

		# take
		if ($self->get_piece($to) ne '_') {
			# 取られた駒
			my $piece_taken = $self->get_piece($to);
			$piece_taken = _opposite($piece_taken);
			if (_is_promoted($piece_taken)) {
				$piece_taken = _rev($piece_taken);
			}

			$self->{komadai} .= $piece_taken;
		}

		$self->set_piece($from, '_');
		$self->set_piece($to, $piece);
	}

	#print STDERR $self->{board}, "\n";

	$self->{lastmove} = $mvref;
}

# $xy にある駒を返す
sub get_piece {
	my $self = shift;
	my ($xy) = @_;

	#print STDERR "get_piece: $xy\n";

	my $x = int($xy / 10);
	my $y = $xy % 10;
	my $i = (9 - $x) + ($y - 1) * 10;

	my $piece = substr($self->{board}, $i, 1); 

	return $piece;
}

# $xy の駒を $replace の駒で置き換える
sub set_piece {
	my $self = shift;
	my ($xy, $replace) = @_;

	#print STDERR "set_piece: $xy, $replace\n";

	my $x = int($xy / 10);
	my $y = $xy % 10;
	my $i = (9 - $x) + ($y - 1) * 10;

	if ($replace) {
		return substr($self->{board}, $i, 1, $replace);
	}
}

sub get_16bitmove {
	my $self = shift;

	my $data = 0;
	$data |= $self->{lastmove}->{to};
	# drop => 1 のときは from => '00' になっている
	$data |= $self->{lastmove}->{from} << 7;
	$data |= $self->{lastmove}->{promote} << 14;
	$data |= $self->{lastmove}->{drop} << 15;

	if ($self->{lastmove}->{drop}) {
		# from の位置に駒の種類を入れる
		$data |= $PIECE_TO_NUMBER{$self->{lastmove}->{piece}} << 7;
	}

	return pack('v', $data);
}

# 16bit の指し手で move()
sub move_16bit {
	my $self = shift;
	my ($rec) = @_;

	my $data = unpack('v', $rec);

	my %moveinfo = ();
	$moveinfo{to} = $data & 0b1111111;
	$moveinfo{from} = ($data >> 7) & 0b1111111;
	$moveinfo{promote} = ($data >> 14) & 0b1;
	$moveinfo{drop} = ($data >> 15) & 0b1;

	if ($moveinfo{drop}) {
		$moveinfo{piece} = $NUMBER_TO_PIECE{$moveinfo{from}};
		$moveinfo{from} = '00';
	} else {
		$moveinfo{piece} = $self->get_piece($moveinfo{from});
	} 
	#print "move_16bit: ", %moveinfo, "\n";

	$self->move(\%moveinfo);
}

# get_piece() では 空白と範囲外を区別できない
sub _in_range {
	my ($xy) = @_;
	my $ret = ($xy =~ /^[1-9][1-9]$/);
	#print STDERR "_in_range:$xy is $ret\n";
	return $ret;
}

# $to に動ける駒の位置をリストで返す
sub _ki2_find_from {
	my $self = shift;
	my ($to, $piece) = @_;

	# 返すリスト
	my @xylist = ();

	# 1回の動き
	for my $d (@{$CANMOVES1{$piece}}) {
		my $from = $to - $d;
		if (_in_range($from) and ($self->get_piece($from) eq $piece)) {
			push(@xylist, $from)
		}
	}

	# 直進する動き
	for my $d (@{$CANMOVES2{$piece}}) {
		my $from = $to - $d; 
		while (_in_range($from) and $self->get_piece($from) eq '_') {
			$from -= $d;
		}
		if (_in_range($from) and $self->get_piece($from) eq $piece) {
			push(@xylist, $from);
		}
	}

	#print STDERR "_ki2_find_from: <@xylist>\n";
	return @xylist;
}

# ki2ファイル風の指し手で move()
sub move_ki2 {
	my $self = shift;
	my ($ki2str) = @_;

	$ki2str =~ tr/ 　\r\n//d;
        $ki2str =~ tr/竜/龍/;
        $ki2str =~ tr/一二三四五六七八九〇１２３４５６７８９０/12345678901234567890/;
        if ($ki2str =~ /同/) {
                if (!$self->{lastmove}->{to}) { 
			die '{lastmove}->{to} is undefined';
		}
                $ki2str =~ s/同/$self->{lastmove}->{to}/;
	} 

        $ki2str =~ /([▲△])([123456789][123456789])(歩|香|桂|銀|金|角|飛|玉|と|成香|成桂|成銀|馬|龍)(左|右)?(上|引|寄|直|行)?(成|不成)?(打)?/ or die "not valid ki2 record: <$ki2str>";

        my $ki2str1 = $1; # 手番
        my $ki2str2 = $2; # 位置
        my $ki2str3 = $3; # 駒
        my $ki2str4 = $4 ? $4 : ''; # 相対位置
        my $ki2str5 = $5 ? $5 : ''; # 動作
        my $ki2str6 = $6 ? $6 : ''; # 成|不成
        my $ki2str7 = $7 ? $7 : ''; # 打

        my $flag = $ki2str1 =~ tr/▲△/+-/r; # 先手/後手とプラス/マイナスの両方の意味で使ってる
        my $to = $ki2str2;
        my $promote = ($ki2str6 eq '成') ? 1 : 0;
	my $drop = ($ki2str7 eq '打') ? 1 : 0;

	my $piece;
	{
		my %h = (
		 '歩'   => 'P',
		 '香'   => 'L',
		 '桂'   => 'N',
		 '銀'   => 'S',
		 '金'   => 'G',
		 '角'   => 'B',
		 '飛'   => 'R',
		 '玉'   => 'K',
		 'と'   => 'T',
		 '成香' => 'A',
		 '成桂' => 'I',
		 '成銀' => 'V',
		 '馬'   => 'H',
		 '龍'   => 'D', 
		);

		$piece = $h{$ki2str3};
		if ($flag eq '-') {
			$piece = lc($piece);
		}
	}

	# 「打」
        if ($drop) {
                return $self->move({ from => '00', to => $to, piece => $piece, promote => 0, drop => 1});
        }

        # $to に動ける駒のリストを得る
        my @xylist = $self->_ki2_find_from($to, $piece);

        # $to に動ける駒がない = 駒を打つ
        if (@xylist == 0) {
                # 駒を打つなら余計な情報はないはず
                if ($ki2str4 || $ki2str5 || $ki2str6) {
                        die "wrong kifu? $ki2str";
                }
                return $self->move({ from => '00', to => $to, piece => $piece, promote => 0, drop => 1});
        } 
        # 移動元候補が1つ
        elsif (@xylist == 1) {
                # $to に動ける駒が1つしかないのに余計な情報がある
                if ($ki2str4 || $ki2str5) {
                        # 見逃す
                        # printf STDERR "wrong kifu?\n"; 
                }
        } 
        # 移動元候補が複数ある
        elsif (@xylist > 1) {
                # 上引寄直でフィルタする
                if ($ki2str5 eq '直') {
                        # 筋が同じ＆段が下の駒
                        @xylist = grep {
                                my $fromx = substr($_, 0, 1);
                                my $fromy = substr($_, 1, 1);
                                my $tox = substr($to, 0, 1);
                                my $toy = substr($to, 1, 1);
                                ($fromx == $tox) && (($fromy - $toy) * (($flag . 1) * 1)  > 0);
                        } @xylist;
                }
                elsif ($ki2str5 eq '寄') {
                        # 移動先と移動元の段が同じ駒を探す
                        @xylist = grep { ($to % 10) == ($_ % 10); } @xylist;
                }
                elsif ($ki2str5 eq '引') {
                        # 移動先より移動元の方が上にある
                        @xylist = grep { ((($to % 10) - ($_ % 10)) * ($flag . 1)) > 0; } @xylist;
                }
                # 「行」は「上」と同じ意味？
                elsif ($ki2str5 eq '上' || $ki2str5 eq '行') {
                        # 移動先より移動元の方が下にある
                        @xylist = grep { ((($to % 10) - ($_ % 10)) * ($flag . 1)) < 0; } @xylist;
                }
                if ($ki2str4 eq '左') {
                        # 候補の中で一番左にある駒の筋は？
                        my $left = int($xylist[0] / 10);
                        for (@xylist) {
                                if ((($left - int($_ / 10)) * ($flag . 1)) < 0) {
                                        $left = int($_ / 10);
                                }
                        }
                        @xylist = grep { $left == int($_ / 10) } @xylist;
                }
                elsif ($ki2str4 eq '右') {
                        # 候補の中で一番右にある駒の筋は？
                        my $right = int($xylist[0] / 10);
                        for (@xylist) {
                                if ((($right - int($_ / 10)) * ($flag . 1)) > 0) {
                                        $right = int($_ / 10);
                                }
                        }
                        @xylist = grep { $right == int($_ / 10) } @xylist;
                }
        }

        # ここでは移動元が1つに確定しているはず
        if (@xylist == 1) {
				return $self->move( { from => $xylist[0], to => $to,
								piece => $piece, promote => $promote, drop => 0 });
        } else {
                # 移動できる駒が決まらなかった
		die "move_ki2: <$ki2str>, <@xylist>";
                return 0;
        }
}

1;
