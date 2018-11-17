COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		visHermanClock.asm

AUTHOR:		Adam de Boor, Feb  4, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 4/92		Initial revision


DESCRIPTION:
	Implementation of the VisHermanClock object
		

	$Id: visHermanClock.asm,v 1.1 97/04/04 14:50:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	clock.def
include Internal/grWinInt.def

idata	segment
	VisHermanClockClass
idata	ends

L_EYEBROW_LEFT		equ	1
L_EYEBROW_TOP		equ	0
L_EYEBROW_RIGHT		equ	25
L_EYEBROW_BOTTOM	equ	8

R_EYEBROW_LEFT		equ	40
R_EYEBROW_TOP		equ	0
R_EYEBROW_RIGHT		equ	65
R_EYEBROW_BOTTOM	equ	7

L_EYE_LEFT		equ	0
L_EYE_TOP		equ	6
L_EYE_RIGHT		equ	32
L_EYE_BOTTOM		equ	35

R_EYE_LEFT		equ	38
R_EYE_TOP		equ	7
R_EYE_RIGHT		equ	70
R_EYE_BOTTOM		equ	37

NOSE_LEFT		equ	25
NOSE_TOP		equ	27
NOSE_RIGHT		equ	42
NOSE_BOTTOM		equ	55

MUSTACHE_LEFT		equ	6
MUSTACHE_TOP		equ	51
MUSTACHE_RIGHT		equ	59
MUSTACHE_BOTTOM		equ	67

HermanCode	segment	resource


PUPIL_WIDTH		equ	5
pupilBitmap		Bitmap	<
	PUPIL_WIDTH,
	PUPIL_WIDTH,
	BMC_UNCOMPACTED,
	BMF_MONO shl offset BMT_FORMAT
>
	byte	01110000b
	byte	11111000b
	byte	11111000b
	byte	11111000b
	byte	01110000b

;
; These hands are drawn at 12 o'clock, because that works with the minimal
; amount of translation, scaling, etc.
; 
if (L_EYE_BOTTOM-L_EYE_TOP) lt (L_EYE_RIGHT-L_EYE_LEFT)
HOUR_HAND_LENGTH	equ	(L_EYE_BOTTOM-L_EYE_TOP)/4-PUPIL_WIDTH/2
else
HOUR_HAND_LENGTH	equ	(L_EYE_RIGHT-L_EYE_LEFT)/4-PUPIL_WIDTH/2
endif


if (R_EYE_BOTTOM-R_EYE_TOP) lt (R_EYE_RIGHT-R_EYE_LEFT)
MINUTE_HAND_LENGTH	equ	(R_EYE_BOTTOM-R_EYE_TOP)/2-PUPIL_WIDTH/2
else
MINUTE_HAND_LENGTH	equ	(R_EYE_RIGHT-R_EYE_LEFT)/2-PUPIL_WIDTH/2
endif

HandStruct	struct
    HS_edge	word		; outer edge for the hand, whatever form it
				;  takes
    HS_center	Point		; translation to get to the center of the
				;  eyeball
    HS_eyeball	VisHermanBodyPart; region for wiping the eyeball out
    HS_pupil	VisHermanBodyPart; part to draw for pupil
HandStruct	ends

hourHand	HandStruct <
	HOUR_HAND_LENGTH,
	<
		L_EYE_LEFT+(L_EYE_RIGHT-L_EYE_LEFT)/2,
		L_EYE_TOP+(L_EYE_BOTTOM-L_EYE_TOP)/2
	>,
	VHBP_LEFT_EYE,
	VHBP_HOUR_PUPIL
>

minuteHand	HandStruct <
	MINUTE_HAND_LENGTH,
	<
		R_EYE_LEFT+(R_EYE_RIGHT-R_EYE_LEFT)/2,
		R_EYE_TOP+(R_EYE_BOTTOM-R_EYE_TOP)/2
	>,
	VHBP_RIGHT_EYE,
	VHBP_MINUTE_PUPIL
>

; Regions for drawing the different parts of Herman.

lEyebrowReg	Rectangle	<
	L_EYEBROW_LEFT, L_EYEBROW_TOP, L_EYEBROW_RIGHT, L_EYEBROW_BOTTOM
>
		word	-1, EOREGREC		; nothing till onscreen
		word	0, 12,21, EOREGREC
		word	1, 10,23, EOREGREC
		word	2, 8,24, EOREGREC
		word	3, 6,25, EOREGREC
		word	4, 4,25, EOREGREC
		word	5, 3,9,22,25, EOREGREC
		word	6, 2,7, EOREGREC
		word	7,  1,3, EOREGREC
		word	8,  1,2, EOREGREC
		word	EOREGREC		; end of region

rEyebrowReg	Rectangle	<
	R_EYEBROW_LEFT, R_EYEBROW_TOP, R_EYEBROW_RIGHT, R_EYEBROW_BOTTOM
>
		word	-1, EOREGREC		; nothing till onscreen
		word	0, 52,59, EOREGREC
		word	1, 49,63, EOREGREC
		word	2, 46,65, EOREGREC
		word	3, 44,65, EOREGREC
		word	4, 43,65, EOREGREC
		word	5, 42,47,61,64, EOREGREC
		word	6, 41,45, EOREGREC
		word	7, 40,43, EOREGREC
		word	EOREGREC		; end of region

lEyeReg		Rectangle	<
	L_EYE_LEFT, L_EYE_TOP, L_EYE_RIGHT, L_EYE_BOTTOM
>
		word	5, EOREGREC		; nothing till onscreen
		word	6, 12,21, EOREGREC
		word	7, 8,24, EOREGREC
		word	8, 6,25, EOREGREC
		word	9, 4,26, EOREGREC
		word	10,3,27, EOREGREC
		word	11,2,28, EOREGREC
		word	12,2,29, EOREGREC
		word	13, 1,30, EOREGREC
		word	14, 1,31, EOREGREC
		word	15, 0,31, EOREGREC
		word	16, 0,31, EOREGREC
		word	18, 0,32, EOREGREC
		word	23, 0,32, EOREGREC
		word	26, 0,31, EOREGREC
		word	27, 1,31, EOREGREC
		word	28, 1,30, EOREGREC
		word	29,2,29, EOREGREC
		word	30,2,28, EOREGREC
		word	31,2,27, EOREGREC
		word	32,3,26, EOREGREC
		word	33,5,25, EOREGREC
		word	34,6,23, EOREGREC
		word	35,8,20, EOREGREC
		word	EOREGREC		; end of region

rEyeReg		Rectangle	<
	R_EYE_LEFT, R_EYE_TOP, R_EYE_RIGHT, R_EYE_BOTTOM
>
		word	6, EOREGREC		; nothing till onscreen
		word	7, 50,59, EOREGREC
		word	8, 47,62, EOREGREC
		word	9, 45,63, EOREGREC
		word	10,44,65, EOREGREC
		word	11,43,66, EOREGREC
		word	12,42,67, EOREGREC
		word	13,41,68, EOREGREC
		word	14,40,68, EOREGREC
		word	15,40,69, EOREGREC
		word	16,39,69, EOREGREC
		word	18,39,69, EOREGREC
		word	23,38,70, EOREGREC
		word	26,38,70, EOREGREC
		word	27,38,69, EOREGREC
		word	28,39,69, EOREGREC
		word	29,39,68, EOREGREC
		word	30,40,68, EOREGREC
		word	31,40,67, EOREGREC
		word	32,41,66, EOREGREC
		word	33,42,65, EOREGREC
		word	34,43,64, EOREGREC
		word	35,45,63, EOREGREC
		word	36,47,60, EOREGREC
		word	37,50,55, EOREGREC
		word	EOREGREC		; end of region

noseReg		Rectangle	<
	NOSE_LEFT, NOSE_TOP, NOSE_RIGHT, NOSE_BOTTOM
>
		word	26, EOREGREC		; nothing till onscreen
		word	27,31,37, EOREGREC
		word	28,31,38, EOREGREC
		word	29,30,38, EOREGREC
		word	31,29,39, EOREGREC
		word	34,28,39, EOREGREC
		word	38,27,40, EOREGREC
		word	42,26,41, EOREGREC
		word	44,25,41, EOREGREC
		word	51,25,42, EOREGREC
		word	52,26,41, EOREGREC
		word	53,27,41, EOREGREC
		word	54,29,40, EOREGREC
		word	55,32,36, EOREGREC
		word	EOREGREC		; end of region

nose1Reg	Rectangle	<
	26,52,41,55
>
		word	51, EOREGREC
		word	52,26,41, EOREGREC
		word	53,27,41, EOREGREC
		word	54,29,40, EOREGREC
		word	55,32,36, EOREGREC
		word	EOREGREC		; end of region

nose2Reg	Rectangle	<
	25,48,42,51
>
		word	47, EOREGREC
		word	51,25,42, EOREGREC
		word	EOREGREC

nose3Reg	Rectangle	<
	25,45,42,47
>
		word	44, EOREGREC
		word	47,25,42, EOREGREC
		word	EOREGREC

nose4Reg	Rectangle	<
	25,42,41,44
>
		word	41, EOREGREC
		word	42,26,41, EOREGREC
		word	44,25,41, EOREGREC
		word	EOREGREC

nose5Reg	Rectangle	<
	26,39,41,41
>
		word	38, EOREGREC
		word	41,26,41, EOREGREC
		word	EOREGREC

nose6Reg	Rectangle	<
	27,36,40,38
>
		word	35, EOREGREC
		word	38,27,40, EOREGREC
		word	EOREGREC

nose7Reg	Rectangle	<
	27,33,40,35
>
		word	32, EOREGREC
		word	35,27,40, EOREGREC
		word	EOREGREC

nose8Reg	Rectangle	<
	28,30,39,32
>
		word	29, EOREGREC
		word	31,29,39, EOREGREC
		word	32,28,39, EOREGREC
		word	EOREGREC

nose9Reg	Rectangle	<
	30,27,38,29
>
		word	26, EOREGREC
		word	27,31,37, EOREGREC
		word	28,31,38, EOREGREC
		word	29,30,38, EOREGREC
		word	EOREGREC

mustacheReg	Rectangle	<
	MUSTACHE_LEFT, MUSTACHE_TOP, MUSTACHE_RIGHT, MUSTACHE_BOTTOM
>
		word	50, EOREGREC		; nothing till onscreen
		word	51,
				16,21,
				45,46,
			 	EOREGREC
		word	52,
				14,17,
				46,49,
				EOREGREC
		word	53,
				12,15,
				20,22,
				47,51,
				EOREGREC
		word	54,
				10,14,
				18,20,
				24,24,
				44,45,
				49,52,
				EOREGREC
		word	55,
				9,13,
				17,19,
				22,24,
				44,47,
				50,53,
				EOREGREC
		word	56,
				9,12,
				16,18,
				21,23,
				26,27,
				42,42,
				45,48,
				52,54,
				EOREGREC
		word	57,
				8,11,
				15,17,
				20,22,
				26,27,
				30,30,
				34,34,
				38,39,
				42,43,
				46,49,
				53,55,
				EOREGREC
		word	58,
				7,10,
				14,17,
				19,21,
				26,27,
				30,31,
				34,34,
				38,40,
				43,44,
				47,50,
				54,56,
				EOREGREC
		word	59,
				7,9,
				13,16,
				19,21,
				25,27,
				30,31,
				34,35,
				38,40,
				43,45,
				48,51,
				54,57,
				EOREGREC
		word	60,
				6,8,
				13,15,
				18,20,
				25,27,
				29,31,
				34,35,
				38,40,
				43,45,
				48,51,
				55,58,
				EOREGREC
		word	61,
				6,8,
				12,15,
				18,20,
				25,26,
				29,31,
				34,35,
				38,40,
				44,46,
				49,52,
				55,58,
				EOREGREC
		word	62,
				6,8,
				12,14,
				17,20,
				24,26,
				29,31,
				34,35,
				38,40,
				44,46,
				49,52,
				56,59,
				EOREGREC
		word	63,
				6,7,
				12,14,
				17,20,
				24,26,
				29,31,
				33,35,
				38,40,
				44,47,
				50,53,
				56,59,
				EOREGREC
		word	64,
				6,7,
				12,14,
				17,20,
				24,26,
				29,31,
				33,35,
				38,40,
				44,47,
				50,53,
				57,58,
				EOREGREC
		word	65,
				12,14,
				17,20,
				24,26,
				29,31,
				33,35,
				38,41,
				44,47,
				50,53,
				EOREGREC
		word	66,
				17,20,
				24,26,
				29,30,
				33,35,
				38,41,
				45,46,
				EOREGREC
		word	67,
				18,19,
				24,25,
				34,35,
				EOREGREC
		word	EOREGREC		; end of region

mustache10Reg	Rectangle	<
	6,51,22,65
>
		word	50, EOREGREC
		word	51, 16,21, 		EOREGREC
		word	52, 14,17, 		EOREGREC
		word	53, 12,15, 20,22, 	EOREGREC
		word	54, 10,14, 18,20, 	EOREGREC
		word	55, 9,13,  17,19, 	EOREGREC
		word	56, 9,12,  16,18, 	EOREGREC
		word	57, 8,11,  15,17, 	EOREGREC
		word	58, 7,10,  14,17, 	EOREGREC
		word	59, 7,9,   13,16, 	EOREGREC
		word	60, 6,8,   13,15, 	EOREGREC
		word	61, 6,8,   12,15, 	EOREGREC
		word	62, 6,8,   12,14, 	EOREGREC
		word	64, 6,7,   12,14,	EOREGREC
		word	65,	   12,14,	EOREGREC
		word	EOREGREC
mustache20Reg	Rectangle	<
	18,54,27,67
>
		word	53,			EOREGREC
		word	54, 24,24,		EOREGREC
		word	55, 22,24,		EOREGREC
		word	56, 21,23, 26,27,	EOREGREC
		word	57, 20,22, 26,27,	EOREGREC
		word	58, 19,21, 26,27,	EOREGREC
		word	59, 19,21, 25,27,	EOREGREC
		word	60, 18,20, 25,27,	EOREGREC
		word	61, 18,20, 25,26,	EOREGREC
		word	66, 17,20, 24,26,	EOREGREC
		word	67, 18,19, 24,25,	EOREGREC
		word	EOREGREC

mustache30Reg	Rectangle	<
	29,57,35,67
>
		word	56, 			EOREGREC
		word	57, 30,30, 34,34,	EOREGREC
		word	58, 30,31, 34,34,	EOREGREC
		word	59, 30,31, 34,35,	EOREGREC
		word	62, 29,31, 34,35,	EOREGREC
		word	65, 29,31, 33,35,	EOREGREC
		word	66, 29,30, 33,35,	EOREGREC
		word	67,	   34,35,	EOREGREC
		word	EOREGREC

mustache40Reg	Rectangle	<
	38,56,47,66
>
		word	55,			EOREGREC
		word	56,	   42,42,	EOREGREC
		word	57, 38,39, 42,43,	EOREGREC
		word	58, 38,40, 43,44,	EOREGREC
		word	60, 38,40, 43,45,	EOREGREC
		word	62, 38,40, 44,46,	EOREGREC
		word	64, 38,40, 44,47,	EOREGREC
		word	65, 38,41, 44,47,	EOREGREC
		word	66, 38,41, 45,46,	EOREGREC
		word	EOREGREC

mustache50Reg	Rectangle	<
	44,51,59,65
>
		word	50,			EOREGREC
		word	51,	   45,46,	EOREGREC
		word	52,	   46,49,	EOREGREC
		word	53,	   47,51,	EOREGREC
		word	54, 44,45, 49,52,	EOREGREC
		word	55, 44,47, 50,53,	EOREGREC
		word	56, 45,48, 52,54,	EOREGREC
		word	57, 46,49, 53,55,	EOREGREC
		word	58, 47,50, 54,56,	EOREGREC
		word	59, 48,51, 54,57,	EOREGREC
		word	60, 48,51, 55,58,	EOREGREC
		word	61, 49,52, 55,58,	EOREGREC
		word	62, 49,52, 56,59,	EOREGREC
		word	63, 50,53, 56,59,	EOREGREC
		word	64, 50,53, 57,58,	EOREGREC
		word	65, 50,53,		EOREGREC
		word	EOREGREC

regions		nptr.Rectangle	lEyebrowReg,	; VHBP_LEFT_EYEBROW
				rEyebrowReg,	; VHBP_RIGHT_EYEBROW
				lEyeReg,	; VHBP_LEFT_EYE
				rEyeReg,	; VHBP_RIGHT_EYE
				noseReg,	; VHBP_NOSE
				mustacheReg	; VHBP_MUSTACHE


emptyRegion	Rectangle	<
	0,0,0,0
>
		word	EOREGREC


noseRegions	nptr.Rectangle 	nose1Reg,
				nose2Reg,
				nose3Reg,
				nose4Reg,
				nose5Reg,
				nose6Reg,
				nose7Reg,
				nose8Reg,
				nose9Reg

mustacheRegions	nptr.Rectangle 	mustache10Reg,
				mustache20Reg,
				mustache30Reg,
				mustache40Reg,
				mustache50Reg
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VHCDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the current time in Herman

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= object
		cl	= DrawFlags
		bp	= gstate
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VHCDraw		method dynamic VisHermanClockClass, MSG_VIS_DRAW
		.enter
		mov	di, bp

		call	TimerGetDateAndTime
		
	;
	; Convert minutes to degrees by multiplying by 6
	; 
		push	dx		; save seconds in case 1-second interval

		clr	dh
		mov	ax, dx		; save minutes for additional
					;  hour-hand rotation
		shl	dx		; *2
		mov	bx, dx
		shl	dx		; *4
		add	dx, bx		; dx <- dl*6
	;
	; Figure AM/PM
	; 
					; bl <- part to fill, bh <- part to
					;  clear
		mov	bx, VHBP_LEFT_EYEBROW or (VHBP_RIGHT_EYEBROW shl 8)
		cmp	ch, 12		; afternoon?
		jb	convertHours	; no, fill left eyebrow for AM
		xchg	bl, bh
		sub	ch, 12		; convert to 0-11
convertHours:
	;
	; Convert hours to degrees by multiplying by 30 = 16 + 8 + 4 + 2
	; 
		shr	ax		; divide minutes by 2 to get additional
					;  degrees of rotation (30 degrees in
					;  an hour...)
		mov	cl, ch
		clr	ch
		shl	cx		; *2
		add	ax, cx
		shl	cx		; *4
		add	ax, cx
		shl	cx		; *8
		add	ax, cx
		shl	cx		; *16
		add	cx, ax		; cx <- cl*30

	;
	; cx and dx are the degrees of rotation, clockwise from north, for the
	; hours and minutes hands, respectively. bl is the VisHermanBodyPart
	; to fill with its proper color, and bh is the VHBP to fill with black.
	; 
		mov	ax, VHC_USE_SET_COLOR
		push	bx
		call	VHCDrawReg	; draw filled eyebrow
		pop	bx

		mov	bl, bh		; draw blanked eyebrow
		mov	ax, C_BLACK
		call	VHCDrawReg

	;
	; Draw the minute hand.
	; 
		push	cx
		mov_trash	ax, dx		; ax <- degrees of rotation
		mov	bx, offset minuteHand
		call	VHCDrawHand
		
	;
	; Draw the hour hand
	; 
		mov	bx, offset hourHand
		pop	ax		; ax <- degress of rotation for hand
		call	VHCDrawHand
	;
	; Draw the nose and mustache.
	; 
		pop	dx
		mov	bx, ds:[si]
		add	bx, ds:[bx].VisHermanClock_offset
		cmp	ds:[bx].VCI_interval, 60	; 1-second interval?
		je	drawSeconds

		mov	ax, VHC_USE_SET_COLOR
		mov	bl, VHBP_NOSE
		call	VHCDrawReg
		
		mov	ax, VHC_USE_SET_COLOR
		mov	bl, VHBP_MUSTACHE
		call	VHCDrawReg
done:
		.leave
		ret
drawSeconds:
	;
	; Draw the nose and mustache clipped appropriately, according to the
	; tens or units portions of the seconds.
	; 
		mov	al, dh
		aam			; ah <- seconds/10
					; al <- seconds%10
		push	ax
		mov	ah, VHBP_NOSE
		mov	bx, offset noseRegions
		mov	dx, length noseRegions
		call	VHCDrawPartiteReg
		pop	ax

		mov	al, ah
		mov	ah, VHBP_MUSTACHE
		mov	bx, offset mustacheRegions
		mov	dx, length mustacheRegions
		call	VHCDrawPartiteReg
		jmp	done

VHCDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VHCDrawPartiteReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a region of Herman that is defined as a series of
		pieces, the first n of which are to be drawn in the body
		part's color, and the remaining m-n of which are to be drawn
		in black. You might recognize this as the code that draws
		the mustache and nose when displaying seconds.

CALLED BY:	VHCDraw
PASS:		al	= 0-9/0-5 to index the array
		ah	= VisHermanBodyPart being drawn
		cs:bx	= array of 10/6 pointers to regions. [0..al] get
			  drawn in part color, [al+1..dx] get drawn in
			  black.
		dx	= number of regions in the array
		*ds:si	= VisHermanClock object
		di	= gstate
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VHCDrawPartiteReg proc	near
		class	VisHermanClockClass
		uses	si, ds
		.enter
	;
	; We start drawing the filled in portions, so set the area color
	; to the color for the body part.
	; 
		mov	si, ds:[si]
		add	si, ds:[si].VisHermanClock_offset

		push	ax, bx
		mov	bl, ah
		clr	bh
			CheckHack <size ColorQuad eq 4>
		shl	bx
		shl	bx
		mov	ax, ({dword}ds:[si].VHCI_colors[bx]).low
		mov	bx, ({dword}ds:[si].VHCI_colors[bx]).high
		call	GrSetAreaColor
		pop	ax, bx

	;
	; Set up for first sequence of loops, where we draw in the body
	; part's color...
	; 
		mov	si, bx		; ds:si <- region table
		segmov	ds, cs
		mov_trash	cx, ax
		clr	ch		; cx <- parts to draw in body part color
		jcxz	firstPartDone
partLoop:
		lodsw			; ds:ax <- region to draw...
		push	si
		mov_trash	si, ax		; ds:si <- region to draw
		clr	ax		; draw region at (0,0)
		mov	bx, ax
		call	GrDrawRegion
		pop	si
		dec	dx		; reduce count of parts remaining
		loop	partLoop
		je	done		; => all parts drawn (dx decremented
					;  to 0, either because this is the
					;  second pass, or there are none to
					;  draw in black)
firstPartDone:
	;
	; Switch to C_BLACK for the second set of regions, unless all regions
	; already drawn, of course...
	; 
		mov	cx, dx		; cx <- parts to draw in black
		mov	ax, C_BLACK
		call	GrSetAreaColor
		jmp	partLoop
done:
		.leave
		ret
VHCDrawPartiteReg endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VHCDrawReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the region in the appropriate color, or whatever
		color is passed.

CALLED BY:	VHCDraw
PASS:		*ds:si	= VisHermanClock object
		bl	= VisHermanBodyPart to draw
		ax	= color in which to draw the region, or
			  VHC_USE_SET_COLOR
		di	= gstate to use
RETURN:		nothing
DESTROYED:	ax, bx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VHCDrawReg	proc	near
		uses	ds, si
		class	VisHermanClockClass
		.enter
		clr	bh		; zero-extend for array indexing...

	;
	; Fetch the defined color for this part, if told to.
	; 
		push	bx
		cmp	ax, VHC_USE_SET_COLOR
		jne	haveColor

		mov	si, ds:[si]
		add	si, ds:[si].VisHermanClock_offset
			CheckHack <size ColorQuad eq 4>
		shl	bx
		shl	bx
		mov	ax, ({dword}ds:[si].VHCI_colors[bx]).low
		mov	bx, ({dword}ds:[si].VHCI_colors[bx]).high
haveColor:
		call	GrSetAreaColor
		pop	bx
	;
	; Fetch the region for this body part and draw it at 0,0 (all regions
	; are defined to be window-relative). If beyond the defined regions,
	; draw nothing (just wanted to get the color)
	; 
		segmov	ds, cs
		assume	ds:@CurSeg
		
		shl	bx
		cmp	bx, size regions
		jae	done

		mov	si, ds:[regions][bx]	; ds:si <- region (bounding
						;  rectangle of same)
		
		clr	ax
		mov	bx, ax
		call	GrDrawRegion
		assume	ds:dgroup
done:		
		.leave
		ret
VHCDrawReg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VHCDrawHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the hand described by the passed HandStruct and rotation

CALLED BY:	VHCDraw
PASS:		cs:bx	= HandStruct describing the hand to draw
		*ds:si	= VisHermanClock object
		di	= gstate to use
		ax	= degrees of rotation (clockwise from noon)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VHCDrawHand	proc	near
		uses	si, ds
		class	VisHermanClockClass
		.enter
		push	ax
	;
	; Blank out the eyeball
	; 
		mov	ax, VHC_USE_SET_COLOR
		push	bx
		mov	bx, cs:[bx].HS_eyeball
		call	VHCDrawReg
	;
	; Set the proper pupil color (can't use VHCDrawReg to draw it b/c it's
	; a bitmap, and it can't be drawn at 0,0 w/o applying a translation
	; 
		pop	bx
		push	bx
		mov	ax, VHC_USE_SET_COLOR
		mov	bx, cs:[bx].HS_pupil
		call	VHCDrawReg
		segmov	ds, cs
		pop	si		; ds:si <- HandStruct
	;
	; Do all the transformations ourselves to avoid distortions in the
	; pupil, as come about whether we use a bitmap or an ellipse. We
	; figure the coordinate for the center of the pupil by the following
	; formulae:
	; 	X = Xcenter + cos(theta') * radius
	; 	Y = Ycenter - sin(theta') * radius
	; the subtraction for Y is caused by the Y axis being inverted from
	; normal geometry. theta' is derived from our input theta, the
	; degrees clockwise from 12, by
	; 	theta' = |((360 - theta) - 270) % 360|
	; as theta+90 shifts the origin of the rotation to 3, and you subtract
	; that from 360 to go the opposite direction. Of course, angles are
	; always 0-359, hence the absolute value of the modulus.
	; 
		pop	ax
		mov	dx, 360
		sub	dx, ax
		sub	dx, 270
		jge	haveAngle
		add	dx, 360
haveAngle:
		push	dx
	;
	; dx.ax <- sin(theta')
	; 
		clr	ax
		call	GrQuickSine
	;
	; dx.cx <- sin(theta') [dx.cx] * radius [bx.ax]
	; 
		mov_trash	cx, ax
		mov	bx, ds:[si].HS_edge
		clr	ax
		call	GrMulWWFixed
		neg	dx		; -sin(theta')

		pop	ax		; recover degrees
		push	dx		; save Y coord
	;
	; dx.ax <- cos(theta')
	; 
		mov_trash	dx, ax
		clr	cx
		call	GrQuickCosine
	;
	; dx.cx <- cos(theta') [dx.cx] * radius [bx.ax]
	; 
		mov_trash	cx, ax
		mov	bx, ds:[si].HS_edge
		clr	ax
		call	GrMulWWFixed

	;
	; Now offset to the center of eyeball, and adjust so bitmap is centered
	; on the final coordinate.
	; 
		mov	ax, dx
		pop	bx
		sub	bx, PUPIL_WIDTH/2
		sub	ax, PUPIL_WIDTH/2
		add	ax, ds:[si].HS_center.P_x
		add	bx, ds:[si].HS_center.P_y		
	;
	; Draw the darn thing.
	; 
		mov	si, offset pupilBitmap
		clr	dx
		call	GrFillBitmap

		.leave
		ret
VHCDrawHand	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VHCRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure how big we should be. Herman is always the same
		size, so this is simple.

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= object
RETURN:		cx	= desired width
		dx	= desired height
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VHCRecalcSize	method dynamic VisHermanClockClass, MSG_VIS_RECALC_SIZE
		.enter
		mov	cx, HERMAN_WIDTH
		mov	dx, HERMAN_HEIGHT
		.leave
		ret
VHCRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VHCSetInterval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note a change in the rate at which we're called

CALLED BY:	MSG_VC_SET_INTERVAL
PASS:		*ds:si	= VisHermanClock object
		ds:di	= VisHermanClockInstance
		cx	= new interval (in ticks)
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		let the superclass do its thing, but invalidate our image,
		as we need to get the nose-as-second-hand going or stopped
		right away.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VHCSetInterval	method dynamic VisHermanClockClass, MSG_VC_SET_INTERVAL
		.enter
		mov	di, offset VisHermanClockClass
		CallSuper	MSG_VC_SET_INTERVAL
		
		mov	cx, mask VOF_IMAGE_INVALID
		mov	dl, VUM_NOW
		call	VisClockMarkInvalid
		.leave
		ret
VHCSetInterval	endm


HermanCode	ends

