COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Font Driver
FILE:		truetype.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	11/03/89	Initial revision

DESCRIPTION:
	This file implements a font driver using TrueType.

	$Id: truetype.asm,v 1.1 97/04/18 11:45:30 newdeal Exp $

------------------------------------------------------------------------------@


;------------------------------------------------------------------------------
;			System Definition
;------------------------------------------------------------------------------

_Driver		=	1
_FontDriver	=	1

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include driver.def
include graphics.def
include gstring.def
include sem.def
include file.def
include lmem.def
include font.def
include localize.def
include char.def
include system.def

include fileEnum.def

DefDriver Internal/fontDr.def
include	Internal/tmatrix.def
include	Internal/grWinInt.def
include Internal/gstate.def
include Internal/window.def
include Internal/threadIn.def





;	Font Driver specific include files
;
include truetypeConstant.def		; constants used for font driver
include	truetypeVariable.def		; Variables


idata		segment

; 	Driver information table
;
DriverTable	FontDriverInfoStruct <
	<TrueTypeStrategy, <>, DRIVER_TYPE_FONT>,
	FM_TRUETYPE	; FDIS_maker
>

ForceRef DriverTable

idata	ends

;TODO: remove dependencys from ansic
udata	segment
	mallocOffset	word	(?)
		public	mallocOffset
udata	ends

include		truetypeMacros.def

WidthMod segment resource
include		truetypeWidths.asm
;include		nimbusUtils.asm
;include		nimbusSetTrans.asm
include		../FontCom/fontcomUtils.asm
WidthMod ends

CharMod segment resource
include			truetypeChars.asm
;include		nimbusRegions.asm
;include		nimbusLoadFont.asm
;include		nimbusBig.asm
;include		nimbusBitmap.asm
NimbusStart	label	near
;include		nimbusMakechar.asm
;include		nimbusSegments.asm
;include		nimbusTrans.asm
;include		nimbusMul.asm
;include		nimbusContinuity.asm
AA_NIMBUS_SIZE equ $-NimbusStart
CharMod ends

;routines form GEOS adapter
global	INIT_FREETYPE:far
global	EXIT_FREETYPE:far

global	tt_Engine:TT_Engine

MetricsMod segment resource
include		truetypeMetrics.asm
include		truetypePath.asm
MetricsMod ends

InitMod	segment resource
include		truetypeInit.asm
include		truetypeEscape.asm
include		../FontCom/fontcomEscape.asm
InitMod ends

include		truetypeEC.asm
include	        ansic_runtime.asm
include		ansic_memory.asm
include		ansic_malloc.asm
include		ansic_string.asm

Resident segment resource	;MODULE_FIXED


COMMENT }----------------------------------------------------------------------

FUNCTION:	TrueTypeStrategy

DESCRIPTION:	Entry point for driver.  All access to devices performed
		through this function

CALLED BY:	EXTERNAL

PASS:
	di - one of the following function codes:
	Function #		routine called		Function
	----------		--------------		--------
	DR_INIT			NimbusInit		initialize
	DR_EXIT			NimbusExit		exit
	DR_FONT_GEN_CHAR	NimbusGenChar		generate one char
	DR_FONT_GEN_WIDTHS	NimbusGenWidths		generate char widths
	DR_FONT_CHAR_METRICS	NimbusCharMetrics	return character metrics
	DR_FONT_INIT_FONTS	NimbusInitFonts		init non-GEOS fonts
	DR_FONT_GEN_PATH	NimbusGenPath		generate outline path
	DR_FONT_GEN_IN_REGION	NimbusGenInRegion 	gen in passed region

RETURN:
	depends on function called
	carry - set if error

DESTROYED:
	depends on function called

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Calls routine from jump table

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/89		modified for font driver

------------------------------------------------------------------------------}


EC <inDriverFlag	byte	0	>

TrueTypeStrategy	proc	far

EC <	tst	cs:[inDriverFlag]		>
EC <	ERROR_NZ RECURSIVE_CALL_TO_FONT_DRIVER	>
EC <	inc	cs:[inDriverFlag]		>

	tst	di			;escape function (>=0x8000) ?
	js	escapeFunction		;branch if escape function

	push	bx
EC <	cmp	di, (size offTable)		;>
EC <	ERROR_AE FONT_BAD_ROUTINE		;>
	mov	ax, cs:offTable[di]	;ax <- addr of routine in module
	mov	bx, cs:hanTable[di]	;bx <- handle of module
	pop	di			;pass old bx in di
	tst	bx			; function supported?
	jz	ignoreCall		; => no (carry clear)
	call	ProcCallModuleRoutine
callComplete:
EC <	mov	cs:[inDriverFlag],0		>
done:
EC <	call	ECNukeVariableBlock		;>
	ret

ignoreCall:
	mov	bx, di
	jmp	callComplete

	;
	; The function is an escape function, so we deal with it specially
	;
escapeFunction:
	call	TrueTypeFontEscape
	jmp	done

;----------------------------

TrueTypeStrategy	endp

offTable	nptr \
	offset TrueTypeInit,	 	;DR_INIT
	offset TrueTypeExit,	 	;DR_EXIT
	0,				;DR_SUSPEND
	0,				;DR_UNSUSPEND
	offset TrueTypeGenChar,	 	;DR_FONT_GEN_CHAR
	offset TrueTypeGenWidths, 	;DR_FONT_GEN_WIDTHS
	offset TrueTypeCharMetrics,	;DR_FONT_CHAR_METRICS
	offset TrueTypeInitFonts, 	;DR_FONT_INIT_FONTS
	offset TrueTypeGenPath,	 	;DR_FONT_GEN_PATH
	offset TrueTypeGenInRegion 	;DR_FONT_GEN_IN_REGION
hanTable	hptr \
	handle InitMod,		 	;DR_INIT
	handle InitMod,		 	;DR_EXIT
	0,				;DR_SUSPEND
	0,				;DR_UNSUSPEND
	handle CharMod,		 	;DR_FONT_GEN_CHAR
	handle WidthMod,	 	;DR_FONT_GEN_WIDTHS
	handle MetricsMod,	 	;DR_FONT_CHAR_METRICS
	handle InitMod,		 	;DR_FONT_INIT_FONTS
	handle MetricsMod,	 	;DR_FONT_GEN_PATH
	handle MetricsMod	 	;DR_FONT_GEN_IN_REGION

CheckHack <(length offTable) eq (length hanTable)>

Resident ends

	end
