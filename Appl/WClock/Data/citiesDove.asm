;
; This file contains the data for a World Clock data file.  
; This version is for a World Clock, Dove version.
;
; To create world.wcm from this file, run 
; /staff/pcgeos/Tools/scripts/makewcm DOVE	- Paul 5/16/95
;
;
; $Id: citiesDove.asm,v 1.1 97/04/04 16:21:44 newdeal Exp $
;




include geos.def
include graphics.def
include wcMacros.def
include unicode.def

WORLD_MAP_WIDTH		equ	472
WORLD_MAP_HEIGHT	equ	208

TOP	equ	0
BOTTOM	equ	WORLD_MAP_HEIGHT	; one more than the real height
					; because the algorithm doesn't
					; get the last pixel

StartWCDataFile		2

UseMap	../Art/wcmapDove.bitmap

; The daylight zone is specified by where it starts at hour 0 in pixels
; referenced to the start of the bitmap.  It also needs the pixels
; spanned by the world.  Half of that is the pixel size of the daylight.
DefDaylight	<WORLD_MAP_WIDTH / 4>, <WORLD_MAP_WIDTH>

;.showm
; This is an unordered list of time zones




; Each time zone is passed its hour, left most point, right most point, 
; and then the points comprising the time zone polygon.
StartTimeZoneList

StartTimeZone	1_, 3, 0, 285, 337
DefTimeZonePoint	 285,    0
DefTimeZonePoint	 319,    0
DefTimeZonePoint	 319,   33
DefTimeZonePoint	 337,   41
DefTimeZonePoint	 326,   44
DefTimeZonePoint	 337,   57
DefTimeZonePoint	 337,  152
DefTimeZonePoint	 319,  135
DefTimeZonePoint	 319,   57
DefTimeZonePoint	 285,   54
DefTimeZonePoint	 285,    0
EndTimeZone	1_

StartTimeZone	2_, 1, 0, 285, 300
DefTimeZonePoint	 285,  167
DefTimeZonePoint	 300,  178
DefTimeZonePoint	 300,  207
DefTimeZonePoint	 285,  207
DefTimeZonePoint	 285,  167
EndTimeZone	2_

StartTimeZone	3_, 2, 0, 285, 337
DefTimeZonePoint	 319,  207
DefTimeZonePoint	 319,  167
DefTimeZonePoint	 337,  167
DefTimeZonePoint	 337,  152
DefTimeZonePoint	 319,  135
DefTimeZonePoint	 319,   57
DefTimeZonePoint	 285,   54
DefTimeZonePoint	 285,  167
DefTimeZonePoint	 300,  178
DefTimeZonePoint	 300,  207
DefTimeZonePoint	 319,  207
EndTimeZone	3_

StartTimeZone	4_, 3, 0, 319, 337
DefTimeZonePoint	 319,  167
DefTimeZonePoint	 337,  167
DefTimeZonePoint	 337,  207
DefTimeZonePoint	 319,  207
DefTimeZonePoint	 319,  167
EndTimeZone	4_

StartTimeZone	5_, 7, 0, 386, 427
DefTimeZonePoint	 390,    0
DefTimeZonePoint	 424,    0
DefTimeZonePoint	 427,    3
DefTimeZonePoint	 409,    8
DefTimeZonePoint	 409,   16
DefTimeZonePoint	 416,   21
DefTimeZonePoint	 416,   36
DefTimeZonePoint	 424,   39
DefTimeZonePoint	 424,   44
DefTimeZonePoint	 420,   44
DefTimeZonePoint	 420,  102
DefTimeZonePoint	 412,  106
DefTimeZonePoint	 412,  110
DefTimeZonePoint	 416,  119
DefTimeZonePoint	 409,  131
DefTimeZonePoint	 420,  135
DefTimeZonePoint	 416,  148
DefTimeZonePoint	 397,  167
DefTimeZonePoint	 397,  106
DefTimeZonePoint	 394,   90
DefTimeZonePoint	 397,   79
DefTimeZonePoint	 386,   54
DefTimeZonePoint	 386,   39
DefTimeZonePoint	 390,   36
DefTimeZonePoint	 390,    0
EndTimeZone	5_

StartTimeZone	6_, 8, 0, 397, 439
DefTimeZonePoint	 417,    6
DefTimeZonePoint	 424,   14
DefTimeZonePoint	 435,   41
DefTimeZonePoint	 439,   67
DefTimeZonePoint	 439,  110
DefTimeZonePoint	 431,  115
DefTimeZonePoint	 431,  119
DefTimeZonePoint	 435,  123
DefTimeZonePoint	 435,  160
DefTimeZonePoint	 420,  156
DefTimeZonePoint	 412,  171
DefTimeZonePoint	 409,  195
DefTimeZonePoint	 416,  198
DefTimeZonePoint	 420,  207
DefTimeZonePoint	 397,  207
DefTimeZonePoint	 397,  167
DefTimeZonePoint	 416,  148
DefTimeZonePoint	 420,  135
DefTimeZonePoint	 409,  131
DefTimeZonePoint	 416,  119
DefTimeZonePoint	 412,  110
DefTimeZonePoint	 412,  106
DefTimeZonePoint	 420,  102
DefTimeZonePoint	 420,   44
DefTimeZonePoint	 424,   44
DefTimeZonePoint	 424,   39
DefTimeZonePoint	 416,   36
DefTimeZonePoint	 416,   21
DefTimeZonePoint	 409,   16
DefTimeZonePoint	 409,    8
DefTimeZonePoint	 417,    6
EndTimeZone	6_

StartTimeZone	7_left, 9, 0,  -63,   19
DefTimeZonePoint	 -48,    0
DefTimeZonePoint	  19,    0
DefTimeZonePoint	   8,   23
DefTimeZonePoint	 -15,   36
DefTimeZonePoint	 -15,  119
DefTimeZonePoint	  -7,  135
DefTimeZonePoint	 -15,  152
DefTimeZonePoint	 -15,  207
DefTimeZonePoint	 -52,  207
DefTimeZonePoint	 -56,  198
DefTimeZonePoint	 -63,  195
DefTimeZonePoint	 -60,  171
DefTimeZonePoint	 -52,  156
DefTimeZonePoint	 -37,  160
DefTimeZonePoint	 -37,  123
DefTimeZonePoint	 -41,  119
DefTimeZonePoint	 -41,  115
DefTimeZonePoint	 -33,  110
DefTimeZonePoint	 -33,   68
DefTimeZonePoint	 -37,   41
DefTimeZonePoint	 -48,   14
DefTimeZonePoint	 -56,    6
DefTimeZonePoint	 -45,    3
DefTimeZonePoint	 -48,    0
EndTimeZone	7_left


StartTimeZone	7_right, 9, 0,  409,  491
DefTimeZonePoint	 424,    0
DefTimeZonePoint	 491,    0
DefTimeZonePoint	 480,   23
DefTimeZonePoint	 457,   36
DefTimeZonePoint	 457,  119
DefTimeZonePoint	 465,  135
DefTimeZonePoint	 457,  152
DefTimeZonePoint	 457,  207
DefTimeZonePoint	 420,  207
DefTimeZonePoint	 416,  198
DefTimeZonePoint	 409,  195
DefTimeZonePoint	 412,  171
DefTimeZonePoint	 420,  156
DefTimeZonePoint	 435,  160
DefTimeZonePoint	 435,  123
DefTimeZonePoint	 431,  119
DefTimeZonePoint	 431,  115
DefTimeZonePoint	 439,  110
DefTimeZonePoint	 439,   68
DefTimeZonePoint	 435,   41
DefTimeZonePoint	 424,   14
DefTimeZonePoint	 416,    6
DefTimeZonePoint	 427,    3
DefTimeZonePoint	 424,    0
EndTimeZone	7_right


StartTimeZone	8_left, 10, 0,  -15,    4
DefTimeZonePoint	   0,   27
DefTimeZonePoint	   0,   33
DefTimeZonePoint	   4,   36
DefTimeZonePoint	   4,   94
DefTimeZonePoint	  -3,   94
DefTimeZonePoint	  -3,  102
DefTimeZonePoint	   4,  102
DefTimeZonePoint	   4,  207
DefTimeZonePoint	 -15,  207
DefTimeZonePoint	 -15,  152
DefTimeZonePoint	  -7,  135
DefTimeZonePoint	 -15,  119
DefTimeZonePoint	 -15,   36
DefTimeZonePoint	   0,   27
EndTimeZone	8_left


StartTimeZone	8_right, 10, 0,  457,  476
DefTimeZonePoint	 472,   27
DefTimeZonePoint	 472,   33
DefTimeZonePoint	 476,   36
DefTimeZonePoint	 476,   94
DefTimeZonePoint	 469,   94
DefTimeZonePoint	 469,  102
DefTimeZonePoint	 476,  102
DefTimeZonePoint	 476,  207
DefTimeZonePoint	 457,  207
DefTimeZonePoint	 457,  152
DefTimeZonePoint	 465,  135
DefTimeZonePoint	 457,  119
DefTimeZonePoint	 457,   36
DefTimeZonePoint	 472,   27
EndTimeZone	8_right


StartTimeZone	9_left, 11, 0,   -3,   23
DefTimeZonePoint	   4,   94
DefTimeZonePoint	  15,  119
DefTimeZonePoint	  23,  119
DefTimeZonePoint	  23,  207
DefTimeZonePoint	   4,  207
DefTimeZonePoint	   4,  102
DefTimeZonePoint	  -3,  102
DefTimeZonePoint	  -3,   94
DefTimeZonePoint	   4,   94
EndTimeZone	9_left


StartTimeZone	9_right, 11, 0,  469,  495
DefTimeZonePoint	 476,   94
DefTimeZonePoint	 487,  119
DefTimeZonePoint	 495,  119
DefTimeZonePoint	 495,  207
DefTimeZonePoint	 476,  207
DefTimeZonePoint	 476,  102
DefTimeZonePoint	 469,  102
DefTimeZonePoint	 469,   94
DefTimeZonePoint	 476,   94
EndTimeZone	9_right


StartTimeZone	10_, 12, 0, 0, 42
DefTimeZonePoint	  19,    0
DefTimeZonePoint	  42,    0
DefTimeZonePoint	  42,   28
DefTimeZonePoint	  34,   36
DefTimeZonePoint	  38,   44
DefTimeZonePoint	  19,   57
DefTimeZonePoint	  23,   61
DefTimeZonePoint	  23,   71
DefTimeZonePoint	  19,   75
DefTimeZonePoint	  19,   82
DefTimeZonePoint	  38,   94
DefTimeZonePoint	  38,   98
DefTimeZonePoint	  34,   98
DefTimeZonePoint	  34,  115
DefTimeZonePoint	  42,  119
DefTimeZonePoint	  42,  207
DefTimeZonePoint	  23,  207
DefTimeZonePoint	  23,  119
DefTimeZonePoint	  15,  119
DefTimeZonePoint	   4,   94
DefTimeZonePoint	   4,   36
DefTimeZonePoint	   0,   33
DefTimeZonePoint	   0,   27
DefTimeZonePoint	   8,   23
DefTimeZonePoint	  19,    0
EndTimeZone	10_

StartTimeZone	11_, 13, 0, 19, 71
DefTimeZonePoint	  42,    0
DefTimeZonePoint	  71,    0
DefTimeZonePoint	  71,   21
DefTimeZonePoint	  60,   23
DefTimeZonePoint	  64,   28
DefTimeZonePoint	  56,   33
DefTimeZonePoint	  60,   41
DefTimeZonePoint	  64,   51
DefTimeZonePoint	  64,   64
DefTimeZonePoint	  64,   75
DefTimeZonePoint	  64,   90
DefTimeZonePoint	  60,  106
DefTimeZonePoint	  68,  115
DefTimeZonePoint	  60,  115
DefTimeZonePoint	  64,  123
DefTimeZonePoint	  56,  131
DefTimeZonePoint	  64,  148
DefTimeZonePoint	  45,  148
DefTimeZonePoint	  56,  175
DefTimeZonePoint	  60,  175
DefTimeZonePoint	  60,  207
DefTimeZonePoint	  42,  207
DefTimeZonePoint	  42,  119
DefTimeZonePoint	  34,  115
DefTimeZonePoint	  34,   98
DefTimeZonePoint	  38,   98
DefTimeZonePoint	  38,   94
DefTimeZonePoint	  19,   82
DefTimeZonePoint	  19,   75
DefTimeZonePoint	  23,   71
DefTimeZonePoint	  23,   61
DefTimeZonePoint	  19,   57
DefTimeZonePoint	  38,   44
DefTimeZonePoint	  34,   36
DefTimeZonePoint	  42,   28
DefTimeZonePoint	  42,    0
EndTimeZone	11_

StartTimeZone	12_, 14, 0, 45, 90
DefTimeZonePoint	  71,   21
DefTimeZonePoint	  71,   30
DefTimeZonePoint	  68,   39
DefTimeZonePoint	  86,   51
DefTimeZonePoint	  83,   57
DefTimeZonePoint	  90,   61
DefTimeZonePoint	  90,   68
DefTimeZonePoint	  79,   68
DefTimeZonePoint	  79,   79
DefTimeZonePoint	  83,   94
DefTimeZonePoint	  75,  110
DefTimeZonePoint	  79,  115
DefTimeZonePoint	  71,  119
DefTimeZonePoint	  71,  131
DefTimeZonePoint	  83,  140
DefTimeZonePoint	  90,  140
DefTimeZonePoint	  83,  163
DefTimeZonePoint	  83,  207
DefTimeZonePoint	  60,  207
DefTimeZonePoint	  60,  175
DefTimeZonePoint	  56,  175
DefTimeZonePoint	  45,  148
DefTimeZonePoint	  64,  148
DefTimeZonePoint	  56,  131
DefTimeZonePoint	  64,  123
DefTimeZonePoint	  60,  115
DefTimeZonePoint	  68,  115
DefTimeZonePoint	  60,  106
DefTimeZonePoint	  64,   90
DefTimeZonePoint	  64,   51
DefTimeZonePoint	  56,   33
DefTimeZonePoint	  64,   28
DefTimeZonePoint	  60,   23
DefTimeZonePoint	  71,   21
DefTimeZonePoint	  71,   21
EndTimeZone	12_

StartTimeZone	13_, 15, 0, 68, 124
DefTimeZonePoint	  71,    0
DefTimeZonePoint	 124,    0
DefTimeZonePoint	 124,   16
DefTimeZonePoint	 116,   21
DefTimeZonePoint	 120,   25
DefTimeZonePoint	 109,   33
DefTimeZonePoint	 101,   36
DefTimeZonePoint	  94,   36
DefTimeZonePoint	  94,   39
DefTimeZonePoint	 101,   41
DefTimeZonePoint	 101,   44
DefTimeZonePoint	  94,   44
DefTimeZonePoint	 101,   47
DefTimeZonePoint	  94,   51
DefTimeZonePoint	  98,   54
DefTimeZonePoint	  94,   57
DefTimeZonePoint	  98,   61
DefTimeZonePoint	  90,   61
DefTimeZonePoint	  83,   57
DefTimeZonePoint	  86,   51
DefTimeZonePoint	  68,   39
DefTimeZonePoint	  71,   30
DefTimeZonePoint	  71,    0
EndTimeZone	13_

StartTimeZone	14_, 16, 0, 94, 101
DefTimeZonePoint	 101,   44
DefTimeZonePoint	 101,   47
DefTimeZonePoint	  94,   44
DefTimeZonePoint	 101,   44
EndTimeZone	14_

StartTimeZone	15_, 16, 0, 94, 101
DefTimeZonePoint	 101,   36
DefTimeZonePoint	 101,   41
DefTimeZonePoint	  94,   39
DefTimeZonePoint	  94,   36
DefTimeZonePoint	 101,   36
EndTimeZone	15_

StartTimeZone	16_, 15, 30, 90, 116
DefTimeZonePoint	  98,   61
DefTimeZonePoint	 105,   68
DefTimeZonePoint	 113,   68
DefTimeZonePoint	 113,   79
DefTimeZonePoint	 116,   86
DefTimeZonePoint	 101,   86
DefTimeZonePoint	  90,   68
DefTimeZonePoint	  90,   61
DefTimeZonePoint	  98,   61
EndTimeZone	16_

StartTimeZone	17_, 16, 30, 113, 128
DefTimeZonePoint	 113,   71
DefTimeZonePoint	 120,   68
DefTimeZonePoint	 128,   68
DefTimeZonePoint	 128,   71
DefTimeZonePoint	 120,   79
DefTimeZonePoint	 113,   79
DefTimeZonePoint	 113,   71
EndTimeZone	17_

StartTimeZone	18_, 15, 0, 71, 109
DefTimeZonePoint	 101,   86
DefTimeZonePoint	 101,   90
DefTimeZonePoint	 105,   90
DefTimeZonePoint	 105,   94
DefTimeZonePoint	 101,   94
DefTimeZonePoint	 101,   98
DefTimeZonePoint	 109,  106
DefTimeZonePoint	 101,  119
DefTimeZonePoint	 101,  207
DefTimeZonePoint	  83,  207
DefTimeZonePoint	  83,  163
DefTimeZonePoint	  90,  140
DefTimeZonePoint	  83,  140
DefTimeZonePoint	  71,  131
DefTimeZonePoint	  71,  119
DefTimeZonePoint	  79,  115
DefTimeZonePoint	  75,  110
DefTimeZonePoint	  83,   94
DefTimeZonePoint	  79,   79
DefTimeZonePoint	  79,   68
DefTimeZonePoint	  90,   68
DefTimeZonePoint	 101,   86
EndTimeZone	18_

StartTimeZone	19_, 17, 0, 94, 146
DefTimeZonePoint	 124,    0
DefTimeZonePoint	 139,    0
DefTimeZonePoint	 139,   18
DefTimeZonePoint	 146,   33
DefTimeZonePoint	 135,   33
DefTimeZonePoint	 131,   39
DefTimeZonePoint	 120,   41
DefTimeZonePoint	 116,   51
DefTimeZonePoint	 120,   57
DefTimeZonePoint	 120,   68
DefTimeZonePoint	 113,   71
DefTimeZonePoint	 113,   68
DefTimeZonePoint	 105,   68
DefTimeZonePoint	  94,   57
DefTimeZonePoint	  98,   54
DefTimeZonePoint	  94,   51
DefTimeZonePoint	 101,   47
DefTimeZonePoint	 101,   36
DefTimeZonePoint	 109,   33
DefTimeZonePoint	 120,   25
DefTimeZonePoint	 116,   21
DefTimeZonePoint	 124,   16
DefTimeZonePoint	 124,    0
EndTimeZone	19_

StartTimeZone	20_, 17, 0, 113, 135
DefTimeZonePoint	 116,   86
DefTimeZonePoint	 124,   90
DefTimeZonePoint	 128,   86
DefTimeZonePoint	 124,   82
DefTimeZonePoint	 135,   71
DefTimeZonePoint	 131,   68
DefTimeZonePoint	 128,   68
DefTimeZonePoint	 128,   71
DefTimeZonePoint	 120,   79
DefTimeZonePoint	 113,   79
DefTimeZonePoint	 116,   86
EndTimeZone	20_

StartTimeZone	21_, 17, 30, 124, 146
DefTimeZonePoint	 124,   90
DefTimeZonePoint	 135,  115
DefTimeZonePoint	 146,   90
DefTimeZonePoint	 146,   82
DefTimeZonePoint	 135,   71
DefTimeZonePoint	 124,   82
DefTimeZonePoint	 128,   86
DefTimeZonePoint	 124,   90
EndTimeZone	21_

StartTimeZone	22_, 18, 0, 116, 146
DefTimeZonePoint	 131,   39
DefTimeZonePoint	 143,   41
DefTimeZonePoint	 143,   44
DefTimeZonePoint	 135,   44
DefTimeZonePoint	 139,   47
DefTimeZonePoint	 146,   51
DefTimeZonePoint	 139,   61
DefTimeZonePoint	 131,   68
DefTimeZonePoint	 120,   68
DefTimeZonePoint	 120,   57
DefTimeZonePoint	 116,   51
DefTimeZonePoint	 120,   41
DefTimeZonePoint	 131,   39
EndTimeZone	22_

StartTimeZone	23_, 16, 0, 101, 120
DefTimeZonePoint	 101,   86
DefTimeZonePoint	 116,   86
DefTimeZonePoint	 120,   90
DefTimeZonePoint	 120,  207
DefTimeZonePoint	 101,  207
DefTimeZonePoint	 101,  119
DefTimeZonePoint	 109,  106
DefTimeZonePoint	 101,   98
DefTimeZonePoint	 101,   94
DefTimeZonePoint	 105,   94
DefTimeZonePoint	 105,   90
DefTimeZonePoint	 101,   90
DefTimeZonePoint	 101,   86
EndTimeZone	23_

StartTimeZone	24_, 17, 0, 116, 139
DefTimeZonePoint	 135,  115
DefTimeZonePoint	 139,  106
DefTimeZonePoint	 139,  106
DefTimeZonePoint	 139,  207
DefTimeZonePoint	 120,  207
DefTimeZonePoint	 120,   90
DefTimeZonePoint	 116,   86
DefTimeZonePoint	 124,   90
DefTimeZonePoint	 135,  115
EndTimeZone	24_

StartTimeZone	25_, 19, 0, 131, 184
DefTimeZonePoint	 139,    0
DefTimeZonePoint	 184,    0
DefTimeZonePoint	 184,   14
DefTimeZonePoint	 176,   14
DefTimeZonePoint	 180,   18
DefTimeZonePoint	 173,   23
DefTimeZonePoint	 169,   36
DefTimeZonePoint	 161,   39
DefTimeZonePoint	 158,   44
DefTimeZonePoint	 161,   44
DefTimeZonePoint	 161,   51
DefTimeZonePoint	 154,   47
DefTimeZonePoint	 146,   51
DefTimeZonePoint	 139,   47
DefTimeZonePoint	 135,   44
DefTimeZonePoint	 143,   44
DefTimeZonePoint	 143,   41
DefTimeZonePoint	 131,   39
DefTimeZonePoint	 135,   33
DefTimeZonePoint	 146,   33
DefTimeZonePoint	 139,   18
DefTimeZonePoint	 139,    0
EndTimeZone	25_

StartTimeZone	26_, 22, 0, 199, 233
DefTimeZonePoint	 206,    0
DefTimeZonePoint	 233,    0
DefTimeZonePoint	 233,   16
DefTimeZonePoint	 221,   18
DefTimeZonePoint	 214,   23
DefTimeZonePoint	 218,   33
DefTimeZonePoint	 225,   33
DefTimeZonePoint	 225,   36
DefTimeZonePoint	 218,   44
DefTimeZonePoint	 214,   57
DefTimeZonePoint	 206,   61
DefTimeZonePoint	 210,   51
DefTimeZonePoint	 203,   54
DefTimeZonePoint	 206,   28
DefTimeZonePoint	 199,   25
DefTimeZonePoint	 206,   18
DefTimeZonePoint	 206,    0
EndTimeZone	26_

StartTimeZone	27_, 18, 0, 139, 161
DefTimeZonePoint	 146,   82
DefTimeZonePoint	 154,   82
DefTimeZonePoint	 154,   90
DefTimeZonePoint	 154,  123
DefTimeZonePoint	 161,  135
DefTimeZonePoint	 161,  207
DefTimeZonePoint	 139,  207
DefTimeZonePoint	 139,  106
DefTimeZonePoint	 146,   90
DefTimeZonePoint	 146,   82
EndTimeZone	27_

StartTimeZone	28_, 18, 0, 154, 161
DefTimeZonePoint	 154,   82
DefTimeZonePoint	 158,   79
DefTimeZonePoint	 161,   86
DefTimeZonePoint	 154,   94
DefTimeZonePoint	 154,   82
EndTimeZone	28_

StartTimeZone	29_, 18, 30, 154, 165
DefTimeZonePoint	 161,   86
DefTimeZonePoint	 165,   90
DefTimeZonePoint	 161,   94
DefTimeZonePoint	 161,  102
DefTimeZonePoint	 161,  115
DefTimeZonePoint	 158,  102
DefTimeZonePoint	 154,   98
DefTimeZonePoint	 154,   94
DefTimeZonePoint	 161,   86
EndTimeZone	29_

StartTimeZone	30_, 17, 30, 154, 161
DefTimeZonePoint	 161,  115
DefTimeZonePoint	 154,  115
DefTimeZonePoint	 154,   98
DefTimeZonePoint	 158,  102
DefTimeZonePoint	 161,  115
EndTimeZone	30_

StartTimeZone	31_, 19, 0, 154, 188
DefTimeZonePoint	 165,   90
DefTimeZonePoint	 173,   86
DefTimeZonePoint	 176,   90
DefTimeZonePoint	 169,   94
DefTimeZonePoint	 176,  102
DefTimeZonePoint	 173,  115
DefTimeZonePoint	 180,  115
DefTimeZonePoint	 173,  127
DefTimeZonePoint	 188,  127
DefTimeZonePoint	 180,  144
DefTimeZonePoint	 180,  207
DefTimeZonePoint	 161,  207
DefTimeZonePoint	 161,  135
DefTimeZonePoint	 154,  123
DefTimeZonePoint	 154,  115
DefTimeZonePoint	 161,  115
DefTimeZonePoint	 161,   94
DefTimeZonePoint	 165,   90
EndTimeZone	31_

StartTimeZone	32_, 20, 0, 131, 210
DefTimeZonePoint	 173,   23
DefTimeZonePoint	 176,   36
DefTimeZonePoint	 188,   36
DefTimeZonePoint	 176,   51
DefTimeZonePoint	 195,   44
DefTimeZonePoint	 203,   54
DefTimeZonePoint	 210,   51
DefTimeZonePoint	 206,   61
DefTimeZonePoint	 195,   64
DefTimeZonePoint	 195,   79
DefTimeZonePoint	 199,   86
DefTimeZonePoint	 199,  207
DefTimeZonePoint	 180,  207
DefTimeZonePoint	 180,  144
DefTimeZonePoint	 188,  127
DefTimeZonePoint	 173,  127
DefTimeZonePoint	 180,  115
DefTimeZonePoint	 173,  115
DefTimeZonePoint	 176,  102
DefTimeZonePoint	 169,   94
DefTimeZonePoint	 176,   90
DefTimeZonePoint	 173,   86
DefTimeZonePoint	 165,   90
DefTimeZonePoint	 161,   86
DefTimeZonePoint	 158,   79
DefTimeZonePoint	 154,   82
DefTimeZonePoint	 146,   82
DefTimeZonePoint	 131,   68
DefTimeZonePoint	 139,   61
DefTimeZonePoint	 146,   51
DefTimeZonePoint	 154,   47
DefTimeZonePoint	 161,   51
DefTimeZonePoint	 161,   44
DefTimeZonePoint	 158,   44
DefTimeZonePoint	 161,   39
DefTimeZonePoint	 169,   36
DefTimeZonePoint	 173,   23
EndTimeZone	32_

StartTimeZone	33_, 23, 0, 214, 248
DefTimeZonePoint	 233,    0
DefTimeZonePoint	 240,    0
DefTimeZonePoint	 240,   18
DefTimeZonePoint	 248,   23
DefTimeZonePoint	 240,   23
DefTimeZonePoint	 244,   28
DefTimeZonePoint	 244,   33
DefTimeZonePoint	 229,   41
DefTimeZonePoint	 240,   51
DefTimeZonePoint	 240,   68
DefTimeZonePoint	 229,   71
DefTimeZonePoint	 221,   57
DefTimeZonePoint	 214,   57
DefTimeZonePoint	 218,   44
DefTimeZonePoint	 225,   36
DefTimeZonePoint	 225,   33
DefTimeZonePoint	 218,   33
DefTimeZonePoint	 214,   23
DefTimeZonePoint	 221,   18
DefTimeZonePoint	 233,   16
DefTimeZonePoint	 233,    0
EndTimeZone	33_

StartTimeZone	34_, 21, 0, 195, 229
DefTimeZonePoint	 229,   71
DefTimeZonePoint	 214,   82
DefTimeZonePoint	 214,  115
DefTimeZonePoint	 218,  123
DefTimeZonePoint	 218,  135
DefTimeZonePoint	 199,  135
DefTimeZonePoint	 199,   86
DefTimeZonePoint	 195,   79
DefTimeZonePoint	 195,   64
DefTimeZonePoint	 206,   61
DefTimeZonePoint	 214,   57
DefTimeZonePoint	 221,   57
DefTimeZonePoint	 229,   71
EndTimeZone	34_

StartTimeZone	35_, 21, 30, 199, 218
DefTimeZonePoint	 199,  135
DefTimeZonePoint	 218,  135
DefTimeZonePoint	 214,  148
DefTimeZonePoint	 214,  160
DefTimeZonePoint	 218,  160
DefTimeZonePoint	 218,  182
DefTimeZonePoint	 199,  182
DefTimeZonePoint	 199,  135
EndTimeZone	35_

StartTimeZone	36_, 21, 0, 199, 218
DefTimeZonePoint	 218,  182
DefTimeZonePoint	 218,  207
DefTimeZonePoint	 199,  207
DefTimeZonePoint	 199,  182
DefTimeZonePoint	 218,  182
EndTimeZone	36_

StartTimeZone	37_, 22, 0, 214, 240
DefTimeZonePoint	 229,   71
DefTimeZonePoint	 240,   68
DefTimeZonePoint	 240,  127
DefTimeZonePoint	 233,  131
DefTimeZonePoint	 240,  140
DefTimeZonePoint	 240,  207
DefTimeZonePoint	 218,  207
DefTimeZonePoint	 218,  160
DefTimeZonePoint	 214,  160
DefTimeZonePoint	 214,  148
DefTimeZonePoint	 218,  135
DefTimeZonePoint	 218,  123
DefTimeZonePoint	 214,  115
DefTimeZonePoint	 214,   82
DefTimeZonePoint	 229,   71
EndTimeZone	37_

StartTimeZone	38_, 24, 0, 229, 281
DefTimeZonePoint	 240,    0
DefTimeZonePoint	 266,    0
DefTimeZonePoint	 266,   14
DefTimeZonePoint	 281,   23
DefTimeZonePoint	 281,   28
DefTimeZonePoint	 255,   44
DefTimeZonePoint	 266,   51
DefTimeZonePoint	 266,  127
DefTimeZonePoint	 278,  144
DefTimeZonePoint	 278,  185
DefTimeZonePoint	 266,  195
DefTimeZonePoint	 266,  207
DefTimeZonePoint	 259,  207
DefTimeZonePoint	 259,  198
DefTimeZonePoint	 248,  192
DefTimeZonePoint	 248,  185
DefTimeZonePoint	 259,  163
DefTimeZonePoint	 259,  127
DefTimeZonePoint	 240,  102
DefTimeZonePoint	 240,   51
DefTimeZonePoint	 229,   41
DefTimeZonePoint	 244,   33
DefTimeZonePoint	 244,   28
DefTimeZonePoint	 240,   23
DefTimeZonePoint	 248,   23
DefTimeZonePoint	 240,   18
DefTimeZonePoint	 240,    0
EndTimeZone	38_

StartTimeZone	39_, 23, 0, 233, 259
DefTimeZonePoint	 240,  102
DefTimeZonePoint	 259,  127
DefTimeZonePoint	 259,  163
DefTimeZonePoint	 248,  185
DefTimeZonePoint	 248,  192
DefTimeZonePoint	 259,  198
DefTimeZonePoint	 259,  207
DefTimeZonePoint	 240,  207
DefTimeZonePoint	 240,  140
DefTimeZonePoint	 233,  131
DefTimeZonePoint	 240,  127
DefTimeZonePoint	 240,  102
EndTimeZone	39_

StartTimeZone	40_, 1, 0, 255, 285
DefTimeZonePoint	 266,    0
DefTimeZonePoint	 285,    0
DefTimeZonePoint	 285,  207
DefTimeZonePoint	 266,  207
DefTimeZonePoint	 266,  195
DefTimeZonePoint	 278,  185
DefTimeZonePoint	 278,  144
DefTimeZonePoint	 266,  127
DefTimeZonePoint	 266,   51
DefTimeZonePoint	 255,   44
DefTimeZonePoint	 281,   28
DefTimeZonePoint	 281,   23
DefTimeZonePoint	 266,   14
DefTimeZonePoint	 266,    0
EndTimeZone	40_

StartTimeZone	41_, 6, 0, 360, 397
DefTimeZonePoint	 371,    0
DefTimeZonePoint	 390,    0
DefTimeZonePoint	 390,   36
DefTimeZonePoint	 386,   39
DefTimeZonePoint	 386,   54
DefTimeZonePoint	 397,   79
DefTimeZonePoint	 394,   90
DefTimeZonePoint	 397,  106
DefTimeZonePoint	 397,  207
DefTimeZonePoint	 379,  207
DefTimeZonePoint	 379,  115
DefTimeZonePoint	 367,   94
DefTimeZonePoint	 364,   75
DefTimeZonePoint	 371,   79
DefTimeZonePoint	 375,   57
DefTimeZonePoint	 367,   51
DefTimeZonePoint	 360,   51
DefTimeZonePoint	 360,   44
DefTimeZonePoint	 367,   44
DefTimeZonePoint	 367,   36
DefTimeZonePoint	 371,   36
DefTimeZonePoint	 371,    0
EndTimeZone	41_

StartTimeZone	42_, 4, 0, 319, 360
DefTimeZonePoint	 319,    0
DefTimeZonePoint	 322,    0
DefTimeZonePoint	 322,   23
DefTimeZonePoint	 352,   47
DefTimeZonePoint	 352,   54
DefTimeZonePoint	 349,   57
DefTimeZonePoint	 356,   64
DefTimeZonePoint	 356,   79
DefTimeZonePoint	 352,   79
DefTimeZonePoint	 360,   90
DefTimeZonePoint	 356,   94
DefTimeZonePoint	 356,  207
DefTimeZonePoint	 337,  207
DefTimeZonePoint	 337,  167
DefTimeZonePoint	 337,   57
DefTimeZonePoint	 326,   44
DefTimeZonePoint	 337,   41
DefTimeZonePoint	 319,   33
DefTimeZonePoint	 319,    0
DefTimeZonePoint	 319,    0
EndTimeZone	42_

StartTimeZone	43_, 5, 0, 322, 379
DefTimeZonePoint	 322,    0
DefTimeZonePoint	 371,    0
DefTimeZonePoint	 371,   36
DefTimeZonePoint	 367,   36
DefTimeZonePoint	 367,   44
DefTimeZonePoint	 360,   44
DefTimeZonePoint	 360,   51
DefTimeZonePoint	 367,   51
DefTimeZonePoint	 375,   57
DefTimeZonePoint	 371,   79
DefTimeZonePoint	 364,   75
DefTimeZonePoint	 367,   94
DefTimeZonePoint	 379,  115
DefTimeZonePoint	 379,  207
DefTimeZonePoint	 356,  207
DefTimeZonePoint	 356,   94
DefTimeZonePoint	 360,   90
DefTimeZonePoint	 352,   79
DefTimeZonePoint	 356,   79
DefTimeZonePoint	 356,   64
DefTimeZonePoint	 349,   57
DefTimeZonePoint	 352,   54
DefTimeZonePoint	 352,   47
DefTimeZonePoint	 322,   23
DefTimeZonePoint	 322,    0
EndTimeZone	43_

StartTimeZone	44_, 21, 0, 173, 206
DefTimeZonePoint	 184,    0
DefTimeZonePoint	 206,    0
DefTimeZonePoint	 206,   18
DefTimeZonePoint	 199,   25
DefTimeZonePoint	 206,   28
DefTimeZonePoint	 203,   54
DefTimeZonePoint	 195,   44
DefTimeZonePoint	 176,   51
DefTimeZonePoint	 188,   36
DefTimeZonePoint	 176,   36
DefTimeZonePoint	 173,   23
DefTimeZonePoint	 180,   18
DefTimeZonePoint	 176,   14
DefTimeZonePoint	 184,   14
DefTimeZonePoint	 184,    0
EndTimeZone	44_

EndTimeZoneList


;.noshowm

; This is an unordered list of cities.  The city and country names are in
; SJIS format.  If any backslashes appear within quotes, they must be
; duplicated in order for esp to pass them along into the world.wcm file.

; default home city: Tokyo, Japan
; default dest city: Tokyo, Japan
; Format: StartCityList	default home city, default dest city, default time
; zone (specify the HOUR of the default time zone)
StartCityList	124, 124, 21
;DefCity city,      country,     city_initial,         country_initial,     x, y
DefCity "レイキャビック",   "アイスランド", C_HIRAGANA_LETTER_RE, C_HIRAGANA_LETTER_A, 3, 30
DefCity "ダブリン",   "アイルランド", C_HIRAGANA_LETTER_DA, C_HIRAGANA_LETTER_A, 24, 45
DefCity "カブール",   "アフガニスタン", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_A, 123, 73
DefCity "アトランタ",   "アメリカ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_A, 394, 74
DefCity "アルバカーキ",   "アメリカ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_A, 365, 71
DefCity "アンカレッジ",   "アメリカ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_A, 308, 34
DefCity "インディアナポリス",   "アメリカ", C_HIRAGANA_LETTER_I, C_HIRAGANA_LETTER_A, 392, 65
DefCity "オクラホマシティー",   "アメリカ", C_HIRAGANA_LETTER_O, C_HIRAGANA_LETTER_A, 377, 71
DefCity "オマハ",   "アメリカ", C_HIRAGANA_LETTER_O, C_HIRAGANA_LETTER_A, 378, 63
DefCity "カンザスシティー",   "アメリカ", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_A, 381, 65
DefCity "クリーブランド",   "アメリカ", C_HIRAGANA_LETTER_KU, C_HIRAGANA_LETTER_A, 398, 63
DefCity "コロンバス",   "アメリカ", C_HIRAGANA_LETTER_KO, C_HIRAGANA_LETTER_A, 395, 64
DefCity "サンアントニオ",   "アメリカ", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_A, 376, 80
DefCity "サンタフェ",   "アメリカ", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_A, 365, 71
DefCity "サンディエゴ",   "アメリカ", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_A, 351, 76
DefCity "サンフランシスコ",   "アメリカ", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_A, 344, 68
DefCity "シアトル",   "アメリカ", C_HIRAGANA_LETTER_SI, C_HIRAGANA_LETTER_A, 344, 54
DefCity "シカゴ",   "アメリカ", C_HIRAGANA_LETTER_SI, C_HIRAGANA_LETTER_A, 390, 61
DefCity "シャーロット",   "アメリカ", C_HIRAGANA_LETTER_SI, C_HIRAGANA_LETTER_A, 399, 71
DefCity "ジャクソ\ンビル",   "アメリカ", C_HIRAGANA_LETTER_ZI, C_HIRAGANA_LETTER_A, 398, 78
DefCity "シンシナチ",   "アメリカ", C_HIRAGANA_LETTER_SI, C_HIRAGANA_LETTER_A, 394, 65
DefCity "セントルイス",   "アメリカ", C_HIRAGANA_LETTER_SE, C_HIRAGANA_LETTER_A, 386, 67
DefCity "ソ\ルトレークシティ",   "アメリカ", C_HIRAGANA_LETTER_SO, C_HIRAGANA_LETTER_A, 357, 64
DefCity "ダラス",   "アメリカ", C_HIRAGANA_LETTER_DA, C_HIRAGANA_LETTER_A, 378, 76
DefCity "タンパ",   "アメリカ", C_HIRAGANA_LETTER_TA, C_HIRAGANA_LETTER_A, 397, 81
DefCity "デトロイト",   "アメリカ", C_HIRAGANA_LETTER_DE, C_HIRAGANA_LETTER_A, 395, 61
DefCity "デンバー",   "アメリカ", C_HIRAGANA_LETTER_DE, C_HIRAGANA_LETTER_A, 367, 65
DefCity "ナッシュビル",   "アメリカ", C_HIRAGANA_LETTER_NA, C_HIRAGANA_LETTER_A, 390, 70
DefCity "ニューオリンズ",   "アメリカ", C_HIRAGANA_LETTER_NI, C_HIRAGANA_LETTER_A, 386, 78
DefCity "ニューヨーク",   "アメリカ", C_HIRAGANA_LETTER_NI, C_HIRAGANA_LETTER_A, 407, 63
DefCity "ノーフォーク",   "アメリカ", C_HIRAGANA_LETTER_NO, C_HIRAGANA_LETTER_A, 405, 68
DefCity "バーミンガム",   "アメリカ", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_A, 390, 74
DefCity "ピッツバーグ",   "アメリカ", C_HIRAGANA_LETTER_PI, C_HIRAGANA_LETTER_A, 399, 64
DefCity "ヒューストン",   "アメリカ", C_HIRAGANA_LETTER_HI, C_HIRAGANA_LETTER_A, 380, 80
DefCity "フィラデルフィア",   "アメリカ", C_HIRAGANA_LETTER_HU, C_HIRAGANA_LETTER_A, 406, 64
DefCity "フェニックス",   "アメリカ", C_HIRAGANA_LETTER_HU, C_HIRAGANA_LETTER_A, 357, 74
DefCity "ポートランド",   "アメリカ", C_HIRAGANA_LETTER_PO, C_HIRAGANA_LETTER_A, 344, 57
DefCity "ボストン",   "アメリカ", C_HIRAGANA_LETTER_BO, C_HIRAGANA_LETTER_A, 411, 61
DefCity "ホノルル",   "アメリカ", C_HIRAGANA_LETTER_HO, C_HIRAGANA_LETTER_A, 297, 91
DefCity "ボルチモア",   "アメリカ", C_HIRAGANA_LETTER_BO, C_HIRAGANA_LETTER_A, 405, 65
DefCity "マイアミ",   "アメリカ", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_A, 399, 86
DefCity "ミネアポリス",   "アメリカ", C_HIRAGANA_LETTER_MI, C_HIRAGANA_LETTER_A, 382, 57
DefCity "ミルウォーキー",   "アメリカ", C_HIRAGANA_LETTER_MI, C_HIRAGANA_LETTER_A, 389, 60
DefCity "メンフィス",   "アメリカ", C_HIRAGANA_LETTER_ME, C_HIRAGANA_LETTER_A, 386, 71
DefCity "ラスベガス",   "アメリカ", C_HIRAGANA_LETTER_RA, C_HIRAGANA_LETTER_A, 354, 70
DefCity "ルイスビル",   "アメリカ", C_HIRAGANA_LETTER_RU, C_HIRAGANA_LETTER_A, 393, 67
DefCity "ロサンゼルス",   "アメリカ", C_HIRAGANA_LETTER_RO, C_HIRAGANA_LETTER_A, 350, 73
DefCity "ワシントンＤ．Ｃ．",   "アメリカ", C_HIRAGANA_LETTER_WA, C_HIRAGANA_LETTER_A, 403, 65
DefCity "バージン諸島",   "アメリカ領", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_A, 419, 96
DefCity "ミッドウェー諸島",   "アメリカ領", C_HIRAGANA_LETTER_MI, C_HIRAGANA_LETTER_A, 272, 81
DefCity "アブダビ",   "アラブ首長国連邦", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_A, 103, 87
DefCity "ドバイ",   "アラブ首長国連邦", C_HIRAGANA_LETTER_DO, C_HIRAGANA_LETTER_A, 104, 86
DefCity "アルジェリア",   "アルジェリア", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_A, 36, 70
DefCity "ブエノスアイレス",   "アルゼンチン", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_A, 428, 170
DefCity "チラナ",   "アルバニア", C_HIRAGANA_LETTER_TI, C_HIRAGANA_LETTER_A, 57, 63
DefCity "ルアンダ",   "アンゴラ", C_HIRAGANA_LETTER_RU, C_HIRAGANA_LETTER_A, 49, 133
DefCity "アンドラララベリャ",   "アンドラ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_A, 34, 61
DefCity "アデン",   "イエメン", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_I, 91, 104
DefCity "サメア",   "イエメン", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_I, 90, 100
DefCity "ロンドン",   "イギリス", C_HIRAGANA_LETTER_RO, C_HIRAGANA_LETTER_I, 32, 48
DefCity "香港",   "イギリス", C_HIRAGANA_LETTER_HO, C_HIRAGANA_LETTER_I, 182, 90
DefCity "エルサレム",   "イスラエル", C_HIRAGANA_LETTER_E, C_HIRAGANA_LETTER_I, 78, 77
DefCity "テルアビブ",   "イスラエル", C_HIRAGANA_LETTER_TE, C_HIRAGANA_LETTER_I, 77, 76
DefCity "ジェノバ",   "イタリア", C_HIRAGANA_LETTER_ZI, C_HIRAGANA_LETTER_I, 44, 58
DefCity "ベニス",   "イタリア", C_HIRAGANA_LETTER_BE, C_HIRAGANA_LETTER_I, 48, 57
DefCity "ミラノ",   "イタリア", C_HIRAGANA_LETTER_MI, C_HIRAGANA_LETTER_I, 44, 57
DefCity "ナポリ",   "イタリア", C_HIRAGANA_LETTER_NA, C_HIRAGANA_LETTER_I, 51, 63
DefCity "ローマ",   "イタリア", C_HIRAGANA_LETTER_RO, C_HIRAGANA_LETTER_I, 48, 61
DefCity "バグダッド",   "イラク", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_I, 90, 74
DefCity "テヘラン",   "イラン", C_HIRAGANA_LETTER_TE, C_HIRAGANA_LETTER_I, 99, 71
DefCity "カルカッタ",   "インド", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_I, 148, 90
DefCity "ニューデリー",   "インド", C_HIRAGANA_LETTER_NI, C_HIRAGANA_LETTER_I, 133, 81
DefCity "ボンベイ",   "インド", C_HIRAGANA_LETTER_BO, C_HIRAGANA_LETTER_I, 128, 94
DefCity "ジャカルタ",   "インドネシア", C_HIRAGANA_LETTER_ZI, C_HIRAGANA_LETTER_I, 173, 130
DefCity "カンパラ",   "ウガンダ", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_U, 74, 121
DefCity "キエフ",   "ウクライナ", C_HIRAGANA_LETTER_KI, C_HIRAGANA_LETTER_U, 72, 50
DefCity "モンテビデオ",   "ウルグアイ", C_HIRAGANA_LETTER_MO, C_HIRAGANA_LETTER_U, 431, 172
DefCity "キト",   "エクアドル", C_HIRAGANA_LETTER_KI, C_HIRAGANA_LETTER_E, 402, 121
DefCity "カイロ",   "エジプト", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_E, 73, 78
DefCity "スエズ",   "エジプト", C_HIRAGANA_LETTER_SU, C_HIRAGANA_LETTER_E, 74, 78
DefCity "アジスアベバ",   "エチオピア", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_E, 82, 109
DefCity "サンサルバドル",   "エルサルバドル", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_E, 388, 103
DefCity "アデレード",   "オーストラリア", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_O, 213, 172
DefCity "アリススプリングス",   "オーストラリア", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_O, 208, 154
DefCity "キャンベラ",   "オーストラリア", C_HIRAGANA_LETTER_KI, C_HIRAGANA_LETTER_O, 228, 172
DefCity "シドニー",   "オーストラリア", C_HIRAGANA_LETTER_SI, C_HIRAGANA_LETTER_O, 230, 170
DefCity "ダーウィン",   "オーストラリア", C_HIRAGANA_LETTER_DA, C_HIRAGANA_LETTER_O, 203, 139
DefCity "ノーフォーク島",   "オーストラリア", C_HIRAGANA_LETTER_NO, C_HIRAGANA_LETTER_O, 253, 163
DefCity "パース",   "オーストラリア", C_HIRAGANA_LETTER_PA, C_HIRAGANA_LETTER_O, 184, 167
DefCity "ブリスベン",   "オーストラリア", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_O, 233, 160
DefCity "ブロークンヒル",   "オーストラリア", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_O, 217, 167
DefCity "メルボルン",   "オーストラリア", C_HIRAGANA_LETTER_ME, C_HIRAGANA_LETTER_O, 222, 175
DefCity "ウィーン",   "オーストリア", C_HIRAGANA_LETTER_U, C_HIRAGANA_LETTER_O, 53, 53
DefCity "ザルツブルグ",   "オーストリア", C_HIRAGANA_LETTER_ZA, C_HIRAGANA_LETTER_O, 49, 54
DefCity "マスカット",   "オマーン", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_O, 108, 88
DefCity "アムステルダム",   "オランダ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_O, 39, 47
DefCity "ロッテルダム",   "オランダ", C_HIRAGANA_LETTER_RO, C_HIRAGANA_LETTER_O, 38, 47
DefCity "アクラ",   "ガーナ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_GA, 32, 114
DefCity "ジョージタウン",   "ガイアナ", C_HIRAGANA_LETTER_ZI, C_HIRAGANA_LETTER_GA, 428, 113
DefCity "ドーハ",   "カタール", C_HIRAGANA_LETTER_DO, C_HIRAGANA_LETTER_KA, 99, 86
DefCity "ウィニペグ",   "カナダ", C_HIRAGANA_LETTER_U, C_HIRAGANA_LETTER_KA, 377, 50
DefCity "エドモントン",   "カナダ", C_HIRAGANA_LETTER_E, C_HIRAGANA_LETTER_KA, 356, 45
DefCity "オタワ",   "カナダ", C_HIRAGANA_LETTER_O, C_HIRAGANA_LETTER_KA, 406, 57
DefCity "カルガリー",   "カナダ", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_KA, 355, 48
DefCity "トロント",   "カナダ", C_HIRAGANA_LETTER_TO, C_HIRAGANA_LETTER_KA, 401, 60
DefCity "ハリファックス",   "カナダ", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_KA, 422, 58
DefCity "バンクーバー",   "カナダ", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_KA, 343, 51
DefCity "モントリオール",   "カナダ", C_HIRAGANA_LETTER_MO, C_HIRAGANA_LETTER_KA, 409, 57
DefCity "レジーナ",   "カナダ", C_HIRAGANA_LETTER_RE, C_HIRAGANA_LETTER_KA, 368, 50
DefCity "リーブルビル",   "ガボン", C_HIRAGANA_LETTER_RI, C_HIRAGANA_LETTER_GA, 44, 121
DefCity "ヤウンデ",   "カメルーン", C_HIRAGANA_LETTER_YA, C_HIRAGANA_LETTER_KA, 47, 116
DefCity "ソ\ウル",   "韓国", C_HIRAGANA_LETTER_SO, C_HIRAGANA_LETTER_KA, 199, 68
DefCity "プノンペン",   "カンボジア", C_HIRAGANA_LETTER_PU, C_HIRAGANA_LETTER_KA, 170, 106
DefCity "コナクリ",   "ギニア", C_HIRAGANA_LETTER_KO, C_HIRAGANA_LETTER_GI, 15, 109
DefCity "ニコシア",   "キプロス", C_HIRAGANA_LETTER_NI, C_HIRAGANA_LETTER_KI, 76, 71
DefCity "ハバナ",   "キューバ", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_KI, 397, 88
DefCity "アテネ",   "ギリシャ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_GI, 62, 67
DefCity "グアテマラシティ",   "グアテマラ", C_HIRAGANA_LETTER_GU, C_HIRAGANA_LETTER_GU, 386, 101
DefCity "クウェート",   "クウェート", C_HIRAGANA_LETTER_KU, C_HIRAGANA_LETTER_KU, 95, 80
DefCity "ザグレブ",   "クロアチア", C_HIRAGANA_LETTER_ZA, C_HIRAGANA_LETTER_KU, 53, 60
DefCity "ナイロビ",   "ケニア", C_HIRAGANA_LETTER_NA, C_HIRAGANA_LETTER_KE, 81, 123
DefCity "アビジャン",   "コートジボワール", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_KO, 27, 114
DefCity "サンホセ",   "コスタリカ", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_KO, 394, 107
DefCity "モロニ",   "コモロ", C_HIRAGANA_LETTER_MO, C_HIRAGANA_LETTER_KO, 89, 137
DefCity "ボゴタ",   "コロンビア", C_HIRAGANA_LETTER_BO, C_HIRAGANA_LETTER_KO, 407, 116
DefCity "ブラザビル",   "コンゴ", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_KO, 52, 127
DefCity "キンシャサ",   "ザイール", C_HIRAGANA_LETTER_KI, C_HIRAGANA_LETTER_ZA, 52, 127
DefCity "ブカブ",   "ザイール", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_ZA, 70, 124
DefCity "ジッダ",   "サウジアラビア", C_HIRAGANA_LETTER_ZI, C_HIRAGANA_LETTER_SA, 83, 91
DefCity "リヤド",   "サウジアラビア", C_HIRAGANA_LETTER_RI, C_HIRAGANA_LETTER_SA, 93, 87
DefCity "ルサカ",   "ザンビア", C_HIRAGANA_LETTER_RU, C_HIRAGANA_LETTER_ZA, 69, 143
DefCity "フリータウン",   "シエラレオネ", C_HIRAGANA_LETTER_HU, C_HIRAGANA_LETTER_SI, 15, 110
DefCity "ジプチ",   "ジプチ", C_HIRAGANA_LETTER_ZI, C_HIRAGANA_LETTER_ZI, 89, 104
DefCity "キングストン",   "ジャマイカ", C_HIRAGANA_LETTER_KI, C_HIRAGANA_LETTER_ZI, 405, 96
DefCity "ダマスカス",   "シリア", C_HIRAGANA_LETTER_DA, C_HIRAGANA_LETTER_SI, 79, 74
DefCity "シンガポール",   "シンガポール", C_HIRAGANA_LETTER_SI, C_HIRAGANA_LETTER_SI, 169, 120
DefCity "ハラーレ",   "ジンバブエ", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_ZI, 73, 147
DefCity "ジュネーブ",   "スイス", C_HIRAGANA_LETTER_ZI, C_HIRAGANA_LETTER_SU, 40, 55
DefCity "チューリッヒ",   "スイス", C_HIRAGANA_LETTER_TI, C_HIRAGANA_LETTER_SU, 43, 54
DefCity "バーゼル",   "スイス", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_SU, 41, 54
DefCity "ベルン",   "スイス", C_HIRAGANA_LETTER_BE, C_HIRAGANA_LETTER_SU, 41, 54
DefCity "ストックホルム",   "スウェーデン", C_HIRAGANA_LETTER_SU, C_HIRAGANA_LETTER_SU, 56, 37
DefCity "ハルツーム",   "スーダン", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_SU, 74, 100
DefCity "カナリア諸島",   "スペイン", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_SU, 14, 81
DefCity "バルセロナ",   "スペイン", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_SU, 35, 63
DefCity "マドリッド",   "スペイン", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_SU, 28, 64
DefCity "パラマリボ",   "スリナム", C_HIRAGANA_LETTER_PA, C_HIRAGANA_LETTER_SU, 432, 113
DefCity "コロンボ",   "スリランカ", C_HIRAGANA_LETTER_KO, C_HIRAGANA_LETTER_SU, 137, 111
DefCity "ブラチスラバ",   "スロバキア", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_SU, 55, 53
DefCity "ルジュブルジャナ",   "スロベニア", C_HIRAGANA_LETTER_RU, C_HIRAGANA_LETTER_SU, 51, 55
DefCity "ビクトリア",   "セイシェル", C_HIRAGANA_LETTER_BI, C_HIRAGANA_LETTER_SE, 104, 127
DefCity "ダカール",   "セネガル", C_HIRAGANA_LETTER_DA, C_HIRAGANA_LETTER_SE, 10, 101
DefCity "モガディシュ",   "ソ\マリア", C_HIRAGANA_LETTER_MO, C_HIRAGANA_LETTER_SO, 91, 119
DefCity "バンコク",   "タイ", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_TA, 163, 103
DefCity "台北",   "台湾", C_HIRAGANA_LETTER_TA, C_HIRAGANA_LETTER_TA, 191, 86
DefCity "ダルエスサラーム",   "タンザニア", C_HIRAGANA_LETTER_DA, C_HIRAGANA_LETTER_TA, 83, 131
DefCity "プラハ",   "チェコ", C_HIRAGANA_LETTER_PU, C_HIRAGANA_LETTER_TI, 51, 50
DefCity "ンジャメナ",   "チャド", C_HIRAGANA_LETTER_N, C_HIRAGANA_LETTER_TI, 52, 104
DefCity "バンギ",   "中央アフリカ共和国", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_TI, 56, 116
DefCity "上海",   "中国", C_HIRAGANA_LETTER_SI, C_HIRAGANA_LETTER_TI, 191, 77
DefCity "北京",   "中国", C_HIRAGANA_LETTER_PE, C_HIRAGANA_LETTER_TI, 184, 64
DefCity "チュニス",   "チュニジア", C_HIRAGANA_LETTER_TI, C_HIRAGANA_LETTER_TI, 45, 68
DefCity "ピョンヤン",   "朝鮮", C_HIRAGANA_LETTER_PI, C_HIRAGANA_LETTER_TI, 197, 65
DefCity "サンチャゴ",   "チリ", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_TI, 413, 169
DefCity "コペンハーゲン",   "デンマーク", C_HIRAGANA_LETTER_KO, C_HIRAGANA_LETTER_DE, 48, 43
DefCity "デュッセルドルフ",   "ドイツ", C_HIRAGANA_LETTER_DE, C_HIRAGANA_LETTER_DO, 40, 48
DefCity "ハノーバー",   "ドイツ", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_DO, 44, 47
DefCity "ハンブルク",   "ドイツ", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_DO, 45, 45
DefCity "フランクフルト",   "ドイツ", C_HIRAGANA_LETTER_HU, C_HIRAGANA_LETTER_DO, 43, 50
DefCity "ベルリン",   "ドイツ", C_HIRAGANA_LETTER_BE, C_HIRAGANA_LETTER_DO, 49, 47
DefCity "ボン",   "ドイツ", C_HIRAGANA_LETTER_BO, C_HIRAGANA_LETTER_DO, 41, 50
DefCity "ミュンヘン",   "ドイツ", C_HIRAGANA_LETTER_MI, C_HIRAGANA_LETTER_DO, 47, 53
DefCity "ロメ",   "トーゴ", C_HIRAGANA_LETTER_RO, C_HIRAGANA_LETTER_TO, 34, 113
DefCity "サントドミンゴ",   "ドミニカ共和国", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_DO, 413, 96
DefCity "ポートオブスペイン",   "トリニダードトバゴ", C_HIRAGANA_LETTER_PO, C_HIRAGANA_LETTER_TO, 424, 107
DefCity "アンカラ",   "トルコ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_TO, 62, 64
DefCity "イスタンブール",   "トルコ", C_HIRAGANA_LETTER_I, C_HIRAGANA_LETTER_TO, 70, 63
DefCity "ラゴス",   "ナイジェリア", C_HIRAGANA_LETTER_RA, C_HIRAGANA_LETTER_NA, 36, 113
DefCity "マナグア",   "ニカラグア", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_NI, 392, 104
DefCity "ニアメ",   "ニジェール", C_HIRAGANA_LETTER_NI, C_HIRAGANA_LETTER_NI, 35, 103
DefCity "大阪",   "日本", C_HIRAGANA_LETTER_O, C_HIRAGANA_LETTER_NI, 209, 73
DefCity "札幌",   "日本", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_NI, 217, 60
DefCity "仙台",   "日本", C_HIRAGANA_LETTER_SE, C_HIRAGANA_LETTER_NI, 217, 67
DefCity "東京",   "日本", C_HIRAGANA_LETTER_TO, C_HIRAGANA_LETTER_NI, 216, 71
DefCity "名古屋",   "日本", C_HIRAGANA_LETTER_NA, C_HIRAGANA_LETTER_NI, 212, 71
DefCity "広島",   "日本", C_HIRAGANA_LETTER_HI, C_HIRAGANA_LETTER_NI, 208, 73
DefCity "福岡",   "日本", C_HIRAGANA_LETTER_HU, C_HIRAGANA_LETTER_NI, 205, 74
DefCity "ウェリントン",   "ニュージーランド", C_HIRAGANA_LETTER_U, C_HIRAGANA_LETTER_NI, 262, 180
DefCity "オークランド",   "ニュージーランド", C_HIRAGANA_LETTER_O, C_HIRAGANA_LETTER_NI, 262, 175
DefCity "カトマンズ",   "ネパール", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_NE, 144, 83
DefCity "オスロ",   "ノルウェー", C_HIRAGANA_LETTER_O, C_HIRAGANA_LETTER_NO, 45, 35
DefCity "ベルゲン",   "ノルウェー", C_HIRAGANA_LETTER_BE, C_HIRAGANA_LETTER_NO, 39, 35
DefCity "マナーマ",   "バーレーン", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_BA, 98, 84
DefCity "ポルトープランス",   "ハイチ", C_HIRAGANA_LETTER_PO, C_HIRAGANA_LETTER_HA, 410, 96
DefCity "イスラマバード",   "パキスタン", C_HIRAGANA_LETTER_I, C_HIRAGANA_LETTER_PA, 128, 74
DefCity "カラチ",   "パキスタン", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_PA, 120, 86
DefCity "バチカン",   "バチカン市国", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_BA, 48, 61
DefCity "パナマ",   "パナマ", C_HIRAGANA_LETTER_PA, C_HIRAGANA_LETTER_PA, 401, 109
DefCity "ポートビラ",   "バヌアツ", C_HIRAGANA_LETTER_PO, C_HIRAGANA_LETTER_BA, 253, 146
DefCity "ナッソ\ー",   "バハマ", C_HIRAGANA_LETTER_NA, C_HIRAGANA_LETTER_BA, 403, 86
DefCity "ポートモレスビー",   "パプアニューギニア", C_HIRAGANA_LETTER_PO, C_HIRAGANA_LETTER_PA, 225, 134
DefCity "ラバウル",   "パプアニューギニア", C_HIRAGANA_LETTER_RA, C_HIRAGANA_LETTER_PA, 232, 127
DefCity "アシスオン",   "パラグアイ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_PA, 430, 157
DefCity "ブダペスト",   "ハンガリー", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_HA, 57, 54
DefCity "ダッカ",   "バングラディッシュ", C_HIRAGANA_LETTER_DA, C_HIRAGANA_LETTER_BA, 150, 88
DefCity "スバ",   "フィジー", C_HIRAGANA_LETTER_SU, C_HIRAGANA_LETTER_HU, 266, 147
DefCity "マニラ",   "フィリピン", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_HU, 191, 101
DefCity "ヘルシンキ",   "フィンランド", C_HIRAGANA_LETTER_HE, C_HIRAGANA_LETTER_HU, 65, 35
DefCity "ティンプー",   "ブータン", C_HIRAGANA_LETTER_TE, C_HIRAGANA_LETTER_BU, 149, 83
DefCity "サンユアン",   "プエルトリコ", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_PU, 418, 96
DefCity "サンパウロ",   "ブラジル", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_BU, 444, 154
DefCity "ブラジリア",   "ブラジル", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_BU, 441, 143
DefCity "マナオス",   "ブラジル", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_BU, 426, 126
DefCity "リオデジャネイロ",   "ブラジル", C_HIRAGANA_LETTER_RI, C_HIRAGANA_LETTER_BU, 448, 154
DefCity "パリ",   "フランス", C_HIRAGANA_LETTER_PA, C_HIRAGANA_LETTER_HU, 35, 51
DefCity "マルセイユ",   "フランス", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_HU, 39, 60
DefCity "ギアナ",   "フランス領", C_HIRAGANA_LETTER_GI, C_HIRAGANA_LETTER_HU, 436, 114
DefCity "タヒチ島",   "フランス領", C_HIRAGANA_LETTER_TA, C_HIRAGANA_LETTER_HU, 308, 147
DefCity "ソ\フィア",   "ブルガリア", C_HIRAGANA_LETTER_SO, C_HIRAGANA_LETTER_BU, 62, 61
DefCity "ワガドゥーグー",   "ブルキナファソ\", C_HIRAGANA_LETTER_WA, C_HIRAGANA_LETTER_BU, 31, 104
DefCity "バンダルスリブガワン",   "ブルネイ", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_BU, 183, 114
DefCity "ブジュンブラ",   "ブルンジ", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_BU, 70, 126
DefCity "ハノイ",   "ベトナム", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_BE, 171, 91
DefCity "ポルトノボ",   "ベナン", C_HIRAGANA_LETTER_PO, C_HIRAGANA_LETTER_BE, 35, 113
DefCity "カラカス",   "ベネズエラ", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_BE, 416, 107
DefCity "ベルモパン",   "ベリーズ", C_HIRAGANA_LETTER_BE, C_HIRAGANA_LETTER_BE, 389, 97
DefCity "リマ",   "ペルー", C_HIRAGANA_LETTER_RI, C_HIRAGANA_LETTER_PE, 403, 139
DefCity "ブリュッセル",   "ベルギー", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_BE, 38, 48
DefCity "ワルシャワ",   "ポーランド", C_HIRAGANA_LETTER_WA, C_HIRAGANA_LETTER_PO, 60, 47
DefCity "ハボローネ",   "ボツワナ", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_BO, 66, 156
DefCity "ラパス",   "ボリビア", C_HIRAGANA_LETTER_RA, C_HIRAGANA_LETTER_BO, 415, 144
DefCity "リスボン",   "ポルトガル", C_HIRAGANA_LETTER_RI, C_HIRAGANA_LETTER_PO, 20, 67
DefCity "アゾレス諸島",   "ポルトガル領", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_PO, 0, 68
DefCity "テグシガルパ",   "ホンジュラス", C_HIRAGANA_LETTER_TE, C_HIRAGANA_LETTER_HO, 390, 101
DefCity "マジュロ",   "マーシャル諸島", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_MA, 253, 110
DefCity "アンタナナリボ",   "マダガスカル", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_MA, 94, 149
DefCity "リロングウェ",   "マラウイ", C_HIRAGANA_LETTER_RI, C_HIRAGANA_LETTER_MA, 76, 142
DefCity "バマコ",   "マリ", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_MA, 22, 104
DefCity "バレッタ",   "マルタ", C_HIRAGANA_LETTER_BA, C_HIRAGANA_LETTER_MA, 51, 70
DefCity "クアラルンプール",   "マレーシア", C_HIRAGANA_LETTER_KU, C_HIRAGANA_LETTER_MA, 165, 117
DefCity "ケープタウン",   "南アフリカ共和国", C_HIRAGANA_LETTER_KE, C_HIRAGANA_LETTER_MI, 56, 170
DefCity "プレトリア",   "南アフリカ共和国", C_HIRAGANA_LETTER_PU, C_HIRAGANA_LETTER_MI, 69, 157
DefCity "ヨハネスブルグ",   "南アフリカ共和国", C_HIRAGANA_LETTER_YO, C_HIRAGANA_LETTER_MI, 69, 159
DefCity "ヤンゴン",   "ミャンマー", C_HIRAGANA_LETTER_YA, C_HIRAGANA_LETTER_MI, 158, 98
DefCity "アカプルコ",   "メキシコ", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_ME, 373, 97
DefCity "エルモシヨ",   "メキシコ", C_HIRAGANA_LETTER_E, C_HIRAGANA_LETTER_ME, 359, 80
DefCity "ティファナ",   "メキシコ", C_HIRAGANA_LETTER_TE, C_HIRAGANA_LETTER_ME, 351, 76
DefCity "メキシコシティー",   "メキシコ", C_HIRAGANA_LETTER_ME, C_HIRAGANA_LETTER_ME, 374, 94
DefCity "ポートルイス",   "モーリシャス", C_HIRAGANA_LETTER_PO, C_HIRAGANA_LETTER_MO, 107, 150
DefCity "ヌアクショット",   "モーリシャス", C_HIRAGANA_LETTER_NU, C_HIRAGANA_LETTER_MO, 11, 96
DefCity "マプート",   "モザンビーク", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_MO, 74, 159
DefCity "モナコ",   "モナコ", C_HIRAGANA_LETTER_MO, C_HIRAGANA_LETTER_MO, 41, 58
DefCity "マレ",   "モルディブ", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_MO, 128, 116
DefCity "カサブランカ",   "モロッコ", C_HIRAGANA_LETTER_KA, C_HIRAGANA_LETTER_MO, 23, 74
DefCity "ウランバートル",   "モンゴル", C_HIRAGANA_LETTER_U, C_HIRAGANA_LETTER_MO, 173, 53
DefCity "ベオグラード",   "ユーゴスラビア", C_HIRAGANA_LETTER_BE, C_HIRAGANA_LETTER_YU, 59, 57
DefCity "アンマン",   "ヨルダン", C_HIRAGANA_LETTER_A, C_HIRAGANA_LETTER_YO, 79, 76
DefCity "ビエンチェン",   "ラオス", C_HIRAGANA_LETTER_BI, C_HIRAGANA_LETTER_RA, 167, 96
DefCity "トリポリ",   "リビヤ", C_HIRAGANA_LETTER_TO, C_HIRAGANA_LETTER_RI, 49, 74
DefCity "ファドーツ",   "リヒテンシュタイン", C_HIRAGANA_LETTER_HU, C_HIRAGANA_LETTER_RI, 44, 54
DefCity "モンロビア",   "リベリア", C_HIRAGANA_LETTER_MO, C_HIRAGANA_LETTER_RI, 19, 113
DefCity "ブカレスト",   "ルーマニア", C_HIRAGANA_LETTER_BU, C_HIRAGANA_LETTER_RU, 66, 58
DefCity "ルクセンブルグ",   "ルクセンブルグ", C_HIRAGANA_LETTER_RU, C_HIRAGANA_LETTER_RU, 40, 51
DefCity "キガリ",   "ルワンダ", C_HIRAGANA_LETTER_KI, C_HIRAGANA_LETTER_RU, 72, 124
DefCity "マセル",   "レソ\ト", C_HIRAGANA_LETTER_MA, C_HIRAGANA_LETTER_RE, 68, 163
DefCity "ベイルート",   "レバノン", C_HIRAGANA_LETTER_BE, C_HIRAGANA_LETTER_RE, 78, 73
DefCity "ウラジオストック",   "ロシア", C_HIRAGANA_LETTER_U, C_HIRAGANA_LETTER_RO, 205, 60
DefCity "サンクトペテルブルク",   "ロシア", C_HIRAGANA_LETTER_SA, C_HIRAGANA_LETTER_RO, 72, 35
DefCity "ハバロフスク",   "ロシア", C_HIRAGANA_LETTER_HA, C_HIRAGANA_LETTER_RO, 209, 53
DefCity "モスクワ",   "ロシア", C_HIRAGANA_LETTER_MO, C_HIRAGANA_LETTER_RO, 81, 43
EndCityList
