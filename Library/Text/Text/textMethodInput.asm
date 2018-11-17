COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989-1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:
FILE:		textMethodInput.asm

AUTHOR:		John Wedgwood, Oct 25, 1989

METHODS:
	Name			Description
	----			-----------
	MSG_META_KBD_CHAR
	MSG_META_START_SELECT
	MSG_META_PTR
	MSG_META_END_SELECT

	CharsetContentVisDraw	Draw a charset table
	CharsetContentSetSelection
				Set selection of the charset table in
				a vis content
	CharsetContentGetSelection
				Get seleection in charset table
	CharsetContentMetaFupKbdChar
				handle char press in the charset table
ROUTINES:
	Name			Description
	----			-----------
INT	VisTextHandleCharset	Handle Charset presses
INT	CheckProhibitInternationalCharacter
				Check if funny chars are prohibited
INT	CharsetChangeChar	Change character according to Charset strings
				(Resp only)
INT	CharsetGetCharBeforeCursor
INT	CharsetHandleStickyShift
INT	DisplayCharsetDialog
INT	CharsetGetCharacter	Find the special character from a table
				(Resp only)
INT	DrawCharacterAtPosition	Draw a character at a particular position
INT	DrawCharacterWithHighlight
				Draw a character with highlight rectangle

INT	CharsetFindMatchingItem	Find the first item that has the passed char
				as the underlying char (Resp only)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/25/89	Initial revision

DESCRIPTION:
	Input method handlers.

	$Id: textMethodInput.asm,v 1.2 98/03/24 21:20:04 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextSelect segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLostGadgetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle loss of gadget exclusive...

CALLED BY:	MSG_VIS_LOST_GADGET_EXCL
PASS:		ds:*si = ptr to instance data.
		es = segment of GenEditClass.
		ax = MSG_VIS_LOST_GADGET_EXCL.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLostGadgetExcl	method	VisTextClass, MSG_VIS_LOST_GADGET_EXCL

	call	TextSelect_DerefVis_DI

	;
	; if doing quick transfer feedback, just treat as if mouse pointer
	; left our bounds
	;
	test	ds:[di].VTI_intSelFlags, mask VTISF_DOING_DRAG_SELECTION
	jz	notDoingFeedback
	call	VisTextVisLeave			; stop grab, restore cursor
						; (clears DOING_DRAG_SELECTION)
notDoingFeedback:
	ret
VisTextLostGadgetExcl	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	TextMakeFocusAndTarget

DESCRIPTION:	Make a text object the target

CALLED BY:	VisTextQuickTransferMoveOrCopy, VisTextStartSelect

PASS:
	*ds:si - object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
TextMakeFocusAndTarget	proc	far
	class	VisTextClass

	call	FlowGetUIButtonFlags
	test	al, mask UIBF_CLICK_TO_TYPE
	jz	10$			; quit if real-estate model
	call	MetaGrabFocusExclLow
10$:

	call	TextSelect_DerefVis_DI
	test	ds:[di].VTI_state, mask VTS_TARGETABLE
	jz	20$
	call	MetaGrabTargetExclLow
20$:
	ret

TextMakeFocusAndTarget	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextVisLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle notification that mouse has left visible bounds
		of text object -- if providing feedback for a quick-transfer,
		stop that feedback

CALLED BY:	VisTextLostGadgetExcl
		TT_SetClipboardQuickTransferFeedback
		VisTextEndMoveCopy

PASS:		ds:*si - VisText object
		ds:di - VisText instance data

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/02/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextVisLeave	proc	far
	class	VisTextClass
	uses	ax, cx, dx, bp
	.enter
	test	ds:[di].VTI_intSelFlags, mask VTISF_DOING_DRAG_SELECTION
	jz	done				; not doing feedback
	call	VisReleaseMouse
	mov	ax, CQTF_CLEAR
	call	ClipboardSetQuickTransferFeedback
	call	TextSelect_DerefVis_DI
	andnf	ds:[di].VTI_intSelFlags, not mask VTISF_DOING_DRAG_SELECTION
done:
	.leave
	ret
VisTextVisLeave	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendAbortSearchSpellNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If a search/spell is in progress, sends an abort search/spell
		notification.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendAbortSearchSpellNotification	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, bp, di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	mov	al, ds:[di].VTI_intFlags
.assert	ASST_NOTHING_ACTIVE	eq	0
	and	al, mask VTIF_ACTIVE_SEARCH_SPELL
	je	exit
EC <	cmp	al, ActiveSearchSpellType shl offset VTIF_ACTIVE_SEARCH_SPELL>
EC <	ERROR_AE	BAD_VIS_TEXT_INT_FLAGS				>
	andnf	ds:[di].VTI_intFlags, not mask VTIF_ACTIVE_SEARCH_SPELL

	cmp	al, ASST_SPELL_ACTIVE shl offset VTIF_ACTIVE_SEARCH_SPELL
	mov	ax, MSG_ABORT_ACTIVE_SPELL
	je	10$
	mov	ax, MSG_ABORT_ACTIVE_SEARCH
10$:
	mov	di, mask MF_RECORD
	call	ObjMessage			;DI <- event handle
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE
	clr	ss:[bp].GCNLMP_block
	mov	ss:[bp].GCNLMP_event, di
	clr	ss:[bp].GCNLMP_flags
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx
exit:
	.leave
	ret
SendAbortSearchSpellNotification	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AbortHWRMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with aborting a macro or mode char. That is if
		the hwr library inserted character to temporarily
		display its state, this will abort that state and
		clean up those characters.

CALLED BY:	GLOBAL
PASS:		*ds:si	= VisText Object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Can delete characters from the text object.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AbortHWRMacro	proc	far
libHandle	local	hptr
protocolNumber	local	ProtocolNumber
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;
	; if this object does not accept ink, then just leave.
	;
	mov	ax, ATTR_VIS_TEXT_DOES_NOT_ACCEPT_INK
	call	ObjVarFindData
	jc	exit

	call	UserGetHWRLibraryHandle
	tst	ax
	jz	exit
	mov	ss:[libHandle], ax

	;
	; exit if this is not a current version of the hwr lib
	;
	mov_tr	bx, ax
	mov	ax, GGIT_GEODE_PROTOCOL
	segmov	es, ss
	lea	di, ss:[protocolNumber]
	call	GeodeGetInfo
	cmp	ss:[protocolNumber].PN_major, HWRLIB_PROTO_MAJOR_FOR_2_1
	jl	exit
	
	CallHWRLibrary	HWRR_RESET_MACRO
	push	ax

	tst	dx
	jz 	skipModeCharCleanup
	;
	; Delete one character backwards to remove the mode character.
	;
	push	bp
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_DELETE_BACKWARD_CHAR
	call	ObjCallInstanceNoLock
	pop	bp
skipModeCharCleanup:
	pop	ax
	tst	ax
	jz	exit
	;
	; clean up any string macro
	;
	push	bp
	call	GestureStringMacroFar
	pop	bp

exit:
	.leave
	ret
AbortHWRMacro	endp

TextSelect	ends

TextFilter	segment	resource


if not PZ_PCGEOS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfSmartQuotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if there are smart quotes.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if smartQuotes not enabled.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
textCategory	char	"text",0
textKey		char	"smartQuotes",0
CheckIfSmartQuotes	proc	near	uses	ds, si, cx, dx
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
	tst	ds:[uiSmartQuotes]
	jnz	noEnabledExit
	mov	cx, cs
	mov	ds, cx			;DS:SI <- category string
	mov	si, offset textCategory
	mov	dx, offset textKey	;CX:DX <- key string
	call	InitFileReadBoolean
	jc	exit
	tst	ax			;Clears carry...
	jnz	exit			;Exit if AX is non-zero (TRUE)
noEnabledExit:
	stc
exit:
	.leave
	ret
CheckIfSmartQuotes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSmartQuotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts quotes to be smart quotes, if that option is
		selected...

CALLED BY:	GLOBAL
PASS:		bl - TextFilters
		dh - ShiftStates
		dl - character
RETURN:		dl - character (possibly altered)
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSmartQuotes	proc	near
	class	VisTextClass
	.enter

DBCS <	push	di, bp							>

;	HANDLE "SMART QUOTES"

	call	CheckIfSmartQuotes
	jc	exit

						;AX <- single quotes
						;BX <- double quotes
	push	ds
	segmov	ds, dgroup, ax			;ds <- seg addr of vars
if DBCS_PCGEOS
	mov	ax, ds:uisqOpenSingle
	mov	di, ds:uisqCloseSingle
	mov	bx, ds:uisqOpenDouble
	mov	bp, ds:uisqCloseDouble
else
	mov	ax, {word}ds:uisqOpenSingle
	mov	bx, {word}ds:uisqOpenDouble
CheckHack <offset uisqCloseSingle eq offset uisqOpenSingle+1	>
CheckHack <offset uisqCloseDouble eq offset uisqOpenDouble+1	>
endif
	pop	ds

	cmp	dx, '\''
	je	singleQuote
	xchg	ax, bx				;AX <- double quotes
						; BX <- single quotes
DBCS <	xchg	di, bp				;DI <- close double	>
DBCS <						; BP <- close single 	>
singleQuote:
;
;        The Smart Quote algorithm is as follows:
;
;                A " or ' typed after a space, non-breaking space, tab, return,
;                (, [, {, or > is converted to an open quote or squote.
;
;                A " or ' typed after any other character is converted to a
;                close quote or squote, except:
;
;                        - a ' after an open quote is always an open squote
;
;                        - a " after an open squote is always an open quote
;
	push	ax, bx				;Save quote characters
	call	TSL_SelectGetSelection		;dx.ax <- start of range
						;cx.bx <- end of range
	mov	cx, dx
	or	cx, ax				;Z flag set if at document start
	pop	cx, bx				;Restore characters

	;
	; cx	= Quote characters
	; bx	= Quote characters
	; dx.ax	= Selection start position
	; Z flag set if the selection start is at the start of the document
	;
	jz	tryInsertChar			;If at start of document,
						; then use open quote.
	
	;
	; Get the character before select-start and see what class it falls 
	; into.
	;
	decdw	dxax				;Move to previous character
	call	TS_GetCharAtOffset		;al <- character at offset
;
;	SCAN LIST OF CHARACTERS THAT WE MAP TO OPEN QUOTES AFTER
;
	push	cx, es, di
	segmov	es, cs
	mov	di, offset openQuoteList
	mov	cx, offset endOpenQuoteList - offset openQuoteList
DBCS <	shr	cx, 1				;#bytes -> # chars	>
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	pop	cx, es, di
	je	tryInsertChar			;Insert the open quote
;
;	Do this check:
;
;                A " or ' typed after any other character is converted to a
;                close quote or squote, except:
;
;                        - a ' after an open quote is always an open squote
;
;                        - a " after an open squote is always an open quote
;
SBCS <	cmp	al, bl				;Is it the other kind of>
SBCS <						; open quote?		>
DBCS <	cmp	ax, bx							>
	je	tryInsertChar			;Branch if so
SBCS <	mov	cl, ch				;Insert the closed quote>
DBCS <	mov	cx, di							>
tryInsertChar:
	;
	; cl	= Quote character to use
	; DBCS: cx = Quote character to use
	;
SBCS < 	clr	ch				;CX <- new quote value	>
	mov	dx, cx
exit:

DBCS <	pop	di, bp							>

	.leave
	ret
DoSmartQuotes	endp

if DBCS_PCGEOS
openQuoteList	wchar \
	' ',
	'(',
	'[',
	'{',
	'<',
	C_TAB,
	C_ENTER,
	C_NON_BREAKING_SPACE
else
openQuoteList	char	' '
		char	'('
		char	'['
		char	'{'
		char	'<'
		char	C_TAB
		char	C_ENTER
		char	C_NONBRKSPACE
;		char	C_MINUS
;		char	C_ENDASH
;		char	C_EMDASH
endif

endOpenQuoteList	label	char
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextKbd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle MSG_META_KBD_CHAR.

CALLED BY:	External (MSG_META_KBD_CHAR)
PASS:		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code
		ds:*si = ptr to instance.
		es = segment containing GenEditClass.
		ax = MSG_META_KBD_CHAR.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/89		Initial version
	eca	8/30/89		Changed checking to handle chars >0x80
	kho	5/23/95		Add support for Charset (Responder)
	kho	7/16/95		Move Charset support to "VisTextHandleCharset"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	TEXT_PERFORMANCE_CHECKING
include timedate.def
PERF_ARRAY_SIZE		=	50

idata	segment
perfIndex	word	0
perfArray	word	PERF_ARRAY_SIZE dup (0)
perfStartArray	word	PERF_ARRAY_SIZE dup (0)
idata	ends

endif
;---

VisTextKbd	method dynamic	VisTextClass, MSG_META_KBD_CHAR

	;
	; Quit if not a valid character
	;
DBCS <	cmp	cx, C_NOT_A_CHARACTER					>
DBCS <	LONG je	quit							>

if	TEXT_PERFORMANCE_CHECKING
	push	ax, bx
	call	TimerGetCount			;bx.ax = count
	mov	bx, es:[perfIndex]
	mov	es:[bx].perfStartArray, ax
	pop	ax, bx
endif

ifdef	USE_FEP
	;
	; If it is a press send it to the FEP.
	;
	test	dl, mask CF_RELEASE
	jnz	noFep
	;
	; Pass call back information on the stack.
	;
	push	bx, di
	sub	sp, size FepCallBackInfo
	mov	di, sp
	mov 	ax, segment FepCallBack
	mov	bx, offset FepCallBack
	movdw	ss:[di].FCBI_function, axbx
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[di].FCBI_data, axsi
	movdw	axbx, ssdi
	mov	di, DR_FEP_KBD_CHAR
	call	FepCallRoutine
	jnc	restore
	mov	al, 1
restore:
	add 	sp, size FepCallBackInfo
	pop	bx, di
	;
	; Check return value: iff al = 0 consume the character.
	;
	tst	al
LONG	jz	quit	
noFep:
endif	; USE_FEP


	call	TextGStateCreate		; May need a gstate.



		
	; Don't handle key releases, or state keys (shift, ctrl, etc).
	; (For speed reasons, we only FUP alt or F10 releases.  Non-alt or F10
	; releases will be thrown away. -chris 9/19/90)  (Not good enough.
	; we need to fup any releases which involve the ALT key, so that
	; ctrl-alt-8 (bullet) doesn't look like an alt press and release.
	; -chris 10/17/90)

SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_LALT			>
DBCS <	cmp	cx, C_SYS_LEFT_ALT					>
	je	sendUp				; Send left-alt press/rel up
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_RALT			>
DBCS <	cmp	cx, C_SYS_RIGHT_ALT					>
	je	sendUp				; Same with right-alt
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F10			>
DBCS <	cmp	cx, C_SYS_F10						>
	je	sendUp				; Same with F10

	test	dl, mask CF_RELEASE
	jz	notRelease			; Not release, do more

if DBCS_PCGEOS
PrintMessage <fix VisTextKbd -- ask Chris (who does not remember)>
else
	cmp	cl, 80h				; Yes, this is gross
						; (Not as gross as putting
						; C_UA_DIERESIS, in my opinion)
	jae	sendUp				; FUP any releases of extended
						;   chars (and some control
						;   chars because I'm lazy.)
endif
	jmp	exit				; Throw away other releases

notRelease:

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	sendUp				; Quit if not character event.

	; special case -- check for Ctrl-Enter, map to C_PAGE_BREAK if this
	; is a large object

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	noPageBreakMapping
SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_ENTER			>
DBCS <	cmp	cx, C_SYS_ENTER						>
	jnz	noPageBreakMapping
	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	noPageBreakMapping
	test	dh, not (mask SS_LCTRL or mask SS_RCTRL)
	jnz	noPageBreakMapping
	mov	cx, C_COLUMN_BREAK
	clr	dh
noPageBreakMapping:

	; test specially for single line object filtering stuff

	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	notOneLine
SBCS <	cmp	cl, C_CR						>
DBCS <	cmp	cx, C_SYS_ENTER						>
	mov	ax, MSG_META_TEXT_CR_FILTERED	;assume CR, set up filter msg
	jz	tabOrCR				;CR, send filter msg
notOneLine:
SBCS <	cmp	cl, C_TAB			;see if tab		>
DBCS <	cmp	cx, C_SYS_TAB			;see if tab		>
	jne	notSpecial			;branch if not
	test	ds:[di].VTI_filters, mask VTF_NO_TABS	;allowing tabs?
	jz	notSpecial			;yes, don't filter them at all
	mov	ax, MSG_META_TEXT_TAB_FILTERED	;else check if filtering
tabOrCR:
	push	cx, dx, bp
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp
	jmp	sendUp				;and send upwards if needed
						;  (used to just exit.)
						;  - cbh 11/ 3/92 
notSpecial:

	test	ds:[di].VTI_intSelFlags, mask VTISF_DOING_SELECTION
	jnz	exit				; Quit if kbd disabled.
	mov	al, ds:[di].VTI_state


	call	AbortHWRMacro			; abort any HWR macro in
						; progress

noAbortHWR::
	call	CallKeyBinding			; Call appropriate binding.
	jc	exit				; Character handled, exit.

sendUp:
	mov	ax, MSG_META_FUP_KBD_CHAR	; Send char to parent focus
	call	VisCallParent
exit:
	call	TextGStateDestroy		; Nuke gstate.

if	TEXT_PERFORMANCE_CHECKING
	mov	bx, segment idata
	mov	es, bx
	call	TimerGetCount			;bx.ax = count
	mov	bx, es:[perfIndex]
	sub	ax, es:[bx].perfStartArray
	mov	es:[bx].perfArray, ax
	add	bx, size word
	cmp	bx, (size word) * PERF_ARRAY_SIZE
	jnz	perfNoWrap
	clr	bx
perfNoWrap:
	mov	es:[perfIndex], bx
endif

;----------------------------------------------------------------------
	;
	; To avoid a cross-module call, the checking for no active search
	; or spell is done here.
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	mov	al, ds:[di].VTI_intFlags
.assert	ASST_NOTHING_ACTIVE	eq	0
	and	al, mask VTIF_ACTIVE_SEARCH_SPELL
	je	quit

	;
	; The checking above will be repeated in this routine, but hopefully
	; we'll cut out some of the extra calls...
	;
	call	SendAbortSearchSpellNotification
quit::
;----------------------------------------------------------------------
	ret


VisTextKbd	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallKeyBinding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate function for a key.

CALLED BY:	VisTextKbd
PASS:		cl	= character.
		dl	= CharFlags
		dh	= ShiftState
		bp low = ToggleState
		bp high = scan code
		ds:di 	= VisText instance data

RETURN:		carry set if character handled.

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
        if char is not in the normal ascii character set,
		FlowCheckKbdShortcut (AUID_textKbdBindings), etc.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallKeyBinding	proc	far
	class	VisTextClass
	uses	cx, dx, bp
	.enter

	push	ds, si

SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_BACKSPACE			>
DBCS <	cmp	cx, C_SYS_BACKSPACE					>
	je	shortcut		 ; definitely handled in shortcuts

	call	UserCheckAcceleratorChar ; a shortcut-type character?
SBCS <	jnc	insert			 ; nope, go try to insert it	>
DBCS <	jnc	insertCheck		 ; nope, go try to insert it	>


	call	UserCheckInsertableCtrlChar
	jnc	shortcut		 ; not insertable ctrl char, branch
	clr	ch			 ; else convert to insertable
	jmp	insert			 ; and go insert it
shortcut:
	clr	bx
	call	GeodeGetUIData		; bx = specific UI
	mov	ax, SPIR_GET_TEXT_KBD_BINDINGS
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable	;ds:si = table

	lodsw				 ; ax, bx <- # of entries.

	; Pass:
	;  ax	= # of shortcuts in the table.
	;  ds:si	= pointer to the list of shortcuts.
	; Return:
	;  si	= pointer to the matching shortcut
	;  carry clear if there was no matching shortcut.

	mov	bx, ax			; Save # of entries in bx.
	mov	di, si			; Save ptr to table start in di.

	call	FlowCheckKbdShortcut	; See if a text shortcut
	jnc	sendAway		; No, go send to application

	shl	bx, 1			; bx <- size of shortcut table.
	add	si, bx
	add	si, di			; es:si <- pointer into function list.
	mov	di, ds:[si]
	pop	ds, si			; Restore instance.

	mov	bx, ds:[si]			
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_state, mask VTS_ONE_LINE
	jz	callFunc

	; for one-line objects we want to look for a few more things

	cmp	di, NUM_MULTI_LINE_ONLY_BINDINGS * DEF_TEXT_CALL_SIZE
	jb	notHandled
callFunc:
	call	TSL_HandleKbdShortcut	; Call the appropriate function.
	jnc	notHandled
	jmp	handled
sendAway:

	; Definitely not insertable.  Bump it upstairs to see if it's a
	; keyboard shortcut.

	pop	ds, si			; Restore these.
notHandled:
	clc				; Say not handled.
	jmp	done


if DBCS_PCGEOS
	;
	; Special check to convert C_SYS keypresses for <Enter> etc.
	; into text characters for interestion.
	;
insertCheck:
	cmp	ch, CS_CONTROL_HB	; system control key?
	jne	insert			; branch if not
	clr	ch			; cx <- character value
endif
	; Do some filtering of the text, according to VTI_filters.
insert:
	pop	ds, si

if DBCS_PCGEOS
	mov	dx, cx
if not PZ_PCGEOS
	cmp	dx, C_APOSTROPHE_QUOTE
	je	quotes
	cmp	dx, C_QUOTATION_MARK
	je	quotes
endif
else
	mov	dl, cl
	cmp	dl, '\''		; Check to see if it is a quote
	je	quotes			; so we can do "smart" quotes.
	cmp	dl, '"'
	je	quotes
endif

doInsert:
	call	VTFInsert
done:
	.leave
	ret

handled:
	stc
	jmp	done

if not PZ_PCGEOS
quotes:

;	IF NO SMART QUOTES ALLOWED ON THIS OBJECT, BRANCH

	call	TextFilter_DerefVis_DI
	test	ds:[di].VTI_features, mask VTF_ALLOW_SMART_QUOTES
	jz	doInsert

	call	DoSmartQuotes
endif
	jmp	doInsert
CallKeyBinding	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertDateOrTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the current date or time into the text.

CALLED BY:	CallKeyBinding

PASS:		cl	= character.
		dl	= CharFlags
		dh	= ShiftState
		bp low = ToggleState
		bp high = scan code
		*ds:si	= text object

RETURN:		carry set if handled, clear otherwise.
		ds - updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a character into the text stream, replacing the current
		selection (if one exists).

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		ds:*si	= instance ptr.
		ds:di	= text instance
	SBCS:
		dl	= character to insert.
	DBCS:
		dx	= character to insert
RETURN:		carry set if inserted
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFInsert	proc	near
	class	VisTextClass
if DBCS_PCGEOS
EC <	tst	dx							>
else
EC <	tst	dl							>
endif
EC <	ERROR_Z	INSERTING_NULL_CHARACTER				>

	test	ds:[di].VTI_state, mask VTS_EDITABLE
	LONG	jz	done			; Quit w/carry clr if not
						; editable.

	push	dx				; Put char on the stack so we
						;   can point to it.
	mov	dx, sp				; ss:dx = pointer

	sub	sp, size VisTextReplaceParameters
	mov	bp, sp			; ss:bp <- frame
	mov	ss:[bp].VTRP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	movdw	ss:[bp].VTRP_insCount, 1
	mov	ss:[bp].VTRP_flags, mask VTRF_FILTER or \
				    mask VTRF_KEYBOARD_INPUT or \
				    mask VTRF_USER_MODIFICATION
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	movdw	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer, ssdx
	movdw	ss:[bp].VTRP_insCount, 1
	
	;
	; Set the range...
	;
	; If we are *not* in overstrike mode then we use the selection
	; as the range to replace.
	;
	; Assume not in overstrike mode
	;
	mov	ss:[bp].VTRP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	test	ds:[di].VTI_state, mask VTS_OVERSTRIKE_MODE
	jz	doReplace
	
	;
	; We are in overstrike mode. If the selected range is a cursor, then
	; we want to delete the character following the cursor, unless of 
	; course we are at the end of the text.
	;
	call	TSL_SelectGetSelectionStart	; dx.ax <- start
						; carry set if range
	jc	doReplace			; Branch if selection is range
	
	;
	; The selection is a cursor, check for at the end of the text
	;
	movdw	cxbx, dxax			; Save start of selection
	call	TS_GetTextSize			; dx.ax <- end of text
	cmpdw	cxbx, dxax			; Check for cursor at end
	je	doReplace			; Branch if it is
	
	;
	; The selection is a cursor and is not at the end of the text.
	; Save a range of one character into the range to replace.
	;
	movdw	ss:[bp].VTRP_range.VTR_start, cxbx
	incdw	cxbx
	movdw	ss:[bp].VTRP_range.VTR_end, cxbx

doReplace:
	call	VisTextReplaceNew
	cmc
	jc	noBeep
	;
	; Added a beep here so that the user will know when the
	; character failed to insert. The reason the character was not
	; inserted is probably becuase the character was filtered or
	; there was no room left in the text object.
	;
	; First check to see if this object has error beeps turned
	; off.
	;
	mov	ax, ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR
	call	ObjVarFindData
	jc	noBeep

	mov	ax, SST_NO_INPUT
	call	UserStandardSound
;	clc
;eat key if we beep, this makes sense for all versions -- brianc 3/4/99
	stc
noBeep:	
	lahf
	add	sp, size VisTextReplaceParameters
	sahf

	pop	dx
if SIMPLE_RTL_SUPPORT
	pushf
	test	ds:[di].VTI_features, mask VTF_RIGHT_TO_LEFT
	je	doneRTL
	cmp	dl, '0'
	jb	doneRTL
	cmp	dl, '9'
	ja	doneRTL
	push	ds, es, si, di
	; you would think this should call VTKF_BACKWARD_CHAR, but
	; because it is also reversed in that section, we have to
	; call VTKF_FORWARD_CHAR to go backward.
	mov	di, VTKF_FORWARD_CHAR	
	call	TSL_HandleKbdShortcut
	pop	ds, es, si, di
doneRTL:
	popf
endif
done:
	ret
VTFInsert	endp



TextFilter	ends

;----------------------------------------------------------------------------

TextFixed	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNotEditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if an object is editable.

CALLED BY:
PASS:		ds:*si	= instance ptr.
RETURN:		ds:di	= instance ptr.
		carry set if the object is not editable.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
        if char is not in the normal ascii character set,
		FlowCheckKbdShortcut (AUID_textKbdBindings), etc.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNotEditable	proc	far
	class	VisTextClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_state, mask VTS_EDITABLE	; clears the carry.
	jnz	done
	stc			; Carry set if not editable.
done:
	ret
CheckNotEditable	endp

TextFixed	ends



