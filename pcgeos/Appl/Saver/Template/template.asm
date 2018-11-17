COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		template
FILE:		tempalte.asm

AUTHOR:		Gene Anderson, Sep 11, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/11/91		Initial revision

DESCRIPTION:
	Template .asm file for specific screen-saver library

	$Id: template.asm,v 1.1 97/04/04 16:47:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include type.def
include geos.def
include geosmacro.def
include errorcheck.def
include library.def
include localmem.def
include graphics.def
include gstring.def
include win.def
include	geode.def
include object.def
include event.def
include metaClass.def
include processClass.def
include	geodeBuild.def
include thread.def
include timer.def
include initfile.def

UseLib	ui.def
UseLib	options.def
UseLib	saver.def

include	coreBlock.def

include character.def

;==============================================================================
;
;		  PUBLIC DECLARATION OF ENTRY POINTS
;
;==============================================================================

global	TemplateStart:far
global	TemplateStop:far
global	TemplateFetchUI:far
global	TemplateFetchHelp:far
global	TemplateSaveState:far
global	TemplateRestoreState:far
global	TemplateSaveOptions:far
global	TemplateDraw:far
global	TemplateSetSpeed:far
global	TemplateSetClearMode:far

;
; If you add options, update these
;
FIRST_OPTION_ENTRY	equ	enum TemplateSetSpeed
LAST_OPTION_ENTRY	equ	enum TemplateSetClearMode

;==============================================================================
;
;		       CONSTANTS AND DATA TYPES
;
;==============================================================================

;
; The different speeds we support, in ticks between draws
;
TEMPLATE_SLOW_SPEED		equ	14
TEMPLATE_MEDIUM_SPEED		equ	8
TEMPLATE_FAST_SPEED		equ	2

TemplateOptionFlags	record
    :7
    TOF_CLEAR_SCREEN:1		;TRUE: clear screen
TemplateOptionFlags	end
;
; The state we save to our parent's state file on shutdown.
;
TemplateState	struc
    TS_speed		word
    TS_options		TemplateOptionFlags
TemplateState	ends

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	template.rdef

udata	segment

;
; Current window and gstate to use for drawing.
;
curWindow	hptr.Window
curGState	hptr.GState
winHeight	word
winWidth	word

;
; Timer we started for moving
;
curTimer	hptr.HandleTimer
curTimerID	word

udata	ends

idata	segment

;
; Parameters for the Template, saved and restored to and from our parent's state
; file.
;
tempstate	TemplateState	<
    TEMPLATE_MEDIUM_SPEED,
    mask TOF_CLEAR_SCREEN
>

idata	ends

;==============================================================================
;
;		   EXTERNAL WELL-DEFINED INTERFACE
;
;==============================================================================
TemplateCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	Generic screen saver library
PASS:		cx	= window handle
		dx	= window height
		si	= window width
		di	= gstate handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateStart	proc	far
	uses	ax, bx, cx, dx, ds, es
	.enter
	segmov	ds, dgroup, ax
	test	ds:[tempstate].TS_options, mask TOF_CLEAR_SCREEN
	jz	blank
	call	SaverInitBlank
blank:
	;
	; Save the window and gstate we were given for later use.
	;
	mov	ds:[curWindow], cx
	mov	ds:[curGState], di
	mov	ds:[winHeight], dx
	mov	ds:[winWidth], si

	;
	; Start up the timer for the first draw
	;
	call	TemplateSetTimer

	.leave
	ret
TemplateStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop drawing a Template

CALLED BY:	Parent library
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateStop	proc	far
	uses	ds, bx, ax
	.enter
	segmov	ds, dgroup, ax
	
	;
	; Stop the draw timer we started.
	;
	mov	bx, ds:[curTimer]
	mov	ax, ds:[curTimerID]
	call	TimerStop
	
	;
	; And mark the window and gstate as no longer existing.
	;
	clr	ax
	mov	ds:[curWindow], ax
	mov	ds:[curGState], ax

	.leave
	ret
TemplateStop	endp

TemplateCode		ends

TemplateInitExit	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateFetchUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the tree of options that affect how this thing
		performs.

CALLED BY:	Saver library
PASS:		nothing
RETURN:		^lcx:dx	= root of option tree to add
		ax	= first entry point stored in OD's in the tree
		bx	= last entry point stored in OD's in the tree
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateFetchUI	proc	far
	uses	bp, si, di, ds
	.enter

	;
	; Duplicate the block -- we have all the items send us methods, so
	; we don't need to save the handle around.
	;
	mov	bx, handle TemplateOptions
	mov	ax, handle saver	; owned by the saver library so it
					;  can get into a state file
	call	ObjDuplicateBlock

	;
	; Return the root in ^lcx:dx
	;
	mov	cx, bx
	mov	dx, offset TemplateRoot
	mov	ax, FIRST_OPTION_ENTRY	; first entry point used in OD's
	mov	bx, LAST_OPTION_ENTRY	; last entry point used in OD's
	.leave
	ret
TemplateFetchUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateFetchHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the tree of UI for the help

CALLED BY:	Saver library
PASS:		nothing
RETURN:		^lcx:dx	= root of help tree (cx == 0 for none)
DESTROYED:	anything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateFetchHelp	proc	far
	.enter

	mov	bx, handle TemplateHelp
	mov	ax, handle saver		;ax <- owned by 'saver'
	call	ObjDuplicateBlock
	;
	; Return in ^lcx:dx
	;
	mov	cx, bx
	mov	dx, offset HelpBox

	.leave
	ret
TemplateFetchHelp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add our little state block to that saved by the generic
		saver library.

CALLED BY:	SF_SAVE_STATE
PASS:		cx	= handle of block to which to append our state
		dx	= first available byte in the block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateSaveState	proc	far
		uses	cx, di, es, ds, si
		.enter
	;
	; Enlarge the block to hold our state information.
	;
		mov	bx, cx
		mov	ax, dx
		add	ax, size TemplateState + size word
		mov	ch, mask HAF_LOCK
		call	MemReAlloc
		jc	done
	;
	; Copy our state block to the passed offset within the block.
	;
		mov	es, ax
		mov	di, dx
		segmov	ds, dgroup, si
		mov	si, offset tempstate
		mov	ax, size tempstate
		stosw		; save the size of the saved state first
		xchg	cx, ax
		rep	movsb
	;
	; Done with the block, so unlock it.
	;
		call	MemUnlock
done:
		.leave
		ret
TemplateSaveState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore our little state block from that saved by the generic
		saver library.

CALLED BY:	SF_RESTORE_STATE
PASS:		cx	= handle of block from which to retrieve our state
		dx	= start of our data in the block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateRestoreState	proc	far
		uses	cx, di, es, ds, si
		.enter
	;
	; Lock down the block that holds our state information.
	;
		mov	bx, cx
		call	MemLock
		jc	done
		mov	ds, ax
	;
	; Copy our state block from the passed offset within the block.
	;
		segmov	es, dgroup, di
		mov	di, offset tempstate
		mov	cx, size tempstate
		mov	si, dx

		lodsw			; make sure the state is the right
					;  size.
		cmp	ax, cx
		jne	unlock		; if not, abort the restore
		rep	movsb
	;
	; Done with the block, so unlock it.
	;
unlock:
		call	MemUnlock
done:
		.leave
		ret
TemplateRestoreState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save any extra options that need saving.

CALLED BY:	Generic saver library
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateSaveOptions	proc	far
		.enter
		clc
		.leave
		ret
TemplateSaveOptions	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing entry point for the kernel's benefit

CALLED BY:	kernel
PASS:		di	= LibraryCallTypes
		cx	= handle of client, if LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateEntry	proc	far
	clc		; no errors
	ret
TemplateEntry	endp

ForceRef TemplateEntry

TemplateInitExit	ends

;==============================================================================
;
;		    DRAWING ROUTINES/ENTRY POINTS
;
;==============================================================================

TemplateCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	TemplateDraw, TemplateStart
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TemplateSetTimer	proc	near
	.enter

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[tempstate].TS_speed
	mov	dx, enum TemplateDraw

	call	SaverStartTimer
	mov	ds:[curTimer], bx
	mov	ds:[curTimerID], ax

	.leave
	ret
TemplateSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of drawing the screen saver
CALLED BY:	timer

PASS:		none
RETURN:		none
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TemplateDraw	proc	far
	.enter

	segmov	ds, dgroup, ax
	mov	es, ax
	;
	; Make sure there is a GState to draw with
	;		
	mov	di, ds:[curGState]
	tst	di
	jz	quit

	;
	; Do cool drawing here
	;
	mov	dx, Colors			;shme
	call	SaverRandom			;random shme
	mov	al, dl				;shme
	mov	ah, COLOR_INDEX			;shme
	call	GrSetAreaColor			;set shme color
	clr	ax				;shme
	clr	bx				;shme
	mov	cx, 100				;shme
	mov	dx, 100				;shme
	call	GrFillRect			;draw shme

	;
	; Set another timer for next time.
	; 
	segmov	ds, dgroup, ax
	call	TemplateSetTimer
quit:

	.leave
	ret
TemplateDraw	endp

TemplateCode	ends

TemplateInitExit	segment	resource
;==============================================================================
;
;		    UI ACTION HANDLER ENTRY POINTS
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateSetSpeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set speed at which our saver gets drawn

CALLED BY:	TemplateSpeedList
PASS:		cx	= interval between moves (ticks)
RETURN:		nothing
DESTROYED:	anything I want

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateSetSpeed	proc	far
	.enter

	segmov	ds, dgroup, ax
	mov	ds:[tempstate].TS_speed, cx

	.leave
	ret
TemplateSetSpeed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateSetClearMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set option to clear screen or not

CALLED BY:	TemplateSpeedList
PASS:		cx	= TemplateOptionFlags
			TOF_CLEAR_SCREEN - set to clear screen
RETURN:		nothing
DESTROYED:	anything I want

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TemplateSetClearMode	proc	far
	.enter

	segmov	ds, dgroup, ax
	andnf	ds:[tempstate].TS_options, not (mask TOF_CLEAR_SCREEN)
	ornf	ds:[tempstate].TS_options, cl

	.leave
	ret
TemplateSetClearMode	endp

TemplateInitExit	ends
