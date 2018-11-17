COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidCom
FILE:		vidcomTables.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	jeremy	5/91		Added support for the mono EGA driver

DESCRIPTION:
	This file contains tables common to all video drivers

	$Id: vidcomTables.asm,v 1.1 97/04/18 11:41:54 newdeal Exp $

-------------------------------------------------------------------------------@

;----------------------------------------------------------------------------
;		Driver jump table (used by DriverStrategy)
;----------------------------------------------------------------------------

driverJumpTable	label	word
	dw	offset dgroup:VidInit		; initialization
	dw	offset dgroup:VidExit		; last gasp
	dw	offset dgroup:VidCallModNoSem	; suspend system
	dw	offset dgroup:VidCallModNoSem	; unsuspend system
	dw	offset dgroup:VidCallModNoSem	; test for device existance
	dw	offset dgroup:VidCallModNoSem	; set device type
	dw	offset dgroup:VidInfo		; get ptr to info block
	dw	offset dgroup:VidGetExclusive	; get exclusive
	dw	offset dgroup:VidStartExclusive	; start exclusive
	dw	offset dgroup:VidEndExclusive	; end exclusive

	dw	offset dgroup:VidGetPixel	; get pixel color
	dw	offset dgroup:VidCallMod	; GetBits in another module
	dw	offset dgroup:VidSetPtr		; set the ptr pic
	dw	offset dgroup:VidHidePtr	; hide the cursor
	dw	offset dgroup:VidShowPtr	; show the cursor
	dw	offset dgroup:VidMovePtr	; move the cursor
	dw	offset dgroup:VidSaveUnder	; set save under area
if	SAVE_UNDER_COUNT	gt	0
	dw	offset dgroup:VidRestoreUnder	; restore save under area
	dw	offset dgroup:VidNukeUnder	; nuke save under area
else
	dw	0
	dw	0
endif
	dw	offset dgroup:VidRequestUnder	; request save under
	dw	offset dgroup:VidCheckUnder	; check save under
	dw	offset dgroup:VidInfoUnder	; get save under info
	dw	offset dgroup:CheckSaveUnderCollisionES ; check s.u. collision
	dw	offset dgroup:VidSetXOR		; set xor region
	dw	offset dgroup:VidClearXOR	; clear xor region

	dw	offset dgroup:VidDrawRect	; rectangle
	dw	offset dgroup:VidPutString	; char string
	dw	offset dgroup:VidCallMod	; BitBlt in another module
	dw	offset dgroup:VidCallMod	; PutBits in another module
	dw	offset dgroup:VidCallMod	; DrawLine in another module
	dw	offset dgroup:VidDrawRegion	; draws a region
	dw	offset dgroup:VidCallMod	; PutLine in another module
	dw	offset dgroup:VidCallMod	; Polygon in another module
	dw	offset dgroup:VidCallMod	; ScreenOn in another module
	dw	offset dgroup:VidCallMod	; ScreenOff in another module
	dw	offset dgroup:VidCallMod	; Polyline in another module
	dw	offset dgroup:VidCallMod	; DashLine in another module
	dw	offset dgroup:VidCallMod	; DashFill in another module
	dw	offset dgroup:VidSetPalette	; SetPalette 
	dw	offset dgroup:VidGetPalette	; GetPalette 

.assert ($-driverJumpTable) eq VidFunction

	; this table holds offsets to the routines in different modules
moduleTable	label	fptr
	fptr	0 				; initialization
	fptr	0				; last gasp
	fptr	VideoMisc:VidSuspend		; suspend system
	fptr	VideoMisc:VidUnsuspend		; unsuspend system
	fptr	VideoMisc:VidTestDevice		; test for device existance
	fptr	VideoMisc:VidSetDevice		; set device type
	fptr	0				; get ptr to info block
	fptr	0				; get exclusive
	fptr	0				; start exclusive
	fptr	0				; end exclusive

	fptr	0				; get pixel color
	fptr	VideoGetBits:VidGetBits 	; GetBits in another module
	fptr	0				; set the ptr pic
	fptr	0				; hide the cursor
	fptr	0				; show the cursor
	fptr	0				; move the cursor
	fptr	0				; set save under area
	fptr	0				; restore save under area
	fptr	0				; nuke save under area
	fptr	0				; request save under
	fptr	0				; check save under
	fptr	0				; get save under info
	fptr	0		 		; check s.u. collision
	fptr	0				; set xor region
	fptr	0				; clear xor region

	fptr	0				; rectangle
	fptr	0				; char string
	fptr	VideoBlt:VidBitBlt		; BitBlt in another module
	fptr	VideoBitmap:VidPutBits  	; PutBits in another module
	fptr	VideoLine:VidDrawLine		; DrawLine in another module
	fptr	0				; draws a region
	fptr	VideoPutLine:VidPutLine		; PutLine in another module
	fptr	VideoPolygon:VidPolygon		; Polygon in another module
	fptr	VideoMisc:VidScreenOn		; ScreenOn in another module
	fptr	VideoMisc:VidScreenOff		; ScreenOff in another module
	fptr	VideoLine:VidPolyline		; Polyline in another module
	fptr	VideoLine:VidDashLine		; DashLine in another module
	fptr	VideoLine:VidDashFill		; DashFill in another module
	fptr	0				; SetPalette
	fptr	0				; GetPalette
.assert ($-moduleTable) eq (VidFunction*2)

;----------------------------------------------------------------------------
;		Exclusive access variables
;----------------------------------------------------------------------------

	; used for GrGrabExclusive, GrReleaseExclusive

videoSem	Semaphore	<1,0>
exclusiveGstate	hptr.GState
exclusiveCausedAbort	word	FALSE
exclBound	Rectangle
	public	videoSem, exclusiveGstate, exclusiveCausedAbort

if	SAVE_UNDER_COUNT	gt	0
;---------------------------------------------------------------------------
;		Save under variables
;---------------------------------------------------------------------------

SaveUnderStruct	struct
    SUS_left		dsw
    SUS_top		dsw
    SUS_right		dsw
    SUS_bottom		dsw		;address on screen
    SUS_window		hptr.Window	;window of save under area
    SUS_parent		hptr.Window	;parent window of save under area
LVR<SUS_saveAddr	dd	?		;address in save buffer	>
SVR<SUS_saveAddr	dw	?		;address in save buffer	>
    SUS_flags		db	?		;ID for save under area
if	BIT_SHIFTS le 2
    SUS_unitsPerLine	dsw		;bytes/words per line
else
    SUS_unitsPerLine	dsb		;bytes/words per line
endif	; BIT_SHIFTS le 2
LVR<SUS_screenAddr	dd	?		;address on screen (left, top)>
SVR<SUS_screenAddr	dw	?		;address on screen (left, top)>
    SUS_lines		dsw		;number of lines
    SUS_scanMod		dw	?		;value to add to next scan line
if	BIT_SHIFTS le 2
    SUS_leftUnit	dsw		;byte/word index of left
    SUS_rightUnit	dsw		;byte/word index of right
else
    SUS_leftUnit	dsb		;byte/word index of left
    SUS_rightUnit	dsb		;byte/word index of right
endif	; BIT_SHIFTS le 2
SaveUnderStruct	ends

suTable		SaveUnderStruct SAVE_UNDER_COUNT dup(<>)
end_suTable	label	SaveUnderStruct
	public	suTable, end_suTable

	;address of first free structure

suFreePtr	dw	offset dgroup:suTable
	public	suFreePtr

suCount		dsb		; number of save under areas active
suFreeFlags	db	11111111b	; unused flags
	public	suCount, suFreeFlags

ALT <	LVR <	suSaveFreePtr	dd	0				>>
ALT <	SVR <	suSaveFreePtr	dw	0				>>
ALT <	public	suSaveFreePtr						>

NOALT <suSaveSegment	sptr						>
NOALT <	public	suSaveSegment						>

udata	segment

ALT <	MRES <	LVR <	suSaveAreaSize	dword				>>>
ALT <	MRES <	SVR <	suSaveAreaSize	word				>>>

ALT <	MRES <	LVR <	suSaveAreaStart	dword				>>>

ifdef	LARGE_VIDEO_RAM
;
; 32-bit "local" variables used in save-under code.  These are put here
; because it's too much trouble playing with bp.  Plus any extra code also
; takes up space in dgroup anyway.
;
ALT <	dest		dword						>
ALT <	src		dword						>
ALT <	unitsToMove	dword		; # bytes/words to move		>
endif	; LARGE_VIDEO_RAM

; Temporary variable used in RestoreMaskedRect for units per line in place
; of currentDrawMode
if	BIT_SHIFTS le 2
	unitsPerLine	word
endif	; BIT_SHIFTS le 2

if	BIT_SHIFTS le 0
	leftMaskBitPos	byte	; pos of mask bit within mask unit (0-7 or 15)
	maskBitsLeft	byte	; # mask bits left within current mask unit
endif	; BIT_SHIFTS le 0

udata	ends

endif	;SAVE_UNDER_COUNT gt 0

;------------------------------------------------------------------------------
;		Table of character drawing routines
;------------------------------------------------------------------------------

ifndef	IS_CLR24
ifndef	IS_CLR8			; 8-bit/pixel drivers have their own
ifndef	BIT_CLR4
ifndef	BIT_CLR2
FCC_table	label	word
	dw	offset dgroup:Char1In1Out	;load 1, draw 1
	dw	offset dgroup:Char1In2Out	;load 1, draw 2
	dw	offset dgroup:NullRoutine	;load 1, draw 3
	dw	offset dgroup:NullRoutine	;load 1, draw 4

	dw	offset dgroup:NullRoutine	;load 2, draw 1
	dw	offset dgroup:Char2In2Out	;load 2, draw 2
	dw	offset dgroup:Char2In3Out	;load 2, draw 3
	dw	offset dgroup:NullRoutine	;load 2, draw 4

	dw	offset dgroup:NullRoutine	;load 3, draw 1
	dw	offset dgroup:NullRoutine	;load 3, draw 2
	dw	offset dgroup:Char3In3Out	;load 3, draw 3
	dw	offset dgroup:Char3In4Out	;load 3, draw 4

	dw	offset dgroup:NullRoutine	;load 4, draw 1
	dw	offset dgroup:NullRoutine	;load 4, draw 2
	dw	offset dgroup:NullRoutine	;load 4, draw 3
	dw	offset dgroup:Char4In4Out	;load 4, draw 4
endif
endif
endif
endif


;	Pre-defined pointer shapes

;	There is only one default pointer shape pre-defined in the video
;	drivers.  See VidSetPtr for details.


pBasic	PointerDef <
	16,				; PD_width
	16,				; PD_height
	0,				; PD_hotX
	0				; PD_hotY
>
ifndef	NO_POINTER
	byte 	11100000b, 00000000b,	; mask data
		11111000b, 00000000b,
		11111110b, 00000000b,
		01111111b, 10000000b,
		01111111b, 11100000b,
		00111111b, 11111000b,
		00111111b, 11111100b,
		00011111b, 11111100b,
		00011111b, 11111000b,
		00001111b, 11110000b,
		00001111b, 11111000b,
		00000111b, 11111100b,
		00000111b, 10111110b,
		00000011b, 00011111b,
		00000000b, 00001111b,
		00000000b, 00000111b


	byte	11100000b, 00000000b,	; image data
		10011000b, 00000000b,
		10000110b, 00000000b,
		01000001b, 10000000b,
		01000000b, 01100000b,
		00100000b, 00011000b,
		00100000b, 00000100b,
		00010000b, 00000100b,
		00010000b, 00111000b,
		00001000b, 00010000b,
		00001000b, 10001000b,
		00000100b, 11000100b,
		00000100b, 10100010b,
		00000011b, 00010001b,
		00000000b, 00001001b,
		00000000b, 00000111b

else
	byte 	00000000b, 00000000b,	; mask data
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b


	byte	00000000b, 00000000b,	; image data
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b,
		00000000b, 00000000b
endif
