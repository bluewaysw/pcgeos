COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar/DayEvent
FILE:		dayeventSentToList.asm

AUTHOR:		Jason Ho, Jan 31, 1997

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_DE_DISPLAY_SENT_TO_INFO
				Display the sent-to information in a list
				and open SentToDialog.

    MTD MSG_DE_QUERY_SENT_TO_ITEM_MONIKER
				Create and replace the item moniker of
				sent-to event.

    MTD MSG_VIS_DRAW		Redraw the title of the list.

    INT SentToHeaderGlyphDrawTitle
				Draw part of the title of the list, with
				the funky line going the entire height of
				the header

    MTD MSG_VIS_COMP_GET_MINIMUM_SIZE
				Return fixed minimum height.

    MTD MSG_VIS_DRAW		Draw the edge markers (the funky vertical
				lines) thru our message items.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/31/97   	Initial revision


DESCRIPTION:
	Code for SentToDynamicListClass, SentToHeaderGlyphClass and
	other code for drawing the list.

	Included ONLY if HANDLE_MAILBOX_MSG is true.


	$Id: dayeventSentToList.asm,v 1.1 97/04/04 14:47:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG

	;
	; There must be an instance of every class in a resource.
	;
idata		segment
	SentToDynamicListClass
	SentToHeaderGlyphClass
idata		ends

DayEventCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventDisplaySentToInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the sent-to information in a list and open
		SentToDialog.

CALLED BY:	MSG_DE_DISPLAY_SENT_TO_INFO
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (no sent-to) {
			enable SentToNoRecipientList
			disable SentToListWithHeaderInteraction
		} else {
			Find the number of sent-to struct in the event.
		}
		if (count == 0) {
			no sent-to!
		} else {
			Initialize the dynamic list.
			enable SentToListWithHeaderInteraction
			disable SentToNoRecipientList
		}
		Initialize SentToDialog.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/31/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayEventDisplaySentToInfo	method dynamic DayEventClass, 
					MSG_DE_DISPLAY_SENT_TO_INFO
		.enter
	;
	; How many sent-to do we have?
	;
		mov	ax, MSG_DE_GET_SENT_TO_COUNT
		call	ObjCallInstanceNoLock		; cx <- count
		jcxz	enableObjs
	;
	; Initialize the dynamic list.
	;
		; cx == number of element
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	bx, handle SentToList
		mov	si, offset SentToList
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
	;
	; Go back to top of list
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	cx, dx
		mov	di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp gone
		mov	cx, TRUE			; non empty list
enableObjs:
	;
	; If we have sent-to info: enable SentToListWithHeaderInteraction,
	; disable SentToNoRecipientList. Else reverse. Two objects are
	; in same block.
	;
		; cx == boolean (has sent-to or not)
		mov	bx, handle SentToNoRecipientList
		mov	si, offset SentToNoRecipientList
		mov	bp, offset SentToListWithHeaderInteraction
		jcxz	noSentTo

		xchg	si, bp
noSentTo:
	;
	; Enable ^lbx:si
	;
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	di
		call	ObjMessage		; send, nothing destroyed
	;
	; Disable ^lbx:bp
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	si, bp
		clr	di
		call	ObjMessage		; send, nothing destroyed
	;
	; Open the dialog!
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	bx, handle SentToDialog
		mov	si, offset SentToDialog
		clr	di
		call	ObjMessage		; send, nothing destroyed
		
		.leave
		Destroy	ax, cx, dx, bp
		ret

DayEventDisplaySentToInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventQuerySentToItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and replace the item moniker of sent-to event.

CALLED BY:	MSG_DE_QUERY_SENT_TO_ITEM_MONIKER
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		^lcx:dx	= the dynamic list requesting the moniker
		bp	= the position of the item requested
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/31/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayEventQuerySentToItemMoniker	method dynamic DayEventClass, 
					MSG_DE_QUERY_SENT_TO_ITEM_MONIKER
itemNum		local	word	push	bp			; item number
listOptr	local	dword	push	cx, dx			; item optr
mft		local	SENT_TO_VIEW_NUM_OF_COLUMN dup (VisMonikerColumn)
dateTimeString	local	SENT_TO_DATE_TIME_STR_MAX_LEN dup (TCHAR)
arrayMemHandle	local	word
arrayChunk	local	word
elementChunk	local	word
		.enter
		Assert	optr, cxdx
	;
	; Lock chunk array.
	;
		push	bp
		mov	ax, ds:[di].DEI_sentToArrayBlock
		mov	si, ds:[di].DEI_sentToArrayChunk
EC <		tst	ax						>
EC <		ERROR_Z	CALENDAR_NO_SENT_TO_INFO_AVAILABLE		>
		call	LockChunkArray			; *ds:si <- array,
							;  bp <- mem handle
							;  ax, bx destroyed
		mov_tr	ax, bp
		pop	bp
		mov	ss:[arrayMemHandle], ax
		mov	ss:[arrayChunk], si
	;
	; Find the right sent-to structure.
	;
		mov	ax, ss:[itemNum]
		call	ChunkArrayElementToPtr		; ds:di <- element,
							;  carry set if error
		mov	ss:[elementChunk], di
EC <		ERROR_C	CALENDAR_SENT_TO_ARRAY_OUT_OF_BOUND		>
	;
	; Pick the name / SMS number as the first column of moniker.
	;
gotElement::
		; ds:di == EventSentToStruct
		lea	si, ds:[di].ESTS_name
		LocalCmpChar	ds:[si], C_NULL
		jne	useName

		lea	si, ds:[di].ESTS_smsNum		; use SMS number
useName:
	;
	; Format the first part.
	;
		mov	ss:[mft][0*VisMonikerColumn].VMC_just, J_RIGHT
		mov	ss:[mft][0*VisMonikerColumn].VMC_width, \
				SENT_TO_NAME_NUMBER_WIDTH
		clr	ss:[mft][0*VisMonikerColumn].VMC_style
		clr	ss:[mft][0*VisMonikerColumn].VMC_border
		mov	ss:[mft][0*VisMonikerColumn].VMC_ptr.segment, ds
		mov	ss:[mft][0*VisMonikerColumn].VMC_ptr.offset, si
	;
	; Get date / time when the sent-to struct is created.
	;
		mov	ax, ds:[di].ESTS_yearSent
		mov	bx, {word} ds:[di].ESTS_monthSent
		mov	dx, {word} ds:[di].ESTS_hourSent
	;
	; Find the dateTimeString.
	;
		segmov	es, ss, di
		lea	di, ss:[dateTimeString]		; es:di <- buffer
	;
	; Format the second part.
	;
		mov	ss:[mft][1*VisMonikerColumn].VMC_just, J_RIGHT
		mov	ss:[mft][1*VisMonikerColumn].VMC_width, \
				SENT_TO_DATE_TIME_WIDTH
		clr	ss:[mft][1*VisMonikerColumn].VMC_style
		mov	ss:[mft][1*VisMonikerColumn].VMC_border, mask CB_LEFT
		mov	ss:[mft][1*VisMonikerColumn].VMC_ptr.segment, es
		mov	ss:[mft][1*VisMonikerColumn].VMC_ptr.offset, di
	;
	; Create date string.
	;
		mov	si, DTF_ZERO_PADDED_SHORT
		call	LocalFormatDateTime		; buffer filled,
							;  cx <- # char
							;  not including null
DBCS <		shl	cx						>
		add	di, cx				; es:di <- end of str
	;
	; Write a space after date string.
	;
		LocalLoadChar	ax, C_SPACE
		LocalPutChar	esdi, ax		; es:di advanced
	;
	; Append the string with time string.
	;
		; dh == minute, dl == hour
		mov	ch, dl
		mov	dl, dh
		mov	si, DTF_HM
		call	LocalFormatDateTime		; buffer filled,
							;  cx <- # char
							;  not including null
	;
	; Now determine which status string to use. It all depends on
	; ESTS_status of the sent-to struct.
	;
		mov	bx, handle DataBlock
		call	MemLock				; ax <- segment
		mov_tr	es, ax
		
		mov	di, ss:[elementChunk]		; ds:di <- ESTS
		mov	si, ds:[di].ESTS_status
		Assert	etype, si, EventRecipientStatus

EC <		cmp	si, ERS_ILLEGAL					>
EC <		ERROR_E	CALENDAR_INTERNAL_ERROR				>
		mov	si, cs:[statusStringTable][si]
		mov	si, es:[si]			; es:si <- status str
	;
	; Format the third part.
	;
		mov	ss:[mft][2*VisMonikerColumn].VMC_just, J_RIGHT
		mov	ss:[mft][2*VisMonikerColumn].VMC_width, \
				SENT_TO_STATUS_WIDTH
		clr	ss:[mft][2*VisMonikerColumn].VMC_style
		mov	ss:[mft][2*VisMonikerColumn].VMC_border, \
				mask CB_LEFT or mask CB_RIGHT
		mov	ss:[mft][2*VisMonikerColumn].VMC_ptr.segment, es
		mov	ss:[mft][2*VisMonikerColumn].VMC_ptr.offset, si
	;
	; Create the moniker!!
	;
		clr	ah
		mov	bx, SENT_TO_LIST_FONT_SIZE	; font size
		mov	cx, SENT_TO_LIST_FONT
		mov	dx, SENT_TO_VIEW_NUM_OF_COLUMN
		segmov	ds, ss, di
		lea	si, ss:[mft]
		call	CreateVisMonikerLine		; ^lcx:dx <- visMoniker
	;
	; Replace moniker of item on dynamic list.
	;
		push	cx, bp
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
		movdw	bxsi, ss:[listOptr]
		mov	bp, ss:[itemNum]
		call	ObjMessage_dayevent_call	; ax, cx, dx, bp gone
		pop	bx, bp
	;
	; Free the vismoniker block.
	;
		call	MemFree
	;
	; Unlock string resource.
	;
		mov	bx, handle DataBlock
		call	MemUnlock			; es destroyed
	;
	; Unlock chunk array.
	;
		push	bp
		mov	bp, ss:[arrayMemHandle]
		Assert	vmMemHandle, bp
		call	VMUnlock			; ds destroyed
		pop	bp
		
		.leave
		ret
DayEventQuerySentToItemMoniker	endm

CheckHack<(length statusStringTable*2) eq EventRecipientStatus>

statusStringTable	nptr \
	-1,				; ERS_ILLEGAL
	offset AcceptedStatusText,	; ERS_ACCEPTED
	offset DiscardedStatusText,	; ERS_DISCARDED
	offset NoReplyStatusText,	; ERS_NO_REPLY
	offset ForcedStatusText,	; ERS_FORCED
	offset ConfirmedStatusText	; ERS_FORCED_AND_ACCEPTED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SentToHeaderGlyphVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw the title of the list.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= SentToHeaderGlyphClass object
		ds:di	= SentToHeaderGlyphClass instance data
		ds:bx	= SentToHeaderGlyphClass object (same as *ds:si)
		es 	= segment of SentToHeaderGlyphClass
		ax	= message #
		cl	= DrawFlags
		^hbp	= gstate for drawing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 1/97   	Initial version (mostly stolen
					from OCHGVisDraw)
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SentToHeaderGlyphVisDraw	method dynamic SentToHeaderGlyphClass, 
					MSG_VIS_DRAW
		.enter
	;
	; Call super first.
	;
		push	bp
		mov	di, offset SentToHeaderGlyphClass
		call	ObjCallSuperNoLock
		pop	di
		Assert	gstate, di
	;
	; Set font for the list.
	;
		call	GrSaveState

		mov	cx, SENT_TO_LIST_TITLE_FONT
		mov	dx, SENT_TO_LIST_TITLE_FONT_SIZE
		clr	ah
		call	GrSetFont
		
		mov	ax, C_BLACK
		call	GrSetLineColor
		call	GrSetTextColor

		mov	ax, mask TS_BOLD or \
				((not mask TS_BOLD and mask TextStyle) shl 8)
		call	GrSetTextStyle
	;
	; Draw "Name/number" title.
	;
		mov	bx, offset SentToNameTitleText
		mov	ax, SENT_TO_NAME_NUMBER_PIXEL
		call	SentToHeaderGlyphDrawTitle
	;
	; Draw "Date & time" title.
	;
		mov	bx, offset SentToDateTimeTitleText
		mov	ax, SENT_TO_DATE_TIME_PIXEL
		call	SentToHeaderGlyphDrawTitle
	;
	; Draw "Status" title.
	;
		mov	bx, offset SentToStatusTitleText
		mov	ax, SENT_TO_STATUS_PIXEL
		call	SentToHeaderGlyphDrawTitle
	;
	; Restore GState.
	;
		call	GrRestoreState

		.leave
		ret
SentToHeaderGlyphVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SentToHeaderGlyphDrawTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw part of the title of the list, with the funky line
		going the entire height of the header

CALLED BY:	(INTERNAL) OCHGVisDraw
PASS:		*ds:si	= SentToHeaderGlyphClass object
		ax	= right edge of field
		bx	= chunk handle of title string in DataBlock
		di	= gstate to use for drawing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/95		Initial version (OCHGDrawTitle)
	kho	1/ 2/97		Stolen to calendar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SentToHeaderGlyphDrawTitle	proc	near
		uses	si
		.enter
		Assert	objectPtr, dssi, SentToHeaderGlyphClass
		Assert	gstate, di
	;
	; Find the bounds of the object, for translating coordinates and
	; figuring how tall a line to draw at the right edge of the field.
	;
		push	ax, bx
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		pop	cx, si
	;
	; Find the width of the string we want to draw for the title.
	;
		add	ax, cx		; ax <- actual right edge coord, in
					;  parent window
					; bp = actual top edge coord
					; dx = bottom edge

		push	ds
		push	ax
		mov	bx, handle DataBlock
		call	MemLock
		mov	ds, ax
		pop	ax		; ax <- right edge
		mov	si, ds:[si]
		clr	cx		; cx <- null-terminated
		
		push	dx
		call	GrTextWidth	; dx <- width
		pop	bx		; bx <- bottom edge
	;
	; Draw the text that far from the left edge of the edge marker,
	; with reasonable separation between the text and the marker.
	;
		push	ax
		sub	ax, SENT_TO_TITLE_SEPARATION+SENT_TO_TITLE_CORNER_LEN
		sub	ax, dx
		xchg	bx, bp		; bx <- top edge, bp <- bottom
		call	GrDrawText
	;
	; Draw the horizontal part of the field edge marker. We use swapped
	; X coords drawing this part so we can reuse what's in AX for drawing
	; the vertical part.
	;
		push	dx, si
		mov	si, GFMI_STRIKE_POS or GFMI_ROUNDED
		call	GrFontMetrics
		add	bx, dx		; start corner at strike-through
					;  pos for font.
		pop	dx, si
		pop	ax		; ax <- right edge of field
;		inc	ax
;		inc	ax		; cope with two-pixel inset of list
					;  item monikers (sigh)
		mov	cx, ax
		sub	cx, SENT_TO_TITLE_CORNER_LEN
		call	GrDrawHLine
	;
	; Now draw the vertical part from the top of the object to the bottom
	;
		mov	dx, bp		; dx <- bottom edge
		call	GrDrawVLine
	;
	; Unlock DataBlock.
	;
		mov	bx, handle DataBlock
		call	MemUnlock

		pop	ds
		.leave
		ret
SentToHeaderGlyphDrawTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDLVisCompGetMinimumSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return fixed minimum height.

CALLED BY:	MSG_VIS_COMP_GET_MINIMUM_SIZE
PASS:		*ds:si	= SentToDynamicListClass object
		ds:di	= SentToDynamicListClass instance data
		ds:bx	= SentToDynamicListClass object (same as *ds:si)
		es 	= segment of SentToDynamicListClass
		ax	= message #
RETURN:		cx	= minimum width for composite
		dx	= minimum height of composite
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 2/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDLVisCompGetMinimumSize	method dynamic SentToDynamicListClass, 
					MSG_VIS_COMP_GET_MINIMUM_SIZE
	;
	; Call superclass first
	;
		mov	di, offset SentToDynamicListClass
		call	ObjCallSuperNoLock
	;
	; Really ensure minimum height, so vertical lines get's
	; MSG_META_EXPOSED correctly.
	;		
		mov	dx, SENT_TO_ITEM_HEIGHT*NUM_SENT_TO_ITEM_ON_SCREEN
		ret
STDLVisCompGetMinimumSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SentToDynamicListVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the edge markers (the funky vertical lines) thru our
		message items.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= SentToDynamicListClass object
		ds:di	= SentToDynamicListClass instance data
		ds:bx	= SentToDynamicListClass object (same as *ds:si)
		es 	= segment of SentToDynamicListClass
		ax	= message #
		cl	= DrawFlags
		bp	= GState handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 1/97   	Initial version (mostly stolen
					from OCMLVisDraw)
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SentToDynamicListVisDraw	method dynamic SentToDynamicListClass, 
					MSG_VIS_DRAW
	;
	; Let superclass handle the bulk of the work.
	;
		push	bp
		mov	di, offset SentToDynamicListClass
		call	ObjCallSuperNoLock
		pop	di
	;
	; Get the top and bottom bounds of the object.
	;
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock	; (ax, bp), (cx, dx)
		mov	bx, bp			; bx = top

		mov	ax, C_BLACK
		call	GrSetLineColor
	;
	; Draw the vertical lines.
	;
		mov	ax, SENT_TO_NAME_NUMBER_PIXEL
		call	GrDrawVLine
		mov	ax, SENT_TO_DATE_TIME_PIXEL
		call	GrDrawVLine
		mov	ax, SENT_TO_STATUS_PIXEL
		GOTO	GrDrawVLine
		
SentToDynamicListVisDraw	endm

DayEventCode	ends

endif	; HANDLE_MAILBOX_MSG

