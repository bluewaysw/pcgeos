COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		chooseui
FILE:		chooseUI.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	This file contains a ui chooser application

	$Id: chooseUI.asm,v 1.1 97/04/04 15:35:22 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_ChooseUI		= 1

_Application		= 1

;
; Standard include files
;
include	type.def
include	geos.def
include geode.def
include	geodeBuild.def
include	opaque.def
include	geosmacro.def
include	errorcheck.def
include	library.def

include object.def
include	graphics.def
include	win.def
include lmem.def
include event.def
include timer.def
include processClass.def	; need for ui.def

include localization.def	; for Resources file
include win.def

include coreBlock.def

;------------------------------------------------------------------------------
;			Resource Definitions
;------------------------------------------------------------------------------

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

USE_DM		=	0

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

ChooseUIClass	class	GenProcessClass
METHOD_OPEN_LOOK	message
METHOD_MOTIF		message
METHOD_CUA		message
METHOD_DESK_MATE	message
ChooseUIClass	endc

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		chooseUI.rdef

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

	ChooseUIClass	mask CLASSF_NEVER_SAVED

idata	ends

;---------------------------------------------------

udata	segment

initUI	db	GEODE_NAME_SIZE dup(?)

udata	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

CommonCode segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ChooseUIOpenLook -- METHOD_OPEN_LOOK for ChooseUIClass

DESCRIPTION:	-

PASS:
	ds - dgroup of geode
	es - dgroup

	ax - Method

	cx - ?
	dx - ?
	bp - ?
	si - ?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@


OpenLookName	char	'ol      '
MotifName	char	'motif   '
CUAName		char	'cua     '

uiNames		word	OpenLookName, MotifName, CUAName
if	USE_DM
		word	DeskMateName
endif

uiEntries	lptr	OpenLookEntry, MotifEntry, CUAEntry
if	USE_DM
		word	DeskMateEntry
endif

ChooseUIOpenLook	method	ChooseUIClass, METHOD_OPEN_LOOK
	mov	di,offset CommonCode:OpenLookName
	call	SetSpecificUI
	ret
ChooseUIOpenLook	endp

ChooseUIMotif	method	ChooseUIClass, METHOD_MOTIF
	mov	di,offset CommonCode:MotifName
	call	SetSpecificUI
	ret
ChooseUIMotif	endp

ChooseUICUA	method	ChooseUIClass, METHOD_CUA
	mov	di,offset CommonCode:CUAName
	call	SetSpecificUI
	ret
ChooseUICUA	endp

if	USE_DM

ChooseUIDeskMate	method ChooseUIClass, METHOD_DESK_MATE
	mov	di,offset CommonCode:DeskMateName
	call	SetSpecificUI
	ret

DeskMateName	char	'dm      '

ChooseUIDeskMate	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetSpecificUI

DESCRIPTION:	Set the given UI

CALLED BY:	INTERNAL

PASS:
	di - offset of name of specific UI (in CommonCode)

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

SetSpecificUI	proc	near

	; get ui's protocol

	push	di
	mov	bx, handle ui
	call	GeodeGetGeodeVersion
	mov	ax,si			;ax = protocol major
	mov	bx,di			;bx - protocol minor
	pop	di

	; try to use the library

	segmov	es,cs			;es = CommonCode
	call	GeodeUseLibrary
	jc	SSUI_ret		;if error then abort

	; send method to the field object to change UI's

	push	bx			;save UI handle

	call	GeodeGetProcessHandle
	call	GeodeGetAppObject

	; cat OD of field

	mov	ax, METHOD_VUP_QUERY
	mov	cx, VUQ_FIELD_OBJECT
	mov	di, mask MF_CALL
	call	ObjMessage
	ERROR_NC	0xffff

	mov	bx, cx
	mov	si, dx

	pop	dx			;pass handle in dx
	mov	ax,METHOD_SETUP
	call	ObjMessage

SSUI_ret:
	ret

SetSpecificUI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseUIOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the current specific UI and set our objects
		to match before coming up.

CALLED BY:	METHOD_UI_OPEN_APPLICATION
PASS:		es	= dgroup
		ds	= dgroup
		bp	= state block
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/22/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChooseUIOpenApplication	method	ChooseUIClass, METHOD_UI_OPEN_APPLICATION
		uses	ax, cx, dx, bp, bx, si
		.enter
		;
		; Query up the generic tree to find the UI used for
		; applications. This returns us the handle of the thing
		; in AX and the carry is set if the query was answered.
		;
		GetResourceHandleNS	ChooseUI, bx
		mov	si, offset ChooseUI
		mov	cx, GUQT_UI_FOR_APPLICATION
		mov	ax, METHOD_GUP_QUERY
		mov	di, mask MF_CALL
		call	ObjMessage
		jnc	noFindee
		;
		; Fetch out the name of the owning geode.
		;
		mov	bx, ax
		mov	cx, size initUI
		mov	si, offset initUI
		call	GeodeGetPermName
		;
		; Loop through the ui's to see if the current one is
		; known.
		; 
		push	es
		segmov	es, cs, di
		assume	es:CommonCode
		mov	bx, size uiNames - 2
scanLoop:
		mov	di, es:uiNames[bx]
		mov	cx, size initUI
		mov	si, offset initUI
		repe	cmpsb
		je	gotIt
		dec	bx
		dec	bx
		jns	scanLoop
		pop	es
		jmp	noFindee
gotIt:		
		;
		; We recognize the thing -- set the appropriate list entry
		; to be the current one.
		; 
		mov	dx, es:uiEntries[bx]
		pop	es			; Recover es to avoid
						;  annoying the EC code
		assume	es:dgroup

		GetResourceHandleNS	SpecificUIList, bx
		mov	cx, bx		
		mov	si, offset SpecificUIList
		mov	bp, mask LF_SUPPRESS_APPLY
		mov	ax, METHOD_GEN_LIST_SET_EXCL
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
noFindee:		
		;
		; Pass the buck to our superclass now everything's set up
		;
		.leave		; Restore all registers from entry
		mov	di, offset ChooseUIClass
		CallSuper	METHOD_UI_OPEN_APPLICATION
		ret
ChooseUIOpenApplication	endp

CommonCode	ends

end
