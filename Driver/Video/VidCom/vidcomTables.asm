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
	dw	offset VideoCode:VidInit		; initialization
	dw	offset VideoCode:VidExit		; last gasp
	dw	offset VideoCode:VidCallMod		; suspend system
	dw	offset VideoCode:VidCallMod		; unsuspend system
	dw	offset VideoCode:VidCallMod		; test for device existance
	dw	offset VideoCode:VidCallMod		; set device type
	dw	offset VideoCode:VidInfo		; get ptr to info block
	dw	offset VideoCode:VidGetExclusive	; get exclusive
	dw	offset VideoCode:VidStartExclusive	; start exclusive
	dw	offset VideoCode:VidEndExclusive	; end exclusive

	dw	offset VideoCode:VidGetPixel	; get pixel color
	dw	offset VideoCode:VidCallMod	; GetBits in another module
	dw	offset VideoCode:VidSetPtr		; set the ptr pic
	dw	offset VideoCode:VidHidePtr	; hide the cursor
	dw	offset VideoCode:VidShowPtr	; show the cursor
	dw	offset VideoCode:VidMovePtr	; move the cursor
	dw	offset VideoCode:VidSaveUnder	; set save under area
if	SAVE_UNDER_COUNT	gt	0
	dw	offset VideoCode:VidRestoreUnder	; restore save under area
	dw	offset VideoCode:VidNukeUnder	; nuke save under area
else
	dw	0
	dw	0
endif
	dw	offset VideoCode:VidRequestUnder	; request save under
	dw	offset VideoCode:VidCheckUnder	; check save under
	dw	offset VideoCode:VidInfoUnder	; get save under info
	dw	offset VideoCode:CheckSaveUnderCollisionES ; check s.u. collision
	dw	offset VideoCode:VidSetXOR		; set xor region
	dw	offset VideoCode:VidClearXOR	; clear xor region

	dw	offset VideoCode:VidDrawRect	; rectangle
	dw	offset VideoCode:VidPutString	; char string
	dw	offset VideoCode:VidCallMod	; BitBlt in another module
	dw	offset VideoCode:VidCallMod	; PutBits in another module
	dw	offset VideoCode:VidCallMod	; DrawLine in another module
	dw	offset VideoCode:VidDrawRegion	; draws a region
	dw	offset VideoCode:VidCallMod	; PutLine in another module
	dw	offset VideoCode:VidCallMod	; Polygon in another module
	dw	offset VideoCode:VidCallMod	; ScreenOn in another module
	dw	offset VideoCode:VidCallMod	; ScreenOff in another module
	dw	offset VideoCode:VidCallMod	; Polyline in another module
	dw	offset VideoCode:VidCallMod	; DashLine in another module
	dw	offset VideoCode:VidCallMod	; DashFill in another module
	dw	offset VideoCode:VidSetPalette	; SetPalette 
	dw	offset VideoCode:VidGetPalette	; GetPalette 

.assert ($-driverJumpTable) eq VidFunction

	; this table holds offsets to the routines called after switching stacks
moduleTable	label	word
	dw	0 				; initialization
	dw	0				; last gasp
	dw	offset VideoCode:VidSuspend	; suspend system
	dw	offset VideoCode:VidUnsuspend	; unsuspend system
	dw	offset VideoCode:VidTestDevice	; test for device existance
	dw	offset VideoCode:VidSetDevice	; set device type
	dw	0				; get ptr to info block
	dw	0				; get exclusive
	dw	0				; start exclusive
	dw	0				; end exclusive

	dw	0				; get pixel color
	dw	offset VideoCode:VidGetBits 	; GetBits in another module
	dw	0				; set the ptr pic
	dw	0				; hide the cursor
	dw	0				; show the cursor
	dw	0				; move the cursor
	dw	0				; set save under area
	dw	0				; restore save under area
	dw	0				; nuke save under area
	dw	0				; request save under
	dw	0				; check save under
	dw	0				; get save under info
	dw	0		 		; check s.u. collision
	dw	0				; set xor region
	dw	0				; clear xor region

	dw	0				; rectangle
	dw	0				; char string
	dw	offset VideoCode:VidBitBlt	; BitBlt in another module
	dw	offset VideoCode:VidPutBits  	; PutBits in another module
	dw	offset VideoCode:VidDrawLine		; DrawLine in another module
	dw	0				; draws a region
	dw	offset VideoCode:VidPutLine	; PutLine in another module
	dw	offset VideoCode:VidPolygon	; Polygon in another module
	dw	offset VideoCode:VidScreenOn	; ScreenOn in another module
	dw	offset VideoCode:VidScreenOff	; ScreenOff in another module
	dw	offset VideoCode:VidPolyline	; Polyline in another module
	dw	offset VideoCode:VidDashLine	; DashLine in another module
	dw	offset VideoCode:VidDashFill	; DashFill in another module
	dw	0				; SetPalette
	dw	0				; GetPalette
.assert ($-moduleTable) eq (VidFunction)

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
	dw	offset VideoCode:Char1In1Out	;load 1, draw 1
	dw	offset VideoCode:Char1In2Out	;load 1, draw 2
	dw	offset VideoCode:NullRoutine	;load 1, draw 3
	dw	offset VideoCode:NullRoutine	;load 1, draw 4

	dw	offset VideoCode:NullRoutine	;load 2, draw 1
	dw	offset VideoCode:Char2In2Out	;load 2, draw 2
	dw	offset VideoCode:Char2In3Out	;load 2, draw 3
	dw	offset VideoCode:NullRoutine	;load 2, draw 4

	dw	offset VideoCode:NullRoutine	;load 3, draw 1
	dw	offset VideoCode:NullRoutine	;load 3, draw 2
	dw	offset VideoCode:Char3In3Out	;load 3, draw 3
	dw	offset VideoCode:Char3In4Out	;load 3, draw 4

	dw	offset VideoCode:NullRoutine	;load 4, draw 1
	dw	offset VideoCode:NullRoutine	;load 4, draw 2
	dw	offset VideoCode:NullRoutine	;load 4, draw 3
	dw	offset VideoCode:Char4In4Out	;load 4, draw 4
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
