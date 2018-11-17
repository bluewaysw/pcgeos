COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefkbd.asm

AUTHOR:		Gene Anderson, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/25/92		Initial revision


DESCRIPTION:
	Code for keyboard module of Preferences

	$Id: prefkbd.asm,v 1.1 97/04/05 01:28:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include initfile.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
;
; Not actually "used" -- just their constants are:
;
UseDriver Internal/kbdDr.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include prefkbd.def
include prefkbd.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment

	PrefKbdDialogClass

idata ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefKbdCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefKbdGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		none

RETURN:		dx:ax - OD of root of tree

DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefKbdGetPrefUITree	proc far
	mov	dx, handle PrefKbdRoot
	mov	ax, offset PrefKbdRoot
	ret
PrefKbdGetPrefUITree	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefKbdGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefKbdGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_HARDWARE
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle PrefKbdMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefKbdMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'K' or ('B' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefKbdGetModuleInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefKbdDialogOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle opening of "Keyboard" section

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PrefKbdDialogClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefKbdDialogOpen		method dynamic PrefKbdDialogClass,
						MSG_VIS_OPEN
	push	bx, ax, si, bp
	;
	;  In the AUI, disable some UI options
	;
	call	UserGetDefaultUILevel	; ax - user level
	cmp	ax, UIIL_INTRODUCTORY
	je	cont
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset KeyboardOptions
	call	ObjCallInstanceNoLock

	sub	sp, size SetSizeArgs
	mov	bp, sp
	mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_UI_QUEUE
	mov	ss:[bp].SSA_width, 425
	mov	ss:[bp].SSA_height, 0
	clr	ss:[bp].SSA_count
	mov	dx, size SetSizeArgs
	mov	ax, MSG_GEN_SET_MINIMUM_SIZE	
	mov	si, offset PrefKbdHelp
	call	ObjCallInstanceNoLock
	add	sp, size SetSizeArgs

cont:
	pop	bx, ax, si, bp

	mov	di, offset PrefKbdDialogClass
	call	ObjCallSuperNoLock
	;
	; Get the value, if the key exists
	;
	push	ds
	mov	cx, cs
	mov	dx, offset typematicKey		;cx:dx <- key
	mov	ds, cx
	mov	si, offset typematicCategory	;ds:si <- category
	call	InitFileReadInteger
	pop	ds
	jc	next				;branch if doesn't exist
	;
	; Set the delay list
	;
	push	ax
	mov	cx, ax
	andnf	cx, KBD_DELAY_SHORT or KBD_DELAY_MEDIUM or KBD_DELAY_LONG
	mov	ax, MSG_PREF_ITEM_GROUP_SET_ORIGINAL_SELECTION
	mov	si, offset KeyboardDelayList
	call	ObjCallInstanceNoLock
	pop	ax
	;
	; Set the repeat list
	;
	mov	cx, ax
	andnf	cx, KBD_REPEAT_FAST or KBD_REPEAT_MEDIUM or KBD_REPEAT_SLOW
	mov	ax, MSG_PREF_ITEM_GROUP_SET_ORIGINAL_SELECTION
	mov	si, offset KeyboardRepeatList
	call	ObjCallInstanceNoLock
next:
	push	ds
	mov	cx, cs
	mov	dx, offset AltGrKey		;cx:dx <- key
	mov	ds, cx
	mov	si, offset typematicCategory	;ds:si <- category
	call	InitFileReadBoolean
	pop	ds
	jc	next2				;branch if doesn't exist

	;
	; Set the delay list
	;
	;	mov	dx, ax
	;	andnf	cx, TRUE
	;	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	cx, ax
	mov	ax, MSG_PREF_BOOLEAN_GROUP_SET_ORIGINAL_STATE
	mov	si, offset KeyboardAltGrList
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage

next2:
	push	ds
	mov	cx, cs
	mov	dx, offset ShiftRKey		;cx:dx <- key
	mov	ds, cx
	mov	si, offset typematicCategory	;ds:si <- category
	call	InitFileReadBoolean
	pop	ds
	jc	next3				;branch if doesn't exist

	;	mov	dx, ax
	;	andnf	cx, TRUE
	;	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	cx, ax
	mov	ax, MSG_PREF_BOOLEAN_GROUP_SET_ORIGINAL_STATE
	mov	si, offset KeyboardCapsLockList
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage

next3:
	push	ds
	mov	cx, cs
	mov	dx, offset SwaptCKey		;cx:dx <- key
	mov	ds, cx
	mov	si, offset typematicCategory	;ds:si <- category
	call	InitFileReadBoolean
	pop	ds
	jc	done				;branch if doesn't exist

	;	mov	dx, ax
	;	andnf	cx, TRUE
	;	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	cx, ax
	mov	ax, MSG_PREF_BOOLEAN_GROUP_SET_ORIGINAL_STATE
	mov	si, offset KeyboardCtrlList
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage

done:
	ret
PrefKbdDialogOpen		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefKbdDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "OK" in "Keyboard" section.

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of PrefKbdDialogClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefKbdDialogApply		method dynamic PrefKbdDialogClass,
						MSG_GEN_APPLY
	mov	di, offset PrefKbdDialogClass
	call	ObjCallSuperNoLock
	;
	; Get the state of the Keyboard Delay list
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset KeyboardDelayList
	call	ObjCallInstanceNoLock
	cmp	ax, GIGS_NONE			;none selected?
	jne	notNoneDelay
	mov	ax, KBD_DELAY_MEDIUM
notNoneDelay:
	push	ax
	;
	; Get the state of the Keyboard Delay list
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset KeyboardRepeatList
	call	ObjCallInstanceNoLock
	cmp	ax, GIGS_NONE			;none selected?
	jne	notNoneRepeat
	mov	ax, KBD_REPEAT_MEDIUM
notNoneRepeat:
	;
	; Write the results to the geos.ini file
	;
	pop	bp
	ornf	bp, ax				;bp <- typematic rate
	mov	cx, cs
	mov	dx, offset typematicKey		;cx:dx <- key
	mov	ds, cx
	mov	si, offset typematicCategory	;ds:si <- category
	call	InitFileWriteInteger
	ret
PrefKbdDialogApply		endm

typematicCategory	char	"keyboard", 0
typematicKey		char	"keyboardTypematic", 0
AltGrKey		char	"keyboardAltGr", 0
ShiftRKey		char	"keyboardShiftRelease", 0
SwaptCKey		char	"keyboardSwapCtrl", 0



PrefKbdCode	ends
