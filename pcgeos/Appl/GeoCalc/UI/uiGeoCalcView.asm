COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiGeoCalcView.asm
FILE:		uiGeoCalcView.asm

AUTHOR:		Gene Anderson, Nov 27, 1991

ROUTINES:
	Name				Description
	----				-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	11/27/91	Initial revision
	witt	11/11/93	DBCS-ized keyboard shortcuts
	
DESCRIPTION:
	GeoCalc subclass of GenView

	$Id: uiGeoCalcView.asm,v 1.2 98/02/09 21:11:04 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcClassStructures	segment	resource
	GeoCalcViewClass		;declare the class record
GeoCalcClassStructures	ends

Document	segment resource


if _USE_FEP
udata	segment
;
; fep variables
;
global fepDriverHandle:hptr
global fepStrategy:fptr
udata	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcView{Gained,Lost}SysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on/off FEP
CALLED BY:	MSG_META_{GAINED,LOST}_SYS_FOCUS_EXCL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcViewClass
		ax - MSG_META_{GAINED,LOST}_SYS_FOCUS_EXCL
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/17/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcViewGainedSysFocusExcl	method	dynamic	GeoCalcViewClass, MSG_META_GAINED_SYS_FOCUS_EXCL
	uses	ax, cx, dx, bp, es, ds, si
	.enter
	GetResourceSegmentNS	fepStrategy, es, ax
	tst	es:[fepStrategy].segment
	jz	noFep
	;
	; Call the FEP
	;
	mov 	ax, segment GeoCalcViewFepCallBack
	mov	bx, offset GeoCalcViewFepCallBack
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	di, DR_FEP_GAIN_FOCUS
	call	es:[fepStrategy]
noFep:
	.leave
	mov	di, offset GeoCalcViewClass
	GOTO	ObjCallSuperNoLock
GeoCalcViewGainedSysFocusExcl	endm

GeoCalcViewLostSysFocusExcl	method	dynamic	GeoCalcViewClass, MSG_META_LOST_SYS_FOCUS_EXCL
	uses	ax, cx, dx, bp, es, ds, si
	.enter
	GetResourceSegmentNS	fepStrategy, es, ax
	tst	es:[fepStrategy].segment
	jz	noFep
	;
	; Call the FEP
	;
	sub	sp, size FepCallBackInfo
	mov	bp, sp
	mov 	cx, segment GeoCalcViewFepCallBack
	mov	dx, offset GeoCalcViewFepCallBack
	movdw	ss:[bp].FCBI_function, cxdx
	mov	cx, ds:[LMBH_handle]
	movdw	ss:[bp].FCBI_data, cxsi
	movdw	cxdx, ssbp
	mov	di, DR_FEP_LOST_FOCUS
	call	es:[fepStrategy]
	add	sp, size FepCallBackInfo
noFep:
	.leave
	mov	di, offset GeoCalcViewClass
	GOTO	ObjCallSuperNoLock
GeoCalcViewLostSysFocusExcl	endm

GeoCalcClassStructures	segment	resource
;
; sorry, let's just put these two bytes in the class structures segment
;
GeoCalcViewFepCallBack	proc	far
	stc		; return error for GET_TEMP_TEXT_{BOUNDS,ATTR}
	ret
GeoCalcViewFepCallBack	endp
GeoCalcClassStructures	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcViewKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle keypress -- send to spreadsheet or edit bar
CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcViewClass
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
	eca	11/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcViewKbdChar	method dynamic GeoCalcViewClass, \
						MSG_META_KBD_CHAR
	;
	; First, see if the spreadsheet is the current focus/target.
	; If not, don't muck with the keypress, just send it on.
	;
	push	ax, cx
	mov	ax, MSG_GEOCALC_APPLICATION_GET_TARGET_LAYER
	call	GenCallApplication
	cmp	cl, GCTL_SPREADSHEET		;does spreadsheet have target?
	pop	ax, cx
	jne	toSuper				;branch if not spreadsheet
	;
	; See if it is a keyboard shortcut in the spreadsheet
	;
	call	SpreadsheetCheckShortcut
	LONG jc	toSuper				;branch if spreadsheet shortcut
	;
	; See if it is a control character that maps to something insertable
	; (eg. a key on the numeric keypad maps to a digit), and activate
	; the edit bar if so.
	;
	call	UserCheckInsertableCtrlChar
	jc	toEditBar			;branch if insertable
	;
	; See if its one of our shortcuts
	;
	call	GCViewCheckShortcut
	jc	done				;branch if shortcut
if _USE_FEP
	;
	; send FEP characters to FEP
	;
	cmp	cx, C_SYS_KANJI
	jb	noFep
	cmp	cx, C_SYS_KANA_EISUU
	ja	noFep
	test	dl, mask CF_RELEASE
	jnz	noFep
	push	es
	GetResourceSegmentNS	dgroup, es
	tst	es:[fepStrategy].segment
	pop	es
	jz	noFep
	;
	; Pass call back information on the stack.
	;
	sub	sp, size FepCallBackInfo
	mov	di, sp
	mov 	ax, segment GeoCalcViewFepCallBack
	mov	bx, offset GeoCalcViewFepCallBack
	movdw	ss:[di].FCBI_function, axbx
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[di].FCBI_data, axsi
	movdw	axbx, ssdi
	push	cx, dx, bp, es, ds, si
	GetResourceSegmentNS	fepStrategy, es, di
	mov	di, DR_FEP_KBD_CHAR
	call	es:[fepStrategy]
	pop	cx, dx, bp, es, ds, si
	add 	sp, size FepCallBackInfo
	;
	; Check return value: iff al = 0 consume the character.
	;
	tst	al
	jz	done
noFep:
endif
	;
	; See if the press is an accelerator character, and pass it our
	; superclass (and hence to the spreadsheet object) if so.
	;
	call	UserCheckAcceleratorChar
	jc	toSuper				;branch if accelerator
	;
	; If not, give the focus to the edit bar and send the press to it
	; after selecting everything
	;
toEditBar:
	;
	; Don't send the keypress to the edit bar if it is a release
	;
	test	dl, mask CF_RELEASE
	jnz	done				;branch if release
	mov	ax, MSG_SSEBC_INITIAL_KEYPRESS
	call	CallEditBar
done:
	ret

	;
	; The keypress is a shortcut.  Pass it on to our superclass
	; (the view), which will eventually pass it on to the spreadsheet.
	;
toSuper:
	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset GeoCalcViewClass
	call	ObjCallSuperNoLock
	jmp	done
GeoCalcViewKbdChar	endm

CallEditBar	proc	near
	uses	bx, si, di
	.enter

	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
CallEditBar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCViewCheckShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a keypress is shortcut for us (and activate if so)

CALLED BY:	GeoCalcViewKbdChar()
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
	gene	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCViewCheckShortcut	proc	near
	uses	ax, ds, si
	.enter

	mov	ax, (length GCViewKbdShortcuts)
	mov	si, offset GCViewKbdShortcuts
	segmov	ds, cs
	call	FlowCheckKbdShortcut
	jnc	notShortcut			;branch if not shortcut
	mov	di, si				;di <- offset of shortcut
	call	cs:GCViewKbdActions[di]
	stc					;carry <- shortcut
notShortcut:

	.leave
	ret
GCViewCheckShortcut	endp

	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;
ifdef GPC_ONLY
if DBCS_PCGEOS
GCViewKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_INSERT and mask KS_CHAR>	;<Insert>
else
GCViewKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_INS>		;<Insert>
endif
else
if DBCS_PCGEOS
GCViewKbdShortcuts KeyboardShortcut \
	<0, 0, 1, 0, C_SPACE>			;<Ctrl><spacebar>
else
GCViewKbdShortcuts KeyboardShortcut \
	<0, 0, 1, 0, 0x0, C_SPACE>		;<Ctrl><spacebar>
endif
endif

GCViewKbdActions nptr \
	offset GCVFocusToEditBar

CheckHack <(length GCViewKbdActions) eq (length GCViewKbdShortcuts)>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCVFocusToEditBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift the focus to the edit bar

CALLED BY:	GCViewCheckShortcut()
PASS:		none
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCVFocusToEditBar		proc	near
	.enter

	mov	ax, MSG_SSEBC_GRAB_FOCUS
	call	CallEditBar

	.leave
	ret
GCVFocusToEditBar		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcViewSetControlledAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle scrollbar change for split views.

PASS:		*ds:si	- GeoCalcViewClass object
		ds:di	- GeoCalcViewClass instance data
		es	- dgroup
		cx	- GenViewControlAttrs
		dx	- scale factor
RETURN:		

DESTROYED:	everything

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

	Remove or add the "leave room for scrollbar" hints on the
	RulerViews or the other GeoCalcViews when in split view mode.
	This causes the views to resize in sync with the main
	GeoCalcView.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/25/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcViewSetControlledAttrs	method	dynamic	GeoCalcViewClass, 
					MSG_GEN_VIEW_SET_CONTROLLED_ATTRS

		push	ax, dx, si
		mov	dx, cx			; dx <- passed attrs
	;
	; If the main GeoCalcView is being modified, update the
	; RulerViews now.
	;
		cmp	si, offset BottomRightView
		jne	updateSplitViews

		mov	si, offset RightColumnView
		mov	ax, HINT_VIEW_LEAVE_ROOM_FOR_VERT_SCROLLER
		mov	cx, mask GVCA_SHOW_VERTICAL
		call	UpdateViewVarData

		mov	si, offset BottomRowView
		mov	ax, HINT_VIEW_LEAVE_ROOM_FOR_HORIZ_SCROLLER
		mov	cx, mask GVCA_SHOW_HORIZONTAL
		call	UpdateViewVarData


done:
		mov	cx, dx
		pop	ax, dx, si
		mov	di, offset GeoCalcViewClass
		GOTO	ObjCallSuperNoLock
		

updateSplitViews:		
if _SPLIT_VIEWS
	;
	; Update the other GeoCalcViews as approriate.
	;
		cmp	si, offset MidRightView
		jne	$10
		mov	ax, HINT_VIEW_LEAVE_ROOM_FOR_VERT_SCROLLER
		mov	cx, mask GVCA_SHOW_VERTICAL
		call	UpdateViewVarData
$10:
		cmp	si, offset BottomLeftView
		jne	$30
		mov	ax, HINT_VIEW_LEAVE_ROOM_FOR_HORIZ_SCROLLER
		mov	cx, mask GVCA_SHOW_HORIZONTAL
		call	UpdateViewVarData
$30:		
	;
	; Turn off the show scrollbar bits, because we never
	; want them to show in the other split views.
	;
		andnf	dx, not (mask GVCA_SHOW_VERTICAL or \
				 mask GVCA_SHOW_HORIZONTAL)
endif			
		jmp	done		
GeoCalcViewSetControlledAttrs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModifyFlagsForDisplayTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if DisplayTitle is usable and modify the
		GenViewControllAttrs flag accordingly.

CALLED BY:	
PASS:		*ds:si - GenView
		dx - passed GenViewControllAttrs
RETURN:		dx - modified GenViewControllAttrs
DESTROYED:	ax, bx, cx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/10/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateViewVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove the "leave room for scrollbar" hint

CALLED BY:	GeoCalcViewSetControlledAttrs
PASS:		dx - passed GenViewControlAttrs  
		cx - bit in GenViewControlAttrs we're interested in
		*ds:si - GeoCalcView
		ax - vardata type
		
RETURN:		bx = 0 if no change in state
		bx = 1 if scrollbar hint was added or removed
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateViewVarData		proc	near
		class	RulerViewClass		; subclass of GenView
		uses	dx
		.enter

		call	ObjVarFindData
		mov	bx, 1			; assume vardata exists
		jc	foundIt
		clr	bx			; no, it doesn't
foundIt:		
		and	cx, dx			; is this attr set?
		jz	remove			; no, remove the hint
		tst	bx			; does vardata exist?
		mov	bx, 0			; assume state won't change
		jnz	finish			; yes, don't need to add it
		clr	cx
		call	ObjVarAddData
		mov	bx, 1
		jmp	finish
remove:
		tst	bx			; is the hint present?
		jz	finish			; no, don't need to delete it
		call	ObjVarDeleteData
		mov	bx, 1
		cmp	si, offset BottomRowView
		je	setNoScrollBar
		cmp	si, offset RightColumnView
		je	setNoScrollBar
finish:
	;
	; bx = 1 if state changed, and need to update geometry.
	; Unfortunately, this hint is examined only when the view
	; is opening or closing, so it will have to be set not usable,
	; then usable.
	;
	; Before setting it not usable, clear out the links so that
	; we don't cause unnecessary (and incorrect) scrolling.
	;
		tst	bx
		jz	exit

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	; 2/5/98 Check to see if this view is currently not usable (as it
	; will be if "Show Rulers" is off).  We don't want to set it usable
	; if it currently isn't, otherwise it will appear seemingly at
	; random when the user toggles the scrollbars on or off.
	; See ND-000496. -- eca
	;
		test	ds:[di].GI_states, mask GS_USABLE
		jz	skipNotUsable

		pushdw	ds:[di].GVI_horizLink	; save the links before 0'ing
		pushdw	ds:[di].GVI_vertLink
		clr	ax
		movdw	ds:[di].GVI_horizLink, axax	
		movdw	ds:[di].GVI_vertLink, axax
		mov	bx, ds:[LMBH_handle]	; bx <- view handle
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallInstanceNoLock
		
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjCallInstanceNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		popdw	ds:[di].GVI_vertLink	; restore the links
		popdw	ds:[di].GVI_horizLink

skipNotUsable:
		mov	bx, 1			; bx = 1 ==> state changed

		cmp	si, offset BottomRowView
		je	clearNoScrollBar
		cmp	si, offset RightColumnView
		je	clearNoScrollBar
exit:
		.leave
		ret

setNoScrollBar:
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		ornf	ds:[di].RVI_attrs, mask RVA_NO_SCROLLBAR
		jmp	finish

clearNoScrollBar:
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		andnf	ds:[di].RVI_attrs, not mask RVA_NO_SCROLLBAR
		jmp	exit
		
UpdateViewVarData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcViewSetDocBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the document bounds, ignoring the upper-left hand
		values before passing the bounds onto our friends the links.

PASS:		*ds:si	- GeoCalcViewClass object
		ds:di	- GeoCalcViewClass instance data
		es	- segment of GeoCalcViewClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcViewSetDocBounds	method	dynamic	GeoCalcViewClass, 
					MSG_GEN_VIEW_SET_DOC_BOUNDS
		
	  	test	ds:[di].GCVI_attrs,
				mask GCVA_DONT_PROPAGATE_DOC_BOUNDS
		jz	gotoSuper

		pushdw	ss:[bp].RD_left
		pushdw	ss:[bp].RD_top
		clrdw	ss:[bp].RD_left
		clrdw	ss:[bp].RD_top

		push	ax, cx, dx, bp
		mov	di, offset GeoCalcViewClass
		call	ObjCallSuperNoLock
		pop	ax, cx, dx, bp

		popdw	ss:[bp].RD_top
		popdw	ss:[bp].RD_left
		
		mov	di, ds:[si]
		add	di, ds:[di].GenView_offset

afterSuper::
		pushdw	ds:[di].GVI_horizLink
		pushdw	ds:[di].GVI_vertLink
		clrdw	ds:[di].GVI_horizLink
		clrdw	ds:[di].GVI_vertLink
		
		mov	di, offset GeoCalcViewClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].GenView_offset
		
		popdw	ds:[di].GVI_vertLink
		popdw	ds:[di].GVI_horizLink
		ret

gotoSuper:
		mov	di, offset GeoCalcViewClass
		GOTO	ObjCallSuperNoLock

GeoCalcViewSetDocBounds	endm


Document	ends
