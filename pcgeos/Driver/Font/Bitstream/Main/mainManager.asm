COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1993 -- All Rights Reserved


PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainManager.asm

AUTHOR:		Brian Chin

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/93		Initial revision

DESCRIPTION:
	This file implements a font driver using Bitstream.

	$Id: mainManager.asm,v 1.1 97/04/18 11:45:04 newdeal Exp $

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

DefDriver Internal/fontDr.def
include Internal/bitstrm.def
include	Internal/tmatrix.def
include	Internal/grWinInt.def
include Internal/gstate.def
include Internal/window.def
include Internal/threadIn.def
include fileEnum.def
include Internal/semInt.def
include disk.def
if PROC_TRUETYPE || PROC_TYPE1
UseLib	ui.def
include math.def
endif

; TRUE to not use char-exists table for Kanji characters, instead saying all
; characters exist in GEN_WIDTHS and return FULLWIDTH_SPACE for such
; characters in GEN_CHAR
;
; - significant improvement
;
if DBCS_PCGEOS
FAST_GEN_WIDTHS = TRUE
else
FAST_GEN_WIDTHS = FALSE		; only works for DBCS
endif

;
; TRUE to use a fixed block for the font header, much better performance
;
; - no significant improvement
;
FIXED_FONT_HEADER = FALSE

;
; TRUE to cache font headers
;
; - noticable improvement
;
FONT_HEADER_CACHE = TRUE

;
; TRUE to use static bitstream globals
; (change STATIC_ALLOC, etc. in useropt.h, also)
;
; - no significant improvement
;
STATIC_GLOBALS = FALSE

;	Font Driver specific include files
;
include ../bitstreamConstant.def	; constants used for font driver
include	mainVariable.def		; Variables


;------------------------------------------------------------------------------
;	macros
;------------------------------------------------------------------------------

Abs	macro	dest
local	done
	tst	dest
	jns	done
	neg	dest
done:
endm

;------------------------------------------------------------------------------
;	constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;	variables
;------------------------------------------------------------------------------

idata		segment

; 	Driver information table
;
DriverTable	FontDriverInfoStruct <
	<BitstreamStrategy, <>, DRIVER_TYPE_FONT>,
	FM_BITSTREAM	; FDIS_maker
>

ForceRef DriverTable

idata	ends

;------------------------------------------------------------------------------
;	globals
;------------------------------------------------------------------------------

if STATIC_GLOBALS
else
global	sp_global_ptr:fptr
endif

FRONTENDCODE	segment word public 'CODE'
global	fi_reset:far
global	fi_set_specs:far
global	fi_make_char:far
global	fi_get_char_bbox:far
global	fi_get_char_width:far
if PROC_TRUETYPE or PROC_TYPE1
global	InitSaveMalloc:far
global	FreeSaveMalloc:far
endif
FRONTENDCODE	ends

KERNCODE	segment word public 'CODE'
global	sp_get_pair_kern:far
KERNCODE	ends

OUTPUTCODE	segment word public 'CODE'
global	sp_open_bitmap:far
global	sp_set_bitmap_bits:far
global	sp_close_bitmap:far
global	sp_open_outline:far
global	sp_start_new_char:far
global	sp_start_contour:far
global	sp_curve_to:far
global	sp_line_to:far
global	sp_close_contour:far
global	sp_close_outline:far
OUTPUTCODE	ends

BITSTREAMCODE	segment word public 'CODE'
global	sp_load_char_data:far
global	sp_report_error:far
BITSTREAMCODE	ends

if PROC_TRUETYPE
TTIFACECODE	segment word public 'CODE'
global	tt_load_font:far
global	tt_release_font:far
TTIFACECODE	ends

Resident	segment	resource
global	tt_get_font_fragment:far
global	tt_release_font_fragment:far
Resident	ends
endif

if PROC_TYPE1
TRLDFNTCODE	segment word public 'CODE'
global	tr_load_font:far
global	tr_unload_font:far
TRLDFNTCODE	ends

Resident	segment resource
global	get_byte:far
Resident	ends
endif

;------------------------------------------------------------------------------
;	code
;------------------------------------------------------------------------------

;include		../mainMacros.def

WidthMod segment resource
include		mainWidths.asm
include		../FontCom/fontcomUtils.asm
WidthMod ends

CharMod segment resource
include		mainChars.asm
CharMod ends

BITSTREAMCODE	segment word public 'CODE'
include		mainLoadChar.asm	; sp_load_char_data
include		mainError.asm		; sp_report_error

if PROC_TRUETYPE
;STRCMP provided by Ansi library for PROC_TRUETYPE
else
SetGeosConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STRCMP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	STRCMP

C DECLARATION	word strcmp(word far *str1, word far *str2);

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	STRCMP:far
STRCMP	proc	far	str1:fptr, str2:fptr
				uses	ds, es, di, si
	.enter
	les	di, str1		;ES:DI <- ptr to str1
	lds	si, str2		;DS:SI <- ptr to str 2
	mov	cx, -1
	clr	ax			;
	repne	scasb			;
	not	cx			;CX <- # chars in str 1 (w/null)

	mov	di, str1.offset		;ES:DI <- ptr to str1
	repe	cmpsb
	jz	exit			;If match, exit (with ax=0)
	mov	al, es:[di][-1]		;Else, return difference of chars
	sub	al, ds:[si][-1]		;
	cbw				;
exit:
	.leave
	ret
STRCMP	endp

SetDefaultConvention
endif

BITSTREAMCODE	ends

if PROC_TRUETYPE	;------------------------------------------------------
TRUETYPECODE	segment	word public 'CODE'

SetGeosConvention

JmpEnv	struct
	JE_ip	word	;0
	JE_cs	word	;2
	JE_bp	word	;4
	JE_sp	word	;6
	JE_ds	word	;8
	JE_es	word	;10
	JE_fs	word	;12
	JE_gs	word	;14
	JE_si	word	;16
	JE_di	word	;18
	JE_bx	word	;20
JmpEnv	ends

global	setjmp:far
SetJmpStack	struct
	SJS_bp		word	;0
	SJS_retf	fptr	;2
	SJS_env		fptr	;6
SetJmpStack	ends
setjmp	proc	far
	push	bp
	mov	bp, sp
	push	di
	les	di, ss:[bp].SJS_env
	push	es
	pop	es:[di].JE_es
	push	ds
	pop	es:[di].JE_ds
	mov	ax, ss:[bp].SJS_bp
	mov	es:[di].JE_bp, ax
	mov	ax, ss:[bp].SJS_retf.offset
	mov	es:[di].JE_ip, ax
	mov	es:[di].JE_si, si
	mov	es:[di].JE_bx, bx
	pop	es:[di].JE_di
	mov	ax, ss:[bp].SJS_retf.segment
	mov	es:[di].JE_cs, ax
	mov	ax, sp
	add	ax, size SetJmpStack
	mov	es:[di].JE_sp, ax
	clr	ax
	pop	bp
	ret
setjmp	endp

global	longjmp:far
LongJmpStack	struct
	LJS_bp		word	;0
	LJS_retf	fptr	;2
	LJS_env		fptr	;6
	LJS_val		word	;10
LongJmpStack	ends
longjmp	proc	far
	push	bp
	mov	bp, sp
	les	di, ss:[bp].LJS_env
	push	es:[di].JE_ds
	pop	ds
	mov	ax, ss:[bp].LJS_val
	cmp	ax, 0
	jne	not0
	inc	ax
not0:
	mov	bx, es:[di].JE_bp
	mov	bp, bx
	mov	bx, es:[di].JE_sp
	mov	sp, bx
	push	es:[di].JE_cs			; save return address
	push	es:[di].JE_ip
	mov	bx, es:[di].JE_es
	mov	es, bx
	mov	bx, es:[di].JE_bx
	mov	si, es:[di].JE_si
	push	es:[di].JE_di
	pop	di
	ret
longjmp	endp

if 0
global	labs:far
labs	proc	far	arg:dword		; long (4 bytes)
	.enter
	mov	dx, arg.high			; dx:ax = dword
	mov	ax, arg.low
	call	FloatIEEE32ToGeos80
	call	FloatAbs
	call	FloatGeos80ToIEEE32		; dx:ax = abs(dword)
	.leave
	ret
labs	endp
endif

Resident segment resource	;MODULE_FIXED
global	floor:far
ieee64 struct
    i64_wd0	word
    i64_wd1	word
    i64_wd2	word
    i64_wd3	word
ieee64 ends
floor	proc	far	arg:ieee64,
			retAddr:fptr.ieee64
	uses	ds, es, si, di
	.enter
	segmov	ds, ss
	lea	si, arg
	call	FloatIEEE64ToGeos80
	call	FloatTrunc
	mov	es, retAddr.segment
	mov	di, retAddr.offset
	call	FloatGeos80ToIEEE64		; dx:ax = floor
	.leave
	ret
floor	endp
Resident ends	;MODULE_FIXED

global	distance:far
distance	proc	far	argx0:dword,
				argy0:dword,
				argx1:dword,
				argy1:dword
	.enter
	movdw	dxax, argx1
	subdw	dxax, argx0		; dx = x1 - x0
	movdw	cxbx, argy1
	subdw	cxbx, argy0		; dy = y1 - y0
	call	FloatDwordToFloat	; fp = dx
	call	FloatDup		; fp = dx dx
	call	FloatMultiply		; fp = (dx*dx)
	movdw	dxax, cxbx
	call	FloatDwordToFloat	; fp = dy (dx*dx)
	call	FloatDup		; fp = dy dy (dx*dx)
	call	FloatMultiply		; fp = (dy*dy) (dx*dx)
	call	FloatAdd		; fp = ((dy*dy)+(dx*dx))
	call	FloatSqrt		; fp = (sqrt((dy*dy)+(dx*dx)))
	push	ds, si
	segmov	ds, cs
	mov	si, offset distancePoint5
	call	FloatPushNumber		; fp = .5 sqrt()
	pop	ds, si
	call	FloatAdd		; fp = (.5+sqrt())
	call	FloatTrunc		; fp = floor(.5+sqrt())
	call	FloatFloatToDword	; dx:ax = result
	.leave
	ret
distance	endp

distancePoint5	label	word
	word	0, 0, 0, 8000h, 3ffeh

SetDefaultConvention

TRUETYPECODE	ends
endif	;----------------------------------------------------------------------

OUTPUTCODE	segment	word public 'CODE'
include		mainOutput.asm
include		mainOutline.asm
OUTPUTCODE	ends

MetricsMod segment resource
include		mainMetrics.asm
include		mainPath.asm
include		mainInRegion.asm
MetricsMod ends

InstallMod segment resource
include		mainInstall.asm
InstallMod ends

InitMod	segment resource
include		mainInit.asm
include		mainEscape.asm
include		../FontCom/fontcomEscape.asm
InitMod ends

UtilCode segment resource
include		mainUtils.asm
UtilCode ends


Resident segment resource	;MODULE_FIXED


COMMENT }----------------------------------------------------------------------

FUNCTION:	BitstreamStrategy

DESCRIPTION:	Entry point for driver.  All access to devices performed
		through this function

CALLED BY:	EXTERNAL

PASS:
	di - one of the following function codes:
	Function #		routine called		Function
	----------		--------------		--------
	DR_INIT			BitstreamInit		initialize
	DR_EXIT			BitstreamExit		exit
	DR_FONT_GEN_CHAR	BitstreamGenChar	generate one char
	DR_FONT_GEN_WIDTHS	BitstreamGenWidths	generate char widths
	DR_FONT_CHAR_METRICS	BitstreamCharMetrics	return character metrics
	DR_FONT_INIT_FONTS	BitstreamInitFonts	init non-GEOS fonts
	DR_FONT_GEN_PATH	BitstreamGenPath	generate outline path
	DR_FONT_GEN_IN_REGION	BitstreamGenInRegion 	gen in passed region

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
	brianc	9/29/93		modified for font driver

------------------------------------------------------------------------------}


BitstreamStrategy	proc	far

if PROC_TRUETYPE
	;
	; should do this only for DR_FONT_GEN_CHAR, DR_FONT_GEN_WIDTHS,
	; DR_FONT_CHAR_METRICS, DR_FONT_GEN_PATH, DR_FONT_GEN_IN_REGION?
	;
	push	ax, bx
	mov	ax, 10			;room for 10 fps -- should be enough
					;	for anything
	mov	bl, FLOAT_STACK_GROW	;grow if absolutely needed
	call	FloatInit
	pop	ax, bx
endif

EC <	call	ECMemVerifyHeap						>

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

EC <	call	ECMemVerifyHeap						>

if PROC_TRUETYPE
	pushf
	call	FloatExit
	popf
endif

EC <	call	ECMemVerifyHeap						>

	ret

ignoreCall:
	mov	bx, di
	jmp	callComplete

	;
	; The function is an escape function, so we deal with it specially
	;
escapeFunction:
	call	BitstreamFontEscape
	jmp	callComplete

;----------------------------

BitstreamStrategy	endp

offTable	nptr \
	offset BitstreamInit,	 	;DR_INIT
	offset BitstreamExit,	 	;DR_EXIT
	0,				;DR_SUSPEND
	0,				;DR_UNSUSPEND
	offset BitstreamGenChar, 	;DR_FONT_GEN_CHAR
	offset BitstreamGenWidths, 	;DR_FONT_GEN_WIDTHS
	offset BitstreamCharMetrics,	;DR_FONT_CHAR_METRICS
	offset BitstreamInitFonts,	;DR_FONT_INIT_FONTS
	offset BitstreamGenPath,	;DR_FONT_GEN_PATH
	offset BitstreamGenInRegion 	;DR_FONT_GEN_IN_REGION
hanTable	hptr \
	handle BitstreamInit,	 	;DR_INIT
	handle BitstreamExit,	 	;DR_EXIT
	0,				;DR_SUSPEND
	0,				;DR_UNSUSPEND
	handle BitstreamGenChar, 	;DR_FONT_GEN_CHAR
	handle BitstreamGenWidths, 	;DR_FONT_GEN_WIDTHS
	handle BitstreamCharMetrics, 	;DR_FONT_CHAR_METRICS
	handle BitstreamInitFonts, 	;DR_FONT_INIT_FONTS
	handle BitstreamGenPath, 	;DR_FONT_GEN_PATH
	handle BitstreamGenInRegion 	;DR_FONT_GEN_IN_REGION

CheckHack <(length offTable) eq (length hanTable)>

Resident ends

	end
