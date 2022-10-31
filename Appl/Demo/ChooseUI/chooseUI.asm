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
;include	type.def
include	geos.def
include geode.def
;include	geodeBuild.def
;include	opaque.def
;include	geosmacro.def
include resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include	win.def
include lmem.def
;include event.def
include timer.def
include Objects/processC.def	; need for ui.def

include localize.def		; for Resources file
include win.def

;include coreBlock.def

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
MSG_CHOOSEUI_OPEN_LOOK		message
MSG_CHOOSEUI_MOTIF		message
MSG_CHOOSEUI_CUA		message
MSG_CHOOSEUI_DESK_MATE		message
MSG_CHOOSEUI_APPLY_SELECTION	message
ChooseUIClass	endc

UiOption	etype	word

OPEN_LOOK	enum	UiOption
MOTIF		enum	UiOption
CUA		enum	UiOption
DESK_MATE	enum	UiOption

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

FUNCTION:	ChooseUIOpenLook -- MSG_CHOOSEUI_OPEN_LOOK for ChooseUIClass

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


OpenLookName	char	'openlook'
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

ChooseUIOpenLook	method	ChooseUIClass, MSG_CHOOSEUI_OPEN_LOOK
	mov	di,offset CommonCode:OpenLookName
	call	SetSpecificUI
	ret
ChooseUIOpenLook	endp

ChooseUIMotif	method	ChooseUIClass, MSG_CHOOSEUI_MOTIF
	mov	di,offset CommonCode:MotifName
	call	SetSpecificUI
	ret
ChooseUIMotif	endp

ChooseUICUA	method	ChooseUIClass, MSG_CHOOSEUI_CUA
	mov	di,offset CommonCode:CUAName
	call	SetSpecificUI
	ret
ChooseUICUA	endp

ChooseUIApplySelection	method	ChooseUIClass, MSG_CHOOSEUI_APPLY_SELECTION

	segmov	es, cs, di
	assume	es:CommonCode

	sal	cx, 1
	mov	bx, cx
	mov	di, es:uiNames[bx]
	call	SetSpecificUI

	ret
ChooseUIApplySelection	endp


if	USE_DM

ChooseUIDeskMate	method ChooseUIClass, MSG_CHOOSEUI_DESK_MATE
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
protocol	local	ProtocolNumber
	.enter

	; get ui's protocol

	push	di
	segmov	es, ss
	lea	di, protocol
	mov	bx, handle ui
	mov	ax, GGIT_GEODE_PROTOCOL
	call	GeodeGetInfo
	mov	ax, protocol.PN_major
	mov	bx, protocol.PN_minor

	pop	di

	; try to use the library

	segmov	ds,cs			;ds = CommonCode
	call	GeodeUseLibraryPermName
	jc	SSUI_ret		;if error then abort

	; send method to the field object to change UI's

	mov	dx, bx			;dx = UI handle
	
	push	si
	mov	ax, MSG_GEN_SYSTEM_SET_SPECIFIC_UI
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD 
	call	ObjMessage
	mov	cx, di			;cx <- ClassedEvent for field
	pop	si
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

SSUI_ret:
	.leave
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
ChooseUIOpenApplication	method	ChooseUIClass, MSG_GEN_PROCESS_OPEN_APPLICATION
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
		mov	ax, MSG_GEN_GUP_QUERY
		mov	di, mask MF_CALL
		call	ObjMessage
		jnc	noFindee
		;
		; Fetch out the name of the owning geode.
		;
		mov	bx, ax
		
		lea	di, ss:initUI
		mov	ax, GGIT_PERM_NAME_ONLY
		call	GeodeGetInfo
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

		mov	ax, bx
		sar	ax, 1
		mov	cx, ax	
		clr	dx	
		GetResourceHandleNS	SpecificUIList, bx
		mov	si, offset SpecificUIList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
noFindee:		
		;
		; Pass the buck to our superclass now everything's set up
		;
		.leave		; Restore all registers from entry
		mov	di, offset ChooseUIClass
		CallSuper	MSG_GEN_PROCESS_OPEN_APPLICATION
		ret
ChooseUIOpenApplication	endp

CommonCode	ends

end
