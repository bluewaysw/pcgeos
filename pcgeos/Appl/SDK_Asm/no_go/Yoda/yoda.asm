COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Yoda (Sample PC GEOS application)
FILE:		yoda.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		Initial version

DESCRIPTION:
	This file contains a welcome application

RCS STAMP:
	$Id: yoda.asm,v 1.1 97/04/04 16:34:09 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1

;Standard include files

include	type.def
include	geos.def
include geode.def
include	geodeBuild.def
include	opaque.def
include	geosmacro.def
include	errorcheck.def
include	library.def
include geode.def

include object.def
include	graphics.def
include gstring.def
include	win.def
include lmem.def
include event.def
include timer.def
include processClass.def	;need for ui.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include mouse.def
include keyboard.def
include character.def		;Need for C_CR and C_LF constants
include localization.def	;for Resources file
include coreBlock.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Object Class include files
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		yoda.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;This is the class for this application's process.

YodaProcessClass	class	GenProcessClass

;METHOD DEFINITIONS: these methods are defined for YodaProcessClass.

METHOD_YODA_BUTTON_PRESSED		message
; This method is sent by the UI thread when the user presses on the
; corresponding GenTrigger. See yoda.ui.
; Pass:		nothing
; Returns:	nothing

YodaProcessClass	endc	;end of class definition


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

;Class definition is stored in the application's idata resource here.

	YodaProcessClass	mask CLASSF_NEVER_SAVED

;initialized variables

SaveStart	label	word	;START of data saved to state file ------------

;When sending a method to the GenList, this is TRUE if we should send the
;item identifier as its POSITION in the list, instead of its OD.

variable1	dw	10	;sample idata variable

SaveEnd		label	word	;END of data saved to state file --------------

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;		Code for YodaProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	METHOD_YODA_BUTTON_PRESSED handler.

DESCRIPTION:	This method is sent by UI thread when the user presses on the
		"Start" GenTrigger.

PASS:		ds	= segment of DGroup (idata, udata, stack, etc)
		es	= segment of class definition (is in DGroup)
		cx, dx, bp = ?

RETURN:		ds, si, es = same
		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

YodaStartButton	method	YodaProcessClass, METHOD_YODA_BUTTON_PRESSED

	;As an example of something the application might want to do,
	;let's set the GenRange to 50.

	GetResourceHandleNS Interface, bx  ;set ^lbx:si = YodaRange object
	mov	si, offset YodaRange

	mov	cx, 50			;pass cx = value to set range to.
	clr	bp			;pass bp = flags (none set)

	mov	ax, METHOD_RANGE_SET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage		;place method on UI's queue, and
					;sleep until it has been handled
YodaStartButton	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	YodaSaveState

DESCRIPTION:	This method is sent to this application as it is attached to
		the system.

PASS:		ds	= segment of DGroup (idata, udata, stack, etc)
		es	= segment of class definition (is in DGroup)

RETURN:		ds, si, es = same
		cx	= handle of block on global heap which
				contains variables

DESTROYED:	?

PSEUDO CODE/STRATEGY:
	Note that we take advantage of the fact that since this is a
	YodaProcessClass method handler, we know that ds is the segment of the
	DGroup of this application, where the idata variables are located.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

YodaSaveState	method	YodaProcessClass, METHOD_UI_CLOSE_APPLICATION

	;allocate a block on the global heap, and lock it.

	mov	ax, SaveEnd-SaveStart	;get size of save area
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		;returns ax = segment of block
	mov	cx, 0			;assume allocation failed, clr cx
					;without affecting carry flag!
	jc	90$			;skip to end (no state to save) if error

	;copy our variables into this block.

	mov	es, ax			;set es:di = address of block
	clr	di
	mov	si, offset SaveStart	;set ds:si = address of variables
	mov	cx, (SaveEnd-SaveStart)/2 ;set cx = size of save area in words
	rep	movsw			;copy words to block

	;unlock the block and return its handle to caller.

	call	MemUnlock
	mov	cx, bx			;return cx = handle

90$:
	ret
YodaSaveState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	YodaGetState

DESCRIPTION:	This method is sent to this application as it is detached from
		the system.

PASS:		ds	= segment of DGroup (idata, udata, stack, etc)
		es	= segment of class definition (is in DGroup)
		bp	= handle of block on global heap which contains vars.

RETURN:		ds, si, es = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:
	Note that we take advantage of the fact that since this is a
	YodaProcessClass method handler, we know that ds is the segment of the
	DGroup of this application, where the idata variables are located.
	We also know that es points to the DGroup, since that is where the
	YodaProcessClass declaration is stored.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

YodaGetState	method	YodaProcessClass, METHOD_UI_OPEN_APPLICATION
	push	ax, bx, cx, dx, si, ds
	tst	bp			;is there a passed handle?
	jz	callSuper		;skip if not...

	;lock the block, so we get its segment.

	mov	bx, bp			;set bx = handle of block
	call	MemLock			;returns ax = segment of block

	;copy it into our variable area.

	mov	ds, ax			;set ds:si = block on global heap
	clr	si
	mov	di, offset SaveStart	;set es:di = variable area in idata
	mov	cx, (SaveEnd-SaveStart)/2 ;cx = number of words to copy
	rep	movsw			;copy words to idata area

	call	MemUnlock		;unlock the block

callSuper:
	;restore registers and call superclass (GenProcessClass for default handling)

	pop	ax, bx, cx, dx, si, ds
	mov	di, offset YodaProcessClass ;set es:di = class declaration
	GOTO	ObjCallSuperNoLock
YodaGetState	endp

CommonCode	ends		;end of CommonCode resource
