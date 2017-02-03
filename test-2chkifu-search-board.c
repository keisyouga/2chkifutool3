// コンパイルして perl 2chkifusearch.pl -board と速度を比べてみる

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pcre.h>

typedef unsigned short MOVEINFO;

const char PIECE_NAME[] = "_PLNSGBRKTAIVHDplnsgbrktaivhd";
const char board_hirate[] = "lnsgkgsnl/_r_____b_/ppppppppp/_________/_________/_________/PPPPPPPPP/_B_____R_/LNSGKGSNL";
char board[90];

#define OVECCOUT 30
#define QUERY_MAX 20
pcre *re[QUERY_MAX];
int rc;
const char *error;
int erroroffset;
int ovector[OVECCOUT];



char get_piece(char *board, int xy)
{
	int x = xy / 10;
	int y = xy % 10;
	int i = (9 - x) + (y - 1) * 10;
	return board[i];
}

void set_piece(char *board, int xy, char piece)
{
	int x = xy / 10;
	int y = xy % 10;
	int i = (9 - x) + (y - 1) * 10;
	board[i] = piece;
}

char rev(char piece)
{
	switch (piece)
	{
		case 'P':
			piece = 'T';
			break;
		case 'L':
			piece = 'A';
			break;
		case 'N':
			piece = 'I';
			break;
		case 'S':
			piece = 'V';
			break;
		case 'G':
			piece = 'G';
			break;
		case 'B':
			piece = 'H';
			break;
		case 'R':
			piece = 'D';
			break;
		case 'K':
			piece = 'K';
			break;
		case 'p':
			piece = 't';
			break;
		case 'l':
			piece = 'a';
			break;
		case 'n':
			piece = 'i';
			break;
		case 's':
			piece = 'v';
			break;
		case 'g':
			piece = 'g';
			break;
		case 'b':
			piece = 'h';
			break;
		case 'r':
			piece = 'd';
			break;
		case 'k':
			piece = 'k';
			break;
		case 'T':
			piece = 'P';
			break;
		case 'A':
			piece = 'L';
			break;
		case 'I':
			piece = 'N';
			break;
		case 'V':
			piece = 'S';
			break;
		case 'H':
			piece = 'B';
			break;
		case 'D':
			piece = 'R';
			break;
		case 't':
			piece = 'p';
			break;
		case 'a':
			piece = 'l';
			break;
		case 'i':
			piece = 'n';
			break;
		case 'v':
			piece = 's';
			break;
		case 'h':
			piece = 'b';
			break;
		case 'd':
			piece = 'r';
			break;
	}
	return piece;
}

void move(MOVEINFO mi)
{
	int to= mi & 0b1111111;
	int from = (mi >> 7) & 0b1111111;
	int promote = mi >> 14 & 0b1;
	int drop = mi >> 15 & 0b1;

	char piece;
	if (drop) {
		piece = PIECE_NAME[from];
		set_piece(board, to, piece);
	} else { 
		piece = get_piece(board, from);
		if (promote) {
			piece = rev(piece);
		}
		set_piece(board, from, '_');
		set_piece(board, to, piece);
	}
	//fprintf(stderr, "move:%d, %d, %d, %d, %c\n", from, to, promote, drop, piece);
	//display_board();
	//getc(stdin);
}

int compare()
{
	pcre **r = &re[0];
	while (*r) {
		rc = pcre_exec(*r, NULL, board, sizeof(board), 0, 0, ovector, OVECCOUT);
		if (rc < 0) {
			return 0;
		}
		r++;
	}
	return 1;
}

int main(int argc, char *argv[])
{

	FILE *fp_bin = fopen("2chkifu.bin", "r");
	if (!fp_bin) {
		exit(1);
	}
	FILE *fp_info = fopen("2chkifu.info", "r");
	if (!fp_info) {
		exit(2);
	}
	MOVEINFO mi;

	if (!fp_bin) {
		fprintf(stderr, "2chkifu.bin");
		exit(1);
	}

	{
		char **p = &argv[1];
		pcre **r = &re[0];
		fprintf(stderr, "query:");
		while (*p) {
			fprintf(stderr, "%s ", *p);
			*r = pcre_compile(*p, 0, &error, &erroroffset, NULL); 
			p++;
			r++;
		}
		fprintf(stderr, "\n");
	}
	memcpy(board, board_hirate, sizeof(board));
	int kif_num = 0;
	int num_move = 0;
	char infoline[1024];
	fgets(infoline, sizeof(infoline) - 1, fp_info);
	while (fread(&mi, 2, 1, fp_bin)) {
		if (mi == 0) { 
			kif_num++;
			fgets(infoline, sizeof(infoline) - 1, fp_info);
			memcpy(board, board_hirate, sizeof(board)); 
			num_move = 0;
			continue;
		}
		move(mi);
		num_move++;
		if (compare()) {
			printf("%d:%s", num_move, infoline);
		}
	}

	return 0;
}
