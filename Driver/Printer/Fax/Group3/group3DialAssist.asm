COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3DialAssist.asm

AUTHOR:		Andy Chiu, Nov 15, 1993

	Name			Description
	----			-----------
METHODS:

	DialAssistInteractionVisOpen
				Tells the quick lists to read the monikers
				it needs from the INI file.

	DialAssistSaveFields	Save the access, long distance and billing
				card fields to the INI file.
	
	DialAssistResetFields	Reset the access, long distance and billing 
				card fields using info from the INI file.

	QuickRetrieveListSetCurrentSelection
				Routine is called when an item has been
				selected from the quick retrieval list.
				This will replace the text in the text
				object that it is linked to.

	QuickRetrieveListRequestMoniker
				This checks the ini file for the moniker
				it should return.

	QuickRetrieveListVisOpen
				Subclassed method so we can tell the text
				to send it's message to update us if it's
				been modified.

	QuickRetrieveListInitialize
				This does the preliminary checking of the
				ini file and tells the list to update itself




ROUTINES:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/15/93   	Initial revision


DESCRIPTION:
	Definitions of the UI objects inside the dial assist dialog
		

	$Id: group3DialAssist.asm,v 1.1 97/04/18 11:53:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DialAssistInteractionVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the quick lists to read the monikers it needs from the
		INI file

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= DialAssistInteractionClass object
		ds:di	= DialAssistInteractionClass instance data
		ds:bx	= DialAssistInteractionClass object (same as *ds:si)
		es 	= segment of DialAssistInteractionClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DialAssistInteractionVisOpen	method dynamic DialAssistInteractionClass, 
					MSG_VIS_OPEN

	;
	; Call super class
	;
		mov	di, offset DialAssistInteractionClass
		call	ObjCallSuperNoLock
	;
	; Tell each quick list to initialize themselves
	;
		mov	ax, MSG_QUICK_RETRIEVE_LIST_INITIALIZE
		mov	si, offset DialAssistAccessList
		call	ObjCallInstanceNoLock

		mov	si, offset DialAssistLongDistanceList
		call	ObjCallInstanceNoLock
		
		ret
DialAssistInteractionVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DialAssistSaveFields/ResetFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save/reset the access, long distance and billing card fields
		to/from the INI file.

CALLED BY:	MSG_DIAL_ASSIST_SAVE_FIELDS/MSG_DIAL_ASSIST_RESET_FIELDS

PASS:		*ds:si	= DialAssistInteractionClass object
		ds:di	= DialAssistInteractionClass instance data
		es 	= segment of DialAssistInteractionClass

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DialAssistSaveFields	method dynamic DialAssistInteractionClass, 
					MSG_DIAL_ASSIST_SAVE_FIELDS
if 0
	;
	; Automatically select "Use Dial Assistance."
	;		
		mov	cx, PO_AUTO_DIAL
		clr	dx				; not indeterminate
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	si, offset Group3DialAssistItemGroup
		call	ObjCallInstanceNoLock
endif
		

		call	Group3WriteDialAssistInfo
		ret
DialAssistSaveFields	endm

DialAssistResetFields	method dynamic DialAssistInteractionClass, 
					MSG_DIAL_ASSIST_RESET_FIELDS
		call	Group3GetDialAssistInfo
		ret
DialAssistResetFields	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickRetrieveListSetCurrentSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine is called when an item has been selected from
		the quick retrieval list.  This will replace the text in
		the text object that it is linked to.

CALLED BY:	MSG_QUICK_RETRIEVE_LIST_SET_CURRENT_SELECTION
PASS:		*ds:si	= QuickRetrieveListClass object
		ds:di	= QuickRetrieveListClass instance data
		ds:bx	= QuickRetrieveListClass object (same as *ds:si)
		es 	= segment of QuickRetrieveListClass
		ax	= message #
		cx	= current selection
		bp	= num of selections
		dl	= GenItemGroupStateFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickRetrieveListSetCurrentSelection	method dynamic QuickRetrieveListClass, 
					MSG_QUICK_RETRIEVE_LIST_SET_CURRENT_SELECTION

tempBuf		local	FAX_MAX_FIELD_LENGTH	dup (char)

		.enter

		push	bp				; needed for local vars
		push	di				; save offset to inst
							; data
		push	ds				; save segment of this
							; object
	;
	; Have di point to the offset of the local var.
	;
		lea	di, ss:[tempBuf]
	;
	; Get the optr of the moniker so we can get it.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
		call	ObjCallInstanceNoLock	; ^lcx:dx = obj chosen
	;
	; Get the text of the object.
	;
		mov	si, dx
		mov	ax, MSG_GEN_GET_VIS_MONIKER
		call	ObjCallInstanceNoLock	; ax <- handle to moniker
	;
	; Use this handle to find the fptr of the text.  We already
	; know the block is locked so we can access it now.
	;
		mov	si, ax
		mov	si, ds:[si]		; ds:bp <- vis moniker
		lea	si, ds:[si].VM_data[VMT_text]	; ds:si <- src string
	;
	; Place the string into the stack.  We can't copy it directly to
	; the text object because the text is in the same block as the
	; text object.
	;
		segmov	es, ss			; es:di <- dest string
		push	di
		LocalCopyString
	;
	; Update the text object that this procedure is associated with
	;
		mov	dx, es
		pop	bp			; dx:bp <- src string
		clr	cx
		pop	ds			; segment of UI block
		pop	di			; pointer to inst data
		mov	si, ds:[di].QRLI_textObj.chunk
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		pop	bp			; needed for local vars

		.leave
		ret
QuickRetrieveListSetCurrentSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickRetrieveListRequestMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This checks the ini file for the moniker it should return.

CALLED BY:	MSG_QUICK_RETRIEVE_LIST_REQUEST_MONIKER
PASS:		*ds:si	= QuickRetrieveListClass object
		ds:di	= QuickRetrieveListClass instance data
		ds:bx	= QuickRetrieveListClass object (same as *ds:si)
		es 	= segment of QuickRetrieveListClass
		ax	= message #
		^lcx:dx	= the dynamic list
		bp	= position in the list
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickRetrieveListRequestMoniker	method dynamic QuickRetrieveListClass, 
					MSG_QUICK_RETRIEVE_LIST_REQUEST_MONIKER

	;
	; Setup the parameters so we can read the ini file.
	;
		push	dx
		mov	si, ds:[di].QRLI_key
		mov	dx, ds:[si]
		mov	cx, ds			; cx:dx <- key string
		mov	si, ds:[di].QRLI_category	; ds:si <- cat string
		mov	si, ds:[si]
		
		mov	ax, bp			; ax <- element wanted
		clr	bp
		call	InitFileReadStringSection	; bx <- mem handle
		pop	si
		jc	exit				; bail if error
	;
	; Put that string in the list.
	;
		mov_tr	bp, ax
		call	MemLock			; ax <- segment of string
		mov_tr	cx, ax
		clr	dx			; cx:dx <- string
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock

		call	MemFree
exit:
		ret

QuickRetrieveListRequestMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickRetrieveListVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subclassed method so we can tell the text to send it's
		message to update us if it's been modified.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= QuickRetrieveListClass object
		ds:di	= QuickRetrieveListClass instance data
		ds:bx	= QuickRetrieveListClass object (same as *ds:si)
		es 	= segment of QuickRetrieveListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickRetrieveListVisOpen	method dynamic QuickRetrieveListClass, 
					MSG_VIS_OPEN
	;
	; Make sure the super class has been called
	;
		mov	di, offset QuickRetrieveListClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].QuickRetrieveList_offset
	;
	; Check here to see if the QuickRetrieveList has to be deselected.
	; If no item in the list is selected, then we don't have to worry
	; about this.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock		; ax <- selection
		jc	sendApply			; nothing selected
	;
	; If there is no text, then we set the selection to none in
	; the QuickRetreiveList.
	;
		push	si
		mov	si, ds:[di].QRLI_textObj.chunk
		clr	dx				; alloc a block
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		call	ObjCallInstanceNoLock		; ^hcx <- text
							; ax <- string length
		pop	si
		xchg	cx, ax				; cx <- string length
		mov_tr	bx, ax				; ^hbx <- text
		call	MemFree				; don't need text ...
		jcxz	setNoneSelected
	;
	; If the text has been modified, then we will set the selection
	; to none in the QuickRetrieveList.
	;
		push	si
		mov	si, ds:[di].QRLI_textObj.chunk
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED
		call	ObjCallInstanceNoLock		; carry set if modified
		pop	si
		jnc	sendApply

setNoneSelected:	
	;
	; Set the QuickRetrieveList to having no selections.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		call	ObjCallInstanceNoLock

sendApply:
	;
	; Now tell the text to apply the message.  
	;
		mov	si, ds:[di].QRLI_textObj.chunk
		mov	ax, MSG_GEN_APPLY
		call	ObjCallInstanceNoLock
		
		.leave
		ret
QuickRetrieveListVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickRetrieveListInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This does the preliminary checking of the ini file
	 	and tells the list to update itself

CALLED BY:	MSG_QUICK_RETRIEVE_LIST_INITIALIZE
PASS:		*ds:si	= QuickRetrieveListClass object
		ds:di	= QuickRetrieveListClass instance data
		ds:bx	= QuickRetrieveListClass object (same as *ds:si)
		es 	= segment of QuickRetrieveListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickRetrieveListInitialize	method dynamic QuickRetrieveListClass, 
					MSG_QUICK_RETRIEVE_LIST_INITIALIZE
		uses	ax, cx, dx, bp
		.enter

		push	si			; save handle to self
	;
	; Setup the parameters so we can read the ini file.
	;
		mov	si, ds:[di].QRLI_key
		mov	dx, ds:[si]
		mov	cx, ds			; cx:dx <- key string
		mov	si, ds:[di].QRLI_category	
		mov	si, ds:[si]		; ds:si <- cat string

		mov	bp, InitFileReadFlags <0, 1, 0, 0>; allocate space
		call	InitFileReadString
		jcxz	short writeDefaults	; category and key not found

		call	MemLock
		mov	es, ax
		clr	di, ax, cx
countEntries:
		mov	{byte} cl, es:[di]
		inc	di
		jcxz	freeMem
		cmp	{byte} cl, C_CR
		jnz	countEntries		; keep searching
		inc	ax			; number of hits
		jmp	countEntries		; keep searching
		
freeMem:
		inc	ax			; there's one more entry
		call	MemFree
	;
	; Initialize the list
	;
		mov_tr	cx, ax
initializeList:
		pop	si			; ds:si <- self
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock
done::
		.leave	
		ret

writeDefaults:
	;
	; Use the table that's indexed to in our instance data to
	; write the default settings in our ini file.
	;
		mov	cx, ds
		mov	es, cx
		mov	bx, es:[di].QRLI_defaults

EC <		tst	bx						>
EC <		ERROR_Z QUICK_RETRIEVE_LIST_MUST_HAVE_DEFAULTS		>

		mov	bx, es:[bx]		; deref chunk
		ChunkSizePtr es, bx, bp	; bp <- size of chunk
		push	bp			; save size of chunk
writeDefaultsLoop:
		dec	bp
		dec	bp
		mov	di, bx
		mov	di, ds:[di].[bp]
		mov	di, ds:[di]
		call	InitFileWriteStringSection

		tst	bp
		jnz	writeDefaultsLoop
	;
	; We must return with cx= to the number of items in the list
	;
		
		pop	cx
		shr	cx
		jmp	initializeList					

QuickRetrieveListInitialize	endm


