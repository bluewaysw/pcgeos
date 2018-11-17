COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiEditBar.asm
FILE:		uiEditBar.asm

AUTHOR:		Gene Anderson, May 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/12/92		Initial revision

DESCRIPTION:
	

	$Id: uiEditBar.asm,v 1.1 97/04/07 11:12:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSEditBarControlClass
	EBCEditBarClass
SpreadsheetClassStructures	ends

;---------------------------------------------------

EditBarControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the EditBarControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCGetInfo	method dynamic SSEditBarControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset EBC_dupInfo
	FALL_THRU	CopyDupInfoCommon
EBCGetInfo	endm

CopyDupInfoCommon	proc	far
EC <	push	bp, ax				;>
EC <	mov	bp, sp				;>
EC <	mov	ax, cs				;ax <- our segment >
EC <	cmp	ss:[bp][4].segment, ax		;4 is for saved regs >
EC <	ERROR_NE CONTROLLER_UTILITY_ROUTINE_MUST_BE_CALLED_FROM_SAME_SEGMENT >
EC <	pop	bp, ax				;>
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
CopyDupInfoCommon	endp

EBC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY or mask GCBF_EXPAND_TOOL_WIDTH_TO_FIT_PARENT,
					; GCBI_flags
	EBC_IniFileKey,			; GCBI_initFileKey
	EBC_gcnList,			; GCBI_gcnList
	length EBC_gcnList,		; GCBI_gcnCount
	EBC_notifyTypeList,		; GCBI_notificationList
	length EBC_notifyTypeList,	; GCBI_notificationCount
	EBCName,			; GCBI_controllerName

	handle EditBarControlUI,	; GCBI_dupBlock
	EBC_childList,			; GCBI_childList
	length EBC_childList,		; GCBI_childCount
	EBC_featuresList,		; GCBI_featuresList
	length EBC_featuresList,	; GCBI_featuresCount
	SSEBC_DEFAULT_FEATURES,		; GCBI_features

	handle EditBarControlToolUI,	; GCBI_toolBlock
	EBC_toolList,			; GCBI_toolList
	length EBC_toolList,		; GCBI_toolCount
	EBC_toolFeaturesList,		; GCBI_toolFeaturesList
	length EBC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SSEBC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures


if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

EBC_IniFileKey	char	"editbar", 0

EBC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_ACTIVE_CELL_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_EDIT_BAR_CHANGE>

EBC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_ACTIVE_CELL_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_EDIT_BAR_CHANGE>
;---

EBC_childList	GenControlChildInfo	\
	<offset GotoDB, mask SSEBCF_GOTO_CELL, mask  GCCF_IS_DIRECTLY_A_FEATURE>
; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

EBC_featuresList	GenControlFeaturesInfo	\
	<offset GotoDB, GotoDBName, 0>

;---

EBC_toolList	GenControlChildInfo	\
	<offset GotoCellEdit, mask SSEBCTF_GOTO_CELL, \
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GotoCellButton, mask SSEBCTF_GOTO_CELL_BUTTON, \
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset EditIcons, mask SSEBCTF_EDIT_ICONS, \
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset EditBar, mask SSEBCTF_EDIT_BAR, \
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset BackspaceButton, mask SSEBCTF_BACKSPACE_BUTTON, \
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset FilterSelector, mask SSEBCTF_FILTER_SELECTOR, \
					mask GCCF_IS_DIRECTLY_A_FEATURE>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

EBC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GotoCellEdit, GotoCellName, 0>,
	<offset GotoCellButton, GotoCellButtonName, 0>,
	<offset EditIcons, EditIconsName, 0>,
	<offset EditBar, EditBarName, 0>,
	<offset BackspaceButton, BackspaceButtonName, 0>,
	<offset FilterSelector, FilterSelectorName, 0>


if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for the EditBarControl
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCUpdateUI	method dynamic SSEditBarControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	;
	; Get notification data
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	bx
	call	MemLock
	mov	dx, ax				;dx <- seg addr of notification
	mov	es, ax				;es <- seg addr of notification

	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	ax, ss:[bp].GCUUIP_toolboxFeatures

	cmp	ss:[bp].GCUUIP_changeType, GWNT_SPREADSHEET_EDIT_BAR_CHANGE
	LONG	je	editBarUpdate

	; make sure that the font of the text in edit bar is the
	; current font

	;
	; Any "Goto" tool?
	;
	test	ax, mask SSEBCTF_GOTO_CELL
	jz	noGotoTool
	push	bp
	mov	bp, offset NSSACC_text		;dx:bp <- ptr to text
	mov	di, offset GotoCellEdit		;^lbx:di <- text object
	call	EBC_SetText
	pop	bp
noGotoTool:
	;
	; Any "Goto" button?
	;
	test	ax, mask SSEBCTF_GOTO_CELL_BUTTON
	jz	noGotoButton
	mov	cx, offset NSSACC_text		;dx:cx <- ptr to text
	mov	di, offset GotoCellButton	;^lbx:di <- text object
	call	EBC_SetMoniker
noGotoButton:
	;
	; Any "Goto" DB?
	;
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	ax, ss:[bp].GCUUIP_features
	test	ax, mask SSEBCF_GOTO_CELL
	jz	noGotoDB	
	mov	bp, offset NSSACC_text		;dx:bp <- ptr to text
	mov	di, offset GotoDBCellEdit	;^lbx:di <- text object
	call	EBC_SetText
	call	EBC_SelectText			;select the new cell ref text
		
noGotoDB:
	jmp	done

editBarUpdate:
	;
	; Any "Edit Bar" tool?
	;
	test	ax, mask SSEBCTF_EDIT_BAR
	jz	noEditBar
	;
	; Is the edit bar dirty?  If so, ignore this update
	; so we don't obliterate what the user is typing.
	;
	call	EBC_CheckModified
	jnz	done				;branch if modified
	;
	; Update the edit bar
	;
	mov	bp, offset NSSEBC_text		;dx:bp <- ptr to text
	mov	di, offset EditBar		;di <- text object
if _PROTECT_CELL
	call	EBC_EnableDisable		;enable/disable the text obj
endif
	call	EBC_SetText
	;
	; Set the edit bar not user modified
	;
	call	EBC_NotModified
noEditBar:

done:
	;
	; All done...clean up
	;
	pop	bx
	call	MemUnlock

	ret
EBCUpdateUI	endm

;---

EBC_CheckModified	proc	near
	uses	ax, si
	.enter

	push	ax, si
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	si, offset EditBar		;^lbx:si <- OD of edit bar
	call	EBC_ObjMessageCall
	pop	ax, si
	tst	cx				;user modified?

	.leave
	ret
EBC_CheckModified	endp

EBC_NotModified	proc	near
	uses	ax, si
	.enter
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	mov	si, offset EditBar		;^lbx:si <- OD of edit bar
	call	EBC_ObjMessageCall
	.leave
	ret
EBC_NotModified	endp

if _PROTECT_CELL
EBC_EnableDisable	proc	near
		uses	ax, cx, si, dx, bp
		.enter
	;
	; enable or disable the Edit bar text field based on the protection
	; flag. If the cell is unprotected, enable the text; otherwise, disable
	; the text.
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED	;assume disable
		push	ds
		mov	ds, dx				;ds = notification seg
		test	ds:[NSSEBC_miscData], mask SSEBCMD_PROTECTION
		pop	ds
		jnz	msgSet				;jump if cell protected
		mov	ax, MSG_GEN_SET_ENABLED
msgSet:
		mov	si, di
		mov	dl, VUM_NOW
		call	EBC_ObjMessageCall
		.leave
		ret
EBC_EnableDisable	endp
endif

EBC_SetText	proc	near
	uses	ax, cx, si, dx, bp
	.enter
	;
	; the text message can destroy cx, dx, bp
	;
	mov	si, di				;^lbx:si <- OD of text object
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				;cx <- text is NULL-terminated
	call	EBC_ObjMessageCall

	.leave
	ret
EBC_SetText	endp

EBC_SetMoniker	proc	near
	uses	ax, cx, si, dx, bp
	.enter
	;
	; the text message can destroy cx, dx, bp
	;
	xchg	cx, dx				; cx:dx = fptr to string	
	mov	bp, VUM_NOW
	mov	si, di				;^lbx:si <- OD of text object
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	call	EBC_ObjMessageCall

	.leave
	ret
EBC_SetMoniker	endp

EBC_SelectText	proc	near
	uses	ax, cx, si, dx, bp
	.enter
	;
	; the text message can destroy cx, dx, bp
	;
	mov	si, di				;^lbx:si <- OD of text object
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	call	EBC_ObjMessageCall

	.leave
	ret
EBC_SelectText	endp

DisEnableEditIcons	proc	near
	uses	ax, dx, si
	.enter

	push	ax
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	mov	si, offset EnterIcon
	call	EBC_ObjMessageSend
	pop	ax
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	mov	si, offset CancelIcon
	call	EBC_ObjMessageSend

	.leave
	ret
DisEnableEditIcons	endp

DisEnableBackspaceButton	proc	near
	uses	ax, dx, si
	.enter

	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	mov	si, offset BackspaceButton
	call	EBC_ObjMessageSend

	.leave
	ret
DisEnableBackspaceButton	endp

DisEnableFilterSelector	proc	near
	uses	ax, dx, si
	.enter

	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	mov	si, offset FilterSelector
	call	EBC_ObjMessageSend

	.leave
	ret
DisEnableFilterSelector	endp

EBC_ObjMessageSend	proc	near
	uses	di
	.enter

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
EBC_ObjMessageSend	endp

EBC_ObjMessageCall	proc	near
	uses	di
	.enter

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
EBC_ObjMessageCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRCValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set row/column GenValues from row/column text

CALLED BY:	INTERNAL
			EBCUpdateUI
PASS:		*ds:si = controller
		dx:bp = row/column text
		bx = child block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCTextGainedFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle gaining the focus
CALLED BY:	MSG_META_GAINED_FOCUS_EXCL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of EBCEditBarClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCTextGainedFocus	method dynamic EBCEditBarClass, \
						MSG_META_GAINED_FOCUS_EXCL
	;
	; Let our superclass do its thing
	;
	mov	di, offset EBCEditBarClass
	call	ObjCallSuperNoLock
	;
	; Save our focus state
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].EBCI_flags, mask SSEBCF_IS_FOCUS
	;
	; If we have any icons, call the controller enable them
	;
	movdw	bxsi, ds:[OLMBH_output]
	mov	ax, MSG_SSEBC_DIS_ENABLE_EDIT_ICONS
	mov	cx, MSG_GEN_SET_ENABLED
	call	EBC_ObjMessageCall
	ret
EBCTextGainedFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCTextLostFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle losing the focus
CALLED BY:	MSG_META_LOST_FOCUS_EXCL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of EBCEditBarClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCTextLostFocus	method dynamic EBCEditBarClass, \
						MSG_META_LOST_FOCUS_EXCL
	;
	; Let our superclass do its thing
	;
	mov	di, offset EBCEditBarClass
	call	ObjCallSuperNoLock
	;
	; Update our focus state
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].EBCI_flags, not (mask SSEBCF_IS_FOCUS)
	;
	; If we have any icons, call the controller to disable them
	;
	movdw	bxsi, ds:[OLMBH_output]
	mov	ax, MSG_SSEBC_DIS_ENABLE_EDIT_ICONS
	mov	cx, MSG_GEN_SET_NOT_ENABLED
	call	EBC_ObjMessageCall
	ret
EBCTextLostFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCTextGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current flags for EditBar text object
CALLED BY:	MSG_EBC_TEXT_EDIT_GET_FLAGS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of EBCEditBarClass
		ax - the message
RETURN:		cl - SSEditBarControlFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCTextGetFlags	method dynamic EBCEditBarClass, \
						MSG_EBC_TEXT_EDIT_GET_FLAGS
	mov	cl, ds:[di].EBCI_flags		;cl <- EditBarControlFlags
	ret
EBCTextGetFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCEditKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle keypress in the edit bar
CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of EBCEditBarClass
		ax - MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCEditKbdChar	method dynamic EBCEditBarClass, \
						MSG_META_KBD_CHAR
SBCS<	cmp	ch, CS_CONTROL			;control key?	>
DBCS<	cmp	ch, CS_CONTROL_HB		;control key?	>
	jne	callSuper			;branch if not a control key

	test	dl, mask CF_STATE_KEY or \
		    mask CF_TEMP_ACCENT
	jnz	callSuper

	call	EBCCheckShortcut		;shortcut?
	jnc	callSuper			;branch if not found

	test	dl, mask CF_RELEASE		;release or press?
	jnz	quit				;ignore releases on shortcuts
	call	cs:EBCKbdActions[di]		;call handler routine
	jnc	callSuper			;branch if not handled
quit:
	.leave
	ret

callSuper:
	mov	di, offset EBCEditBarClass	;es:di <- ptr to class
	call	ObjCallSuperNoLock
	jmp	quit
EBCEditKbdChar	endm

EBCCancel	proc	near
	movdw	bxsi, ds:[OLMBH_output]
	mov	ax, MSG_SSEBC_CANCEL_DATA
	call	EBC_ObjMessageCall
	stc					;carry <- press handled
	ret
EBCCancel	endp

EBCEnterNoPass	proc	near
	clr	bp
	FALL_THRU EBCEnter
EBCEnterNoPass	endp
		
EBCEnter	proc	near

	movdw	bxsi, ds:[OLMBH_output]
	mov	ax, MSG_SSEBC_ENTER_DATA
	call	EBC_ObjMessageCall
	stc				;carry <- press handled
	ret
EBCEnter	endp

EBCEnterAndPass	proc	near
	;
	; Record the keyboard event
	;
	mov	bx, segment SpreadsheetClass
	mov	si, offset SpreadsheetClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	bp, di				; kbd event

	GOTO	EBCEnter
EBCEnterAndPass	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCCheckStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're at the start of the edit bar

CALLED BY:	EBCEditKbdChar()
PASS:		*ds:si - EBCEditBar object
		ax - MSG_META_KBD_CHAR
		cx, dx, bp - values for MSG_META_KBD_CHAR
RETURN:		carry - set if at start of edit bar
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EBCCheckStart		proc	near
	mov	bx, ds:LMBH_handle		;^lbx:si <- OD of text object
	push	ax, cx, dx, bp
	;
	; Get the current selection
	;
	sub	sp, (size VisTextRange)
	mov	bp, sp				;ss:bp <- ptr to VisTextRange
	call	GetSelection
	mov	bx, ss:[bp].VTR_start.low	;bx <- start of selection
	add	sp, (size VisTextRange)
	;
	; If we're at the start, enter data and go...
	;
	pop	ax, cx, dx, bp
	tst	bx				;at start?
	jne	notStart			;branch (carry clear)
	call	EBCEnterAndPass
notStart:
	ret
EBCCheckStart		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCCheckEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're at the end of the edit bar

CALLED BY:	EBCEditKbdChar()
PASS:		*ds:si - EBCEditBar object
		ax - MSG_META_KBD_CHAR
		cx, dx, bp - values for MSG_META_KBD_CHAR
RETURN:		carry - set if at end of edit bar
DESTROYED:	bx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EBCCheckEnd		proc	near
	mov	bx, ds:LMBH_handle		;^lbx:si <- OD of text object
	push	ax, cx, dx, bp
	;
	; Get the current selection
	;
	sub	sp, (size VisTextRange)
	mov	bp, sp				;ss:bp <- ptr to VisTextRange
	call	GetSelection
	mov	dx, ss:[bp].VTR_end.low		;bx <- end of selection
	add	sp, (size VisTextRange)
	;
	; Get the length
	;
	push	dx
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	EBC_ObjMessageCall		;dx:ax <- length of text
EC <	tst	dx				;>
EC <	ERROR_NZ VISIBLE_POSITION_TOO_LARGE	;>
	pop	bx
	sub	bx, ax				;bx <- position - length
	;
	; If we're at the end, enter data and go...
	;
	pop	ax, cx, dx, bp
	tst	bx				;at end?
	jne	notEnd				;branch (carry clear)
	call	EBCEnterAndPass
notEnd:
	ret
EBCCheckEnd		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCCheckShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the keypress is an edit bar shortcut
CALLED BY:	EBCKbdChar()

PASS:		ax - MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code
RETURN:		carry - set if shortcut
		di - offset of shortcut in table
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCCheckShortcut	proc	near
	uses	ax, ds, si
	.enter

	mov	ax, (length EBCKbdShortcuts)
	mov	si, offset EBCKbdShortcuts
	segmov	ds, cs
	call	FlowCheckKbdShortcut
	mov	di, si				;di <- offset of shortcut

	.leave
	ret
EBCCheckShortcut	endp

	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;

if DBCS_PCGEOS
EBCKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0,  C_SYS_ESCAPE and mask KS_CHAR>,	;<Esc>
	<0, 0, 0, 0,  C_SYS_TAB    and mask KS_CHAR>,	;<Tab>
	<0, 0, 0, 1,  C_SYS_TAB    and mask KS_CHAR>,	;<Shift-Tab>
	<0, 0, 0, 0,  C_SYS_ENTER  and mask KS_CHAR>,	;<Enter>
	<0, 0, 0, 1,  C_SYS_ENTER  and mask KS_CHAR>,	;<Shift-Enter>
	<0, 0, 0, 0,  C_SYS_UP     and mask KS_CHAR>,	;<UpArrow>
	<0, 0, 0, 0,  C_SYS_DOWN   and mask KS_CHAR>,	;<DownArrow>
	<0, 0, 1, 0,  C_SYS_UP	   and mask KS_CHAR>,	;<Ctrl-Up>
	<0, 0, 1, 0,  C_SYS_DOWN   and mask KS_CHAR>,	;<Ctrl-Down>
	<0, 0, 1, 0,  C_SYS_LEFT   and mask KS_CHAR>,	;<Ctrl-Left>
	<0, 0, 1, 0,  C_SYS_RIGHT  and mask KS_CHAR>,	;<Ctrl-Right>
	<0, 0, 0, 0,  C_SYS_PREVIOUS and mask KS_CHAR>,	;<PageUp>
	<0, 0, 0, 0,  C_SYS_NEXT     and mask KS_CHAR>,	;<PageDown>
	<0, 0, 1, 0,  C_SYS_PREVIOUS and mask KS_CHAR>,	;<Ctrl-PageUp>
	<0, 0, 1, 0,  C_SYS_NEXT     and mask KS_CHAR>,	;<Ctrl-PageDown>
	<0, 0, 0, 0,  C_SYS_LEFT   and mask KS_CHAR>,	;<LeftArrow>
	<0, 0, 0, 0,  C_SYS_RIGHT  and mask KS_CHAR>,	;<RightArrow>
	<0, 0, 1, 0,  C_SYS_ENTER  and mask KS_CHAR>	;<Ctrl><Enter>
else

EBCKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_ESCAPE>,		;<Esc>
	<0, 0, 0, 0, 0xf, VC_TAB>,		;<Tab>
	<0, 0, 0, 1, 0xf, VC_TAB>,		;<Shift-Tab>
	<0, 0, 0, 0, 0xf, VC_ENTER>,		;<Enter>
	<0, 0, 0, 1, 0xf, VC_ENTER>,		;<Shift-Enter>
	<0, 0, 0, 0, 0xf, VC_UP>,		;<UpArrow>
	<0, 0, 0, 0, 0xf, VC_DOWN>,		;<DownArrow>
	<0, 0, 1, 0, 0xf, VC_UP>,		;<Ctrl-Up>
	<0, 0, 1, 0, 0xf, VC_DOWN>,		;<Ctrl-Down>
	<0, 0, 1, 0, 0xf, VC_LEFT>,		;<Ctrl-Left>
	<0, 0, 1, 0, 0xf, VC_RIGHT>,		;<Ctrl-Right>
	<0, 0, 0, 0, 0xf, VC_PREVIOUS>,		;<PageUp>
	<0, 0, 0, 0, 0xf, VC_NEXT>,		;<PageDown>
	<0, 0, 1, 0, 0xf, VC_PREVIOUS>,		;<Ctrl-PageUp>
	<0, 0, 1, 0, 0xf, VC_NEXT>,		;<Ctrl-PageDown>
	<0, 0, 0, 0, 0xf, VC_LEFT>,		;<LeftArrow>
	<0, 0, 0, 0, 0xf, VC_RIGHT>,		;<RightArrow>
	<0, 0, 1, 0, 0xf, VC_ENTER>		;<Ctrl><Enter>

endif


EBCKbdActions nptr \
	offset EBCCancel,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCEnterAndPass,
	offset EBCCheckStart,
	offset EBCCheckEnd,
	offset EBCEnterNoPass
CheckHack <(length EBCKbdActions) eq (length EBCKbdShortcuts)>




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCEnterData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter data from the edit bar
CALLED BY:	MSG_SSEBC_ENTER_DATA

PASS:		*ds:si - instance data
		es - seg addr of SSEditBarControlClass
		ax - the message

		bp - keyboard event to send to spreadsheet, or zero if none.

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCEnterData	method dynamic SSEditBarControlClass,
						MSG_SSEBC_ENTER_DATA
	call	SSCGetToolBlockAndTools
	;
	; See if any changes have been made.  If not, we're done
   	; !* Commenting this out to fix a bug that allowed illegally formated
   	; data to be entered into a cell from the edit bar on the 2nd try
   	; (see bug 38444.  PB 7/5/95   
   	; call	EBC_CheckModified
   	; jz	done				;branch if not modified

	mov	di, offset EditBar		;^lbx:di <- OD of text object

	mov	ax, MSG_SPREADSHEET_ENTER_DATA_WITH_EVENT
						;ax <- message to send
	call	GetSendText			;get text and send to ssheet
	;
	; Mark the edit bar as not modified
	;
	call	EBC_NotModified
done::
	ret
EBCEnterData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCCancelData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel changes to data in edit abr

CALLED BY:	MSG_SSEBC_CANCEL_DATA
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/31/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EBCCancelData		method dynamic SSEditBarControlClass,
						MSG_SSEBC_CANCEL_DATA
	call	SSCGetToolBlockAndTools
	;
	; Mark the text as not modified so the notification isn't ignored
	;
	call	EBC_NotModified
	;
	; Force the controller to send a new notification
	;
	mov	ax, MSG_GEN_RESET
	call	ObjCallInstanceNoLock
	ret
EBCCancelData		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCInitiateEditBarDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Brings up the "Goto Cell" dialog box

CALLED BY:	MSG_SSEBC_INITIATE_GOTO_CELL_DB

PASS:		*ds:si	= SSEditBarContorlClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EBCInitiateEditBarDB	method dynamic SSEditBarControlClass, 
					MSG_SSEBC_INITIATE_GOTO_CELL_DB
		.enter
	;
	; Get pointer to Goto Dialog
	;
		call	SSCGetChildBlockAndFeatures
		tst	bx
		jnz	gotGotoDB
	;
	; If no child block yet, build it now
	;
		mov	ax, MSG_GEN_CONTROL_GENERATE_UI
		call	ObjCallInstanceNoLock
		call	SSCGetChildBlockAndFeatures
gotGotoDB:
	;
	; If the feature exists, initiate the dialog!
	;
		test	ax, mask SSEBCF_GOTO_CELL
		jz	noGotoDB		
		mov	si, offset GotoDB	;^lbx:si <- OD of text object
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	EBC_ObjMessageCall	
noGotoDB:
		.leave
		ret
EBCInitiateEditBarDB	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCInitialKeypress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle initial keypress that begins editing
CALLED BY:	MSG_SSEBC_INITIAL_KEYPRESS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCInitialKeypress	method dynamic SSEditBarControlClass, \
						MSG_SSEBC_INITIAL_KEYPRESS
	call	SSCGetToolBlockAndTools
	test	ax, mask SSEBCTF_EDIT_BAR	;any edit bar?
	jz	done				;branch if no edit bar
	;
	; If we have an edit bar:
	; (1) select all the text
	; (2) send the keypress to it
	; (3) tell it to grab the focus
	; changed 6/27/94-brianc to work with FEP:
	; (1) select all the text
	; (2) tell it to grab the focus
	; (3) send the keypress to it
	;
	mov	si, offset EditBar
if _PROTECT_CELL
	;
	; We don't want to get any keyboard input when the cell is protected,
	; so ignore the input when the text field is disabled.
	;
	push	cx, dx, bp
	mov	ax, MSG_GEN_GET_ENABLED
	call	EBC_ObjMessageCall
	pop	cx, dx, bp
	jnc	done
endif
	push	cx, dx, bp
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	call	EBC_ObjMessageCall
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	EBC_ObjMessageCall
	pop	cx, dx, bp
	mov	ax, MSG_META_KBD_CHAR
	call	EBC_ObjMessageCall
done:
	ret
EBCInitialKeypress	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCPassKeypress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass a keypress on to the spreadsheet
CALLED BY:	MSG_SSEBC_PASS_KEYPRESS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCPassKeypress	method dynamic SSEditBarControlClass, \
						MSG_SSEBC_PASS_KEYPRESS
	mov	ax, MSG_META_KBD_CHAR
	call	SSCSendToSpreadsheet
	ret
EBCPassKeypress	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCEnableIcons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the edit icons
CALLED BY:	MSG_SSEBC_ENABLE_ICONS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/92		Initial version
	martin	7/13/93   	Added more features

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCEnableIcons	method dynamic SSEditBarControlClass, \
						MSG_SSEBC_DIS_ENABLE_EDIT_ICONS
		.enter
	;
	; Do we have any icons?
	;
		call	SSCGetToolBlockAndTools
		xchg	ax, cx			;ax <- MSG_GEN_SET_ENABLED
	;
	; If we have icons, enable them
	;
		test	cx, mask SSEBCTF_EDIT_ICONS
		jz	iconsDone
		call	DisEnableEditIcons

iconsDone:
	;
	; Do we have a backspace button?
	;
		test	cx, mask SSEBCTF_BACKSPACE_BUTTON
		jz	backspaceDone
		call	DisEnableBackspaceButton

backspaceDone:
	;
	; Do we have a mask selector?
	;
		test	cx, mask SSEBCTF_FILTER_SELECTOR
		jz	exit
		call	DisEnableFilterSelector

exit:
		.leave
		ret
EBCEnableIcons	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCGotoCellDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goto a cell, from the DB
CALLED BY:	MSG_SSEBC_GOTO_CELL_DB

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCGotoCellDB	method dynamic SSEditBarControlClass, \
						MSG_SSEBC_GOTO_CELL_DB
	call	SSCGetChildBlockAndFeatures
	mov	di, offset GotoDBCellEdit	;^lbx:di <- OD of text object
	mov	ax, MSG_SPREADSHEET_GOTO_CELL
	call	GetSendText
	ret
EBCGotoCellDB	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCGotoCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goto a cell
CALLED BY:	MSG_SSEBC_GOTO_CELL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EBCGotoCell	method dynamic SSEditBarControlClass, \
						MSG_SSEBC_GOTO_CELL
	call	SSCGetToolBlockAndTools
	mov	di, offset GotoCellEdit		;^lbx:di <- OD of text object
	mov	ax, MSG_SPREADSHEET_GOTO_CELL
	call	GetSendText
	ret
EBCGotoCell	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRCFromValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go to cell specified by R/C GenValue pair

CALLED BY:	UTILITY
PASS:		*ds:si = controller
		bx = child block
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSendText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text from an controller text object and send to the ssheet
CALLED BY:	UTILITY

PASS:		*ds:si - controller
		^lbx:di - OD of text object
		ax - message to send
RETURN:		none
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: assumes the spreadsheet message wants the text as:
		dx - handle of text block (NULL-terminated)
		cx - length of text (w/o NULL)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSendText	proc	near
	.enter

	;
	; Get the text from the object
	;
	push	si, ax
	mov	si, di				;^lbx:si <- OD of text object
	clr	dx				;dx <- alloc new block
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	call	EBC_ObjMessageCall
	mov	dx, cx				;dx <- new text block
	mov	cx, ax				;cx <- string length
	pop	si, ax
	;
	; Send the text to the Spreadsheet
	;
	call	SSCSendToSpreadsheet

	.leave
	ret
GetSendText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get flags about the state of the edit bar

CALLED BY:	MSG_SSEBC_GET_FLAGS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
RETURN:		cl - SSEditBarControlFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/31/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EBCGetFlags		method dynamic SSEditBarControlClass,
						MSG_SSEBC_GET_FLAGS
	call	SSCGetToolBlockAndTools
	clr	cl				;cl <- no flags
	test	ax, mask SSEBCTF_EDIT_BAR	;edit bar existeth?
	jz	noEditBar			;branch if not
	mov	si, offset EditBar		;^lbx:si <- OD of edit bar
	mov	ax, MSG_EBC_TEXT_EDIT_GET_FLAGS
	call	EBC_ObjMessageCall
noEditBar:
	ret
EBCGetFlags		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current selection range

CALLED BY:	EBCTextReplaceSelection(), AddOpIfNeeded(), etc.
PASS:		^lbx:si - OD of text
		ss:bp - ptr to VisTextRange
RETURN:		ss:bp - VisTextRange filled in
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelection		proc	far
	uses	ax, cx, dx
	.enter

	mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
	mov	dx, ss				;dx:bp <- VisTextRange
	call	EBC_ObjMessageCall
EC <	tst	ss:[bp].VTR_start.high		;>
EC <	ERROR_NZ	VISIBLE_POSITION_TOO_LARGE >
EC <	tst	ss:[bp].VTR_end.high		;>
EC <	ERROR_NZ	VISIBLE_POSITION_TOO_LARGE >

	.leave
	ret
GetSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSEBCGrabFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the focus (and give it to the edit bar)

CALLED BY:	MSG_SSEBC_GRAB_FOCUS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: this is done via a separate message rather than subclassing
	MSG_META_GRAB_FOCUS_EXCL because the "current cell" indicator can also
	have/grab the focus...
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSEBCGrabFocus		method dynamic SSEditBarControlClass,
						MSG_SSEBC_GRAB_FOCUS
	call	SSCGetToolBlockAndTools
	test	ax, mask SSEBCTF_EDIT_BAR
	jz	noEditBar
	mov	si, offset EditBar		;^lbx:si <- OD of edit bar
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	EBC_ObjMessageCall
noEditBar:
	ret
SSEBCGrabFocus		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSEBCPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle a paste by passing off to our text object

CALLED BY:	MSG_META_CLIPBOARD_PASTE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditBarControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSEBCPaste		method dynamic SSEditBarControlClass,
						MSG_META_CLIPBOARD_PASTE
	call	SSCGetToolBlockAndTools
	test	ax, mask SSEBCTF_EDIT_BAR
	jz	noEditBar
	mov	si, offset EditBar		;^lbx:si <- OD of edit bar

if _PROTECT_CELL
	;
	; If the EditBar is not-enabled, then don't paste.
	;
	call	EBCCheckEnabledEditBar
	jnc	error
endif		

	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	call	EBC_ObjMessageCall
	mov	ax, MSG_META_CLIPBOARD_PASTE
	call	EBC_ObjMessageCall
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	EBC_ObjMessageCall
noEditBar:
	ret

if _PROTECT_CELL
error:
	mov	ax, SST_ERROR
	call	UserStandardSound
	jmp	noEditBar
endif
SSEBCPaste		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSEBCNotifiedWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a handwriting notification by passing it off to our
		text object.

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK
PASS:		*ds:si	= SSEditBarControlClass object
		ds:di	= SSEditBarControlClass instance data
		ds:bx	= SSEditBarControlClass object (same as *ds:si)
		es 	= segment of SSEditBarControlClass
		ax	= message #
		cx:dx	= NotificationType
			cx - NT_manuf
			dx - NT_type
		^hbp	= SHARABLE data block having a "reference count" 
		       	  initialized via MemInitRefCount.

RETURN:		nothing

DESTROYED:	bx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSEBCNotifiedWithDataBlock	method dynamic SSEditBarControlClass, 
					MSG_META_NOTIFY_WITH_DATA_BLOCK
	;
	; We only want to pass this message on to our text object if it is
	; sent with the notification type, GWNT_TEXT_REPLACE_WITH_HWR.
	; Any other notification types should be passed on to our superclass.
	;
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_TEXT_REPLACE_WITH_HWR
	jne	callSuper

	call	SSCGetToolBlockAndTools
	test	ax, mask SSEBCTF_EDIT_BAR
	jz	noEditBar
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	si, offset EditBar		;^lbx:si <- OD of edit bar
	call	EBC_ObjMessageCall
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	EBC_ObjMessageCall

noEditBar:
	ret

callSuper:
	mov	di, offset SSEditBarControlClass
	GOTO	ObjCallSuperNoLock

SSEBCNotifiedWithDataBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSEBCContextNotif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle message by passing it off to our text object.

CALLED BY:	MSG_META_GENERATE_CONTEXT_NOTIFICATION
PASS:		*ds:si	= SSEditBarControlClass object
		ds:di	= SSEditBarControlClass instance data
		ds:bx	= SSEditBarControlClass object (same as *ds:si)
		es 	= segment of SSEditBarControlClass
		ax	= message #
		ss:bp	= GetContextParams (GCP_replyObj ignored)

RETURN:		nothing

DESTROYED:	bx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSEBCContextNotif	method dynamic SSEditBarControlClass, 
					MSG_META_GENERATE_CONTEXT_NOTIFICATION

	call	SSCGetToolBlockAndTools
	test	ax, mask SSEBCTF_EDIT_BAR
	jz	noEditBar

	mov	ax, MSG_META_GENERATE_CONTEXT_NOTIFICATION
	mov	si, offset EditBar		;^lbx:si <- OD of edit bar
	mov	di, mask MF_STACK or mask MF_CALL
	call	ObjMessage

noEditBar:
	ret

SSEBCContextNotif	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSEBCDeleteRangeOfChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle message by passing it off to our text object.

CALLED BY:	MSG_META_DELETE_RANGE_OF_CHARS
PASS:		*ds:si	= SSEditBarControlClass object
		ds:di	= SSEditBarControlClass instance data
		ds:bx	= SSEditBarControlClass object (same as *ds:si)
		es 	= segment of SSEditBarControlClass
		ax	= message #
		ss:bp	= VisTextRange (range of chars to delete)

RETURN:		nothing

DESTROYED:	bx, si, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSEBCDeleteRangeOfChars	method dynamic SSEditBarControlClass, 
					MSG_META_DELETE_RANGE_OF_CHARS

	call	SSCGetToolBlockAndTools
	test	ax, mask SSEBCTF_EDIT_BAR
	jz	noEditBar

	mov	ax, MSG_META_DELETE_RANGE_OF_CHARS
	mov	si, offset EditBar		;^lbx:si <- OD of edit bar
	mov	di, mask MF_STACK or mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	EBC_ObjMessageCall

noEditBar:
	ret

SSEBCDeleteRangeOfChars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSEBCSetNotEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the edit bar not modified, so that text doesn't
		remain across document closings, etc.

PASS:		*ds:si	- SSEditBarControlClassClass object
		ds:di	- SSEditBarControlClassClass instance data
		es	- segment of SSEditBarControlClassClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSEBCSetNotEnabled	method	dynamic	SSEditBarControlClass,
					MSG_GEN_SET_NOT_ENABLED
		mov	di, offset SSEditBarControlClass
		call	ObjCallSuperNoLock

		call	SSCGetToolBlockAndTools
		tst	bx
		jz	done

		test	ax, mask SSEBCTF_EDIT_BAR
		jz	done

		call	EBC_NotModified
done:
		ret
SSEBCSetNotEnabled	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColumnValueGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get text representation of current value

CALLED BY:	MSG_GEN_VALUE_GET_VALUE_TEXT
PASS:		*ds:si	= ColumnValueClass object
		ds:di	= ColumnValueClass instance data
		ds:bx	= ColumnValueClass object (same as *ds:si)
		es 	= segment of ColumnValueClass
		ax	= message #
		cx:dx	= buffer for text
		bp	= GenValueType
RETURN:		cx:dx	= buffer filled
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/28/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


EditBarControlCode ends

EditBarMouseCode segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EBCTextReplaceSelection

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_SPREADSHEET_REPLACE_TEXT_SELECTION)
		Sent by the ChooseFunction and ChooseName controllers.

PASS:		cx - length of text (0 for NULL-terminated)
		^hdx - handle of text
		dx - 0 to indicate that nothing should be appended at all
		bp.low - offset to new cursor position
			When the text is replaced, the cursor will be
		     positioned at the end of the new text, so the
		     offset will have to be 0 or less.
			A value > 0 means to select the new text.
		bp.high - UIFunctionsActive:
			UIFA_EXTEND - extend modifier down
			UIFA_ADJUST - adjust modifier down

RETURN:		handle freed

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

EBCTextReplaceSelection	method	dynamic	SSEditBarControlClass,
	MSG_SPREADSHEET_REPLACE_TEXT_SELECTION

	call	SSCGetToolBlockAndTools
	test	ax, mask SSEBCTF_EDIT_BAR
	LONG	jz	noEditBar			;branch if no edit bar

if _PROTECT_CELL
	mov	si, offset EditBar
	call	EBCCheckEnabledEditBar
	LONG jnc freeBlock
endif

	;
	; Make sure the edit bar has the focus (it will enable the icons)
	;
	push	cx, dx, bp
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	si, offset EditBar
	call	EBMC_ObjMessageCall
	pop	cx, dx, bp

	;
	; Check for no block passed, meaning append nothing, no select change
	;
	tst	dx
	jz	markModified

	;
	; An an operator if necessary
	;
	call	AddOpIfNeeded
	;
	; For getting the current selection...
	;
	mov	ax, bp				;ax <- offset, flags
	sub	sp, (size VisTextRange)
	mov	bp, sp
	push	ax				;save offset, flags
	;
	; If we want to select the new text, get the range of the
	; old selection and adjust it accordingly.
	;
	tst	al				;0 or less?
	jle	noNewSelect			;branch if 0 or less
	;
	; We adjust the new selection to start at the old start,
	; and end at the old start plus the length of the new.
	; This will select the new text (in theory...)
	;
	call	GetSelection
	tst	cx				;length passed?
	jnz	gotLength			;branch if length passed
	push	bx
	mov	bx, dx				;bx <- text block
	call	MemLock
	mov	es, ax
	clr	di				;es:di <- ptr to text
	call	LocalStringLength		;cx <- # chars
	call	MemUnlock
	pop	bx
gotLength:
	mov	ax, cx
	add	ax, ss:[bp].VTR_start.low	;ax <- start + length
	mov	ss:[bp].VTR_end.low, ax
noNewSelect:
	;
	; Paste the text
	;
	push	dx, bp
	mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION_BLOCK
	call	EBMC_ObjMessageCall
	pop	dx, bp
	;
	; Free the text
	;
	push	bx
	mov	bx, dx				;bx <- handle of text block
	call	MemFree
	pop	bx
	;
	; See if we need to adjust the selection
	;
	pop	ax				;al <- offset to select
	tst	al				;already adjusted?
	jg	doneAdjust			;branch if adjusted
	;
	; Adjust the new selection by the appropriate amount
	;
	call	GetSelection
	cbw					;ax <- adjustment
	neg	ax
	sub	ss:[bp].VTR_start.low, ax	;sub offset
	sub	ss:[bp].VTR_end.low, ax		;sub offset
doneAdjust:
	;
	; Set the new selection
	;
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	mov	dx, size VisTextRange
	call	EBMC_ObjMessageCall
	add	sp, size VisTextRange

markModified:
	;
	; Mark the text as user modified
	;
	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	call	EBMC_ObjMessageCall
noEditBar:
	ret

if _PROTECT_CELL
freeBlock:
	mov	bx, dx
	tst	bx		; On the off chance that there's no block
	jz	afterFree
	call	MemFree
afterFree:
	mov	ax, SST_ERROR
	call	UserStandardSound
	ret
endif
EBCTextReplaceSelection	endm


if _PROTECT_CELL
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBCCheckEnabledEditBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To check if the EditBar is enabled or disabled.

CALLED BY:	EBCTextReplaceSelection()
PASS:		^lbx:si	= EditBar object
		ds	= pointing to some object blocks
RETURN:		carry 	= set	-- EditBar is enabled
			  clear	-- EditBar is not-enabled
		ds	= updated
DESTROYED:	ax, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EBCCheckEnabledEditBar	proc	far
		uses	cx, dx, bp
		.enter
		Assert objectOD bxsi, GenTextClass

		mov	ax, MSG_GEN_GET_ENABLED
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		.leave
		ret
EBCCheckEnabledEditBar		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddOpIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an "=" or other operator to the edit bar if needed

CALLED BY:	EBCTextReplaceSelection()
PASS:		^lbx:si - OD of edit bar text object
		bp.high - UIFunctionsActive
			UIFA_EXTEND - extend modifier down
			UIFA_ADJUST - adjust modifier down
RETURN:		none
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Uses "mov dx, '+'" here to get char and C_NULL at same time.
		In SBCS version, AddCharToEditbar depends on this.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddOpIfNeeded		proc	near
	uses	bx, cx, dx
	.enter

	;
	; Get the length of the current text, if any
	;
	push	bp
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				;dx <- new block, please
	call	EBMC_ObjMessageCall
	pop	bp
	tst	ax
	jnz	checkOtherText
	;
	; There was no text -- add an "="
	;
addEqual:
	mov	dx, "="				;dx <- character to insert
addChar:
	call	AddCharToEditBar
done:
	.leave
	ret

checkOtherText:
	mov	dx, bp				;dh <- UIFunctionsActive
	;
	; Figure out where the selection is
	;
	push	bp
	sub	sp, (size VisTextRange)
	mov	bp, sp				;ss:bp <- ptr to VisTextRange
	call	GetSelection
	mov	di, ss:[bp].VTR_start.low	;di <- start of selection
	add	sp, (size VisTextRange)
	pop	bp
	tst	di				;at start of edit bar?
	jz	addEqual			;branch if at start
	;
	; Get the character before the selection
	;
	push	bx, ds
	mov	bx, cx				;bx <- handle of text
	call	MemLock
	mov	ds, ax				;ds <- seg addr of text
	dec	di				;di <- before selection start
DBCS<	shl	di, 1				;di <- byte offset last char >
	LocalGetChar ax, dsdi, NO_ADVANCE	;ax <- char before selection
	call	MemUnlock
	pop	bx, ds
	;
	; Special case ")" -- it needs another operator after it
	;
	LocalCmpChar	ax, ")"
	je	addOperator
	;
	; See if it is punctuation -- if so, we're done
	;
SBCS<	clr	ah							>
	call	LocalIsPunctuation
	jnz	done				;branch if punctuation
	;
	; Figure out what operator to stick in based on the modifiers
	;
addOperator:
	mov	al, dh				;al <- UIFunctionsActive
	mov	dx, ","
	test	al, mask UIFA_ADJUST		;<Ctrl>?
	jnz	addChar
	mov	dx, ":"
	test	al, mask UIFA_EXTEND		;<Shift>?
	jnz	addChar
	mov	dx, "+"				;default operator "+"
	jmp	addChar
AddOpIfNeeded		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddCharToEditBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a single character to the edit bar

CALLED BY:	AddCharIfNeeded()
PASS:		^lbx:si - OD
		dx - character to add
		^hcx - handle of text
RETURN:		cx - freed
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddCharToEditBar		proc	near
	uses	bx, bp
	.enter

	;
	; Resize the passed block to a reasonable size
	;
	push	bx, cx, ds
	mov	bx, cx				;bx <- handle of text
	mov	ax, (size word)*2		;ax <- size in bytes
	mov	ch, mask HAF_LOCK or \
		    mask HAF_ZERO_INIT		;ch <- HeapAllocFlags
	call	MemReAlloc
	mov	ds, ax				;ds <- seg addr of block
	mov	ds:[0], dx
DBCS <	mov	{wchar}ds:[2], C_NULL		;NULL-terminate 	>
	pop	bx, cx, ds
	;
	; Replace the selected text
	;
	push	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION_BLOCK
	mov	dx, cx				;dx <- handle of block
	clr	cx				;cx <- NULL-terminated
	call	EBMC_ObjMessageCall
	pop	bx
	;
	; Free the text block
	;
	call	MemFree

	.leave
	ret
AddCharToEditBar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EBMC_ObjMessageCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do an ObjMessage with MF_CALL and MF_FIXUP_DS

CALLED BY:	UTILITY
PASS:		^lbx:si - OD of object
		ax - message
		cx, dx, bp - data for message
RETURN:		ax, cx, dx, bp - depends on message
DESTROYED:	ax, cx, dx, bp - depends on message

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EBMC_ObjMessageCall		proc	near
	uses	di
	.enter

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
EBMC_ObjMessageCall		endp

EditBarMouseCode ends
