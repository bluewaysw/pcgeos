;
; This file contains the data for a World Clock data file for Penelope.  
; This version is for a World Clock, English version.
;
; To create world.wcm from this file, run 
; /staff/pcgeos/Tools/scripts/makewcm	- Paul 5/16/95
;
;
; $Id: citiesPenelope.asm,v 1.1 97/04/04 16:21:45 newdeal Exp $
;


include geos.def
include graphics.def
include wcMacros.def

WORLD_MAP_WIDTH		equ	266
WORLD_MAP_HEIGHT	equ	116

StartWCDataFile		1

UseMap	../Art/wcmapPenelope.bitmap


; The daylight zone is specified by where it starts at hour 0 in pixels
; referenced to the start of the bitmap.  It also needs the pixels
; spanned by the world.  Half of that is the pixel size of the daylight.
DefDaylight	<WORLD_MAP_WIDTH / 4>, <WORLD_MAP_WIDTH>

;.showm
; This is an unordered list of time zones


StartTimeZoneList

; Each time zone is passed it's hour, left most point, right most point, 
; and then the points comprising the time zone polygon.

StartTimeZone	1_, 3, 0, 9, 39
DefTimeZonePoint	   9,    0
DefTimeZonePoint	  28,    0
DefTimeZonePoint	  28,   19
DefTimeZonePoint	  39,   24
DefTimeZonePoint	  32,   25
DefTimeZonePoint	  39,   32
DefTimeZonePoint	  39,   85
DefTimeZonePoint	  28,   76
DefTimeZonePoint	  28,   32
DefTimeZonePoint	   9,   30
DefTimeZonePoint	   9,    0
EndTimeZone	1_

StartTimeZone	2_, 1, 0, 9, 17
DefTimeZonePoint	   9,   94
DefTimeZonePoint	  17,  100
DefTimeZonePoint	  17,  116
DefTimeZonePoint	   9,  116
DefTimeZonePoint	   9,   94
EndTimeZone	2_

StartTimeZone	3_, 2, 0, 9, 39
DefTimeZonePoint	  28,  116
DefTimeZonePoint	  28,   94
DefTimeZonePoint	  39,   94
DefTimeZonePoint	  39,   85
DefTimeZonePoint	  28,   76
DefTimeZonePoint	  28,   32
DefTimeZonePoint	   9,   30
DefTimeZonePoint	   9,   94
DefTimeZonePoint	  17,  100
DefTimeZonePoint	  17,  116
DefTimeZonePoint	  28,  116
EndTimeZone	3_

StartTimeZone	4_, 3, 0, 28, 39
DefTimeZonePoint	  28,   94
DefTimeZonePoint	  39,   94
DefTimeZonePoint	  39,  116
DefTimeZonePoint	  28,  116
DefTimeZonePoint	  28,   94
EndTimeZone	4_

StartTimeZone	5_, 7, 0, 66, 89
DefTimeZonePoint	  68,    0
DefTimeZonePoint	  87,    0
DefTimeZonePoint	  89,    2
DefTimeZonePoint	  79,    5
DefTimeZonePoint	  79,   10
DefTimeZonePoint	  83,   12
DefTimeZonePoint	  83,   20
DefTimeZonePoint	  87,   22
DefTimeZonePoint	  87,   25
DefTimeZonePoint	  85,   25
DefTimeZonePoint	  85,   57
DefTimeZonePoint	  81,   60
DefTimeZonePoint	  81,   62
DefTimeZonePoint	  83,   67
DefTimeZonePoint	  79,   74
DefTimeZonePoint	  85,   76
DefTimeZonePoint	  83,   83
DefTimeZonePoint	  72,   94
DefTimeZonePoint	  72,   60
DefTimeZonePoint	  70,   51
DefTimeZonePoint	  72,   44
DefTimeZonePoint	  66,   30
DefTimeZonePoint	  66,   22
DefTimeZonePoint	  68,   20
DefTimeZonePoint	  68,    0
EndTimeZone	5_

StartTimeZone	6_, 8, 0, 72, 96
DefTimeZonePoint	  83,    4
DefTimeZonePoint	  87,    8
DefTimeZonePoint	  93,   24
DefTimeZonePoint	  96,   38
DefTimeZonePoint	  96,   62
DefTimeZonePoint	  91,   64
DefTimeZonePoint	  91,   67
DefTimeZonePoint	  93,   69
DefTimeZonePoint	  93,   89
DefTimeZonePoint	  85,   87
DefTimeZonePoint	  81,   96
DefTimeZonePoint	  79,  109
DefTimeZonePoint	  83,  111
DefTimeZonePoint	  85,  116
DefTimeZonePoint	  72,  116
DefTimeZonePoint	  72,   94
DefTimeZonePoint	  83,   83
DefTimeZonePoint	  85,   76
DefTimeZonePoint	  79,   74
DefTimeZonePoint	  83,   67
DefTimeZonePoint	  81,   62
DefTimeZonePoint	  81,   60
DefTimeZonePoint	  85,   57
DefTimeZonePoint	  85,   25
DefTimeZonePoint	  87,   25
DefTimeZonePoint	  87,   22
DefTimeZonePoint	  83,   20
DefTimeZonePoint	  83,   12
DefTimeZonePoint	  79,   10
DefTimeZonePoint	  79,    5
DefTimeZonePoint	  83,    4
EndTimeZone	6_

StartTimeZone	7_, 9, 0, 79, 125
DefTimeZonePoint	  87,    0
DefTimeZonePoint	 125,    0
DefTimeZonePoint	 119,   13
DefTimeZonePoint	 106,   20
DefTimeZonePoint	 106,   67
DefTimeZonePoint	 110,   76
DefTimeZonePoint	 106,   85
DefTimeZonePoint	 106,  116
DefTimeZonePoint	  85,  116
DefTimeZonePoint	  83,  111
DefTimeZonePoint	  79,  109
DefTimeZonePoint	  81,   96
DefTimeZonePoint	  85,   87
DefTimeZonePoint	  93,   89
DefTimeZonePoint	  93,   69
DefTimeZonePoint	  91,   67
DefTimeZonePoint	  91,   64
DefTimeZonePoint	  96,   62
DefTimeZonePoint	  96,   38
DefTimeZonePoint	  93,   24
DefTimeZonePoint	  87,    8
DefTimeZonePoint	  83,    4
DefTimeZonePoint	  89,    2
DefTimeZonePoint	  87,    0
EndTimeZone	7_

StartTimeZone	8_, 10, 0, 106, 117
DefTimeZonePoint	 114,   16
DefTimeZonePoint	 115,   19
DefTimeZonePoint	 117,   20
DefTimeZonePoint	 117,   53
DefTimeZonePoint	 112,   53
DefTimeZonePoint	 112,   57
DefTimeZonePoint	 117,   57
DefTimeZonePoint	 117,  116
DefTimeZonePoint	 106,  116
DefTimeZonePoint	 106,   85
DefTimeZonePoint	 110,   76
DefTimeZonePoint	 106,   67
DefTimeZonePoint	 106,   20
DefTimeZonePoint	 114,   16
EndTimeZone	8_

StartTimeZone	9_, 11, 0, 112, 127
DefTimeZonePoint	 117,   53
DefTimeZonePoint	 123,   67
DefTimeZonePoint	 127,   67
DefTimeZonePoint	 127,  116
DefTimeZonePoint	 117,  116
DefTimeZonePoint	 117,   57
DefTimeZonePoint	 112,   57
DefTimeZonePoint	 112,   53
DefTimeZonePoint	 117,   53
EndTimeZone	9_

StartTimeZone	10_, 12, 0, 115, 138
DefTimeZonePoint	 125,    0
DefTimeZonePoint	 138,    0
DefTimeZonePoint	 138,   16
DefTimeZonePoint	 134,   20
DefTimeZonePoint	 136,   25
DefTimeZonePoint	 125,   32
DefTimeZonePoint	 127,   34
DefTimeZonePoint	 127,   40
DefTimeZonePoint	 125,   42
DefTimeZonePoint	 125,   46
DefTimeZonePoint	 136,   53
DefTimeZonePoint	 136,   55
DefTimeZonePoint	 134,   55
DefTimeZonePoint	 134,   64
DefTimeZonePoint	 138,   67
DefTimeZonePoint	 138,  116
DefTimeZonePoint	 127,  116
DefTimeZonePoint	 127,   67
DefTimeZonePoint	 123,   67
DefTimeZonePoint	 117,   53
DefTimeZonePoint	 117,   20
DefTimeZonePoint	 115,   19
DefTimeZonePoint	 115,   16
DefTimeZonePoint	 119,   13
DefTimeZonePoint	 125,    0
EndTimeZone	10_

StartTimeZone	11_, 13, 0, 125, 155
DefTimeZonePoint	 138,    0
DefTimeZonePoint	 155,    0
DefTimeZonePoint	 155,   12
DefTimeZonePoint	 148,   13
DefTimeZonePoint	 150,   16
DefTimeZonePoint	 146,   19
DefTimeZonePoint	 148,   24
DefTimeZonePoint	 150,   29
DefTimeZonePoint	 150,   36
DefTimeZonePoint	 150,   42
DefTimeZonePoint	 150,   51
DefTimeZonePoint	 148,   60
DefTimeZonePoint	 153,   64
DefTimeZonePoint	 148,   64
DefTimeZonePoint	 150,   69
DefTimeZonePoint	 146,   74
DefTimeZonePoint	 150,   83
DefTimeZonePoint	 140,   83
DefTimeZonePoint	 146,   98
DefTimeZonePoint	 148,   98
DefTimeZonePoint	 148,  116
DefTimeZonePoint	 138,  116
DefTimeZonePoint	 138,   67
DefTimeZonePoint	 134,   64
DefTimeZonePoint	 134,   55
DefTimeZonePoint	 136,   55
DefTimeZonePoint	 136,   53
DefTimeZonePoint	 125,   46
DefTimeZonePoint	 125,   42
DefTimeZonePoint	 127,   40
DefTimeZonePoint	 127,   34
DefTimeZonePoint	 125,   32
DefTimeZonePoint	 136,   25
DefTimeZonePoint	 134,   20
DefTimeZonePoint	 138,   16
DefTimeZonePoint	 138,    0
EndTimeZone	11_

StartTimeZone	12_, 14, 0, 140, 165
DefTimeZonePoint	 155,   12
DefTimeZonePoint	 155,   17
DefTimeZonePoint	 153,   22
DefTimeZonePoint	 163,   29
DefTimeZonePoint	 161,   32
DefTimeZonePoint	 165,   34
DefTimeZonePoint	 165,   38
DefTimeZonePoint	 159,   38
DefTimeZonePoint	 159,   44
DefTimeZonePoint	 161,   53
DefTimeZonePoint	 157,   62
DefTimeZonePoint	 159,   64
DefTimeZonePoint	 155,   67
DefTimeZonePoint	 155,   74
DefTimeZonePoint	 161,   78
DefTimeZonePoint	 165,   78
DefTimeZonePoint	 161,   92
DefTimeZonePoint	 161,  116
DefTimeZonePoint	 148,  116
DefTimeZonePoint	 148,   98
DefTimeZonePoint	 146,   98
DefTimeZonePoint	 140,   83
DefTimeZonePoint	 150,   83
DefTimeZonePoint	 146,   74
DefTimeZonePoint	 150,   69
DefTimeZonePoint	 148,   64
DefTimeZonePoint	 153,   64
DefTimeZonePoint	 148,   60
DefTimeZonePoint	 150,   51
DefTimeZonePoint	 150,   29
DefTimeZonePoint	 146,   19
DefTimeZonePoint	 150,   16
DefTimeZonePoint	 148,   13
DefTimeZonePoint	 155,   12
DefTimeZonePoint	 155,   12
EndTimeZone	12_

StartTimeZone	13_, 15, 0, 153, 184
DefTimeZonePoint	 155,    0
DefTimeZonePoint	 184,    0
DefTimeZonePoint	 184,   10
DefTimeZonePoint	 180,   12
DefTimeZonePoint	 182,   15
DefTimeZonePoint	 176,   19
DefTimeZonePoint	 172,   20
DefTimeZonePoint	 167,   20
DefTimeZonePoint	 167,   22
DefTimeZonePoint	 172,   24
DefTimeZonePoint	 172,   25
DefTimeZonePoint	 167,   25
DefTimeZonePoint	 172,   27
DefTimeZonePoint	 167,   29
DefTimeZonePoint	 169,   30
DefTimeZonePoint	 167,   32
DefTimeZonePoint	 169,   34
DefTimeZonePoint	 165,   34
DefTimeZonePoint	 161,   32
DefTimeZonePoint	 163,   29
DefTimeZonePoint	 153,   22
DefTimeZonePoint	 155,   17
DefTimeZonePoint	 155,    0
EndTimeZone	13_

StartTimeZone	14_, 16, 0, 167, 172
DefTimeZonePoint	 172,   25
DefTimeZonePoint	 172,   27
DefTimeZonePoint	 167,   25
DefTimeZonePoint	 172,   25
EndTimeZone	14_

StartTimeZone	15_, 16, 0, 167, 172
DefTimeZonePoint	 172,   20
DefTimeZonePoint	 172,   24
DefTimeZonePoint	 167,   22
DefTimeZonePoint	 167,   20
DefTimeZonePoint	 172,   20
EndTimeZone	15_

StartTimeZone	16_, 15, 30, 165, 180
DefTimeZonePoint	 169,   34
DefTimeZonePoint	 174,   38
DefTimeZonePoint	 178,   38
DefTimeZonePoint	 178,   44
DefTimeZonePoint	 180,   49
DefTimeZonePoint	 172,   49
DefTimeZonePoint	 165,   38
DefTimeZonePoint	 165,   34
DefTimeZonePoint	 169,   34
EndTimeZone	16_

StartTimeZone	17_, 16, 30, 178, 186
DefTimeZonePoint	 178,   40
DefTimeZonePoint	 182,   38
DefTimeZonePoint	 186,   38
DefTimeZonePoint	 186,   40
DefTimeZonePoint	 182,   44
DefTimeZonePoint	 178,   44
DefTimeZonePoint	 178,   40
EndTimeZone	17_

StartTimeZone	18_, 15, 0, 155, 176
DefTimeZonePoint	 172,   49
DefTimeZonePoint	 172,   51
DefTimeZonePoint	 174,   51
DefTimeZonePoint	 174,   53
DefTimeZonePoint	 172,   53
DefTimeZonePoint	 172,   55
DefTimeZonePoint	 176,   60
DefTimeZonePoint	 172,   67
DefTimeZonePoint	 172,  116
DefTimeZonePoint	 161,  116
DefTimeZonePoint	 161,   92
DefTimeZonePoint	 165,   78
DefTimeZonePoint	 161,   78
DefTimeZonePoint	 155,   74
DefTimeZonePoint	 155,   67
DefTimeZonePoint	 159,   64
DefTimeZonePoint	 157,   62
DefTimeZonePoint	 161,   53
DefTimeZonePoint	 159,   44
DefTimeZonePoint	 159,   38
DefTimeZonePoint	 165,   38
DefTimeZonePoint	 172,   49
EndTimeZone	18_

StartTimeZone	19_, 17, 0, 167, 197
DefTimeZonePoint	 184,    0
DefTimeZonePoint	 193,    0
DefTimeZonePoint	 193,   11
DefTimeZonePoint	 197,   19
DefTimeZonePoint	 191,   19
DefTimeZonePoint	 188,   22
DefTimeZonePoint	 182,   24
DefTimeZonePoint	 180,   29
DefTimeZonePoint	 182,   32
DefTimeZonePoint	 182,   38
DefTimeZonePoint	 178,   40
DefTimeZonePoint	 178,   38
DefTimeZonePoint	 174,   38
DefTimeZonePoint	 167,   32
DefTimeZonePoint	 169,   30
DefTimeZonePoint	 167,   29
DefTimeZonePoint	 172,   27
DefTimeZonePoint	 172,   20
DefTimeZonePoint	 176,   19
DefTimeZonePoint	 182,   15
DefTimeZonePoint	 180,   12
DefTimeZonePoint	 184,   10
DefTimeZonePoint	 184,    0
EndTimeZone	19_

StartTimeZone	20_, 17, 0, 178, 191
DefTimeZonePoint	 180,   49
DefTimeZonePoint	 184,   51
DefTimeZonePoint	 186,   49
DefTimeZonePoint	 184,   46
DefTimeZonePoint	 191,   40
DefTimeZonePoint	 188,   38
DefTimeZonePoint	 186,   38
DefTimeZonePoint	 186,   40
DefTimeZonePoint	 182,   44
DefTimeZonePoint	 178,   44
DefTimeZonePoint	 180,   49
EndTimeZone	20_

StartTimeZone	21_, 17, 30, 184, 197
DefTimeZonePoint	 184,   51
DefTimeZonePoint	 191,   64
DefTimeZonePoint	 197,   51
DefTimeZonePoint	 197,   46
DefTimeZonePoint	 191,   40
DefTimeZonePoint	 184,   46
DefTimeZonePoint	 186,   49
DefTimeZonePoint	 184,   51
EndTimeZone	21_

StartTimeZone	22_, 18, 0, 180, 197
DefTimeZonePoint	 188,   22
DefTimeZonePoint	 195,   24
DefTimeZonePoint	 195,   25
DefTimeZonePoint	 191,   25
DefTimeZonePoint	 193,   27
DefTimeZonePoint	 197,   29
DefTimeZonePoint	 193,   34
DefTimeZonePoint	 188,   38
DefTimeZonePoint	 182,   38
DefTimeZonePoint	 182,   32
DefTimeZonePoint	 180,   29
DefTimeZonePoint	 182,   24
DefTimeZonePoint	 188,   22
EndTimeZone	22_

StartTimeZone	23_, 16, 0, 172, 182
DefTimeZonePoint	 172,   49
DefTimeZonePoint	 180,   49
DefTimeZonePoint	 182,   51
DefTimeZonePoint	 182,  116
DefTimeZonePoint	 172,  116
DefTimeZonePoint	 172,   67
DefTimeZonePoint	 176,   60
DefTimeZonePoint	 172,   55
DefTimeZonePoint	 172,   53
DefTimeZonePoint	 174,   53
DefTimeZonePoint	 174,   51
DefTimeZonePoint	 172,   51
DefTimeZonePoint	 172,   49
EndTimeZone	23_

StartTimeZone	24_, 17, 0, 180, 193
DefTimeZonePoint	 191,   64
DefTimeZonePoint	 193,   60
DefTimeZonePoint	 193,   60
DefTimeZonePoint	 193,  116
DefTimeZonePoint	 182,  116
DefTimeZonePoint	 182,   51
DefTimeZonePoint	 180,   49
DefTimeZonePoint	 184,   51
DefTimeZonePoint	 191,   64
EndTimeZone	24_

StartTimeZone	25_, 19, 0, 188, 218
DefTimeZonePoint	 193,    0
DefTimeZonePoint	 218,    0
DefTimeZonePoint	 218,    8
DefTimeZonePoint	 214,    8
DefTimeZonePoint	 216,   11
DefTimeZonePoint	 212,   13
DefTimeZonePoint	 210,   20
DefTimeZonePoint	 205,   22
DefTimeZonePoint	 203,   25
DefTimeZonePoint	 205,   25
DefTimeZonePoint	 205,   29
DefTimeZonePoint	 201,   27
DefTimeZonePoint	 197,   29
DefTimeZonePoint	 193,   27
DefTimeZonePoint	 191,   25
DefTimeZonePoint	 195,   25
DefTimeZonePoint	 195,   24
DefTimeZonePoint	 188,   22
DefTimeZonePoint	 191,   19
DefTimeZonePoint	 197,   19
DefTimeZonePoint	 193,   11
DefTimeZonePoint	 193,    0
EndTimeZone	25_

StartTimeZone	26_, 22, 0, 226, 245
DefTimeZonePoint	 231,    0
DefTimeZonePoint	 245,    0
DefTimeZonePoint	 245,   10
DefTimeZonePoint	 239,   11
DefTimeZonePoint	 235,   13
DefTimeZonePoint	 237,   19
DefTimeZonePoint	 241,   19
DefTimeZonePoint	 241,   20
DefTimeZonePoint	 237,   25
DefTimeZonePoint	 235,   32
DefTimeZonePoint	 231,   34
DefTimeZonePoint	 233,   29
DefTimeZonePoint	 229,   30
DefTimeZonePoint	 231,   16
DefTimeZonePoint	 226,   15
DefTimeZonePoint	 231,   11
DefTimeZonePoint	 231,    0
EndTimeZone	26_

StartTimeZone	27_, 18, 0, 193, 205
DefTimeZonePoint	 197,   46
DefTimeZonePoint	 201,   46
DefTimeZonePoint	 201,   51
DefTimeZonePoint	 201,   69
DefTimeZonePoint	 205,   76
DefTimeZonePoint	 205,  116
DefTimeZonePoint	 193,  116
DefTimeZonePoint	 193,   60
DefTimeZonePoint	 197,   51
DefTimeZonePoint	 197,   46
EndTimeZone	27_

StartTimeZone	28_, 18, 0, 201, 205
DefTimeZonePoint	 201,   46
DefTimeZonePoint	 203,   44
DefTimeZonePoint	 205,   49
DefTimeZonePoint	 201,   53
DefTimeZonePoint	 201,   46
EndTimeZone	28_

StartTimeZone	29_, 18, 30, 201, 207
DefTimeZonePoint	 205,   49
DefTimeZonePoint	 207,   51
DefTimeZonePoint	 205,   53
DefTimeZonePoint	 205,   57
DefTimeZonePoint	 205,   64
DefTimeZonePoint	 203,   57
DefTimeZonePoint	 201,   55
DefTimeZonePoint	 201,   53
DefTimeZonePoint	 205,   49
EndTimeZone	29_

StartTimeZone	30_, 17, 30, 201, 205
DefTimeZonePoint	 205,   64
DefTimeZonePoint	 201,   64
DefTimeZonePoint	 201,   55
DefTimeZonePoint	 203,   57
DefTimeZonePoint	 205,   64
EndTimeZone	30_

StartTimeZone	31_, 19, 0, 201, 220
DefTimeZonePoint	 207,   51
DefTimeZonePoint	 212,   49
DefTimeZonePoint	 214,   51
DefTimeZonePoint	 210,   53
DefTimeZonePoint	 214,   57
DefTimeZonePoint	 212,   64
DefTimeZonePoint	 216,   64
DefTimeZonePoint	 212,   71
DefTimeZonePoint	 220,   71
DefTimeZonePoint	 216,   81
DefTimeZonePoint	 216,  116
DefTimeZonePoint	 205,  116
DefTimeZonePoint	 205,   76
DefTimeZonePoint	 201,   69
DefTimeZonePoint	 201,   64
DefTimeZonePoint	 205,   64
DefTimeZonePoint	 205,   53
DefTimeZonePoint	 207,   51
EndTimeZone	31_

StartTimeZone	32_, 20, 0, 188, 233
DefTimeZonePoint	 212,   13
DefTimeZonePoint	 214,   20
DefTimeZonePoint	 220,   20
DefTimeZonePoint	 214,   29
DefTimeZonePoint	 224,   25
DefTimeZonePoint	 229,   30
DefTimeZonePoint	 233,   29
DefTimeZonePoint	 231,   34
DefTimeZonePoint	 224,   36
DefTimeZonePoint	 224,   44
DefTimeZonePoint	 226,   49
DefTimeZonePoint	 226,  116
DefTimeZonePoint	 216,  116
DefTimeZonePoint	 216,   81
DefTimeZonePoint	 220,   71
DefTimeZonePoint	 212,   71
DefTimeZonePoint	 216,   64
DefTimeZonePoint	 212,   64
DefTimeZonePoint	 214,   57
DefTimeZonePoint	 210,   53
DefTimeZonePoint	 214,   51
DefTimeZonePoint	 212,   49
DefTimeZonePoint	 207,   51
DefTimeZonePoint	 205,   49
DefTimeZonePoint	 203,   44
DefTimeZonePoint	 201,   46
DefTimeZonePoint	 197,   46
DefTimeZonePoint	 188,   38
DefTimeZonePoint	 193,   34
DefTimeZonePoint	 197,   29
DefTimeZonePoint	 201,   27
DefTimeZonePoint	 205,   29
DefTimeZonePoint	 205,   25
DefTimeZonePoint	 203,   25
DefTimeZonePoint	 205,   22
DefTimeZonePoint	 210,   20
DefTimeZonePoint	 212,   13
EndTimeZone	32_

StartTimeZone	33_, 23, 0, 235, 254
DefTimeZonePoint	 245,    0
DefTimeZonePoint	 250,    0
DefTimeZonePoint	 250,   11
DefTimeZonePoint	 254,   13
DefTimeZonePoint	 250,   13
DefTimeZonePoint	 252,   16
DefTimeZonePoint	 252,   19
DefTimeZonePoint	 243,   24
DefTimeZonePoint	 250,   29
DefTimeZonePoint	 250,   38
DefTimeZonePoint	 241,   34
DefTimeZonePoint	 239,   32
DefTimeZonePoint	 235,   32
DefTimeZonePoint	 237,   25
DefTimeZonePoint	 241,   20
DefTimeZonePoint	 241,   19
DefTimeZonePoint	 237,   19
DefTimeZonePoint	 235,   13
DefTimeZonePoint	 239,   11
DefTimeZonePoint	 245,   10
DefTimeZonePoint	 245,    0
EndTimeZone	33_

StartTimeZone	34_, 21, 0, 224, 241
DefTimeZonePoint	 241,   34
DefTimeZonePoint	 235,   42
DefTimeZonePoint	 235,   64
DefTimeZonePoint	 237,   69
DefTimeZonePoint	 237,   76
DefTimeZonePoint	 226,   76
DefTimeZonePoint	 226,   49
DefTimeZonePoint	 224,   44
DefTimeZonePoint	 224,   36
DefTimeZonePoint	 231,   34
DefTimeZonePoint	 235,   32
DefTimeZonePoint	 239,   32
DefTimeZonePoint	 241,   34
EndTimeZone	34_

StartTimeZone	35_, 21, 30, 226, 237
DefTimeZonePoint	 226,   76
DefTimeZonePoint	 237,   76
DefTimeZonePoint	 235,   83
DefTimeZonePoint	 235,   89
DefTimeZonePoint	 237,   89
DefTimeZonePoint	 237,  102
DefTimeZonePoint	 226,  102
DefTimeZonePoint	 226,   76
EndTimeZone	35_

StartTimeZone	36_, 21, 0, 226, 237
DefTimeZonePoint	 237,  102
DefTimeZonePoint	 237,  116
DefTimeZonePoint	 226,  116
DefTimeZonePoint	 226,  102
DefTimeZonePoint	 237,  102
EndTimeZone	36_

StartTimeZone	37_, 22, 0, 235, 250
DefTimeZonePoint	 241,   34
DefTimeZonePoint	 250,   38
DefTimeZonePoint	 250,   71
DefTimeZonePoint	 245,   74
DefTimeZonePoint	 250,   78
DefTimeZonePoint	 250,  116
DefTimeZonePoint	 237,  116
DefTimeZonePoint	 237,   89
DefTimeZonePoint	 235,   89
DefTimeZonePoint	 235,   83
DefTimeZonePoint	 237,   76
DefTimeZonePoint	 237,   69
DefTimeZonePoint	 235,   64
DefTimeZonePoint	 235,   42
DefTimeZonePoint	 241,   34
EndTimeZone	37_

StartTimeZone	38_left, 24, 0,  -23,    7
DefTimeZonePoint	 -16,    0
DefTimeZonePoint	  -2,    0
DefTimeZonePoint	  -2,    8
DefTimeZonePoint	   7,   13
DefTimeZonePoint	   7,   16
DefTimeZonePoint	  -8,   25
DefTimeZonePoint	  -2,   29
DefTimeZonePoint	  -2,   71
DefTimeZonePoint	   5,   81
DefTimeZonePoint	   5,  104
DefTimeZonePoint	  -2,  109
DefTimeZonePoint	  -2,  116
DefTimeZonePoint	  -6,  116
DefTimeZonePoint	  -6,  111
DefTimeZonePoint	 -12,  108
DefTimeZonePoint	 -12,  104
DefTimeZonePoint	  -6,   92
DefTimeZonePoint	  -6,   71
DefTimeZonePoint	 -16,   57
DefTimeZonePoint	 -16,   29
DefTimeZonePoint	 -23,   24
DefTimeZonePoint	 -14,   19
DefTimeZonePoint	 -14,   16
DefTimeZonePoint	 -16,   13
DefTimeZonePoint	 -12,   13
DefTimeZonePoint	 -16,   11
DefTimeZonePoint	 -16,    0
EndTimeZone	38_left


StartTimeZone	38_right, 24, 0,  243,  273
DefTimeZonePoint	 250,    0
DefTimeZonePoint	 264,    0
DefTimeZonePoint	 264,    8
DefTimeZonePoint	 273,   13
DefTimeZonePoint	 273,   16
DefTimeZonePoint	 258,   25
DefTimeZonePoint	 264,   29
DefTimeZonePoint	 264,   71
DefTimeZonePoint	 271,   81
DefTimeZonePoint	 271,  104
DefTimeZonePoint	 264,  109
DefTimeZonePoint	 264,  116
DefTimeZonePoint	 260,  116
DefTimeZonePoint	 260,  111
DefTimeZonePoint	 254,  108
DefTimeZonePoint	 254,  104
DefTimeZonePoint	 260,   92
DefTimeZonePoint	 260,   71
DefTimeZonePoint	 250,   57
DefTimeZonePoint	 250,   29
DefTimeZonePoint	 243,   24
DefTimeZonePoint	 252,   19
DefTimeZonePoint	 252,   16
DefTimeZonePoint	 250,   13
DefTimeZonePoint	 254,   13
DefTimeZonePoint	 250,   11
DefTimeZonePoint	 250,    0
EndTimeZone	38_right


StartTimeZone	39_, 23, 0, 245, 260
DefTimeZonePoint	 250,   57
DefTimeZonePoint	 260,   71
DefTimeZonePoint	 260,   92
DefTimeZonePoint	 254,  104
DefTimeZonePoint	 254,  108
DefTimeZonePoint	 260,  111
DefTimeZonePoint	 260,  116
DefTimeZonePoint	 250,  116
DefTimeZonePoint	 250,   78
DefTimeZonePoint	 245,   74
DefTimeZonePoint	 250,   71
DefTimeZonePoint	 250,   57
EndTimeZone	39_

StartTimeZone	40_left, 1, 0,   -8,    9
DefTimeZonePoint	  -2,    0
DefTimeZonePoint	   9,    0
DefTimeZonePoint	   9,  116
DefTimeZonePoint	  -2,  116
DefTimeZonePoint	  -2,  109
DefTimeZonePoint	   5,  104
DefTimeZonePoint	   5,   81
DefTimeZonePoint	  -2,   71
DefTimeZonePoint	  -2,   29
DefTimeZonePoint	  -8,   25
DefTimeZonePoint	   7,   16
DefTimeZonePoint	   7,   13
DefTimeZonePoint	  -2,    8
DefTimeZonePoint	  -2,    0
EndTimeZone	40_left


StartTimeZone	40_right, 1, 0,  258,  275
DefTimeZonePoint	 264,    0
DefTimeZonePoint	 275,    0
DefTimeZonePoint	 275,  116
DefTimeZonePoint	 264,  116
DefTimeZonePoint	 264,  109
DefTimeZonePoint	 271,  104
DefTimeZonePoint	 271,   81
DefTimeZonePoint	 264,   71
DefTimeZonePoint	 264,   29
DefTimeZonePoint	 258,   25
DefTimeZonePoint	 273,   16
DefTimeZonePoint	 273,   13
DefTimeZonePoint	 264,    8
DefTimeZonePoint	 264,    0
EndTimeZone	40_right


StartTimeZone	41_, 6, 0, 51, 72
DefTimeZonePoint	  58,    0
DefTimeZonePoint	  68,    0
DefTimeZonePoint	  68,   20
DefTimeZonePoint	  66,   22
DefTimeZonePoint	  66,   30
DefTimeZonePoint	  72,   44
DefTimeZonePoint	  70,   51
DefTimeZonePoint	  72,   60
DefTimeZonePoint	  72,  116
DefTimeZonePoint	  62,  116
DefTimeZonePoint	  62,   64
DefTimeZonePoint	  55,   53
DefTimeZonePoint	  53,   42
DefTimeZonePoint	  58,   44
DefTimeZonePoint	  60,   32
DefTimeZonePoint	  55,   29
DefTimeZonePoint	  51,   29
DefTimeZonePoint	  51,   25
DefTimeZonePoint	  55,   25
DefTimeZonePoint	  55,   20
DefTimeZonePoint	  58,   20
DefTimeZonePoint	  58,    0
EndTimeZone	41_

StartTimeZone	42_, 4, 0, 28, 51
DefTimeZonePoint	  28,    0
DefTimeZonePoint	  30,    0
DefTimeZonePoint	  30,   13
DefTimeZonePoint	  47,   27
DefTimeZonePoint	  47,   30
DefTimeZonePoint	  45,   32
DefTimeZonePoint	  49,   36
DefTimeZonePoint	  49,   44
DefTimeZonePoint	  47,   44
DefTimeZonePoint	  51,   51
DefTimeZonePoint	  49,   53
DefTimeZonePoint	  49,  116
DefTimeZonePoint	  39,  116
DefTimeZonePoint	  39,   94
DefTimeZonePoint	  39,   32
DefTimeZonePoint	  32,   25
DefTimeZonePoint	  39,   24
DefTimeZonePoint	  28,   19
DefTimeZonePoint	  28,    0
DefTimeZonePoint	  28,    0
EndTimeZone	42_

StartTimeZone	43_, 5, 0, 30, 62
DefTimeZonePoint	  30,    0
DefTimeZonePoint	  58,    0
DefTimeZonePoint	  58,   20
DefTimeZonePoint	  55,   20
DefTimeZonePoint	  55,   25
DefTimeZonePoint	  51,   25
DefTimeZonePoint	  51,   29
DefTimeZonePoint	  55,   29
DefTimeZonePoint	  60,   32
DefTimeZonePoint	  58,   44
DefTimeZonePoint	  53,   42
DefTimeZonePoint	  55,   53
DefTimeZonePoint	  62,   64
DefTimeZonePoint	  62,  116
DefTimeZonePoint	  49,  116
DefTimeZonePoint	  49,   53
DefTimeZonePoint	  51,   51
DefTimeZonePoint	  47,   44
DefTimeZonePoint	  49,   44
DefTimeZonePoint	  49,   36
DefTimeZonePoint	  45,   32
DefTimeZonePoint	  47,   30
DefTimeZonePoint	  47,   27
DefTimeZonePoint	  30,   13
DefTimeZonePoint	  30,    0
EndTimeZone	43_

StartTimeZone	44_, 21, 0, 212, 231
DefTimeZonePoint	 218,    0
DefTimeZonePoint	 231,    0
DefTimeZonePoint	 231,   11
DefTimeZonePoint	 226,   15
DefTimeZonePoint	 231,   16
DefTimeZonePoint	 229,   30
DefTimeZonePoint	 224,   25
DefTimeZonePoint	 214,   29
DefTimeZonePoint	 220,   20
DefTimeZonePoint	 214,   20
DefTimeZonePoint	 212,   13
DefTimeZonePoint	 216,   11
DefTimeZonePoint	 214,    8
DefTimeZonePoint	 218,    8
DefTimeZonePoint	 218,    0
EndTimeZone	44_

EndTimeZoneList


; This is an unordered list of cities

; default home city: London
; default dest city: Washington
; Format: StartCityList	default home city, default dest city, default time zone
StartCityList	117, 246, 1			; cities are zero based!

	DefCity "Kabul",  "Afghanistan",  183,   40, "93"
	DefCity "Tirana",  "Albania",  147,   35, "355"
	DefCity "Algiers",  "Algeria",  135,   38, "213"
	DefCity "Pago Pago",  "American Samoa",    6,   79, "684"
	DefCity "The Valley",  "Anguilla",   84,   53, "1"
	DefCity "St John's",  "Antigua & Barbuda",   87,   54, "1"
	DefCity "Buenos Aires",  "Argentina",   90,   96, "54"
	DefCity "Yerevan",  "Armenia",  165,   36, "7"
	DefCity "Oranjestad",  "Aruba",   81,   58,  "297"
	DefCity "Canberra",  "Australia",  243,   96, "61"
	DefCity "Adelaide",  "Australia",  235,   96, "61"
	DefCity "Perth",  "Australia",  218,   93, "61"
	DefCity "Vienna",  "Austria",  144,   29, "43"
	DefCity "Baku",  "Azerbaijan",  169,   32, "994"
	DefCity "Ponta Delgada",  "Azores",  113,   36, "351"
	DefCity "Nassau",  "Bahamas",   76,   48, "1"
	DefCity "Manama",  "Bahrain",  169,   47, "973"
	DefCity "Dhaka",  "Bangladesh",  199,   48, "880"
	DefCity "Bridgetown",  "Barbados",   88,   57, "1"
	DefCity "Minsk",  "Belarus",  153,   24, "7"
	DefCity "Brussels",  "Belgium",  135,   27, "32"
	DefCity "Belmopan",  "Belize",   67,   56, "501"
	DefCity "Porto Novo",  "Benin",  135,   63, "229"
	DefCity "Hamilton",  "Bermuda",   84,   42, "1"
	DefCity "La Paz",  "Bolivia",   82,   81, "591"
	DefCity "Sarajevo",  "Bosnia-Herzegovina",  146,   32, "837"
	DefCity "Brasilia",  "Brazil",   97,   80, "55"
	DefCity "Manaus",  "Brazil",   88,   70, "55"
	DefCity "Rio Branco",  "Brazil",   81,   75, "55"
	DefCity "Bandar Seri Begawan",  "Brunei",  217,   64, "673"
	DefCity "Sofia",  "Bulgaria",  149,   33, "359"
	DefCity "Rangoon",  "Burma",  203,   54, "95"
	DefCity "Phnom Penh",  "Cambodia",  210,   58, "855"
	DefCity "Yaounde",  "Cameroon",  140,   64, "237"
	DefCity "St Johns",  "Canada",   93,   29, "1"
	DefCity "Halifax",  "Canada",   85,   32, "1"
	DefCity "Ottawa",  "Canada",   76,   32, "1"
	DefCity "Winnipeg",  "Canada",   61,   28, "1"
	DefCity "Edmonton",  "Canada",   48,   24, "1"
	DefCity "Vancouver",  "Canada",   42,   28, "1"
	DefCity "Praia",  "Cape Verde",  116,   54, "238"
	DefCity "George Town",  "Cayman Islands",   73,   52, "1"
	DefCity "Ndjamena",  "Chad",  144,   58, "235"
	DefCity "Santiago",  "Chile",   80,   94, "56"
	DefCity "Beijing.",  "China",  218,   36, "86"
	DefCity "Bogota",  "Colombia",   78,   64, "57"
	DefCity "Brazzaville",  "Congo",  144,   71, "242"
	DefCity "Avarua on Rarotonga",  "Cook Islands",   14,   84, "682"
	DefCity "San Jose",  "Costa Rica",   70,   60, "506"
	DefCity "Zagreb",  "Croatia",  144,   31, "385"
	DefCity "Havana",  "Cuba",   72,   49, "53"
	DefCity "Willemstad",  "Curacao",   81,   58,  "1"
	DefCity "Nicosia",  "Cyprus",  157,   40, "357"
	DefCity "Prague",  "Czech Republic",  143,   28, "42"
	DefCity "Copenhagen",  "Denmark",  142,   23, "45"
	DefCity "Djibouti",  "Djibouti",  164,   58, "253"
	DefCity "Santo Domingo",  "Dominican Republic",   81,   53, "1"
	DefCity "Quito",  "Ecuador",   74,   68, "593"
	DefCity "Cairo",  "Egypt",  155,   44, "20"
	DefCity "San Salvador",  "El Salvador",   67,   56, "503"
	DefCity "Asmara",  "Eritrea",  161,   56, " "
	DefCity "Tallinn",  "Estonia",  151,   20, "372"
	DefCity "Addis Ababa",  "Ethiopia",  161,   55, "251"
	DefCity "Stanley",  "Falkland Islands",   90,  109, "298"
	DefCity "Suva",  "Fiji",  263,   53, "679"
	DefCity "Helsinki",  "Finland",  151,   20, "358"
	DefCity "Paris",  "France",  134,   28, "33"
	DefCity "Cayenne",  "French Guiana",   94,   64, "594"
	DefCity "Papeete",  "French Polynesia",   22,   82, "689"
	DefCity "Libreville",  "Gabon",  139,   67, "241"
	DefCity "Banjul",  "Gambia",  120,   57, "220"
	DefCity "Tbilisi",  "Georgia",  166,   34, "7"
	DefCity "Berlin",  "Germany",  142,   26, "49"
	DefCity "Accra",  "Ghana",  133,   63, "233"
	DefCity "Gibralta",  "Gibraltar",  129,   39, "350"
	DefCity "Athens",  "Greece",  150,   37, "30"
	DefCity "Nuuk",  "Greenland",   94,   16, "299"
	DefCity "Scoresbysund",  "Greenland",  116,   10, "299"
	DefCity "Thule",  "Greenland",   82,    6, "299"
	DefCity "St. George's",  "Grenada",   87,   58,  "1"
	DefCity "Basse-Terre",  "Guadeloupe",   87,   55, "590"
	DefCity "Agana",  "Guam",   25,   57, "671"
	DefCity "Guatemala City",  "Guatemala",   65,   56, "502"
	DefCity "Georgetown",  "Guyana",   90,   62, "592"
	DefCity "Port-au-Prince",  "Haiti",   79,   52, "509"
	DefCity "Tegucigalpa",  "Honduras",   68,   56, "504"
	DefCity "Hong Kong",  "Hong Kong",  217,   50, "852"
	DefCity "Budapest",  "Hungary",  147,   29, "36"
	DefCity "Reykjavik",  "Iceland",  116,   16, "354"
	DefCity "New Delhi",  "India",  189,   44, "91"
	DefCity "Jakarta",  "Indonesia",  212,   72, "62"
	DefCity "Borneo",  "Indonesia",  217,   68,  "62"
	DefCity "Teheran",  "Iran",  170,   39, "98"
	DefCity "Baghdad",  "Iraq",  165,   41, "964"
	DefCity "Dublin",  "Ireland",  128,   25, "353"
	DefCity "Jerusalem",  "Israel",  158,   42, "972"
	DefCity "Rome",  "Italy",  142,   34, "39"
	DefCity "Yamoussoukro",  "Ivory Coast",  129,   72,  "225"
	DefCity "Kingston",  "Jamaica",   76,   53, "1"
	DefCity "Tokyo",  "Japan",  236,   39, "81"
	DefCity "Amman",  "Jordan",  159,   42, "962"
	DefCity "Alma-Ata",  "Kazakhstan",  189,   33, "7"
	DefCity "Gur'yev",  "Kazakhstan",  181,   44, "7"
	DefCity "Nairobi",  "Kenya",  160,   68, "254"
;	DefCity "Gilbert Islands",  "Kiribati",  262,   68, "686"
	DefCity "Phoenix Islands",  "Kiribati",    3,   68, "686"
	DefCity "P'yongyang",  "Korea North",  226,   36, "850"
	DefCity "Seoul",  "Korea South",  226,   37, "82"
	DefCity "Kuwait City",  "Kuwait",  168,   44, "965"
	DefCity "Riga",  "Latvia",  150,   22, "371"
	DefCity "Beirut",  "Lebanon",  158,   40, "961"
	DefCity "Monrovia",  "Liberia",  124,   63, "231"
	DefCity "Tripoli",  "Libya",  142,   41, "218"
	DefCity "Vilnius",  "Lithuania",  151,   24, "370"
	DefCity "Luxembourg",  "Luxembourg",  137,   28, "352"
	DefCity "Macau",  "Macau",  216,   50, "853"
	DefCity "Skopje",  "Macedonia",  148,   34, "389"
	DefCity "Kuala Lumpur",  "Malaysia",  208,   65, "60"
	DefCity "Male",  "Maldives",  186,   64, "960"
	DefCity "Valletta",  "Malta",  143,   39, "356"
	DefCity "Dalap-Uliga-Darrit", "Marshall Islands", 258, 62, "692"
	DefCity "Fort-de-France",  "Martinique",   87,   56, "596"
	DefCity "Mexico City",  "Mexico",   59,   52, "52"
	DefCity "Tijuana",  "Mexico",   46,   42, "52"
	DefCity "Chisinau",  "Moldova",  154,   30, "373"
	DefCity "Ulan Bator",  "Mongolia",  212,   29,  "33"
	DefCity "Plymouth",  "Montserrat",   87,   54,  "1"
	DefCity "Monaco",  "Monaco",  138,   32, "33"
	DefCity "Rabat",  "Morocco",  127,   40, "212"
	DefCity "Maputo",  "Mozambique",  157,   88,  "258"
	DefCity "Windhoek",  "Namibia",  145,   86,  "264"
	DefCity "Yaren",  "Nauru",  251,   75,  "674"
	DefCity "Kathmandu",  "Nepal",  195,   45, "977"
	DefCity "Amsterdam",  "Netherlands",  136,   26, "31"
	DefCity "Noumea",  "New Caledonia",  256,   85, "687"
	DefCity "Wellington",  "New Zealand",  262,  100, "64"
	DefCity "Managau",  "Nicaragua",   69,   58, "505"
	DefCity "Abuja",  "Nigeria",  137,   60, "234"
	DefCity "Alofi",  "Niue",    7,   84,  "683"
	DefCity "Saipan",  "Northern Mariana Islands",  240,   56, "670"
	DefCity "Oslo",  "Norway",  141,   20, "47"
	DefCity "Islamabad",  "Pakistan",  186,   40, "92"
	DefCity "Koror",  "Palau",  232,   62, "6809"
	DefCity "Panama City",  "Panama",   73,   60, "507"
	DefCity "Port Moresby",  "Papua New Guinea",  241,   75, "675"
	DefCity "Asuncion",  "Paraguay",   90,   88, "595"
	DefCity "Lima",  "Peru",   76,   77, "51"
	DefCity "Manila",  "Philippines",  222,   56, "63"
	DefCity "Warsaw",  "Poland",  148,   26, "48"
	DefCity "Lisbon",  "Portugal",  126,   36, "351"
	DefCity "San Juan",  "Puerto Rico",   84,   53, "1"
	DefCity "Doha",  "Qatar",  171,   48, "974"
	DefCity "St-Denis",  "Reunion",  175,   84,  "262"
	DefCity "Bucharest",  "Romania",  152,   32, "40"
	DefCity "Moscow",  "Russia",  161,   23, "7"
	DefCity "Perm",  "Russia",  173,   20,  "7"
	DefCity "Krasnoyarsk",  "Russia",  201,   23, "7"
	DefCity "Vladivostok",  "Russia",  230,   33, "7"
	DefCity "Jamestown",  "St Helena",  122,   74, "290"
	DefCity "Basseterre",  "St Kitts & Nevis",   87,   54,  "1"
	DefCity "Castries",  "St Lucia",   80,   56, "1"
	DefCity "St-Pierre",  "St Pierre & Miquelon",   91,   30, "508"
	DefCity "Riyadh",  "Saudi Arabia",  167,   48, "966"
	DefCity "Dakar",  "Senegal",  120,   56, "221"
	DefCity "Victoria",  "Seychelles",  173,   72, "248"
	DefCity "Singapore",  "Singapore",  209,   67, "65"
	DefCity "Bratislava",  "Slovakia",  145,   29, "42"
	DefCity "Ljubljana",  "Slovenia",  144,   31, "386"
	DefCity "Honiara",  "Solomon Islands",  251,   75, "677"
	DefCity "Mogadishu",  "Somalia",  169,   66, "252"
	DefCity "Pretoria",  "South Africa",  153,   88, "27"
	DefCity "Madrid",  "Spain",  130,   36, "34"
	DefCity "Colombo",  "Sri Lanka",  192,   62, "94"
	DefCity "Khartoum",  "Sudan",  157,   55, "249"
	DefCity "Paramaribo",  "Surinam",   92,   63, "597"
	DefCity "Stockholm",  "Sweden",  146,   20, "46"
	DefCity "Bern",  "Switzerland",  138,   30, "41"
	DefCity "Damascus",  "Syria",  159,   40, "963"
	DefCity "Papeete",  "Tahiti",   22,   82, " "
	DefCity "Taipei",  "Taiwan",  223,   48, "886"
	DefCity "Dushanbe",  "Tajikistan",  183,   36, "7"
	DefCity "Dodoma",  "Tanzania",  161,   73, "255"
	DefCity "Bangkok",  "Thailand",  207,   56, "66"
	DefCity "Port of Spain",  "Trinidad & Tobago",   87,   59, "1"
	DefCity "Tunis",  "Tunisia",  140,   38, "216"
	DefCity "Ankara",  "Turkey",  157,   36, "90"
	DefCity "Grand Turk",  "Turks & Caicos Islands",   80,   51, "1"
	DefCity "Kampala",  "Uganda",  156,   68, "256"
	DefCity "Kiev",  "Ukraine",  155,   27, "7"
	DefCity "Abu Dhabi",  "United Arab Emirates",  173,   48, "971"
	DefCity "London",  "U.K.",  132,   27, "44"
	DefCity "Washington D.C.",  "U.S.A.",   76,   36, "1"
	DefCity "Montgomery",  "U.S.A.",   69,   42, "1"
	DefCity "Juneau",  "U.S.A.",  33,   22, "1"
	DefCity "Phoenix",  "U.S.A.",   50,   41, "1"
	DefCity "Little Rock",  "U.S.A.",   65,   40, "1"
;	DefCity "Sacramento",  "U.S.A.",   42,   36, "1"
	DefCity "Denver",  "U.S.A.",   55,   36, "1"
	DefCity "Hartford",  "U.S.A.",   79,   34, "1"
	DefCity "Dover",  "U.S.A.",   77,   36, "1"
;	DefCity "Tallahassee",  "U.S.A.",   70,   44, "1"
	DefCity "Atlanta",  "U.S.A.",   70,   40, "1"
	DefCity "Honolulu",  "U.S.A.",   16,   51, "1"
	DefCity "Boise",  "U.S.A.",   47,   32, "1"
;	DefCity "Moscow",  "U.S.A.",   46,   30, "1"
;	DefCity "Springfield",  "U.S.A.",   66,   36, "1"
	DefCity "Indianapolis",  "U.S.A.",   69,   36, "1"
	DefCity "Des Moines",  "U.S.A.",   63,   34, "1"
	DefCity "Topeka",  "U.S.A.",   62,   36, "1"
;	DefCity "Frankfort",  "U.S.A.",   70,   37, "1"
;	DefCity "Baton Rouge",  "U.S.A.",   65,   43, "1"
;	DefCity "Augusta",  "U.S.A.",   81,   32, "1"
;	DefCity "Annapolis",  "U.S.A.",   76,   36, "1"
	DefCity "Boston",  "U.S.A.",   80,   34, "1"
;	DefCity "Lansing",  "U.S.A.",   70,   33, "1"
;	DefCity "St. Paul",  "U.S.A.",   64,   32, "1"
	DefCity "Jackson",  "U.S.A.",   66,   42, "1"
;	DefCity "Jefferson City",  "U.S.A.",   65,   36, "1"
	DefCity "Helena",  "U.S.A.",   50,   30, "1"
;	DefCity "Lincoln",  "U.S.A.",   61,   35, "1"
;	DefCity "Carson City",  "U.S.A.",   44,   36, "1"
	DefCity "Concord",  "U.S.A.",   79,   33, "1"
;	DefCity "Trenton",  "U.S.A.",   77,   36, "1"
	DefCity "Santa Fe",  "U.S.A.",   54,   39, "1"
;	DefCity "Albany",  "U.S.A.",   78,   34, "1"
	DefCity "Raleigh",  "U.S.A.",   74,   39, "1"
	DefCity "Bismarck",  "U.S.A.",   58,   30, "1"
;	DefCity "Columbus",  "U.S.A.",   71,   36, "1"
	DefCity "Oklahoma City",  "U.S.A.",   60,   40, "1"
;	DefCity "Salem",  "U.S.A.",   42,   32, "1"
;	DefCity "Harrisburg",  "U.S.A.",   76,   36, "1"
	DefCity "Providence",  "U.S.A.",   80,   34, "1"
;	DefCity "Columbia",  "U.S.A.",   73,   40, "1"
;	DefCity "Pierre",  "U.S.A.",   59,   32, "1"
	DefCity "Nashville",  "U.S.A.",   68,   39, "1"
;	DefCity "Knoxville",  "U.S.A.",   70,   39, "1"
;	DefCity "Austin",  "U.S.A.",   60,   44, "1"
;	DefCity "El Paso",  "U.S.A.",   54,   42, "1"
	DefCity "Salt Lake City",  "U.S.A.",   50,   35, "1"
	DefCity "Montpelier",  "U.S.A.",   79,   32, "1"
	DefCity "Richmond",  "U.S.A.",   76,   38, "1"
;	DefCity "Olympia",  "U.S.A.",   42,   30, "1"
	DefCity "Charleston",  "U.S.A.",   72,   37, "1"
;	DefCity "Madison",  "U.S.A.",   67,   33, "1"
;	DefCity "Cheyenne",  "U.S.A.",   55,   35, "1"
	DefCity "Baltimore",   "U.S.A.",   76,   36,  "1"
	DefCity "Chicago",   "U.S.A.",   68,   35,  "1"
	DefCity "Cincinnati",   "U.S.A.",   70,   36,  "1"
	DefCity "Dallas",   "U.S.A.",   62,   42,  "1"
	DefCity "Detroit",   "U.S.A.",   71,   34,  "1"
	DefCity "Las Vegas",   "U.S.A.",   48,   39,  "1"
	DefCity "Los Angeles",   "U.S.A.",   45,   40,  "1"
	DefCity "Louisville",   "U.S.A.",   70,   37,  "1"
	DefCity "Miami",   "U.S.A.",   73,   48,  "1"
	DefCity "Milwaukee",   "U.S.A.",   68,   33,  "1"
	DefCity "Minneapolis",   "U.S.A.",   64,   32,  "1"
	DefCity "New Orleans",   "U.S.A.",   66,   44,  "1"
	DefCity "New York",   "U.S.A.",   78,   36,  "1"
	DefCity "Newark",   "U.S.A.",   78,   36,  "1"
	DefCity "Omaha",   "U.S.A.",   62,   35,  "1"
	DefCity "Philadelphia",   "U.S.A.",   77,   36,  "1"
	DefCity "Pittsburgh",   "U.S.A.",   74,   36,  "1"
;	DefCity "Portland",   "U.S.A.",   81,   33,  "1"
	DefCity "Portland",   "U.S.A.",   42,   32,  "1"
	DefCity "Rapid City",   "U.S.A.",   56,   32,  "1"
	DefCity "Saint Louis",   "U.S.A.",   66,   37,  "1"
	DefCity "San Francisco",   "U.S.A.",   42,   38,  "1"
	DefCity "Seattle",   "U.S.A.",   42,   30,  "1"
	DefCity "Montevideo",  "Uruguay",   91,   96, "598"
	DefCity "Port-Vila",  "Vanuatu",  257,   82, "678"
	DefCity "Vatican City",  "Vatican City",  142,   34, "39"
	DefCity "Caracas",  "Venezuela",   83,   59, "58"
	DefCity "Hanoi",  "Vietnam",  211,   51, "84"
	DefCity "Road Town",  "Virgin Islands (UK)",   84,   53, "1"
	DefCity "Charlotte Amalie", "Virgin Islands (USA)", 84,	53, "1"
	DefCity "Mata-Uta",  "Wallis & Futana Islands",    0,   80, "1"
	DefCity "Laayoune",  "Western Sahara",  121,   49,  "1"
	DefCity "Apia",  "Western Samoa",    7,   76,  "1"
	DefCity "Sana",  "Yemen",  166,   57, "967"
	DefCity "Belgrade",  "Yugoslavia",  147,   32, "381"
	DefCity "Kinshasa",  "Zaire",  144,   71, "243"
	DefCity "Lubumbashi",  "Zaire",  152,   77,  "243"
	DefCity "Lusaka",  "Zambia",  153,   80, "260"
	DefCity "Harare",  "Zimbabwe",  155,   82,  "263"

EndCityList
















































































