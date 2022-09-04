COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Open
FILE:		openData.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

DESCRIPTION:
	This file contains data for drawing open look stuff

	$Id: copenData.asm,v 2.54 96/10/15 18:08:32 grisco Exp $
-------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Menu Down Mark
;------------------------------------------------------------------------------


if _FXIP
DrawBWRegions	segment resource
else
DrawBW segment resource
endif

if not _REDMOTIF ;----------------------- Not needed for Redwood project

;this table is used by DrawBWButton in copenButton.asm (DrawBW resource)

if _OL_STYLE 	;--------------------------------------------------------------
MenuDownMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b
	byte	11111111b
	byte	10000001b
	byte	01000010b
	byte	01000010b
	byte	00100100b
	byte	00100100b
	byte	00011000b
endif		;--------------------------------------------------------------

;------------------------------------------------------------------------------
;			Menu Right Mark
;------------------------------------------------------------------------------

;this table is used by DrawBWButton in copenButton.asm (DrawBW resource)

if _OL_STYLE 	;--------------------------------------------------------------
MenuRightMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	01100000b
	byte	01011000b
	byte	01000110b
	byte	01000001b
	byte	01000001b
	byte	01000110b
	byte	01011000b
	byte	01100000b
endif		;--------------------------------------------------------------


if _CUA_STYLE	;--------------------------------------------------------------

if _PM		;--------------------------------------------------------------

MenuDownMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00001101b, 10000000b
	byte	00000111b, 00000000b
	byte	00000010b, 00000000b
	byte	00000000b, 00000000b
	byte	00000111b, 00000000b
	byte	00000000b, 00000000b
	byte	00000111b, 00000000b
else		;--------------------------------------------------------------

if _TRIANGLE_MENU_DOWN_MARK
   
if _MENU_DOWN_MARKS_ARE_UP_ARROWS
MenuDownMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000100b, 00000000b
	byte	00001110b, 00000000b
	byte	00011111b, 00000000b
	byte	00111111b, 10000000b
	byte	01111111b, 11000000b
	byte	11111111b, 11100000b
else
MenuDownMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	11111111b, 11100000b
	byte	01111111b, 11000000b
	byte	00111111b, 10000000b
	byte	00011111b, 00000000b
	byte	00001110b, 00000000b
	byte	00000100b, 00000000b
endif
else

if _JEDIMOTIF
MenuDownMarkBitmap	label	word
	word	OL_MARK_WIDTH		;width
	word	OL_MARK_HEIGHT		;height
	byte	BMC_UNCOMPACTED		;method of compaction
	byte	BMF_MONO		;bitmap type
	byte	00000000b
	byte	00000000b
	byte	00111000b
	byte	01111100b
	byte	01111100b
	byte	00111000b
	byte	00000000b
	byte	00000000b
else		;--------------------------------------------------------------

;if _MOTIF 	;Should be different for CUA...

MenuDownMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	01111111b, 11000000b
	byte	01111111b, 11000000b
	byte	01111111b, 11000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
;endif

endif		; if _JEDIMOTIF -----------------------------------------------

endif		; if _TRIANGLE_MENU_DOWN_MARK

endif		; if _PM ------------------------------------------------------


endif		; if _CUA_STYLE -----------------------------------------------


if _MAC 	;--------------------------------------------------------------
MenuRightMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	01100000b
	byte	01111000b
	byte	01111110b
	byte	01111111b
	byte	01111111b
	byte	01111110b
	byte	01111000b
	byte	01100000b
endif		;--------------------------------------------------------------

if _CUA

MenuRightMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000001b, 10000000b
	byte	00000000b, 11000000b
	byte	00000000b, 01100000b
	byte	11111111b, 11110000b
	byte	11111111b, 11110000b
	byte	00000000b, 01100000b
	byte	00000000b, 11000000b
	byte	00000001b, 10000000b
endif		;--------------------------------------------------------------

if _MOTIF and not _JEDIMOTIF ;-------------------------------------------------
MenuRightMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b,00000000b
	byte	00001100b,00000000b
	byte	00001111b,00000000b
	byte	00001111b,11000000b
	byte	00001111b,11110000b
	byte	00001111b,11000000b
	byte	00001111b,00000000b
	byte	00001100b,00000000b
endif		;--------------------------------------------------------------

if _JEDIMOTIF	;--------------------------------------------------------------
MenuRightMarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b
	byte	00000110b
	byte	00011110b
	byte	01111110b
	byte	01111110b
	byte	00011110b
	byte	00000110b
	byte	00000000b
endif		; _JEDIMOTIF

if _PM		;--------------------------------------------------------------

MenuRightMarkBitmap	label word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000001b, 00000000b
	byte	00000001b, 10000000b
	byte	00011111b, 11000000b
	byte	00011111b, 11100000b
	byte	00011111b, 11000000b
	byte	00000001b, 10000000b
	byte	00000001b, 00000000b

MenuRightMarkBorderedBitmap	label word
	word	OL_MARK_WIDTH+4			;width
	word	OL_MARK_HEIGHT+4		;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00111111b, 11111000b
	byte	01000000b, 00000100b
	byte	01000001b, 00000100b
	byte	01000001b, 10000100b
	byte	01011111b, 11000100b
	byte	01011111b, 11100100b
	byte	01011111b, 11000100b
	byte	01000001b, 10000100b
	byte	01000001b, 00000100b
	byte	01000000b, 00000100b
	byte	00111111b, 11111000b
endif		;--------------------------------------------------------------

endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

if _FXIP
DrawBWRegions	ends
else
DrawBW ends
endif

;-------------------------
if not _ASSUME_BW_ONLY

if _FXIP
DrawColorRegions segment resource
else
DrawColor segment resource
endif



;these tables=used by DrawColorButton in copenButton.asm (DrawColor resource)

if _OL_STYLE 	;--------------------------------------------------------------

MenuDownMarkLightBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b
	byte	00000000b
	byte	00000001b
	byte	00000010b
	byte	00000010b
	byte	00000100b
	byte	00000100b
	byte	00001000b

MenuDownMarkDarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b
	byte	11111111b
	byte	10000000b
	byte	01000000b
	byte	01000000b
	byte	00100000b
	byte	00100000b
	byte	00010000b
endif		;--------------------------------------------------------------

if _CUA_STYLE 	;--------------------------------------------------------------

if _PM		;--------------------------------------------------------------

MenuDownMarkDarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00001101b, 10000000b
	byte	00000111b, 00000000b
	byte	00000010b, 00000000b
	byte	00000000b, 00000000b
	byte	00000111b, 00000000b
	byte	00000000b, 00000000b
	byte	00000111b, 00000000b
else		;--------------------------------------------------------------

    if _MOTIF

MenuDownMarkLightBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	01111111b, 10000000b
	byte	01000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

MenuDownMarkDarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 01000000b
	byte	00000000b, 01000000b
	byte	01111111b, 11000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b

    else		;CUA?

MenuDownMarkDarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00001111b, 11100000b
	byte	00001111b, 11100000b
	byte	00000111b, 11000000b
	byte	00000111b, 11000000b
	byte	00000011b, 10000000b
	byte	00000011b, 10000000b
	byte	00000001b, 00000000b
	byte	00000001b, 00000000b
endif
endif		; if _PM ------------------------------------------------------

endif		; if _CUA_STYLE -----------------------------------------------

;------------------------------------------------------------------------------
;			Menu Right Mark
;------------------------------------------------------------------------------

;these tables=used by DrawColorButton in copenButton.asm (DrawColor resource)

if _OL_STYLE 	;--------------------------------------------------------------
MenuRightMarkLightBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b
	byte	00000000b
	byte	00000000b
	byte	00000000b
	byte	00000001b
	byte	00000110b
	byte	00011000b
	byte	00100000b

MenuRightMarkDarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	01100000b
	byte	01011000b
	byte	01000110b
	byte	01000001b
	byte	01000000b
	byte	01000000b
	byte	01000000b
	byte	01000000b
endif		;--------------------------------------------------------------

if _MOTIF 	;--------------------------------------------------------------

MenuRightMarkLightBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b,00000000b
	byte	00011000b,00000000b
	byte	00010110b,00000000b
	byte	00010001b,10000000b
	byte	00010000b,00000000b
	byte	00010000b,00000000b
	byte	00010000b,00000000b
	byte	00000000b,00000000b


MenuRightMarkDarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b,00000000b
	byte	00000000b,00000000b
	byte	00000000b,00000000b
	byte	00000000b,00000000b
	byte	00000000b,01100000b
	byte	00000001b,10000000b
	byte	00000110b,00000000b
	byte	00011000b,00000000b
endif		;--------------------------------------------------------------


if _PM	 	;--------------------------------------------------------------

MenuRightMarkDarkBitmap	label	word
	word	OL_MARK_WIDTH			;width
	word	OL_MARK_HEIGHT			;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000001b, 00000000b
	byte	00000001b, 10000000b
	byte	00011111b, 11000000b
	byte	00011111b, 11100000b
	byte	00011111b, 11000000b
	byte	00000001b, 10000000b
	byte	00000001b, 00000000b

MenuRightMarkLightBorder	label	word
	word	OL_MARK_WIDTH+4			;width
	word	OL_MARK_HEIGHT+4		;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	01111111b, 11111000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b
	byte	01000000b, 00000000b

MenuRightMarkDarkBorder		label	word
	word	OL_MARK_WIDTH+4			;width
	word	OL_MARK_HEIGHT+6		;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	11111111b, 11111110b
	byte	10000000b, 00000010b
	byte	10000000b, 00000110b
	byte	10000000b, 00000110b
	byte	10000000b, 00000110b
	byte	10000000b, 00000110b
	byte	10000000b, 00000110b
	byte	10000000b, 00000110b
	byte	10000000b, 00000110b
	byte	10000000b, 00000110b
	byte	10000000b, 00000110b
	byte	10111111b, 11111110b
	byte	11111111b, 11111110b
endif		;--------------------------------------------------------------

if _FXIP 
DrawColorRegions ends
else
DrawColor ends
endif

endif		; if not _ASSUME_BW_ONLY
