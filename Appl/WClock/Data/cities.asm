;
; This file contains the data for a World Clock data file.  
; This version is for a World Clock, English version.
;
; To create world.wcm from this file, run 
; /staff/pcgeos/Tools/scripts/makewcm	- Paul 5/16/95
;
;
; $Id: cities.asm,v 1.1 97/04/04 16:21:42 newdeal Exp $
;




include geos.def
include graphics.def
include wcMacros.def



WORLD_MAP_WIDTH		equ	248
WORLD_MAP_HEIGHT	equ	141

TOP	equ	0
BOTTOM	equ	WORLD_MAP_HEIGHT	; one more than the real height
					; because the algorithm doesn't
					; get the last pixel

StartWCDataFile		1

UseMap	../Art/wcmap.bitmap


; The daylight zone is specified by where it starts at hour 0 in pixels
; referenced to the start of the bitmap.  It also needs the pixels
; spanned by the world.  Half of that is the pixel size of the daylight.
DefDaylight	<WORLD_MAP_WIDTH / 4>, <WORLD_MAP_WIDTH>

;.showm
; This is an unordered list of time zones



StartTimeZoneList

; Each time zone is passed it's hour, left most point, right most point, 
; and then the points comprising the time zone polygon.


StartTimeZone	1am1,	1, 0, 0, 11
DefTimeZonePoint	11, BOTTOM
DefTimeZonePoint	11, 108
DefTimeZonePoint	7, 106
DefTimeZonePoint	11, 101
DefTimeZonePoint	2, 99
DefTimeZonePoint	11, 97
DefTimeZonePoint	2, 63
DefTimeZonePoint	11, 63
DefTimeZonePoint	11, 63
DefTimeZonePoint	11, 45
DefTimeZonePoint	11, 44
DefTimeZonePoint	1, 42
DefTimeZonePoint	3, 23
DefTimeZonePoint	11, 17
DefTimeZonePoint	11, TOP
DefTimeZonePoint	0, TOP
DefTimeZonePoint	0, BOTTOM
EndTimeZone	1am1


StartTimeZone	2am1,	2, 0, 11, 20
DefTimeZonePoint	11, 17
DefTimeZonePoint	11, TOP
DefTimeZonePoint	20, TOP
DefTimeZonePoint	20, 13
EndTimeZone	2am1

StartTimeZone	2am2,	2, 0, 2, 23
DefTimeZonePoint	19, 44
DefTimeZonePoint	19, 102
DefTimeZonePoint	23, 103
DefTimeZonePoint	23, 106
DefTimeZonePoint	19, 108
DefTimeZonePoint	19, BOTTOM
DefTimeZonePoint	11, BOTTOM
DefTimeZonePoint	11, 108
DefTimeZonePoint	7, 106
DefTimeZonePoint	11, 101
DefTimeZonePoint	2, 99
DefTimeZonePoint	11, 97
DefTimeZonePoint	2, 63
DefTimeZonePoint	11, 63
DefTimeZonePoint	11, 63
DefTimeZonePoint	11, 44
EndTimeZone	2am2


StartTimeZone	3am,	3, 0, 1, 31
DefTimeZonePoint	26, BOTTOM
DefTimeZonePoint	26, 44
DefTimeZonePoint	21, 32
DefTimeZonePoint	21, 20
DefTimeZonePoint	31, 11
DefTimeZonePoint	31, TOP
DefTimeZonePoint	20, TOP
DefTimeZonePoint	20, 13
DefTimeZonePoint	11, 17
DefTimeZonePoint	3, 23
DefTimeZonePoint	1, 42
DefTimeZonePoint	11, 44
DefTimeZonePoint	19, 44
DefTimeZonePoint	19, 102
DefTimeZonePoint	23, 103
DefTimeZonePoint	23, 106
DefTimeZonePoint	19, 108
DefTimeZonePoint	19, BOTTOM
EndTimeZone	3am


StartTimeZone	4am,	4, 0, 21, 42
DefTimeZonePoint	42, TOP
DefTimeZonePoint	42, 9
DefTimeZonePoint	27, 23
DefTimeZonePoint	35, 47
DefTimeZonePoint	34, 69
DefTimeZonePoint	34, BOTTOM
DefTimeZonePoint	26, BOTTOM
DefTimeZonePoint	26, 44
DefTimeZonePoint	21, 32
DefTimeZonePoint	21, 20
DefTimeZonePoint	31, 11
DefTimeZonePoint	31, TOP
EndTimeZone	4am


StartTimeZone	5am,	5, 0, 27, 51
DefTimeZonePoint	42, TOP
DefTimeZonePoint	42, 9
DefTimeZonePoint	27, 23
DefTimeZonePoint	35, 47
DefTimeZonePoint	34, 69
DefTimeZonePoint	34, BOTTOM
DefTimeZonePoint	46, BOTTOM
DefTimeZonePoint	46, 117
DefTimeZonePoint	36, 115
DefTimeZonePoint	46, 113
DefTimeZonePoint	46, 76
DefTimeZonePoint	41, 75
DefTimeZonePoint	37, 62
DefTimeZonePoint	41, 59
DefTimeZonePoint	43, 47
DefTimeZonePoint	39, 44
DefTimeZonePoint	44, 33
DefTimeZonePoint	47, 8
DefTimeZonePoint	51, 7
DefTimeZonePoint	51, TOP
EndTimeZone	5am


StartTimeZone	6am,	6, 0, 36, 62
DefTimeZonePoint	51, TOP
DefTimeZonePoint	51, 7
DefTimeZonePoint	47, 8
DefTimeZonePoint	44, 33
DefTimeZonePoint	39, 44
DefTimeZonePoint	43, 47
DefTimeZonePoint	41, 59
DefTimeZonePoint	37, 62
DefTimeZonePoint	41, 75
DefTimeZonePoint	46, 76
DefTimeZonePoint	46, 113
DefTimeZonePoint	36, 115
DefTimeZonePoint	46, 117
DefTimeZonePoint	46, BOTTOM
DefTimeZonePoint	55, BOTTOM
DefTimeZonePoint	55, 63
DefTimeZonePoint	53, 49
DefTimeZonePoint	55, 36
DefTimeZonePoint	58, 38
DefTimeZonePoint	58, 6
DefTimeZonePoint	62, 2
DefTimeZonePoint	62, TOP
EndTimeZone	6am


StartTimeZone	7am,	7, 0, 53, 79
DefTimeZonePoint	62, TOP
DefTimeZonePoint	62, 2
DefTimeZonePoint	58, 6
DefTimeZonePoint	58, 38
DefTimeZonePoint	55, 36
DefTimeZonePoint	53, 49
DefTimeZonePoint	55, 63
DefTimeZonePoint	55, 114
DefTimeZonePoint	55, 120
DefTimeZonePoint	55, BOTTOM
DefTimeZonePoint	68, BOTTOM
DefTimeZonePoint	63, 138
DefTimeZonePoint	55, 120
DefTimeZonePoint	55, 114
DefTimeZonePoint	65, 110
DefTimeZonePoint	65, 97
DefTimeZonePoint	67, 96
DefTimeZonePoint	63, 94
DefTimeZonePoint	66, 86
DefTimeZonePoint	66, 83
DefTimeZonePoint	63, 81
DefTimeZonePoint	63, 71
DefTimeZonePoint	71, 70
DefTimeZonePoint	72, 14
DefTimeZonePoint	70, 13
DefTimeZonePoint	70, 9
DefTimeZonePoint	73, 8
DefTimeZonePoint	79, 4
DefTimeZonePoint	73, TOP
EndTimeZone	7am


StartTimeZone	8am1,	8, 0, 73, 81
DefTimeZonePoint	79, 4
DefTimeZonePoint	73, TOP
DefTimeZonePoint	81, TOP
EndTimeZone	8am1

StartTimeZone	8am2,	8, 0, 55, 81
DefTimeZonePoint	68, BOTTOM
DefTimeZonePoint	63, 138
DefTimeZonePoint	55, 120
DefTimeZonePoint	55, 114
DefTimeZonePoint	65, 110
DefTimeZonePoint	65, 97
DefTimeZonePoint	67, 96
DefTimeZonePoint	63, 94
DefTimeZonePoint	66, 86
DefTimeZonePoint	66, 83
DefTimeZonePoint	63, 81
DefTimeZonePoint	63, 71
DefTimeZonePoint	71, 70
DefTimeZonePoint	72, 14
DefTimeZonePoint	70, 13
DefTimeZonePoint	70, 9
DefTimeZonePoint	73, 8
DefTimeZonePoint	76, 12
DefTimeZonePoint	81, 26
DefTimeZonePoint	81, 76
DefTimeZonePoint	75, 84
DefTimeZonePoint	75, 87
DefTimeZonePoint	78, 87
DefTimeZonePoint	77, 112
DefTimeZonePoint	68, 110
DefTimeZonePoint	66, 133
DefTimeZonePoint	69, 139
DefTimeZonePoint	81, 139
DefTimeZonePoint	81, BOTTOM
EndTimeZone	8am2


StartTimeZone	9am,	9, 0, 66, 111
DefTimeZonePoint	81, TOP
DefTimeZonePoint	79, 4
DefTimeZonePoint	73, 8
DefTimeZonePoint	76, 12
DefTimeZonePoint	81, 26
DefTimeZonePoint	81, 76
DefTimeZonePoint	75, 84
DefTimeZonePoint	75, 87
DefTimeZonePoint	78, 87
DefTimeZonePoint	77, 112
DefTimeZonePoint	68, 110
DefTimeZonePoint	66, 133
DefTimeZonePoint	69, 139
DefTimeZonePoint	81, 139
DefTimeZonePoint	81, BOTTOM
DefTimeZonePoint	92, BOTTOM
DefTimeZonePoint	92, 27
DefTimeZonePoint	100, 24
DefTimeZonePoint	104, 21
DefTimeZonePoint	111, 3
DefTimeZonePoint	101, TOP
EndTimeZone	9am


StartTimeZone	10am,	10, 0, 92, 100
DefTimeZonePoint	92, BOTTOM
DefTimeZonePoint	92, 27
DefTimeZonePoint	100, 24
DefTimeZonePoint	100, 24
DefTimeZonePoint	100, 30
DefTimeZonePoint	100, BOTTOM
EndTimeZone	10am


StartTimeZone	11am1,	11, 0, 100, 112
DefTimeZonePoint	101, TOP
DefTimeZonePoint	111, 3
DefTimeZonePoint	104, 21
DefTimeZonePoint	100, 24
DefTimeZonePoint	100, 24
DefTimeZonePoint	112, 23
DefTimeZonePoint	112, TOP
EndTimeZone	11am1

StartTimeZone	11am2,	11, 0, 100, 112
DefTimeZonePoint	100, 30
DefTimeZonePoint	100, BOTTOM
DefTimeZonePoint	112, BOTTOM
DefTimeZonePoint	112, 125
DefTimeZonePoint	107, 120
DefTimeZonePoint	112, 120
DefTimeZonePoint	112, 96
DefTimeZonePoint	106, 96
DefTimeZonePoint	106, 93
DefTimeZonePoint	112, 93
DefTimeZonePoint	112, 86
DefTimeZonePoint	104, 76
DefTimeZonePoint	104, 59
DefTimeZonePoint	110, 49
DefTimeZonePoint	112, 44
DefTimeZonePoint	108, 40
DefTimeZonePoint	112, 34
DefTimeZonePoint	112, 30
EndTimeZone	11am2


StartTimeZone	12am1,	12, 0, 100, 122
DefTimeZonePoint	112, TOP
DefTimeZonePoint	112, 23
DefTimeZonePoint	100, 24
DefTimeZonePoint	100, 30
DefTimeZonePoint	112, 30
DefTimeZonePoint	112, 34
DefTimeZonePoint	108, 40
DefTimeZonePoint	112, 44
DefTimeZonePoint	120, 40
DefTimeZonePoint	120, 29
DefTimeZonePoint	122, 26
DefTimeZonePoint	122, TOP
EndTimeZone	12am1

StartTimeZone	12am2,	12, 0, 104, 124
DefTimeZonePoint	110, 49
DefTimeZonePoint	104, 59
DefTimeZonePoint	104, 76
DefTimeZonePoint	112, 86
DefTimeZonePoint	112, 93
DefTimeZonePoint	106, 93
DefTimeZonePoint	106, 96
DefTimeZonePoint	112, 96
DefTimeZonePoint	112, 120
DefTimeZonePoint	107, 120
DefTimeZonePoint	112, 125
DefTimeZonePoint	112, BOTTOM
DefTimeZonePoint	124, BOTTOM
DefTimeZonePoint	124, 85
DefTimeZonePoint	119, 83
DefTimeZonePoint	119, 74
DefTimeZonePoint	112, 65
DefTimeZonePoint	116, 58
DefTimeZonePoint	112, 56
EndTimeZone	12am2


StartTimeZone	1pm,	13, 0, 110, 138
DefTimeZonePoint	122, TOP
DefTimeZonePoint	122, 26
DefTimeZonePoint	120, 29
DefTimeZonePoint	120, 40
DefTimeZonePoint	112, 44
DefTimeZonePoint	110, 49
DefTimeZonePoint	112, 56
DefTimeZonePoint	116, 58
DefTimeZonePoint	112, 65
DefTimeZonePoint	119, 74
DefTimeZonePoint	119, 83
DefTimeZonePoint	124, 85
DefTimeZonePoint	124, BOTTOM
DefTimeZonePoint	135, BOTTOM
DefTimeZonePoint	135, 119
DefTimeZonePoint	131, 119
DefTimeZonePoint	126, 102
DefTimeZonePoint	135, 102
DefTimeZonePoint	135, 70
DefTimeZonePoint	125, 67
DefTimeZonePoint	125, 59
DefTimeZonePoint	135, 59
DefTimeZonePoint	132, 54
DefTimeZonePoint	134, 41
DefTimeZonePoint	130, 35
DefTimeZonePoint	131, 21
DefTimeZonePoint	135, 21
DefTimeZonePoint	137, 19
DefTimeZonePoint	131, 16
DefTimeZonePoint	131, 13
DefTimeZonePoint	138, 11
DefTimeZonePoint	138, 4
DefTimeZonePoint	131, 3
DefTimeZonePoint	131, TOP
EndTimeZone	1pm


StartTimeZone	2pm1,	14, 0, 131, 143
DefTimeZonePoint	131, TOP
DefTimeZonePoint	131, 3
DefTimeZonePoint	138, 4
DefTimeZonePoint	138, 11
DefTimeZonePoint	131, 13
DefTimeZonePoint	131, 16
DefTimeZonePoint	137, 19
DefTimeZonePoint	143, 21
DefTimeZonePoint	143, TOP
EndTimeZone	2pm1


StartTimeZone	2pm2,	14, 0, 125, 150
DefTimeZonePoint	131, 21
DefTimeZonePoint	130, 37
DefTimeZonePoint	134, 41
DefTimeZonePoint	132, 54
DefTimeZonePoint	135, 59
DefTimeZonePoint	125, 59
DefTimeZonePoint	125, 67
DefTimeZonePoint	135, 70
DefTimeZonePoint	135, 102
DefTimeZonePoint	126, 102
DefTimeZonePoint	131, 119
DefTimeZonePoint	135, 119
DefTimeZonePoint	135, BOTTOM
DefTimeZonePoint	146, BOTTOM
DefTimeZonePoint	146, 103
DefTimeZonePoint	148, 101
DefTimeZonePoint	148, 96
DefTimeZonePoint	144, 97
DefTimeZonePoint	140, 92
DefTimeZonePoint	144, 64
DefTimeZonePoint	150, 55
DefTimeZonePoint	134, 34
DefTimeZonePoint	135, 21
EndTimeZone	2pm2


StartTimeZone	3pm1,	15, 0, 134, 167
DefTimeZonePoint	143, TOP
DefTimeZonePoint	143, 21
DefTimeZonePoint	137, 19
DefTimeZonePoint	135, 21
DefTimeZonePoint	134, 34
DefTimeZonePoint	150, 55
DefTimeZonePoint	153, 55
DefTimeZonePoint	152, 47
DefTimeZonePoint	147, 42
DefTimeZonePoint	151, 38
DefTimeZonePoint	155, 39
DefTimeZonePoint	156, 37
DefTimeZonePoint	151, 34
DefTimeZonePoint	151, 31
DefTimeZonePoint	156, 33
DefTimeZonePoint	159, 30
DefTimeZonePoint	167, 3
DefTimeZonePoint	156, 3
DefTimeZonePoint	156, TOP
EndTimeZone	3pm1

StartTimeZone	3pm2,	15, 0, 140, 156
DefTimeZonePoint	150, 55
DefTimeZonePoint	144, 64
DefTimeZonePoint	140, 92
DefTimeZonePoint	144, 97
DefTimeZonePoint	148, 96
DefTimeZonePoint	148, 101
DefTimeZonePoint	146, 103
DefTimeZonePoint	146, BOTTOM
DefTimeZonePoint	156, BOTTOM
DefTimeZonePoint	156, 96
DefTimeZonePoint	151, 97
DefTimeZonePoint	156, 93
DefTimeZonePoint	156, 64
EndTimeZone	3pm2


StartTimeZone	4pm1,	16, 0, 156, 167
DefTimeZonePoint	167, 3
DefTimeZonePoint	156, 3
DefTimeZonePoint	156, TOP
DefTimeZonePoint	167, TOP
EndTimeZone	4pm1

StartTimeZone	4pm2,	16, 0, 151, 156
DefTimeZonePoint	156, 37
DefTimeZonePoint	151, 34
DefTimeZonePoint	151, 31
DefTimeZonePoint	156, 33
EndTimeZone	4pm2

StartTimeZone	4pm3,	16, 0, 147, 155
DefTimeZonePoint	152, 47
DefTimeZonePoint	155, 39
DefTimeZonePoint	151, 38
DefTimeZonePoint	147, 42
EndTimeZone	4pm3


StartTimeZone	4pm4,	16, 0, 151, 167
DefTimeZonePoint	156, BOTTOM
DefTimeZonePoint	156, 96
DefTimeZonePoint	151, 97
DefTimeZonePoint	156, 93
DefTimeZonePoint	156, 64
DefTimeZonePoint	164, 66
DefTimeZonePoint	167, 67
DefTimeZonePoint	167, BOTTOM
EndTimeZone	4pm4


StartTimeZone	330pm,	15, 30, 150, 164
DefTimeZonePoint	150, 55
DefTimeZonePoint	156, 64
DefTimeZonePoint	164, 66
DefTimeZonePoint	163, 63
DefTimeZonePoint	163, 57
DefTimeZonePoint	153, 55
DefTimeZonePoint	157, 56

EndTimeZone	330pm


StartTimeZone	430pm,	16, 30, 163, 172
DefTimeZonePoint	163, 63
DefTimeZonePoint	163, 57
DefTimeZonePoint	172, 57
EndTimeZone	430pm


StartTimeZone	5pm1,	17, 0, 152, 178
DefTimeZonePoint	167, TOP
DefTimeZonePoint	167, 3
DefTimeZonePoint	159, 30
DefTimeZonePoint	156, 33
DefTimeZonePoint	156, 37
DefTimeZonePoint	155, 39
DefTimeZonePoint	152, 47
DefTimeZonePoint	157, 56, 
DefTimeZonePoint	153, 45
DefTimeZonePoint	163, 57
DefTimeZonePoint	169, 57
DefTimeZonePoint	166, 42
DefTimeZonePoint	174, 35
DefTimeZonePoint	178, 32
DefTimeZonePoint	178, 3
DefTimeZonePoint	178, TOP
EndTimeZone	5pm1


StartTimeZone	5pm2,	17, 0, 163, 172
DefTimeZonePoint	167, 67
DefTimeZonePoint	172, 57
DefTimeZonePoint	163, 63
DefTimeZonePoint	164, 66
EndTimeZone	5pm2


StartTimeZone	5pm3,	17, 0, 167, 178
DefTimeZonePoint	167, 66
DefTimeZonePoint	167, BOTTOM
DefTimeZonePoint	178, BOTTOM
DefTimeZonePoint	178, 83
DefTimeZonePoint	174, 82
EndTimeZone	5pm3


StartTimeZone	530pm1,	17, 30, 167, 183
DefTimeZonePoint	167, 67
DefTimeZonePoint	174, 82
DefTimeZonePoint	178, 83
DefTimeZonePoint	180, 71
DefTimeZonePoint	183, 67
DefTimeZonePoint	183, 63
DefTimeZonePoint	172, 57
EndTimeZone	530pm1


StartTimeZone	530pm2,	17, 30, 183, 188
DefTimeZonePoint	183, 67
DefTimeZonePoint	183, 63
DefTimeZonePoint	188, 62
EndTimeZone	530pm2


StartTimeZone	630pm,	18, 30, 183, 188
DefTimeZonePoint	183, 67
DefTimeZonePoint	188, 62
DefTimeZonePoint	189, 76
DefTimeZonePoint	186, 75
EndTimeZone	630pm


StartTimeZone	6pm1,	18, 0, 178, 188
DefTimeZonePoint	178, TOP
DefTimeZonePoint	178, 3
DefTimeZonePoint	188, 3
DefTimeZonePoint	188, TOP
EndTimeZone	6pm1

StartTimeZone	6pm2,	18, 0, 166, 183
DefTimeZonePoint	169, 57
DefTimeZonePoint	166, 42
DefTimeZonePoint	174, 35
DefTimeZonePoint	183, 45
DefTimeZonePoint	172, 57
EndTimeZone	6pm2

StartTimeZone	6pm3,	18, 0, 178, 189
DefTimeZonePoint	178, BOTTOM
DefTimeZonePoint	178, 83
DefTimeZonePoint	180, 71
DefTimeZonePoint	183, 67
DefTimeZonePoint	186, 75
DefTimeZonePoint	189, 76
DefTimeZonePoint	188, BOTTOM
EndTimeZone	6pm3


StartTimeZone	7pm1,	19, 0, 174, 198
DefTimeZonePoint	188, TOP
DefTimeZonePoint	188, 3
DefTimeZonePoint	178, 3
DefTimeZonePoint	178, 32
DefTimeZonePoint	174, 35
DefTimeZonePoint	183, 45
DefTimeZonePoint	188, 52
DefTimeZonePoint	188, 35
DefTimeZonePoint	194, 34
;DefTimeZonePoint	197, 27
DefTimeZonePoint	198, 13
DefTimeZonePoint	198, TOP
EndTimeZone	7pm1

StartTimeZone	7pm2,	19, 0, 188, 206
DefTimeZonePoint	188, BOTTOM
DefTimeZonePoint	189, 76
DefTimeZonePoint	195, 70
DefTimeZonePoint	199, 79
DefTimeZonePoint	192, 84
DefTimeZonePoint	195, 87
DefTimeZonePoint	198, 84
DefTimeZonePoint	199, 90
DefTimeZonePoint	206, 93
DefTimeZonePoint	200, 98
DefTimeZonePoint	200, BOTTOM
EndTimeZone	7pm2


StartTimeZone	8pm1,	20, 0, 198, 207
DefTimeZonePoint	198, TOP
DefTimeZonePoint	198, 13
DefTimeZonePoint	207, 13
DefTimeZonePoint	207, TOP
EndTimeZone	8pm1

StartTimeZone	8pm2,	20, 0, 172, 212
DefTimeZonePoint	197, 27
DefTimeZonePoint	194, 34
DefTimeZonePoint	188, 35
DefTimeZonePoint	188, 52
DefTimeZonePoint	183, 45
DefTimeZonePoint	172, 57
DefTimeZonePoint	173, 58
DefTimeZonePoint	183, 63
DefTimeZonePoint	188, 62
DefTimeZonePoint	189, 76
DefTimeZonePoint	195, 70
DefTimeZonePoint	199, 79
DefTimeZonePoint	192, 84
DefTimeZonePoint	195, 87
DefTimeZonePoint	198, 84
DefTimeZonePoint	199, 90
DefTimeZonePoint	206, 93
DefTimeZonePoint	200, 98
DefTimeZonePoint	200, BOTTOM
DefTimeZonePoint	212, BOTTOM
DefTimeZonePoint	212, 116
DefTimeZonePoint	212, 98
DefTimeZonePoint	210, 89
DefTimeZonePoint	212, 83
DefTimeZonePoint	206, 52
DefTimeZonePoint	210, 50
DefTimeZonePoint	206, 41
DefTimeZonePoint	203, 47
DefTimeZonePoint	200, 48
DefTimeZonePoint	201, 44
DefTimeZonePoint	198, 44
DefTimeZonePoint	203, 33
DefTimeZonePoint	199, 34
EndTimeZone	8pm2


StartTimeZone	9pm1,	21, 0, 197, 216
DefTimeZonePoint	207, TOP
DefTimeZonePoint	207, 13
DefTimeZonePoint	198, 13
DefTimeZonePoint	197, 27
DefTimeZonePoint	199, 34
DefTimeZonePoint	203, 33
DefTimeZonePoint	198, 44
DefTimeZonePoint	201, 44
DefTimeZonePoint	200, 48
DefTimeZonePoint	203, 47
DefTimeZonePoint	206, 41
DefTimeZonePoint	210, 50
DefTimeZonePoint	207, 25
DefTimeZonePoint	204, 22
DefTimeZonePoint	204, 20
DefTimeZonePoint	207, 19
DefTimeZonePoint	212, 14
DefTimeZonePoint	216, 10
DefTimeZonePoint	216, TOP
EndTimeZone	9pm1

StartTimeZone	9pm2,	21, 0, 206, 223
DefTimeZonePoint	210, 50
DefTimeZonePoint	206, 52
DefTimeZonePoint	212, 83
DefTimeZonePoint	210, 89
DefTimeZonePoint	212, 98
DefTimeZonePoint	219, 96
DefTimeZonePoint	222, 95
DefTimeZonePoint	222, 89
DefTimeZonePoint	218, 78
DefTimeZonePoint	218, 66
DefTimeZonePoint	223, 61
DefTimeZonePoint	223, 49
DefTimeZonePoint	216, 45
EndTimeZone	9pm2

StartTimeZone	9pm3,	21, 0, 212, 220
DefTimeZonePoint	212, 116
DefTimeZonePoint	212, BOTTOM
DefTimeZonePoint	220, BOTTOM
DefTimeZonePoint	220, 122
EndTimeZone	9pm3


StartTimeZone	930pm,	21, 30, 212, 220
DefTimeZonePoint	212, 98
DefTimeZonePoint	212, 116
DefTimeZonePoint	220, 122
DefTimeZonePoint	219, 111
DefTimeZonePoint	219, 96
EndTimeZone	930pm


StartTimeZone	10pm1,	22, 0, 204, 225
DefTimeZonePoint	216, TOP
DefTimeZonePoint	216, 10
DefTimeZonePoint	212, 14
DefTimeZonePoint	207, 19
DefTimeZonePoint	204, 20
DefTimeZonePoint	204, 22
DefTimeZonePoint	207, 25
DefTimeZonePoint	210, 50
DefTimeZonePoint	216, 45
DefTimeZonePoint	217, 19
DefTimeZonePoint	221, 9
DefTimeZonePoint	225, 7
DefTimeZonePoint	225, TOP
EndTimeZone	10pm1

StartTimeZone	10pm2,	22, 0, 218, 231
DefTimeZonePoint	223, 49
DefTimeZonePoint	223, 61
DefTimeZonePoint	218, 66
DefTimeZonePoint	218, 78
DefTimeZonePoint	222, 89
DefTimeZonePoint	222, 95
DefTimeZonePoint	219, 96
DefTimeZonePoint	219, 111
DefTimeZonePoint	220, 122
DefTimeZonePoint	220, BOTTOM
DefTimeZonePoint	231, BOTTOM
DefTimeZonePoint	231, 49
EndTimeZone	10pm2


StartTimeZone	11pm,	23, 0, 216, 241
DefTimeZonePoint	234, TOP
DefTimeZonePoint	234, 12
DefTimeZonePoint	225, 18
DefTimeZonePoint	225, 30
DefTimeZonePoint	223, 36
DefTimeZonePoint	226, 40
DefTimeZonePoint	241, 48
DefTimeZonePoint	233, 75
DefTimeZonePoint	233, 83
DefTimeZonePoint	241, 95
DefTimeZonePoint	241, 122
DefTimeZonePoint	233, 124
DefTimeZonePoint	233, 133
DefTimeZonePoint	241, 134
DefTimeZonePoint	241, BOTTOM
DefTimeZonePoint	231, BOTTOM
DefTimeZonePoint	231, 49
DefTimeZonePoint	223, 49
DefTimeZonePoint	216, 45
DefTimeZonePoint	217, 19
DefTimeZonePoint	221, 9
DefTimeZonePoint	225, 7
DefTimeZonePoint	225, TOP
EndTimeZone	11pm


StartTimeZone	12pm,	24, 0, 223, 248
DefTimeZonePoint	234, TOP
DefTimeZonePoint	234, 12
DefTimeZonePoint	225, 18
DefTimeZonePoint	225, 30
DefTimeZonePoint	223, 36
DefTimeZonePoint	226, 40
DefTimeZonePoint	241, 48
DefTimeZonePoint	233, 75
DefTimeZonePoint	233, 83
DefTimeZonePoint	241, 95
DefTimeZonePoint	241, 122
DefTimeZonePoint	233, 124
DefTimeZonePoint	233, 133
DefTimeZonePoint	241, 134
DefTimeZonePoint	241, BOTTOM
DefTimeZonePoint	248, BOTTOM
DefTimeZonePoint	248, 40
DefTimeZonePoint	236, 40
DefTimeZonePoint	236, 38
DefTimeZonePoint	234, 29
DefTimeZonePoint	230, 24
DefTimeZonePoint	243, 12
DefTimeZonePoint	243, TOP
EndTimeZone	12pm


StartTimeZone	1am2,	25, 0, 230, 248
DefTimeZonePoint	236, 38
DefTimeZonePoint	234, 29
DefTimeZonePoint	230, 24
DefTimeZonePoint	243, 12
DefTimeZonePoint	243, TOP
DefTimeZonePoint	248, TOP
DefTimeZonePoint	248, 38
EndTimeZone	1am2


StartTimeZone	2am3,	2, 0, 234, 248
DefTimeZonePoint	248, 40
DefTimeZonePoint	236, 40
DefTimeZonePoint	234, 38
DefTimeZonePoint	248, 38
EndTimeZone	2am3


EndTimeZoneList

;.noshowm

; This is an unordered list of cities

; default home city: Washington D.C.
; default dest city: San Francisco
; Format: StartCityList	default home city, default dest city, default time zone
StartCityList	209, 179, 4			; cities are zero based!

	DefCity "Abidjan", "C\x93te D'Ivoire", 113, 85
	DefCity "Abu Dhabi", "United Arab Emirates", 157, 68
	DefCity "Acapulco", "Mexico", 42, 74
	DefCity "Accra", "Ghana", 117, 85
	DefCity "Addis Ababa", "Ethiopia", 146, 82
	DefCity "Adelaide", "Australia", 219, 119 
	DefCity	"Aden", "Yemen", 151, 75 
	DefCity "Al Manamah", "Bahrain", 155, 65 
	DefCity "Algiers", "Algeria", 120, 57
	DefCity "Alice Springs", "Australia", 216, 109 
	DefCity "Amman", "Jordan", 144, 59
	DefCity "Amsterdam", "Netherlands", 125, 39 
	DefCity "Anchorage", "U.S.A.", 16, 32 
	DefCity "Andorra la Vella", "Andorra", 118, 51
	DefCity "Ankara", "Turkey", 140, 53
	DefCity "Antananarivo", "Madagascar", 153, 105
	DefCity "Asunci\xa2n", "Paraguay", 76, 110 
	DefCity "Athens", "Greece", 134, 55
	DefCity "Atlanta", "U.S.A.", 55, 59
	DefCity "Auckland", "New Zealand", 244, 120
	DefCity "Azores", "Portugal", 103, 54 
	DefCity "Baghdad", "Iraq", 150, 59
	DefCity "Baltimore", "U.S.A.", 62, 55 
	DefCity "Bangkok", "Thailand", 192, 77
	DefCity "Barcelona", "Spain", 119, 52
	DefCity "Basel", "Switzerland", 123, 47 
	DefCity "Beirut", "Lebanon", 143, 58
	DefCity "Belgrade", "Yugoslavia", 132, 50
	DefCity "Bergen", "Norway", 124, 33
	DefCity "Berlin",  "Germany", 122, 43
	DefCity "Birmingham", "U.S.A.", 53, 60
	DefCity "Bismarck", "U.S.A.", 44, 48
	DefCity "Bogota", "Colombia", 62, 85
	DefCity "Boise", "U.S.A.", 35, 50
	DefCity "Bombay", "India", 171, 72
	DefCity "Bonn", "Germany", 122, 44
	DefCity "Boston", "U.S.A.", 66, 51
	DefCity "Brasilia", "Brazil", 80, 102 
	DefCity "Brazzaville", "Congo", 130, 92 
	DefCity "Brisbane", "Australia", 229, 110
	DefCity "Broken Hill", "Australia", 219, 116 
	DefCity "Brussels", "Belgium", 120, 43 
	DefCity "Bucharest", "Romania", 134, 48
	DefCity "Budapest", "Hungary", 131, 45
	DefCity "Buenos Aires", "Argentina", 76, 120
	DefCity "Cairo", "Egypt", 141, 62
	DefCity "Calcutta", "India", 181, 69
	DefCity "Canberra", "Australia", 223, 119
	DefCity "Cape Town", "South Africa", 132, 118
	DefCity "Caracas", "Venezuela", 66, 80
	DefCity "Casablanca", "Morocco", 111, 60
	DefCity "Cayenne", "French Guiana", 77, 85
;	DefCity "Chatham Island", "New Zealand", 245, 126   
	DefCity "Cheyenne",  "U.S.A.", 40, 53
	DefCity "Chicago", "U.S.A.", 53, 53
	DefCity "Cincinnati", "U.S.A.", 56, 54 
	DefCity "Cleveland", "U.S.A.", 56, 55
	DefCity "Colombo", "Sri Lanka", 177, 82 
	DefCity "Conakry", "Guinea", 106, 78
	DefCity "Copenhagen", "Denmark", 126, 36
	DefCity "Dakar", "Senegal", 105, 70
	DefCity "Dallas", "U.S.A.", 46, 60
	DefCity "Damascus", "Syria", 144, 59 
	DefCity "Dar es Salaam", "Tanzania", 147, 93
	DefCity "Darwin", "Australia", 215, 98
	DefCity "Delhi", "India", 175, 63
	DefCity "Denver", "U.S.A.", 39, 55
	DefCity "Detroit", "U.S.A.", 55, 52 
	DefCity "Dhaka", "Bangladesh", 182, 68
	DefCity "Dubai", "United Arab Emirates", 158, 67
	DefCity "Dublin", "Ireland", 112, 38
	DefCity "Dusseldorf", "Germany", 122, 43 
	DefCity "Edmonton", "Canada", 37, 38
	DefCity "Fernando de Noronha", "Brazil", 93, 92
	DefCity "Fort Worth", "U.S.A.", 45, 61
	DefCity "Frankfurt", "Germany", 124, 42  
	DefCity "Freetown", "Sierra Leone", 106, 78
	DefCity "Geneva", "Switzerland", 121, 46 
	DefCity "Georgetown", "Guyana", 74, 83
	DefCity "Guam", "Guam", 219, 74  
	DefCity "Guatemala", "Guatemala", 50, 77 
	DefCity "Hamburg", "Germany", 124, 40
	DefCity "Hannover", "Germany", 123, 42 
;	DefCity "Hanoi", "Viet Nam", 195, 71 	does seem to work!
	DefCity "Hanoi", "Viet Nam", 194, 71 
	DefCity "Havana", "Cuba", 57, 70 
	DefCity "Helena", "U.S.A.", 38, 47
	DefCity "Helsinki", "Finland", 133, 32
	DefCity "Hermosillo", "Mexico", 38, 66 
	DefCity "Hong Kong", "Hong Kong", 202, 68
	DefCity "Honolulu", "U.S.A.", 9, 73 
	DefCity "Houston", "U.S.A.", 47, 64
	DefCity "Indianapolis" "U.S.A.", 54, 55
	DefCity "Istanbul", "Turkey", 138, 51
	DefCity "Jacksonville", "U.S.A.", 58, 63 
	DefCity "Jakarta", "Indonesia", 199, 93
	DefCity "Jerusalem", "Israel", 143, 60
	DefCity "Jeddah", "Saudi Arabia", 148, 70                   
	DefCity "Johannesburg", "South Africa", 138, 112 
	DefCity "Kabul", "Afghanistan", 168, 59
	DefCity "Kampala", "Uganda", 142, 88
	DefCity "Kansas City", "U.S.A.", 50, 55
	DefCity "Karachi", "Pakistan", 167, 67
;	DefCity "Kathmandu", "Nepal", 179, 63  
	DefCity "Khabarovsk", "Russia", 211, 45
	DefCity "Khartoum", "Sudan", 139, 74
	DefCity "Kingston", "Jamaica", 60, 74
	DefCity "Kinshasa", "Zaire", 129, 91
	DefCity "Kuala Lumpur", "Malaysia", 194, 84 
	DefCity "Kuwait", "Kuwait", 153, 62
	DefCity "La Paz", "Bolivia", 67, 102
	DefCity "Lagos", "Nigeria", 121, 83 
	DefCity "Las Palmas", "Canary Islands", 105, 65
	DefCity "Lilongwe", "Malawi", 142, 101
	DefCity "Lima", "Peru", 59, 98
	DefCity "Lisbon", "Portugal", 111, 54
	DefCity "Lome", "Togo", 117, 83
	DefCity "London", "United Kingdom", 116, 41
	DefCity "Los Angeles", "U.S.A.", 31, 60
	DefCity "Luanda", "Angola", 127, 95
	DefCity "Lusaka", "Zambia", 140, 102 
	DefCity "Luxembourg", "Luxembourg", 121, 46
	DefCity "Madrid", "Spain", 114, 52
	DefCity "Managua", "Nicaragua", 51, 79
	DefCity "Manaus", "Brazil", 72, 91 
	DefCity "Manila", "Philippines", 206, 75
	DefCity "Maputo", "Mozambique", 142, 111 
	DefCity "Marseille", "France", 121, 50 
	DefCity "Melbourne", "Australia", 222, 121
	DefCity "Memphis", "U.S.A.", 53, 58 
	DefCity "Mexico City", "Mexico", 44, 72
	DefCity "Miami", "U.S.A.", 58, 67
	DefCity "Midway", "Midway Islands", 1, 70
	DefCity "Milan", "Italy", 123, 48
	DefCity "Milwaukee", "U.S.A.", 52, 51 
	DefCity "Minneapolis", "U.S.A.", 49, 51 
	DefCity "Mogadishu", "Somalia", 151, 86 
	DefCity "Monrovia", "Liberia", 107, 79
	DefCity "Montevideo", "Uruguay", 74, 120 
	DefCity "Montreal", "Canada", 63, 50
	DefCity "Moscow", "Russia", 142, 37
	DefCity "Munich", "Germany", 125, 46
	DefCity "Muscat", "Oman", 160, 69
	DefCity "Nadi", "Fiji", 246, 101
	DefCity "Nairobi", "Kenya", 142, 89
	DefCity "Nashville", "U.S.A.", 54, 57 
	DefCity "Nassau", "Bahamas", 59, 67 
	DefCity "New Orleans", "U.S.A.", 51, 63
	DefCity "New York", "U.S.A.", 64, 53
	DefCity "Niamey", "Niger", 119, 76 
	DefCity "Norfolk", "U.S.A." 61, 57
;	DefCity "Norfolk Island", "Australia", 241, 112
	DefCity "Noumea", "New Caledonia", 240, 106
	DefCity "Oklahoma City", "U.S.A.", 46, 58
	DefCity "Omaha", "U.S.A.", 48, 53
	DefCity "Oslo", "Norway", 125, 31
	DefCity "Ottawa", "Canada", 62, 51 
	DefCity "Panama", "Panama", 57, 81 
	DefCity "Papeete", "Tahiti", 5, 99 
	DefCity "Paramaribo", "Suriname", 78, 85
	DefCity "Paris", "France", 119, 45
	DefCity "Peking (Beijing)", "China", 201, 52
	DefCity "Perth", "Australia", 200, 115
	DefCity "Philadelphia", "U.S.A.", 62, 55
	DefCity "Phnom Penh", "Cambodia", 195, 78
	DefCity "Phoenix", "U.S.A.", 36, 61
	DefCity "Pittsburgh", "U.S.A.", 55, 54 
;	DefCity "Port au Prince", "Haiti", 63, 73
	DefCity "Port au Prince", "Haiti", 62, 73
	DefCity "Port Louis", "Mauritius", 157, 105 
	DefCity "Port Moresby", "Papua New Guinea", 226, 94 
	DefCity "Port of Spain", "Trinidad", 75, 81
	DefCity "Portland", "U.S.A.", 30, 50
	DefCity "Prague", "Czech Republic", 128, 45
	DefCity "Quito", "Ecuador", 57, 89 
	DefCity "Reykjavik", "Iceland", 102, 27
	DefCity "Rio de Janeiro", "Brazil", 85, 109
	DefCity "Riyadh", "Saudi Arabia", 152, 68
	DefCity "Rome", "Italy", 126, 52
	DefCity "Saint Louis", "U.S.A.", 52, 56 
	DefCity "Salt Lake City", "U.S.A.", 35, 53
	DefCity "Salzburg", "Austria", 126, 47   
	DefCity "San Antonio", "U.S.A.", 42, 64 
	DefCity "San Diego", "U.S.A.", 32, 62
	DefCity "San Francisco", "U.S.A.", 29, 55 
	DefCity "San Jose", "Costa Rica", 54, 82
	DefCity "San Juan", "Puerto Rico", 68, 74
	DefCity "San Salvador", "El Salvador", 50, 76
	DefCity "Sanaa", "Yemen", 150, 73 
	DefCity "Santa Fe", "U.S.A.", 38, 58 
	DefCity "Santiago", "Chile", 66, 118
	DefCity "Santo Domingo", "Dominican Republic", 65, 74
	DefCity "Sao Paulo", "Brazil", 82, 109
	DefCity "Seattle", "U.S.A.", 30, 52
	DefCity "Seoul", "South Korea", 208, 55
	DefCity "Shanghai", "China", 205, 59
	DefCity "Singapore", "Singapore", 195, 86
	DefCity "Sofia", "Bulgaria", 135, 51
;	DefCity "St. Petersburg", "Russia", 135, 32
	DefCity "St. Petersburg", "Russia", 137, 31
	DefCity "Stockholm", "Sweden", 129, 33
	DefCity "Sydney", "Australia", 227, 117
	DefCity "Taipei", "Taiwan", 206, 67
	DefCity "Tampa", "U.S.A.", 56, 65
	DefCity "Tegucigalpa", "Honduras", 51, 77
	DefCity "Tehran", "Iran", 155, 57
	DefCity "Tijuana", "Mexico", 32, 63 
	DefCity "Tokyo", "Japan", 217, 57
	DefCity "Toronto", "Canada", 61, 50
	DefCity "Tripoli", "Libya", 127, 60
	DefCity "Tunis", "Tunisia", 125, 57 
	DefCity "Vancouver", "Canada", 30, 48
	DefCity "Vienna", "Austria", 129, 45
	DefCity "Vientiane", "Laos", 193, 73 
	DefCity "Warsaw", "Poland", 131, 41
	DefCity "Washington, D.C.", "U.S.A.", 61, 54
	DefCity "Wellington", "New Zealand", 243, 124 
	DefCity "Winnipeg", "Canada", 50, 46
;	DefCity "Yangon", "Myanmar", 188, 74
	DefCity "Yangon", "Burma", 187, 71
	DefCity "Yaounde", "Cameroon", 128, 86
	DefCity "Zurich", "Switzerland", 125, 48 


; This coordinate results in no time.  The point doesn't seem to fall within
; a time zone! 3/2/93
;	DefCity "Denver", "U.S.A.", 40, 54

EndCityList

