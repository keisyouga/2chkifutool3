
# 2chkifutool

[2chkifu.zip](https://code.google.com/archive/p/zipkifubrowser/downloads) の局面を検索するプログラム

必要なもの

- 2chkifu.zip
- perl
- unzip 

## 同手順検索

初手から指し手と引数が一致した棋譜を表示

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -move <指し手> [...]
```

- 相掛かり 

``` 
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -move ▲２六歩 △８四歩 ▲２五歩 △８五歩 ▲７八金 △３二金 ▲２四歩 △同歩 ▲同飛 △２三歩 ▲２八飛 △８六歩 ▲同歩 △同飛 ▲８七歩 △８二飛
```

- 位置だけ

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -move 26 84 25 85 78 32 24 '' '' 23 28 86 '' '' 87 82
```

- 駒だけ

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -move 歩 歩 歩 歩 金 金 歩 歩 飛 歩 飛 歩 歩 飛 歩 飛 
```

## 同局面検索

引数と一致した盤面の棋譜を表示

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -board <盤面> [...]
```

- 角換わり腰掛け銀先後同型

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -board l_____knl/_r__g_g__/__n_p_sp_/p_ppspp_p/_p_____P_/P_PPSPP_P/_PS_P_N__/__G_G__R_/LNK_____L
```

- 相銀冠

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -board '/.kg....../.s|gk./.......s' '/.S......./.KG|S./.......GK'
```

- 先手の玉と後手の玉が56と54にいる局面 

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -board ^........./........./........./....[Kk]..../........./....[Kk]..../
```

- 成香が4枚ある局面

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -board [Aa].*[Aa].*[Aa].*[Aa]
```

- 5筋の駒柱検索

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl -board '^....([A-Za-z]..../....){8}[A-Za-z]'
```

- 同じ駒が縦に4枚並ぶ

```
unzip -c ~/2chkifu.zip | perl 2chkifu-search.pl '(?i)([A-Z]).{9}\1.{9}\1.{9}\1'
```

平手初期盤面

```
lnsgkgsnl/_r_____b_/ppppppppp/_________/_________/_________/PPPPPPPPP/_B_____R_/LNSGKGSNL

P:歩
L:香
N:桂
S:銀
G:金
B:角
R:飛
K:玉
T:と
A:成香
I:成桂
V:成銀
H:馬
D:龍

_T_OKIN
L_A_NCE
KN_I_GHT
SIL_V_ER
_H_ORSE
_D_RAGON
```

## 2chkifu.bin  2chkifu.info

同局面検索が少し速くなります

```
unzip -c 2chkifu.zip | perl 2chkifu-search.pl -mkdb
```

2chkifu.bin と 2chkifu.info ファイルが作成されます

- 2chkifu.bin は 2chkifu.zip の指し手情報を1手16ビットで保存したもの  
移動先: 7bit  
移動元: 7bit  
成不成: 1bit  
打: 1bit  
打のときは移動元のかわりにに駒情報が入ります

- 2chkifu.info は 2chkifu.zip の ki2 ファイルの情報を1ファイル1行で出力したもの 
