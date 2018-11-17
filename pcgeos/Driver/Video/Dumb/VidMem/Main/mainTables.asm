COMMENT @-----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video memory driver
FILE:		mainTables.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/89		Initial version

DESCRIPTION:
	This file contains tables for the memory video driver
	
	$Id: mainTables.asm,v 1.1 97/04/18 11:42:43 newdeal Exp $

------------------------------------------------------------------------------@

;----------------------------------------------------------------------------
;		Driver jump table (used by DriverStrategy)
;----------------------------------------------------------------------------

driverJumpTable	label	word
	word	offset Main:VidInit		;intiialization
	word	offset Main:VideoNull		;last gasp
	word	offset Main:VideoNullCLCOnly	;suspend
	word	offset Main:VideoNullCLCOnly	;unsuspend
	word	offset Main:VideoNull		;test device existence
	word	offset Main:VideoNull		;set device enum
	word	offset Main:VidInfo		;get ptr to info block
	word	offset Main:VideoNull		;get exclusive
	word	offset Main:VideoNull		;start exclusive
	word	offset Main:VideoNull		;end exclusive

	word	offset Main:VidCallMod		; get a pixel color
	word	offset Main:VidCallMod		; get some bits
	word	offset Main:VideoNull		;set the ptr pic
	word	offset Main:VideoNull		;hide the cursor
	word	offset Main:VideoNull		;show the cursor
	word	offset Main:VideoNull		;move the cursor
	word	offset Main:VideoNullSet	;set save under area
	word	offset Main:VideoNullSet	;restore save under area
	word	offset Main:VideoNull		;nuke save under area
	word	offset Main:VideoNull		;request save under
	word	offset Main:VideoNull		;check save under
	word	offset Main:VideoNull		;get save under info
	word	offset Main:VideoNull		;get save under info
	word	offset Main:VideoNull		;dummy routine
	word	offset Main:VideoNull		;dummy routine

	word	offset Main:VidCallMod		; rectangle
	word	offset Main:VidCallMod		; char string
	word	offset Main:VidCallMod		; bitblt
	word	offset Main:VidCallMod		; putbits
	word	offset Main:VidCallMod		; drawline
	word	offset Main:VidCallMod		; drawregion
	word	offset Main:VidCallMod		; putline
	word	offset Main:VidCallMod		; polygon
	word	offset Main:VideoNull		; screen on
	word	offset Main:VideoNull		; screen off 
	word	offset Main:VidCallMod		; polyline
	word	offset Main:VidCallMod		; dash line
	word	offset Main:VidCallMod		; dash fill
	word	offset Main:VidSetPalette	; SetPalette
	word	offset Main:VidGetPalette	; GetPalette
.assert ($-driverJumpTable) eq VidFunction





