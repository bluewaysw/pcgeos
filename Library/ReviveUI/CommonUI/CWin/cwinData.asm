COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1996.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin
FILE:		cwinData.asm

AUTHOR:		Steve Yegge, May 20, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/20/96		took OpenLook stuff out

DESCRIPTION:

	Data for the WinCommon resource.
	
	$Id: cwinData.asm,v 2.11 96/08/15 03:47:18 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


WinCommon segment resource

;SEE cwinConstant.def for this structure definition:

;BitmapPlaneDefs	struct
;    BPD_width		word	;width and height for centering
;    BPD_height		word
;    BPD_light		word	;light bitmap used for color and black&white
;    BPD_bwDark		word	;dark bitmap used for black&white
;    BPD_colorDark	word	;dark bitmap used for color
;    BPD_colorWhite	word	;white bitmap used for color
;    BPD_colorBlack	word	;black bitmap used for color
;BitmapPlaneDefs	ends

;------------------------------------------------------------------------------
;			Close Mark
;------------------------------------------------------------------------------
;The CloseMark is the small square icon at the top-left of an OpenLook window.
;Click on it to close the window.

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------

CloseMarkBitmapPlaneDefs	label	BitmapPlaneDefs
	word	OLS_CLOSE_MARK_WIDTH		;width and height for centering
	word	OLS_CLOSE_MARK_HEIGHT
	word	offset CloseMarkLightBitmap
	word	offset CloseMarkBWDarkBitmap
	word	offset CloseMarkColorDarkBitmap
	word	offset CloseMarkColorWhiteBitmap
	word	0				;no black Color bitmap

CloseMarkLightBitmap	label	byte
	word	16				;width
	word	15				;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00111111b, 11111000b
	byte	01111111b, 11111100b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	11111111b, 11111110b
	byte	01111111b, 11111100b
	byte	00111111b, 11111000b
	byte	00000000b, 00000000b

CloseMarkBWDarkBitmap	label	byte
	word	16				;width
	word	15				;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00111111b, 11111000b
	byte	01000000b, 00000100b
	byte	10000000b, 00000010b
	byte	10000000b, 00000010b
	byte	10001111b, 11100010b
	byte	10001000b, 00100010b
	byte	10000100b, 01000010b
	byte	10000100b, 01000010b
	byte	10000010b, 10000010b
	byte	10000010b, 10000010b
	byte	10000001b, 00000010b
	byte	10000000b, 00000010b
	byte	01000000b, 00000100b
	byte	00111111b, 11111000b
	byte	00000000b, 00000000b

CloseMarkColorDarkBitmap	label	byte
	word	16				;width
	word	15				;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000010b
	byte	00000000b, 00000010b
	byte	00001111b, 11100010b
	byte	00001000b, 00000010b
	byte	00000100b, 00000010b
	byte	00000100b, 00000010b
	byte	00000010b, 00000010b
	byte	00000010b, 00000010b
	byte	00000000b, 00000010b
	byte	00000000b, 00000010b
	byte	01000000b, 00000100b
	byte	00111111b, 11111000b
	byte	00000000b, 00000000b

CloseMarkColorWhiteBitmap	label	byte
	word	16				;width
	word	15				;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00111111b, 11111000b
	byte	01000000b, 00000100b
	byte	10000000b, 00000000b
	byte	10000000b, 00000000b
	byte	10000000b, 00000000b
	byte	10000000b, 00100000b
	byte	10000000b, 01000000b
	byte	10000000b, 01000000b
	byte	10000000b, 10000000b
	byte	10000000b, 10000000b
	byte	10000001b, 00000000b
	byte	10000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

endif		;END of OPEN LOOK specific code -------------------------------


;------------------------------------------------------------------------------
;			Pushpin (unpinned)
;------------------------------------------------------------------------------
;These are the bitmap definitions for the OpenLook pushpin.

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------

PushpinBitmapPlaneDefs	label	BitmapPlaneDefs
	word	OLS_PUSHPIN_UNPINNED_WIDTH ;width and height for centering
	word	OLS_PUSHPIN_HEIGHT
	word	offset PushpinLightBitmap
	word	offset PushpinBWDarkBitmap
	word	offset PushpinColorDarkBitmap
	word	offset PushpinColorWhiteBitmap
	word	offset PushpinColorBlackBitmap

PushpinLightBitmap	label	word
	word	32			;bitmap width
	word	14			;bitmap height
	byte	BMC_UNCOMPACTED		;method of compaction
	byte	BMF_MONO		;bitmap type
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000111b, 00000000b, 00000000b
	byte	00000000b, 00000111b, 10000001b, 10000000b
	byte	00000000b, 00000111b, 10000011b, 11000000b
	byte	00000000b, 00000111b, 11111111b, 11000000b
	byte	00000000b, 00000111b, 11111111b, 11000000b
	byte	00001111b, 11111111b, 11111111b, 11000000b
	byte	00000111b, 11111111b, 11111111b, 11000000b
	byte	00000000b, 00000111b, 11111111b, 11000000b
	byte	01100000b, 00000111b, 11111111b, 11000000b
	byte	11110000b, 00000111b, 10000011b, 11000000b
	byte	11110000b, 00000111b, 10000001b, 10000000b
	byte	01100000b, 00000111b, 00000000b, 00000000b

PushpinBWDarkBitmap	label	word
	word	32			;bitmap width
	word	14			;bitmap height
	byte	BMC_UNCOMPACTED		;method of compaction
	byte	BMF_MONO		;bitmap type
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000111b, 00000000b, 00000000b
	byte	00000000b, 00000100b, 10000001b, 10000000b
	byte	00000000b, 00000100b, 10000010b, 01000000b
	byte	00000000b, 00000100b, 11111110b, 01000000b
	byte	00000000b, 00000100b, 10000010b, 01000000b
	byte	00001111b, 11111100b, 10000010b, 01000000b
	byte	00000111b, 11111100b, 10000010b, 01000000b
	byte	00000000b, 00000100b, 11111110b, 01000000b
	byte	01100000b, 00000100b, 11111111b, 11000000b
	byte	10010000b, 00000111b, 10000011b, 11000000b
	byte	10010000b, 00000111b, 10000001b, 10000000b
	byte	01100000b, 00000111b, 00000000b, 00000000b

PushpinColorDarkBitmap	label	word
	word	32			;bitmap width
	word	14			;bitmap height
	byte	BMC_UNCOMPACTED		;method of compaction
	byte	BMF_MONO		;bitmap type
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 10000000b, 00000000b
	byte	00000000b, 00000000b, 10000000b, 01000000b
	byte	00000000b, 00000000b, 10000000b, 01000000b
	byte	00000000b, 00000000b, 10000000b, 01000000b
	byte	00000000b, 00000000b, 10000000b, 01000000b
	byte	00000000b, 00000000b, 11111100b, 01000000b
	byte	01100000b, 00000000b, 00000000b, 11000000b
	byte	10000000b, 00000001b, 10000011b, 11000000b
	byte	10000000b, 00000111b, 10000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b

PushpinColorWhiteBitmap	label	word
	word	32			;bitmap width
	word	14			;bitmap height
	byte	BMC_UNCOMPACTED		;method of compaction
	byte	BMF_MONO		;bitmap type
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000111b, 00000000b, 00000000b
	byte	00000000b, 00000100b, 00000001b, 10000000b
	byte	00000000b, 00000100b, 00000010b, 00000000b
	byte	00000000b, 00000100b, 00111110b, 00000000b
	byte	00000000b, 00000100b, 00000010b, 00000000b
	byte	00001111b, 11111100b, 00000010b, 00000000b
	byte	00000000b, 00000100b, 00000010b, 00000000b
	byte	00000000b, 00000100b, 00000010b, 00000000b
	byte	00000000b, 00000100b, 00000000b, 00000000b
	byte	00010000b, 00000000b, 00000000b, 00000000b
	byte	00010000b, 00000000b, 00000000b, 00000000b
	byte	01100000b, 00000000b, 00000000b, 00000000b

PushpinColorBlackBitmap	label	word
	word	32			;bitmap width
	word	14			;bitmap height
	byte	BMC_UNCOMPACTED		;method of compaction
	byte	BMF_MONO		;bitmap type
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000111b, 11111000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 11111100b, 00000000b
	byte	00000000b, 00000000b, 00000000b, 00000000b
	byte	00000000b, 00000000b, 00000001b, 10000000b
	byte	00000000b, 00000111b, 00000000b, 00000000b

endif		;END of OPEN LOOK specific code -------------------------------


;------------------------------------------------------------------------------
;			Pushpin (pinned)
;------------------------------------------------------------------------------
;These are the bitmap definitions for the OpenLook pushpin.

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------

PinnedPushpinBitmapPlaneDefs	label	BitmapPlaneDefs
	word	OLS_PUSHPIN_PINNED_WIDTH	;width and height for centering
	word	OLS_PUSHPIN_HEIGHT
	word	offset PinnedPushpinLightBitmap
	word	offset PinnedPushpinBWDarkBitmap
	word	offset PinnedPushpinColorDarkBitmap
	word	offset PinnedPushpinColorWhiteBitmap
	word	offset PinnedPushpinColorBlackBitmap

PinnedPushpinLightBitmap	label	word
	word	16				;bitmap width
	word	14				;bitmap height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type

	byte	00000000b, 11100000b
	byte	00000111b, 11111000b
	byte	00011111b, 11111000b
	byte	00111111b, 11111100b
	byte	00111111b, 11111100b
	byte	01111111b, 11111100b
	byte	01111111b, 11111000b
	byte	01111111b, 11111000b
	byte	01111111b, 11111000b
	byte	00111111b, 11110000b
	byte	00111111b, 11110000b
	byte	01111111b, 11100000b
	byte	01100111b, 10000000b
	byte	00000000b, 00000000b

PinnedPushpinBWDarkBitmap	label	word
	word	16				;bitmap width
	word	14				;bitmap height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type

	byte	00000000b, 11100000b
	byte	00000111b, 00011000b
	byte	00011010b, 00001000b
	byte	00100100b, 00000100b
	byte	00100100b, 00000100b
	byte	01000100b, 00000100b
	byte	01000110b, 00001000b
	byte	01000011b, 00011000b
	byte	01000011b, 11111000b
	byte	00100001b, 11110000b
	byte	00111000b, 11110000b
	byte	01111111b, 11100000b
	byte	01100111b, 10000000b
	byte	00000000b, 00000000b

PinnedPushpinColorDarkBitmap	label	word
	word	16				;bitmap width
	word	14				;bitmap height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00001000b
	byte	00000000b, 00000100b
	byte	00000000b, 00000100b
	byte	00000000b, 00000100b
	byte	00000000b, 00001000b
	byte	00000011b, 00011000b
	byte	00000011b, 11110000b
	byte	00000001b, 11100000b
	byte	00000000b, 11000000b
	byte	00001111b, 10000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

PinnedPushpinColorWhiteBitmap	label	word
	word	16				;bitmap width
	word	14				;bitmap height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 11100000b
	byte	00000111b, 00011000b
	byte	00011010b, 00000000b
	byte	00100100b, 00000000b
	byte	00100100b, 00000000b
	byte	01000100b, 00000000b
	byte	01000110b, 00000000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b
	byte	00100000b, 00000000b
	byte	00011000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

PinnedPushpinColorBlackBitmap	label	word
	word	16				;bitmap width
	word	14				;bitmap height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00011000b
	byte	00100000b, 00110000b
	byte	01110000b, 01100000b
	byte	01100111b, 10000000b
	byte	00000000b, 00000000b

endif		;END of OPEN LOOK specific code -------------------------------


;------------------------------------------------------------------------------
;		Resizable frame
;------------------------------------------------------------------------------
;This region defines the resizable frame (pass = cx = width, dx = height)

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------

ResizeRegionBlack	label	Region
	word	0
	word	0
	word	PARAM_2
	word	PARAM_3

	word	-1,						EOREGREC
	word	0, 0, PARAM_2,					EOREGREC

	;top of window: black border and black lines for resize boxes
	word	1, 0, 0
	word	 OLS_WIN_RESIZE_SEGMENT_LENGTH+1, PARAM_2-OLS_WIN_RESIZE_SEGMENT_LENGTH-1
	word	 PARAM_2, PARAM_2,				EOREGREC
	word	OLS_WIN_RESIZE_SEGMENT_THICKNESS, 0, 0
	word	 OLS_WIN_RESIZE_SEGMENT_LENGTH+1, OLS_WIN_RESIZE_SEGMENT_LENGTH+1
	word	 PARAM_2-OLS_WIN_RESIZE_SEGMENT_LENGTH-1, PARAM_2-OLS_WIN_RESIZE_SEGMENT_LENGTH-1
	word	PARAM_2, PARAM_2,				EOREGREC
	word	OLS_WIN_RESIZE_SEGMENT_THICKNESS+1, 0, 0
	word	 OLS_WIN_RESIZE_SEGMENT_THICKNESS+1, OLS_WIN_RESIZE_SEGMENT_LENGTH+1
	word	 PARAM_2-OLS_WIN_RESIZE_SEGMENT_LENGTH-1, PARAM_2-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1
	word	 PARAM_2, PARAM_2,				EOREGREC
	word	OLS_WIN_RESIZE_SEGMENT_LENGTH, 0,0
	word	OLS_WIN_RESIZE_SEGMENT_THICKNESS+1, OLS_WIN_RESIZE_SEGMENT_THICKNESS+1
	word	 PARAM_2-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1, PARAM_2-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1
	word	 PARAM_2, PARAM_2,				EOREGREC
	word	OLS_WIN_RESIZE_SEGMENT_LENGTH+1, 0, OLS_WIN_RESIZE_SEGMENT_THICKNESS+1
	word	 PARAM_2-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1, PARAM_2,	EOREGREC

	;middle of window: black border

	word	PARAM_3-OLS_WIN_RESIZE_SEGMENT_LENGTH-2, 0, 1

	;bottom of window: black border and black lines for resize boxes

	word	 PARAM_2-1, PARAM_2,				EOREGREC
	word	PARAM_3-OLS_WIN_RESIZE_SEGMENT_LENGTH-1, 0, OLS_WIN_RESIZE_SEGMENT_THICKNESS+1
	word	 PARAM_2-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1, PARAM_2,	EOREGREC
	word	PARAM_3-OLS_WIN_RESIZE_SEGMENT_THICKNESS-2, 0, 0
	word	 OLS_WIN_RESIZE_SEGMENT_THICKNESS+1, OLS_WIN_RESIZE_SEGMENT_THICKNESS+1
	word	 PARAM_2-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1, PARAM_2-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1
	word	 PARAM_2, PARAM_2,				EOREGREC
	word	PARAM_3-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1, 0, 0
	word	 OLS_WIN_RESIZE_SEGMENT_THICKNESS+1, OLS_WIN_RESIZE_SEGMENT_LENGTH+1
	word	 PARAM_2-OLS_WIN_RESIZE_SEGMENT_LENGTH-1, PARAM_2-OLS_WIN_RESIZE_SEGMENT_THICKNESS-1
	word	 PARAM_2, PARAM_2,				EOREGREC
	word	PARAM_3-2, 0, 0
	word	 OLS_WIN_RESIZE_SEGMENT_LENGTH+1, OLS_WIN_RESIZE_SEGMENT_LENGTH+1
	word	 PARAM_2-OLS_WIN_RESIZE_SEGMENT_LENGTH-1, PARAM_2-OLS_WIN_RESIZE_SEGMENT_LENGTH-1
	word	 PARAM_2, PARAM_2,				EOREGREC

	word	PARAM_3-1, 0, 0
	word	 OLS_WIN_RESIZE_SEGMENT_LENGTH+1, PARAM_2-OLS_WIN_RESIZE_SEGMENT_LENGTH-1
	word	 PARAM_2, PARAM_2,				EOREGREC
	word	PARAM_3, 0, PARAM_2,				EOREGREC

endif		;END of OPEN LOOK specific code -------------------------------





;------------------------------------------------------------------------------
;			Menu shape
;------------------------------------------------------------------------------

;This region if for OLWinClass objects which serve as the background for
;a pull-down menu. This region is drawn at the origin, so (ax, bx) must be
;passed as the region's intended position.

;ONLY USED FOR WINDOWS WHICH HAVE A SHADOW!

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------
MenuSolidRegion	label	Region
								; Bounds
	word	PARAM_0
	word	PARAM_1
	word	PARAM_2-OLS_WIN_SHADOW_SIZE
	word	PARAM_3-OLS_WIN_SHADOW_SIZE

	word	PARAM_1-1, EOREGREC
	word	PARAM_1, PARAM_0+2, PARAM_2-2-OLS_WIN_SHADOW_SIZE, EOREGREC
	word	PARAM_1+1, PARAM_0+1, PARAM_2-1-OLS_WIN_SHADOW_SIZE, EOREGREC
	word	PARAM_3-2-OLS_WIN_SHADOW_SIZE
	word	    PARAM_0, PARAM_2-OLS_WIN_SHADOW_SIZE, EOREGREC
	word	PARAM_3-1-OLS_WIN_SHADOW_SIZE
	word	    PARAM_0+1, PARAM_2-1-OLS_WIN_SHADOW_SIZE, EOREGREC
	word	PARAM_3-OLS_WIN_SHADOW_SIZE
	word	    PARAM_0+2, PARAM_2-2-OLS_WIN_SHADOW_SIZE, EOREGREC
	word	EOREGREC

;The region definition gives us the thin black border around the menu area.

MenuBorderRegion	label	Region
								; Bounds
	word	PARAM_0
	word	PARAM_1
	word	PARAM_2-OLS_WIN_SHADOW_SIZE
	word	PARAM_3-OLS_WIN_SHADOW_SIZE

	word	PARAM_1-1, EOREGREC
	word	PARAM_1, PARAM_0+2, PARAM_2-2-OLS_WIN_SHADOW_SIZE, EOREGREC
	word	PARAM_1+1
	word	    PARAM_0+1
	word	    PARAM_0+1
	word	    PARAM_2-1-OLS_WIN_SHADOW_SIZE
	word	    PARAM_2-1-OLS_WIN_SHADOW_SIZE
	word	    EOREGREC
	word	PARAM_3-2-OLS_WIN_SHADOW_SIZE
	word	    PARAM_0
	word	    PARAM_0
	word	    PARAM_2-OLS_WIN_SHADOW_SIZE
	word	    PARAM_2-OLS_WIN_SHADOW_SIZE
	word	    EOREGREC
	word	PARAM_3-1-OLS_WIN_SHADOW_SIZE
	word	    PARAM_0+1
	word	    PARAM_0+1
	word	    PARAM_2-1-OLS_WIN_SHADOW_SIZE
	word	    PARAM_2-1-OLS_WIN_SHADOW_SIZE
	word	    EOREGREC
	word	PARAM_3-OLS_WIN_SHADOW_SIZE
	word	    PARAM_0+2, PARAM_2-2-OLS_WIN_SHADOW_SIZE, EOREGREC
	word	EOREGREC
endif		;END of OPEN LOOK specific code -------------------------------

;------------------------------------------------------------------------------
;			Shadow
;------------------------------------------------------------------------------
;	pass: ax = start of shadow in x, bx = start of shadow in y
;	      cx = right = dx = bottom

;	XXX
;	XXXX
;	XXXXX
;	XXXXX

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------
ShadowRegion	label	Region
								;Bounds
	word	OLS_WIN_SHADOW_SIZE, OLS_WIN_SHADOW_SIZE, PARAM_2, PARAM_3

	word	OLS_WIN_SHADOW_SIZE-1,				EOREGREC
	word	OLS_WIN_SHADOW_SIZE, PARAM_0, PARAM_2-2,	EOREGREC
	word	OLS_WIN_SHADOW_SIZE+1, PARAM_0, PARAM_2-1,	EOREGREC
	word	PARAM_1-2, PARAM_0-1, PARAM_2,		EOREGREC
	word	PARAM_1-1, PARAM_0-2, PARAM_2,		EOREGREC
	word	PARAM_3-2, OLS_WIN_SHADOW_SIZE, PARAM_2,	EOREGREC
	word	PARAM_3-1, OLS_WIN_SHADOW_SIZE+1, PARAM_2-1,	EOREGREC
	word	PARAM_3, OLS_WIN_SHADOW_SIZE+2, PARAM_2-2,	EOREGREC
	word	EOREGREC
endif		;END of OPEN LOOK specific code -------------------------------

WinCommon ends

