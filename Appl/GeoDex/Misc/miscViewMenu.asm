COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscViewMenu.asm

AUTHOR:		Ted H. Kim, 12/5/89

ROUTINES:
	Name			Description
	----			-----------
	RolodexCard		Displays card view only
	ReattachSomeFields	Moves phone fields from Search to Interface
	RolodexBrowse		Displays browse view only
	RolodexBoth		Displays both card and browse view
	DisplayPhoneFields	Displays phone number and phone type name
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	12/5/89		Initial revision
	ted	3/5/92		Complete restructuring for 2.0

DESCRIPTION:
	Contains routines for chaning view mode in GeoDex.

	$Id: miscViewMenu.asm,v 1.1 97/04/04 15:50:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MenuCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexChangeView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message handler for MSG_ROLODEX_CHANGE_VIEW

CALLED BY:	UI 

PASS:		cx - identifier of the view menu item selected

RETURN:		nothing

DESTROYED:	everything

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexChangeView		proc	far

	class	RolodexClass

	cmp	cx, CARD_VIEW			; card view selected?
	jne	checkBrowse			; if not, skip

	cmp	ds:[displayStatus], CARD_VIEW	; are we already in card view?
	je	exit				; if so, exit

	call	RolodexCard			; change the view
	jmp	exit				; and exit
checkBrowse:
	cmp	cx, BROWSE_VIEW			; browse view selected?
	jne	checkBoth			; if not, skip

	cmp	ds:[displayStatus], BROWSE_VIEW	; are we already in browse view?
	je	exit				; if so, exit

	clr	ax
	call	RolodexBrowse			; change the view
	jmp	exit				; and exit
checkBoth:
	cmp	ds:[displayStatus], BOTH_VIEW	; are we already in both view?
	je	exit				; if so, exit

	call	RolodexBoth			; change the view
exit:
ifdef GPC
	; ensure Prev/Next state, regardless of setting change
	mov	ax, MSG_GEN_SET_USABLE
	cmp	ds:[displayStatus], CARD_VIEW	; only needed in card view
	je	setPrevNext
	mov	ax, MSG_GEN_SET_NOT_USABLE
setPrevNext:
	push	ax
	GetResourceHandleNS	PreviousTrigger, bx
	mov	si, offset PreviousTrigger
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_NOW			; dl - do it right now
	call	ObjMessage			; make this object not usable
	pop	ax
	GetResourceHandleNS	NextTrigger, bx
	mov	si, offset NextTrigger
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_NOW			; dl - do it right now
	call	ObjMessage			; make this object not usable
endif
	ret
RolodexChangeView		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays card view only.

CALLED BY:	Kernel

PASS:		ax - zero if you have to display the current record
		     -1 if you don't have to display the current record
		ds - segment address of core block
			doublePress, displayStatus

RETURN:		dgroup:displayStatus - CARD_VIEW

DESTROYED:	ax, bx, dx, si, di

PSEUDO CODE/STRATEGY:
	Nuke the browse view
	If both view
		resize the entire window
	Else display card view
	Give focus to index field in card view

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexCard		proc	far
	cmp	cx, CARD_VIEW			; called from View Menu?
	jne	start				; if not, skip

	clr	ax				; if so, set this flag
start:
	push	ax				; save the flag

	clr	ds:[doublePress]		; clear double press flag

	cmp	ds:[displayStatus], BROWSE_VIEW	; is browse view up?
	jne	both				; if not, tear down browse view
	
	GetResourceHandleNS	Interface, bx	; get handle of Interface
	GetResourceHandleNS	BrowseView, ax	; get handle of MenuResource
	call	ReattachSomeFields		; move some objects back to card
both:
	GetResourceHandleNS	BrowseView, bx	; get handle of MenuResource
	mov	si, offset BrowseView 		; bx:si - OD of browse window
	call	MakeObjectNotUsable		; make the window not usable

	pop	ax

	cmp	ds:[displayStatus], BOTH_VIEW	; is both views up?
	je	grabFocus			; if so, skip

	push	ax

	GetResourceHandleNS	CardView, bx	
	mov	si, offset CardView		; bx:si - OD of card view 
	call	MakeObjectUsable		; make this window usable

	mov	ax, MSG_GEN_INTERACTION_INITIATE	
	mov	di, mask MF_FIXUP_DS		
	call	ObjMessage			; display this window

	pop	ax
	tst	ax				; display current record? 
	js	grabFocus			; if not, skip

	mov	si, ds:[curRecord]		; si - current record handle
	tst	si				; is record blank?
	jne	notBlank			; if not, skip
	call	ClearRecord			; if so, clear the record 
	jmp	short	grabFocus		; and skip to grab focus
notBlank:
	push	bx				; save resource handle 
	mov	ds:[displayStatus], CARD_VIEW	; set the flag
	call	DisplayCurRecord		; display current record
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag
	pop	bx				; restore resource handle
grabFocus:
	GetResourceHandleNS	LastNameField, bx	
	mov	si, offset LastNameField 	; bx:si - OD of index field
	mov	ax, MSG_GEN_MAKE_FOCUS	
	mov	di, mask MF_FIXUP_DS		
	call	ObjMessage			; set focus to index field

	mov	si, offset RolodexPrimary	; bx:si - OD of app. window
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	; update it right now
	call	ObjMessage			; resize the window

	mov	ds:[displayStatus], CARD_VIEW	; set the flag
	clr	dx				; dx - not indeterminate
	mov	cx, CARD_VIEW			; cx - identifier 
	mov	si, offset ShowMenuList 	; bx:si - OD of menu list 
	GetResourceHandleNS	ShowMenuList, bx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; make the selection
	ret
RolodexCard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReattachSomeFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the phone fields from SearchResource and attaches
		them to Interface resource.

CALLED BY:	RolodexCard, BringUpBothView

PASS:		ax - resource handle of SearchResource
		bx - resource handle of Interface

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReattachSomeFields	proc	near
	push	bx
	push	ax
ifdef GPC
	mov	si, offset AllPhoneFields		; bx:si - OD of object to move
else
	mov	si, offset PhoneFields		; bx:si - OD of object to move
endif
	call	MakeObjectNotUsable		; make it disappear
ifdef GPC
	mov	ax, C_WHITE
	call	SetTextBackgroundColor
endif

	mov	cx, bx
ifdef GPC
	mov	dx, offset AllPhoneFields		; cx:dx - OD of child
else
	mov	dx, offset PhoneFields		; cx:dx - OD of child
endif
	pop 	bx				; get handle of SearchResource
	mov	si, offset BrowseView		; bx:si - OD of parent
	mov	ax, MSG_GEN_REMOVE_CHILD	
	mov	di, mask MF_FIXUP_DS		
	mov	bp, mask CCF_MARK_DIRTY		; mark the links dirty
	call	ObjMessage			; remove it from browse view 
	pop	bx				; get handle of Interface
	mov	si, offset Records		; bx:si - OD of parent
	mov	cx, bx
ifdef GPC
	mov	dx, offset AllPhoneFields		; cx:dx - OD of child
else
	mov	dx, offset PhoneFields		; cx:dx - OD of child
endif
	mov	ax, MSG_GEN_ADD_CHILD	
	mov	di, mask MF_FIXUP_DS		
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY	; it is the last item
	call	ObjMessage			; add phone fields to card view

ifdef GPC
	mov	si, offset AllPhoneFields		; bx:si - OD of object to enable
else
	mov	si, offset PhoneFields		; bx:si - OD of object to enable
endif
	call	MakeObjectUsable		; make it appear
	ret
ReattachSomeFields	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexBrowse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays browse view only.

CALLED BY:	Kernel

PASS:		ds - segment address of core block

RETURN:		displayStatus - BROWSE_VIEW

DESTROYED:	ax, bx, dx, si, di

PSEUDO CODE/STRATEGY:
	Nuke the card view
	If both view
		resize the entire window
	Else display browse view
	Give focus to filter box in browse view

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/8/89		Initial version
	witt	2/8/94		Handle bigger TableEntry size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexBrowse	proc	far
ifndef GPC
	tst	ds:[cga]
	je	notCGA
endif

	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	

	push	ax
	sub	sp, size SetSizeArgs
	mov	bp, sp				; ss:bp - ptr to stack frame
	mov	ss:[bp].SSA_width, SpecWidth <SST_WIDE_CHAR_WIDTHS, 16> 
ifdef GPC
	mov	ss:[bp].SSA_height, SpecHeight <SST_LINES_OF_TEXT, 9>
	mov	ss:[bp].SSA_count, 9		; child count
else
	mov	ss:[bp].SSA_height, SpecHeight <SST_LINES_OF_TEXT, 10>
	mov	ss:[bp].SSA_count, 10		; child count
endif
	mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_APP_QUEUE
	mov	ax, MSG_GEN_SET_FIXED_SIZE
	mov	dx, size SetSizeArgs
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size SetSizeArgs		; restore SP
	pop	ax
notCGA::
	tst	ax				
	js	quit

	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	GetResourceHandleNS	SearchList, bx	

	mov	cx, ds:[gmb.GMB_numMainTab]		; cx - # of entries in database
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			; redraw the dynamic list

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	clr	dx				; if so, no exclusive
	mov	cx, ds:[curOffset]		; offset to the current record
	TableEntryOffsetToIndex  cx		; cx - entry # to select 

	tst	ds:[curRecord]			; is there a blank record?
	je	blank				; if so, skip	
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
blank:
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			; redraw the dynamic list

	mov	ds:[doublePress], -1		; set double press flag
	mov	si, ds:[curRecord]		; si - current record handle
	tst	si				; is record blank?
	jne	notBlank			; if not, skip
	call	ClearRecord			; if so, clear the record 
	jmp	short	quit			; and skip to grab focus
notBlank:
	push	si				; save current record handle
	call	SaveCurRecord			; update any changes to cur rec
	pop	si				; restore current record handle
	LONG	jc	notCard			; exit if error

	push	si				; save current record handle
	call	UpdateNameList			; set the new exclusive
	pop	si				; restore current record handle

	test	ds:[recStatus], mask RSF_WARNING; was warning box up?
	LONG	jne	exit			; if so, exit

	push	si
	call	DisableUndo			; no undoable action exists
	pop	si
	call	DisplayPhoneFields		; display phone fields
quit:
ifdef GPC
	GetResourceHandleNS	AllPhoneFields, bx	
	mov	si, offset AllPhoneFields		; bx:si - OD of object
else
	GetResourceHandleNS	PhoneFields, bx	
	mov	si, offset PhoneFields		; bx:si - OD of object
endif
	call	MakeObjectNotUsable		; make it disappear
ifdef GPC
	mov	ax, C_LIGHT_GREY
	call	SetTextBackgroundColor
endif

	mov	cx, bx
ifdef GPC
	mov	dx, offset AllPhoneFields		; cx:dx - OD of child
else
	mov	dx, offset PhoneFields		; cx:dx - OD of child
endif
	mov	si, offset Records		; bx:si - OD of parent
	mov	ax, MSG_GEN_REMOVE_CHILD	
	mov	di, mask MF_FIXUP_DS		
	mov	bp, mask CCF_MARK_DIRTY		; marks the links dirty
	call	ObjMessage			; remove child from its parents
	
	mov	si, offset CardView		; bx:si - OD of card view
	call	MakeObjectNotUsable		; make the window not usable

	GetResourceHandleNS	BrowseView, bx	; get handle of UI block

	cmp	ds:[displayStatus], BOTH_VIEW	; was both view up?
	je	grabFocus			; if so, resize the window

	mov	si, offset BrowseView		; bx:si - OD of browse view
	call	MakeObjectUsable		; display the browse view

	mov	ax, MSG_GEN_INTERACTION_INITIATE	
	mov	di, mask MF_FIXUP_DS		
	call	ObjMessage			; display the browse window

grabFocus:
ifdef GPC
	GetResourceHandleNS	AllPhoneFields, cx	
	mov	dx, offset AllPhoneFields		; cx:dx - OD of child
else
	GetResourceHandleNS	PhoneFields, cx	
	mov	dx, offset PhoneFields		; cx:dx - OD of child
endif
	mov	si, offset BrowseView		; bx:si - OD of parent
	mov	ax, MSG_GEN_ADD_CHILD	
	mov	di, mask MF_FIXUP_DS		
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY	; it is the last item
	call	ObjMessage			; add it to browse view

ifdef GPC
	GetResourceHandleNS	AllPhoneFields, bx	
	mov	si, offset AllPhoneFields		; bx:si - OD of object
else
	GetResourceHandleNS	PhoneFields, bx	
	mov	si, offset PhoneFields		; bx:si - OD of object
endif
	call	MakeObjectUsable		; make phone fields usable 

	call	FocusPhoneField			; set focus to filter box

	mov	si, offset RolodexPrimary	; bx:si - OD of appl. window
	GetResourceHandleNS	RolodexPrimary, bx
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE	
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	; update it right now
	clr	bp				; resets to desired size
	call	ObjMessage			; resize the window

	mov	ds:[displayStatus], BROWSE_VIEW	; set the flag
exit:
	clr	ch
	mov	cl, ds:[displayStatus]		; cx - identifier
	clr	dx				; dx - not indeterminate
	mov	si, offset ShowMenuList 	; bx:si - OD of menu list 
	GetResourceHandleNS	ShowMenuList, bx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	
	mov	di, mask MF_FIXUP_DS 		
	call	ObjMessage			; set new exclusive
notCard:
	ret
RolodexBrowse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexBoth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays both card view and browse view.

CALLED BY:	RolodexChangeView

PASS:		ds - segment address of core block

RETURN:		displayStatus - BOTH_VIEW

DESTROYED:	ax, bx, dx, si, di

PSEUDO CODE/STRATEGY:
	If card view is up
		Display browse view
	If browse view is up
		Dispaly card view
	Give focus to index field in card view

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexBoth	proc	far
	cmp	ds:[displayStatus], BOTH_VIEW	; already in both view?
	je	exit				; if so, exit
	GetResourceHandleNS	Interface, bx	; bx - handle of Interface
	GetResourceHandleNS	MenuResource, dx; dx - handle of Menu block
	GetResourceHandleNS	SearchResource, ax	; ax - handle of search
	call	BringUpBothView
exit:
	ret
RolodexBoth		endp

BringUpBothView	proc	far
ifndef GPC
	tst	ds:[cga]			; CGA display?
	je	notCGA				; if not, skip
endif
	; if CGA, make the dynamic list a little shorter
	; if GPC, determine the fixed size of the object

	push	ax, bx, cx, dx, si, di
	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	mov	bx, ax
	sub	sp, size SetSizeArgs
	mov	bp, sp				; ss:bp - ptr to stack frame
	mov	ss:[bp].SSA_width, SpecWidth <SST_WIDE_CHAR_WIDTHS, 14> 
ifdef GPC
	; Allow width to be tweaked between VGA-size screens and larger
	; screens. This is really done for localization purposes. -Don 11/23/00

	cmp	ds:[displaySize], DS_STANDARD	; larger than VGA display??
	ja	haveWidth
	call	GetVGASearchListWidth		; SpecWidth value => AX
	mov	ss:[bp].SSA_width, ax
haveWidth:
	mov	ss:[bp].SSA_height, SpecHeight <SST_LINES_OF_TEXT, 18>
	mov	ss:[bp].SSA_count, 18		; child count
else
	mov	ss:[bp].SSA_height, SpecHeight <SST_LINES_OF_TEXT, 12>
	mov	ss:[bp].SSA_count, 12		; child count
endif
	mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_APP_QUEUE
	mov	ax, MSG_GEN_SET_FIXED_SIZE
	mov	dx, size SetSizeArgs		; dx - size of stack frame
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage			; change the height of list
	add	sp, size SetSizeArgs		; restore SP
	pop	ax, bx, cx, dx, si, di
notCGA::
	cmp	ds:[displayStatus], BROWSE_VIEW	; in browse view?
	je	notInit				; if so, no need to initialize
	tst	ds:[fileHandle]			; file open?
	jz	notInit

	push	ax, bx, cx, dx, si, di
	mov	si, offset SearchList 		; bx:si - OD of SearchList 
	mov	bx, ax
	mov	cx, ds:[gmb.GMB_numMainTab]		; cx - # of entries in database
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; redraw the dynamic list

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	clr	dx				; dx - no indeterminate
	mov	cx, ds:[curOffset]		; offset to the current record
	TableEntryOffsetToIndex  cx		; cx - entry # to select 

	tst	ds:[curRecord]			; is there a blank record?
	je	blank				; if so, skip	
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
blank:
	mov	di, mask MF_FIXUP_DS or mask MF_CALL 
	call	ObjMessage			; redraw the dynamic list
	pop	ax, bx, cx, dx, si, di
notInit:
	push	dx				; save handle of Menu block

	cmp	ds:[displayStatus], BOTH_VIEW	; are we already in both view?
	LONG	je	exit			; if so, exit

	push	bx				; save handle of Interface
	push	ax				; save handle of search block

	cmp	ds:[displayStatus], CARD_VIEW	; was card view up?
	jne	browseView			; if so, skip

	mov	bx, ax				; bx:si - OD of browse view
	mov	si, offset BrowseView	
	jmp	short	common
browseView:
	push	bx				; bx - handle of Interface
	call	ReattachSomeFields		; move some objects back to card
	pop	bx				; bx - handle of Interface
	mov	si, offset CardView		; si - offset to card view
common:
	call	MakeObjectUsable		; make this window usable

	mov	ax, MSG_GEN_INTERACTION_INITIATE	
	mov	di, mask MF_FIXUP_DS		
	call	ObjMessage			; display this window

	mov	si, ds:[curRecord]		; si - current record handle
	tst	si				; is record blank?
	je	grabFocus			; if so, skip

	cmp	ds:[displayStatus], CARD_VIEW	; card view only?
	je	grabFocus			; if not, skip

	mov	ds:[displayStatus], BOTH_VIEW	; set the flag
	call	DisplayCurRecord		; display current record
	andnf	ds:[searchFlag], not mask SOF_NEW   ; clear search flag
	call	EnableCopyRecord		; fix up some menu
grabFocus:
	pop	bx				; bx - handle of search block
	pop	bx				; bx - handle of Interface
	mov	si, offset RolodexPrimary	; bx:si - OD of Primary
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	di, mask MF_FIXUP_DS		
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	; update it right now
	call	ObjMessage			; resize the window

	mov	ds:[displayStatus], BOTH_VIEW	; set the flag
exit:
	pop	bx				; bx - handle of Menu block
	clr	dx				; dx - not indeterminate
	mov	cx, BOTH_VIEW			; cx - identifier 
	mov	si, offset ShowMenuList 	; bx:si - OD of menu list 
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; make the selection

	clr	ds:[ignoreInput]
	ret
BringUpBothView		endp

ifdef GPC
GetVGASearchListWidth	proc	near
	uses	bx, dx, si, ds
	.enter

	; Width value is stored in a string as the number of
	; SST_WIDE_CHAR_WIDTHS. Convert the string to a number
	; and return it.

	mov	bx, handle TextResource
	call	MemLock
	mov	ds, ax
	mov	si, offset SearchListVGAWidthString
	mov	si, ds:[si]
	call	UtilAsciiToHex32	; integer value -> DX:AX
	call	MemUnlock
	or	ax, SST_WIDE_CHAR_WIDTHS shl offset SW_TYPE
		
	.leave
	ret
GetVGASearchListWidth	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayPhoneFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays phone number and phone number type name. 

CALLED BY:	FindRecord, RolodexBrowse

PASS:		si - current record handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es, bp

PSEUDO CODE/STRATEGY:
	For each text edit field
		clear the text field
		display the text string
	Next text field

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayPhoneFields	proc	far
	push	si			; save current record handle
	mov	ds:[curRecord], si	; new current record handle 
	mov	cx, 2			; cx - # of text fields to clear 
	mov	si, TEFO_PHONE_TYPE	; si - offset to phone type name field
	call	ClearTextFields	; clear both phone fields
	pop	di			; restore current record handle
	call	DBLockNO
	mov	di, es:[di]		; open up this record
	cmp     es:[di].DBR_noPhoneNo, MAX_PHONE_NO_RECORD  ; 8 phone entries?	
	jne	notEight		; if not, skip
	mov	cx, 1			; if so, display the 2nd entry first 
	jmp	common
notEight:
	mov	cl, es:[di].DBR_phoneDisp
	clr	ch			; cx - current phone number counter
common:
	mov	ds:[gmb.GMB_curPhoneIndex], cx	; save it 
	mov	bp, ds:[curRecord]	; bp - current record handle
	call	DisplayPhoneNoField	; display phone field text string
	call	DBUnlock
	ret
DisplayPhoneFields	endp

ifdef GPC

;
; pass:	ax = new color
;
SetTextBackgroundColor	proc	near
	uses	bx, cx, dx, bp, si, di, es
addVarParams	local	AddVarDataParams
	.enter
	GetResourceSegmentNS	dgroup, es
	mov	es:colorQ.CQ_redOrIndex, al
	mov	es:colorQ.CQ_info, CF_INDEX
	mov	addVarParams.AVDP_data.segment, es
	mov	ax, offset colorQ
	mov	addVarParams.AVDP_data.offset, ax
	mov	addVarParams.AVDP_dataSize, size ColorQuad
	mov	addVarParams.AVDP_dataType, HINT_TEXT_WASH_COLOR or mask VDF_SAVE_TO_STATE
	mov	cx, length textBackColorFields
	clr	di
	GetResourceHandleNS	Interface, bx
clearLoop:
	push	di, cx, bp
	mov	si, cs:textBackColorFields[di]
	mov	ax, MSG_META_ADD_VAR_DATA
	lea	bp, addVarParams
	mov	dx, size AddVarDataParams
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di, cx, bp
	add	di, size lptr
	loop	clearLoop
	.leave
	ret
SetTextBackgroundColor	endp

textBackColorFields	lptr \
	offset	Interface:StaticPhoneOneName,
	offset	Interface:StaticPhoneTwoName,
	offset	Interface:StaticPhoneThreeName,
	offset	Interface:StaticPhoneFourName,
	offset	Interface:StaticPhoneFiveName,
	offset	Interface:StaticPhoneSixName

; needs to always be sitting around since we don't MF_CALL
udata	segment
colorQ	ColorQuad
udata	ends

endif

MenuCode	ends
