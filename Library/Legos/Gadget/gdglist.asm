COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdglist.asm

AUTHOR:		Ronald Braunstein, Jul  7, 1995

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_ENT_INITIALIZE	Create a singe GenItem inside.

 ?? INT GadgetListInitStringArray
				Creates the array of strings in the heap
				and initializes the values.

    MTD MSG_ENT_DO_ACTION	See if this is an action we know how to
				perform

    MTD MSG_ENT_RESOLVE_ACTION	See if this is an action we know how to
				perform

    MTD MSG_GADGET_LIST_ACTION_SET_ITEM,
	MSG_GADGET_LIST_ACTION_GET_ITEM
				Message is sent when an item needs to be
				added or retrieved.

    MTD MSG_GADGET_LIST_GET_ITEM
				Return the string for the correct element
				of the list

 ?? INT GadgetListSetItem	Set a given item to be a given string.  If
				that ti

    MTD MSG_GADGET_LIST_QUERY_ITEM_MONIKER
				Return the string to use for the moniker
				for the given item.

    MTD MSG_GADGET_LIST_SET_BEHAVIOR
				

    MTD MSG_GADGET_LIST_GET_BEHAVIOR
				Returns the behavior type.

    MTD MSG_GADGET_LIST_GET_NUM_SELECTIONS
				Returns the highest number item that has
				been added to the list.

    MTD MSG_GADGET_LIST_GET_NUM_ITEMS
				Returns the highest number item that has
				been added to the list.

    MTD MSG_GADGET_LIST_SET_NUM_ITEMS
				This property can't be set, return error.

    MTD MSG_GADGET_LIST_GET_SELECTED_ITEM
				

    MTD MSG_GADGET_LIST_SET_SELECTED_ITEM
				Ensures the item is selected

    MTD MSG_GADGET_LIST_ACTION_GET_SELECTIONS,
	MSG_GADGET_LIST_ACTION_SET_SELECTIONS
				Gets or sets a given selection

    MTD MSG_GADGET_LIST_STATUS_MSG
				If we have been modifed generate a basic
				event

    INT GL_GetTrueSelection	Get lowest selected item if > 1 selection

    MTD MSG_GADGET_LIST_GENERATE_CHANGED_EVENT
				Creates a basic event and sends it.

    MTD MSG_GADGET_LIST_ACTION_DELETE_ITEM
				Deletes the given item and moves all items
				above it down one.  Redraws the list.

 ?? INT DeleteItemRealCode	Callback routine for operating on an array
				to delete an item

 ?? INT GadgetListDoActionOnArray
				Common code for inserting and deleting

    MTD MSG_ENT_GET_CLASS	

    MTD MSG_GADGET_LIST_ACTION_INSERT_ITEM
				Inserts a new item in the list before the
				given index.

 ?? INT InsertItemRealCode	Callback routine for operating on an array
				to Insert an item

 ?? INT ClearItemsFromRealCode	

    MTD MSG_GADGET_LIST_SET_NUM_VISIBLE_ITEMS
				Sets the number of lines in the list.

    INT GetListSize		Looks up the HINT_FIXED_SIZE values for the
				list

 ?? INT SetListSize		Sets the number of elements in a list

    MTD MSG_GADGET_LIST_GET_NUM_VISIBLE_ITEMS
				Returns the number of visible items.

    MTD MSG_GEN_REMOVE_GEOMETRY_HINT
				Deal with a bug in the UI that causes
				crashes when twiddling geometry hints on
				scrolling lists while they're not usable.
				See CopySizeToViewIfSpecified::50$:.  The
				code tries to send a message to
				ds:[si].OLSLI_view, which will be 0 in this
				case.

    MTD MSG_GADGET_SET_WIDTH,
	MSG_GADGET_SET_HEIGHT	

 ?? INT GLCheckWidthHeightArg	Check that the argument passed to the
				list's SET_WIDTH/HEIGHT is acceptable.
				
				width: Must be positive. Must be >=5 The
				regions characterizing normalButtons are
				parameterized.  Since width < 5 will make
				the regions unhealthy, we filter out those
				widthes here.  Note that the spui provides
				a min height in BWButtonRegionSet Struct,
				but nothing for min widthes. Also note that
				the MenuDownMarkBitmap (the black
				horizontal line) requires 14 bits, so lists
				probably won't be narrower than ~14.
				
				height: Must be positive. Must be >=6 If
				height is less than 6, vertical lines
				appear when the main button is drawn. I
				tried fixing this the way a similar problem
				with buttons was fixed -- set the
				normalButton's minHeight to 6.  But
				something (possibly OLMBSpecGetExtraSize in
				copenMenuButton.asm) is causing this value
				to be ignored.  This is probably a
				temporary fix.

    MTD MSG_GADGET_LIST_ACTION_CLEAR_ALL
				

    MTD MSG_GADGET_SET_LOOK	Legos Property Handler

    MTD MSG_GADGET_GET_LOOK	

    MTD MSG_GADGET_SET_SIZE_HCONTROL,
	MSG_GADGET_SET_SIZE_VCONTROL
				Intercept these messages so we can forward
				hints on to our child object

 ?? INT GLForwardHintIfFound	Intercept these messages so we can forward
				hints on to our child object

    MTD MSG_GADGET_LIST_SET_NUM_SELECTIONS
				Call the common error routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/ 7/95   	Initial revision


DESCRIPTION:
	The list component, in both its incarnations:  pulldown and
	scrollable.

	Notes on Classes:
		Unfortunately, GadgetListClass is not actually a
		GenDynamicList, but is a GenInteraction instead.
		The interactions has GenDynamicList as a child.
		I believe this was done to get work around some geometry
		issues in the builder.

		The problem with this is that you have to use
		ObjCallContent instead of ObjCallInstance to send messages
		in list component handlers to the dynamic list.  If you
		want to send component messages to itself, continue to use
		ObjCallInstance.

		Lastly, the GDL is actually a subclass of GenDynamicList
		so it can subclass SPEC_CONVERT_DESIRED_SIZE_HINT to fix
		yet more geometry problems.


		Also, the GadgetList is subclassed from GadgetAgg,
		an extremely poorly named class.  It has nothing to do with
		aggregates in the legos sense, but just means an interaction
		that hold a real class.


TODO:
	* Document differences in set width/height for pulldown and scrolling
	* Ask components what numVisibleItems should do for pulldown lists
	* Do we want heightInLines to go along with widthInStdChars?
	* Larger question -- do we want itemHeight = height/numVisibleItems
	* Fix assertions in GET_NUM_VISIBLE_ITEMS
	* Document hints for each look

	$Id: gdglist.asm,v 1.1 98/03/11 04:26:33 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GADGET_LIST_MAX_ITEMS equ	64

idata	segment
	GadgetListClass		; this is really an interaction at Ent Level
idata	ends

makePropEntry list, behavior, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_GET_BEHAVIOR>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_SET_BEHAVIOR>

makePropEntry list, numSelections, LT_TYPE_INTEGER \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_GET_NUM_SELECTIONS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_SET_NUM_SELECTIONS>

makePropEntry list, numItems, LT_TYPE_INTEGER \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_GET_NUM_ITEMS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_SET_NUM_ITEMS>

makePropEntry list, selectedItem, LT_TYPE_INTEGER \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_GET_SELECTED_ITEM>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_SET_SELECTED_ITEM>

makePropEntry list, numVisibleItems, LT_TYPE_INTEGER \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_GET_NUM_VISIBLE_ITEMS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_SET_NUM_VISIBLE_ITEMS>

makePropEntry list, widthInStdChars, LT_TYPE_INTEGER \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_GET_WIDTH_IN_STD_CHARS>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_LIST_SET_WIDTH_IN_STD_CHARS>


makeUndefinedPropEntry list, caption
makeUndefinedPropEntry list, readOnly
makeUndefinedPropEntry list, graphic

compMkPropTable GadgetListProperty, list, behavior, numSelections, \
	numItems, selectedItem, numVisibleItems, widthInStdChars, \
	caption, readOnly, graphic

; normal actions
makeActionEntry	list, Delete, MSG_GADGET_LIST_ACTION_DELETE_ITEM, LT_TYPE_INTEGER,1
makeActionEntry list, Clear, MSG_GADGET_LIST_ACTION_CLEAR_ALL, LT_TYPE_INTEGER,0
makeActionEntry	list, Insert, MSG_GADGET_LIST_ACTION_INSERT_ITEM, LT_TYPE_INTEGER,2
makeActionEntry	list, Getcaptions, MSG_GADGET_LIST_ACTION_GET_ITEM, LT_TYPE_STRING,VAR_NUM_PARAMS
makeActionEntry	list, Setcaptions, MSG_GADGET_LIST_ACTION_SET_ITEM, LT_TYPE_VOID,VAR_NUM_PARAMS
makeActionEntry list, Getselections, MSG_GADGET_LIST_ACTION_GET_SELECTIONS, LT_TYPE_INTEGER,VAR_NUM_PARAMS
makeActionEntry list, Setselections, MSG_GADGET_LIST_ACTION_SET_SELECTIONS, LT_TYPE_VOID,VAR_NUM_PARAMS


compMkActTable list, Delete, Clear, Insert, Getcaptions, Setcaptions, Getselections, Setselections


;========================================================================
;			GadgetListClass Code
;========================================================================


MakePropRoutines List, list


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a singe GenItem inside.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 6/ 9/95   	Initial version
	martin	 9/27/95	Converted lists to base on GadgetAggClass

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListInitialize	method dynamic GadgetListClass, 
					MSG_ENT_INITIALIZE

		.enter
	;
	; I wish there were some way to stuff default values for a 
	; class in a .def file...
	;
		mov	cx, segment GenDynamicListClass
		mov	dx, offset  GenDynamicListClass
		movdw	ds:[di].GAI_contentClass, cxdx

	;
	; Call our superclass to create the content object of the class
	; we just stuffed in our instance data.
	;
		mov	di, offset GadgetListClass
		call	ObjCallSuperNoLock
	;
	; Now add the new child in the gen tree below us.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
		movdw	cxdx, ds:[di].GAI_contentObj
		clr	bp
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjCallInstanceNoLock
	;
	; Forward all list related messages to the container.
	;
		push	si
		mov	bx, ds:[LMBH_handle]
		xchgdw	bxsi, cxdx
		mov	di, ds:[si]
		add	di, ds:[di].GenItemGroup_offset
		movdw	ds:[di].GIGI_destination, cxdx
		mov	ax, MSG_GADGET_LIST_QUERY_ITEM_MONIKER
		mov	ds:[di].GDLI_queryMsg, ax 
	;
	; Set the container (our child) usable
	;
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjCallInstanceNoLock
	;
	; Code to tweak the actual GenDynamicList to work right at 
	; run-time 
	;	

	; now set us up to recieve the status message
		mov	ax, ATTR_GEN_ITEM_GROUP_STATUS_MSG
		mov	cx, 2
		call	ObjVarAddData
		mov	ds:[bx], MSG_GADGET_LIST_STATUS_MSG
				
		pop	si
		mov	di, ds:[si]			; deref handle
		add	di, ds:[di].GadgetList_offset
	;
	; Set number of items to 0
	;
		Assert	fptr	dsdi
		clr	ds:[di].GL_currentItems

	;
	; Initialize heap of 100 items.
	; (8 now)

	; get a fptr.RunHeapInfo
		push	di, si
		clr	ax
		pushdw	dsax
		call	RunComponentLockHeap
		add	sp, size fptr
		pop	di, si

		movdw	bxcx, dxax
		mov	ax, 8
		clr	dx			; no previous values
		clr	bp			; size of old list
		call	GadgetListInitStringArray
		Assert	fptr	dsdi
		mov	ds:[di].GL_arraySize, 8
		mov	ds:[di].GL_stringArrayToken, ax

		clr	ax
		push	si
		pushdw	dsax
		call	RunComponentUnlockHeap
		add	sp, size fptr
		pop	si

	;
	; Set the number of visible items in the list
	;
		mov	ax, 8
		mov	cx, SpecWidth <0,0>
		mov	dx, SpecHeight <SST_LINES_OF_TEXT, 8>
		call	SetListSize

	;
	; Tell the actual list to initialize
	;
		mov	di, ds:[si]			; deref handle
		add	di, ds:[di].GadgetList_offset
		mov	si, ds:[di].GAI_contentObj.chunk

		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		clr	cx
		call	ObjCallInstanceNoLock

	; Make it a pulldown list
	
		clr	cx
		mov	ax, HINT_ITEM_GROUP_TOOLBOX_STYLE
		call	ObjVarAddData
		mov	ax, HINT_ITEM_GROUP_MINIMIZE_SIZE
		call	ObjVarAddData
		mov	ax, HINT_ITEM_GROUP_DISPLAY_CURRENT_SELECTION
		call	ObjVarAddData
		
		.leave
		Destroy ax, cx, dx, bp	
		ret
GadgetListInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListInitStringArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the array of strings in the heap and initializes
		the values.

CALLED BY:	GadgetListEntInitialize, GadgetListSetItem
PASS:		ax	- size to create in tokens
		dx	- token of old array
		bx:cx	- fptr.RunHeapInfo
		bp	- size of old list in toknes
RETURN:		ax	- current token for array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListInitStringArray	proc	near
		uses	bx, cx, dx, es, si, di
		.enter

	; Alloc new array of ax*2 bytes
	;
		push	dx
		mov	cx, ax			; cx <- size in words
		shl	cx			; cx <- size in bytes
		mov	dl, 1			; initial ref
		clr	ax, di			; no initial data
		call	RunHeapAlloc_asm	; ax <- new token
		mov	bx, ax			; bx <- new token
		pop	dx

	; ax,bx - new array
	; cx - size new list in bytes
	; dx - old array
	; bp - size old list in tokens
	; Reset all elements to 0

		call	RunHeapLock_asm	; es:di <- new array
		clr	ax
		shr	cx		; always even # bytes
EC <		ERROR_C	-1						>
		push	di
		rep	stosw
		pop	di
		
		tst	dx
		jz	done

	; old array was passed, so copy it into new array
	; and throw it away

		push	ds		; must save sptr to obj block
		mov	ax, dx
		pushdw	esdi
		call	RunHeapLock_asm	; es:di <- old array
		movdw	dssi, esdi
		popdw	esdi
		mov	cx, bp		; cx <- size old list in tokens
		rep	movsw
		pop	ds
		call	RunHeapUnlock_asm
		call	RunHeapDecRef_asm

done:
		mov_tr	ax, bx		; ax <- new array
		call	RunHeapUnlock_asm

		.leave
		ret
GadgetListInitStringArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListDoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this is an action we know how to perform

CALLED BY:	MSG_ENT_DO_ACTION
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	8/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListDoAction	method dynamic GadgetListClass, 
					MSG_ENT_DO_ACTION
	.enter
	segmov	es, cs
	mov	bx, offset listActionTable
	mov	di, offset GadgetListClass	; for calling super
	mov	ax, segment dgroup		
	call	EntUtilDoAction
	.leave
	ret
GadgetListDoAction	endm



GadgetListResolveAction	method dynamic GadgetListClass, 
					MSG_ENT_RESOLVE_ACTION
	.enter
	mov	bx, offset listActionTable
	segmov	es, cs
	mov	di, offset GadgetListClass
	mov	ax, segment dgroup		
	call	EntResolveActionCommon
	.leave
	ret
GadgetListResolveAction	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListActionItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message is sent when an item needs to be added or retrieved.
		

CALLED BY:	MSG_GADGET_LIST_ACTION_ITEM
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		ss:bp	= EntDoActionArgs
RETURN:		
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		argv[0] = index of item
		argv[1] = value of item if it needs to be set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListActionItem	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_ACTION_SET_ITEM,
					MSG_GADGET_LIST_ACTION_GET_ITEM
		uses	es
		.enter
		Assert	fptr	ssbp

	;
	; If there is only one arg, retrieve the data.
	; If two args, set the data.
	;
		cmp	ss:[bp].EDAA_argc, 1
		je	getItem
		cmp	ss:[bp].EDAA_argc, 2
		LONG je	setItem

		mov	ax, CAE_WRONG_NUMBER_ARGS
error:
	;
	; Some error, ax contains which one.
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		
done:		
		.leave
		ret
		
getItem:
	; Get the item specified by the index passed in.
	; Validate index: should be in [0, numItems-1]
	; Return the string.
		mov	bx, ds:[di].GL_currentItems

		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error

		mov	cx, es:[di].CD_data.LD_integer
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		cmp	cx, bx
		jae	error

		movdw	dxax, ss:[bp].EDAA_runHeapInfoPtr
		push	bp
		sub	sp, size GetPropertyArgs
		mov	bp, sp
		movdw	ss:[bp].GPA_runHeapInfoPtr, dxax		
		mov	cx, es:[di].CD_data.LD_integer
		mov	ax, MSG_GADGET_LIST_GET_ITEM
		call	ObjCallInstanceNoLock
		add	sp, size GetPropertyArgs
		pop	bp

	;
	; Return its pointer
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, dx
		jmp	done

setItem:
	;
	; Set the item specified by the index.
	; There is no return value.

		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi

	; get the index arg
		mov	ax, CPE_PROPERTY_TYPE_MISMATCH
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error
	; get the string arg
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_STRING
		jne	error
		mov	ax, CPE_PROPERTY_TYPE_MISMATCH
		mov	bx, es:[di].CD_data.LD_integer
		cmp	bx, GADGET_LIST_MAX_ITEMS	; range is [0, 1023]
		jae	error
		mov	ax, es:[di][size ComponentData].CD_data.LD_string
		movdw	cxdx, ss:[bp].EDAA_runHeapInfoPtr
		call	GadgetListSetItem

		jmp	done

GadgetListActionItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGetItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the string for the correct element of the list

CALLED BY:	MSG_GADGET_LIST_GET_ITEM
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		cx	= item number (0-based)
		ss:bp	= GetPropertyArgs
RETURN:		dx	= string in heap (unlocked)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListGetItem	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_GET_ITEM
		uses	ax, bx, cx, bp, es, di
		.enter

	; check cx is in [0, numItems-1]
		cmp	cx, ds:[di].GL_currentItems
		ja	error
	;
	; First, get the array block so we can look up the string
		sub	sp, size RunHeapLockWithSpaceStruct
		movdw	dxax, ss:[bp].GPA_runHeapInfoPtr
		mov	bp, sp
		movdw	ss:[bp].RHLS_rhi, dxax
		mov	dx, ds:[di].GL_stringArrayToken
		mov	ss:[bp].RHLS_token, dx
		lea	bx, ss:[bp].RHLS_eptr
		movdw	ss:[bp].RHLS_dataPtr, ssbx
		mov	ss:[bp].RHLWSS_tempCX, cx
		
		call	RunHeapLock
		mov	bp, sp
		les	di, ss:[bp].RHLS_eptr

	;
	; Get the token for the string
		mov	bx, ss:[bp].RHLWSS_tempCX	; item number
		shl	bx			; byte offset in word array
		mov	dx, es:[di][bx]		; token of string
		mov	ss:[bp].RHLWSS_tempCX, dx
		call	RunHeapUnlock
		mov	bp, sp
		mov	dx, ss:[bp].RHLWSS_tempCX
		add	sp, size RunHeapLockWithSpaceStruct

	; return the token for the string, unlocked
done:
		.leave
		ret
error:
	; return a NULL pointer
		clr	dx
		jmp	done	
GadgetListGetItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a given item to be a given string.  If that ti

CALLED BY:	GadgetListActionItem
PASS:		ax	= token of string
		cx:dx	= fptr.RunHeapInfo
		bx	= index of item (0-based)
		*ds:si 	= GadgetListObject
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:
		increases reference count of string.

PSEUDO CODE/STRATEGY:
	Assume array of tokens created.
	If new item > arraySize
		# Make more space
		Create heap item of (new item) size.
		Copy data from old array to new array.
		Set others to NullToken.
		Delete old array heap item.
		
		Set new heap item in instance data of component.
		
	if array[token] = NullToken goto createNew
	# Change string
		Replace old string with new string.
		Delete old Heap Item.
			# Because string is passed in on heap, dont need:
			Create New Heap Item.
			Copy string into heap.
		Inc ref count on string.
		Store New token in array.
		Tell List number of items changed.
		goto done
	:createNew
		# Because string is passed in on heap, don't need:
			Create new Heap Item.
			Copy string into heap.
		Inc Ref Count on string.
		Store New token in array
		Tell List number of items changed.



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListSetItem	proc	far
	class	GadgetListClass
	uses	ax, cx, dx, bp, si, di, ds, es
	.enter
		mov	di, ds:[si]
		add	di, ds:[di].GadgetList_offset
		cmp	bx, ds:[di].GL_currentItems
		mov	bp, GDLI_NO_CHANGE
		jb	itemsSet

	; We now have more items than we had before.
		inc	bx
		mov	bp, bx
		sub	bp, ds:[di].GL_currentItems ; number of new items
		mov	ds:[di].GL_currentItems, bx
		dec	bx			; 0-based item number

itemsSet:
		push	bx			; 0-based item number
		push	bp			; save # new items
		cmp	bx, ds:[di].GL_arraySize
		jb	lockArrayBlock

	; The new element is out of our range, make the array bigger
	; have: cxdx-fptr  bx-item index    ax-string token
	; want: bxcx-fptr  ax-new # tokens  dx-old array token
	;
		push	bx, ax			; save index, string
		mov_tr	ax, bx
		inc	ax		; ax <- # tokens
		mov_tr	bx, cx		; bx <- fptr.high
		mov_tr	cx, dx		; cx <- fptr.low
		mov	dx, ds:[di].GL_stringArrayToken

		mov	bp, ds:[di].GL_arraySize
		mov	ds:[di].GL_arraySize, ax
		call	GadgetListInitStringArray
		mov	ds:[di].GL_stringArrayToken, ax
		pop	bx, ax			; restore index, string


	; If overwriting a string, decref the old value
	; ax - string token
	; bx - index of new item
	;
lockArrayBlock:
		mov_tr	cx, ax			; save string in cx
		mov	dx, ds:[di].GL_stringArrayToken
		mov	ax, dx
		call	RunHeapLock_asm		; es:di <- locked block
		shl	bx			; elt # to byte offset
		
		mov	ax, es:[di][bx]
		cmp	ax, NULL_TOKEN
		je	setToken
		call	RunHeapDecRef_asm

	; Put string in our array, incref, unlock array
	; cx string, dx array
setToken:
		mov_tr	ax, cx			; ax <- string
		mov	es:[di][bx], ax
		call	RunHeapIncRef_asm

		mov_tr	ax, dx			; ax <- array
		call	RunHeapUnlock_asm

	; Tell actual list to initialize either because of new item or
	; item changed
		pop	cx			; # new items
		pop	bx			; 0-based item number
		cmp	cx, GDLI_NO_CHANGE
		jne	addItems

	; We changed a moniker on an item.
	; Request it again.
	;
		mov	ax, MSG_GADGET_LIST_QUERY_ITEM_MONIKER
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bp, bx			; item number
		call	ObjCallInstanceNoLock
		jmp	done

addItems:
		mov	dx, cx
		mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
		mov	cx, GDLP_LAST
		call	ObjCallContentNoLock
	;
	; The spuis don't ask for new monikers if list is visible.
	; (There is one weird case where this happens)
	; Lets see if we can force the moniker updates it to happen.
		mov	cx, GDLI_NO_CHANGE
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallContentNoLock
done:
		.leave
		ret
GadgetListSetItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGenDynamicListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the string to use for the moniker for the
		given item.

CALLED BY:	MSG_GADGET_LIST_QUERY_ITEM_MONIKER
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		^lcx:dx	= list requesting moniker
		bp	= position of item requested. (0-based)

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		send MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 7/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListQueryItemMoniker    method dynamic GadgetListClass,
				MSG_GADGET_LIST_QUERY_ITEM_MONIKER
		.enter
	;
	; Lock down the string
	;
		push	bp			; item number
		clr	cx
		pushdw	dscx			; Object Block Header arg
		call	RunComponentLockHeap
		add	sp, size fptr

		pop	cx			; item number
	
		pushdw	dxax			; fptr.RunHeapInfo
		push	si

		sub	sp, size GetPropertyArgs
		mov	bp, sp
		movdw	ss:[bp].GPA_runHeapInfoPtr, dxax, bx

		mov	ax, MSG_GADGET_LIST_GET_ITEM
		call	ObjCallInstanceNoLock
		add	sp, size GetPropertyArgs

		mov	bx, cx			; item number
		mov	cx, dx			; token of string
		pop	si
		popdw	dxax			; fptr.RunHeapInfo

		jcxz	done
	; decrement stack after the unlock
			
	
		sub	sp, size RunHeapLockWithSpaceStruct
		mov	bp, sp
		movdw	ss:[bp].RHLS_rhi, dxax	; fptr.RunHeapInfo
		mov	ss:[bp].RHLS_token, cx
		mov	ss:[bp].RHLWSS_tempCX, bx
		lea	bx, ss:[bp].RHLS_eptr
		movdw	ss:[bp].RHLS_dataPtr, ssbx

		call	RunHeapLock
		mov	bp, sp
		movdw	cxdx, ss:[bp].RHLS_eptr
		mov	bp, ss:[bp].RHLWSS_tempCX	; item number
		
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallContentNoLock

		call	RunHeapUnlock
		add	sp, size RunHeapLockWithSpaceStruct

		clr	ax
		pushdw	dsax
		call	RunComponentUnlockHeap
		add	sp, size fptr
done:		
		.leave
		ret
GadgetListQueryItemMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetBehavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_LIST_SET_BEHAVIOR
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListSetBehavior	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_SET_BEHAVIOR
		uses	bp
		.enter

		mov	dl, ds:[di].EI_flags

		mov	si, ds:[di].GAI_contentObj.chunk
		les	di, ss:[bp].SPA_compDataPtr
		mov	cx, es:[di].CD_data.LD_integer
	;
	; Convert value to GenItemGroupBehaviorType
	; 0 -> GIGBT_EXCLUSIVE_NONE, 1 -> GIGBE_EXCLUSIVE,
	; 2 -> GIGBT_NON_EXCLUSIVE
	;
	CheckHack <GIGBT_EXCLUSIVE eq 0>
	CheckHack <GIGBT_EXCLUSIVE_NONE eq 1>
	CheckHack <GIGBT_NON_EXCLUSIVE eq 3>
		cmp	cx, 2		; check in range 0-2
		ja	errorDone
		neg	cx	; <0, -1, -3>
		inc	cx	; <1, 0, -2>
		jns	gotGIGBT

		mov	cx, GIGBT_NON_EXCLUSIVE
gotGIGBT:
		Assert	etype, cl, GenItemGroupBehaviorType
	;
	; List must be not usable while the behavior is changed.  Check the
	; visible flag to see what's up.
	;
		test	dl, mask EF_VISIBLE
		pushf
		jz	dontChange

		push	cx
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallInstanceNoLock
		pop	cx
dontChange:
		mov	ax, MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE
		call	ObjCallInstanceNoLock

		popf
		jz	done

		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock

done:
		.leave
		ret
errorDone:
EC <		mov	cx, es						>
EC <		cmpdw	cxdi, ss:[bp].SPA_compDataPtr			>
EC <		ERROR_NE -1						>
		Assert	fptr, esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
		
GadgetListSetBehavior	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGetBehavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the behavior type.

CALLED BY:	MSG_GADGET_LIST_GET_BEHAVIOR
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListGetBehavior	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_GET_BEHAVIOR
		uses	bp
		.enter
		mov	si, ds:[di].GAI_contentObj.chunk
		les	di, ss:[bp].GPA_compDataPtr

		mov	ax, MSG_GEN_ITEM_GROUP_GET_BEHAVIOR_TYPE
		call	ObjCallInstanceNoLock
		clr	ah
	;
	; Convert GIGBT value to spec value
	; 0 = no items (um.... EXCLUSIVE_NONE?)
	; 1 = one item (EXCLUSIVE)
	; 2 = multiple items (NON_EXCLUSIVE)
	;
	CheckHack <GIGBT_EXCLUSIVE eq 0>
	CheckHack <GIGBT_EXCLUSIVE_NONE eq 1>
	CheckHack <GIGBT_NON_EXCLUSIVE eq 3>

		cmp	ax, GIGBT_NON_EXCLUSIVE
		jne	convert
		mov	ax, -1
convert:
		neg	ax		; <-1, 0, 1>
		inc	ax		; <0, 1, 2>
		
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
		.leave
		ret
GadgetListGetBehavior	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGetNumSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the highest number item that has been added to the
		list.

CALLED BY:	MSG_GADGET_LIST_GET_NUM_SELECTIONS
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListGetNumSelections	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_GET_NUM_SELECTIONS
		uses	bp
		.enter
		mov	si, ds:[di].GAI_contentObj.chunk
		les	di, ss:[bp].GPA_compDataPtr

		mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
		call	ObjCallInstanceNoLock
		
		mov	es:[di].CD_data.LD_integer, ax
		mov	es:[di].CD_type, LT_TYPE_INTEGER
			
		.leave
		ret
GadgetListGetNumSelections	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGetNumItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the highest number item that has been added to the
		list.

CALLED BY:	MSG_GADGET_LIST_GET_NUM_ITEMS
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListGetNumItems	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_GET_NUM_ITEMS
		.enter
		mov	cx, ds:[di].GL_currentItems
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_data.LD_integer, cx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
			
		.leave
		ret

GadgetListGetNumItems	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetNumItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This property can't be set, return error.

CALLED BY:	MSG_GADGET_LIST_SET_NUM_ITEMS
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/12/95 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
GadgetListSetNumItems	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_SET_NUM_ITEMS
		.enter

		call	GadgetUtilReturnReadOnlyError

		les	bx, ss:[bp].SPA_compDataPtr
		mov	cx, es:[bx].CD_data.LD_integer
		mov	dx, ds:[di].GL_currentItems
		mov	ds:[di].GL_currentItems, cx

	;
	; FIXME Isn't this supposed to be a read-only property?
	;
	;
	; Hack -- in order to reuse GadgetListDoActionOnArray code, 
	; create an fake DoAction stack frame, and copy over relevant
	; Property stack frame stuff.  EntDoActionArgs is a superset
	; of SetPropertyArgs.  Why aren't the offsets just the same!
	; If EntDoActionArgs and SetPropertyArgs were made to match,
	; the following code would work.
	;
		cmp	cx, dx
		jge	done
	;  
	; Delete extra items.  The code below deletes items from
	; es:[bx].CD_data.LD_integer on.
	;
		push	cx, dx
		mov	dx, offset ClearItemsFromRealCode
		call	GadgetListDoActionOnArray

		pop	cx, dx
		mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
		call	ObjCallContentNoLock
done:

		.leave
		ret

GadgetListSetNumItems	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGetSelectedItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_LIST_GET_SELECTED_ITEM
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		0-based index into list
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListGetSelectedItem	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_GET_SELECTED_ITEM
		uses	bp
		.enter
		les	di, ss:[bp].GPA_compDataPtr

		mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
		call	ObjCallContentNoLock

		cmp	ax, 1
		ja	many
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallContentNoLock
done:
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
		.leave
		ret
many:
		mov	bp, ax		; bp - num items
		call	GL_GetTrueSelection
		mov_tr	ax, cx
		jmp	done

GadgetListGetSelectedItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetSelectedItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures the item is selected

CALLED BY:	MSG_GADGET_LIST_SET_SELECTED_ITEM
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListSetSelectedItem	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_SET_SELECTED_ITEM
		uses	bp
		.enter

		mov	dx, ds:[di].GL_currentItems
		les	di, ss:[bp].SPA_compDataPtr
		mov	cx, es:[di].CD_data.LD_integer

		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		cmp	cx, dx			; 0-based index
		jae	setNone
		tst	cx
		jb	setNone

		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
setNone:
		clr	dx			; determinate
		call	ObjCallContentNoLock

		.leave
		ret

GadgetListSetSelectedItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListActionSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets or sets a given selection

CALLED BY:	MSG_GADGET_LIST_ACTION_SELECTIONS
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListActionSelections	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_ACTION_GET_SELECTIONS,
					MSG_GADGET_LIST_ACTION_SET_SELECTIONS
		uses	bp
		.enter


	; Validate 1st param: should be in [0, numItems-1]
	;
		mov	bx, ds:[di].GL_currentItems

		les	di, ss:[bp].EDAA_argv
		Assert	fptr	esdi
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error
		
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		cmp	es:[di].CD_data.LD_integer, bx
		jae	error
		
	; One arg:  retrieve the data.
	; Two args: set the data.
	;
		cmp	ss:[bp].EDAA_argc, 1
		je	getSelection
		cmp	ss:[bp].EDAA_argc, 2
		je	setSelection

	;argError:
		mov	ax, CAE_WRONG_NUMBER_ARGS

error:
	;
	; Some error.  ax contains which one
	;
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		
done:		
		.leave
		ret


getSelection:
	; esdi points to argv[0], integer
		Assert	fptr	esdi
		Assert	e	es:[di].CD_type, LT_TYPE_INTEGER

		mov	cx, es:[di].CD_data.LD_integer
		push	bp
		mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
		call	ObjCallContentNoLock
		pop	bp
	; Carry set if selected

		mov	cx, 0			; clear without changing CF
		jnc	returnCX
		inc	cx
returnCX:
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		jmp	done


setSelection:
		Assert	fptr	esdi
		Assert	e	es:[di].CD_type, LT_TYPE_INTEGER
		
	; first arg is index of item
		
		mov	cx, es:[di].CD_data.LD_integer

	; second arg is value, 0 for unselect, 1 for select
		mov	dx, es:[di][size ComponentData].CD_data.LD_integer

	;
	; unfortunately MSG_GEN_ITEM_GROUP_SET_ITEM_STATE does not work
	; for exclusive lists.
	;
		push	cx, dx, bp
		mov	ax, MSG_GEN_ITEM_GROUP_GET_BEHAVIOR_TYPE
		call	ObjCallContentNoLock
		pop	cx, dx, bp

		cmp	al, GIGBT_NON_EXCLUSIVE
		je	nonExcl
		cmp	dx, 0
		je	clearExcl

setExcl::
		push	bp		; frame ptr
		push	cx		; item
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		call	ObjCallContentNoLock
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		pop	cx		; item
		clr	dx
		call	ObjCallContentNoLock
		pop	bp		; frame ptr
ret0:
		clr	cx
		jmp	returnCX

nonExcl:
		push	bp
		mov	ax, MSG_GEN_ITEM_GROUP_SET_ITEM_STATE
		call	ObjCallContentNoLock
		pop	bp
		clr	cx
		jmp	returnCX

clearExcl:
	; Only exclusive/none is allowed to clear
	;
		cmp	al, GIGBT_EXCLUSIVE
		je	ret0
		Assert	e, al, GIGBT_EXCLUSIVE_NONE
	
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		push	bp		; frame ptr
		push	cx		; item
		call	ObjCallContentNoLock
		pop	cx
		cmp	ax, cx
		jne	cleared
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		call	ObjCallContentNoLock
cleared:		
		pop	bp		; frame ptr
		jmp	ret0
		
GadgetListActionSelections	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListStatusMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we have been modifed generate a basic event

CALLED BY:	MSG_GADGET_LIST_STATUS_MSG
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		cx 	= current selection
		bp	= number of selections
		dl	= GenItemGroupStateFlags
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListStatusMsg	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_STATUS_MSG
		.enter
	;
	; If we aren't modified by the user, just exit.
	;
		test	dl, mask GIGSF_MODIFIED
		jz	done
		
		cmp	bp, 1
		jbe	doEvent
		call	GL_GetTrueSelection
doEvent:
		mov	ax, MSG_GADGET_LIST_GENERATE_CHANGED_EVENT
		call	ObjCallInstanceNoLock

done:
		.leave
		ret
GadgetListStatusMsg	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GL_GetTrueSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get lowest selected item if > 1 selection

CALLED BY:	INTERNAL
PASS:		*ds:si	- GadgetList object
		bp	- # selections
RETURN:		cx	- selected item
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	2/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GL_GetTrueSelection	proc	near
	uses	ax,bx,dx,ds,si,di,bp
	.enter
		mov	ax, bp
		shl	ax		; convert to # words
		mov	di, sp		; save for later
		sub	sp, ax
		movdw	cxdx, sssp	; cx:dx - buffer of ax bytes
		mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
		call	ObjCallContentNoLock
		
	; Loop through buffer, find lowest item into bx
	;
		movdw	dssi, cxdx	; dssi - buffer
		mov_tr	cx, ax		; cx - # selections
		mov	bx, 0xffff

bufferLoop:
		lodsw
		cmp	ax, bx
		jae	nextItem
		mov_tr	bx, ax		; found a new lower bound
nextItem:
		loop	bufferLoop
		mov	cx, bx		; cx - current selection
		mov	sp, di		; restore sp

	.leave
	ret
GL_GetTrueSelection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGenerateChangedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a basic event and sends it.

CALLED BY:	MSG_GADGET_LIST_GENERATE_CHANGED_EVENT
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		cx	= index (0-based)
		dx	= value
RETURN:		nada
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	If the list is a popup, an event raised here might cause a
	runtime error and a UserDoDialog.  The dialog dispatch loop
	causes a MSG_META_FINAL_OBJ_FREE to go to the selected GenItem
	too soon, as the Item still has a MSG_META_END_SELECT on the
	stack above us.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListGenerateChangedEvent	method dynamic GadgetListClass, 
				MSG_GADGET_LIST_GENERATE_CHANGED_EVENT

		mov	ax, MSG_GADGET_LIST_GENERATE_CHANGED_EVENT_LOW
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		ret

GadgetListGenerateChangedEvent	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGenerateChangedEvent_LOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a basic event and sends it.

CALLED BY:	MSG_GADGET_LIST_GENERATE_CHANGED_EVENT_LOW
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		cx	= index (0-based)
RETURN:		nada
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
listSetEventString	TCHAR	"changed", C_NULL
GadgetListGenerateChangedEventLow	method dynamic GadgetListClass, 
				MSG_GADGET_LIST_GENERATE_CHANGED_EVENT_LOW
		params	local	EntHandleEventStruct
		result	local	ComponentData
		ForceRef	result
		.enter

		mov	ax, offset listSetEventString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 1
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, cx
		movdw	cxdx, ssax			; cx:dx = params
		mov	ax, MSG_ENT_HANDLE_EVENT
		call	ObjCallInstanceNoLock

done::
	.leave
	ret
GadgetListGenerateChangedEventLow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListActionDeleteItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the given item and moves all items above it down
		one.  Redraws the list.

CALLED BY:	MSG_GADGET_LIST_ACTION_DELETE_ITEM
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		ss:bp	= EntDoActionArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListActionDeleteItem	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_ACTION_DELETE_ITEM
		uses	bp
		.enter
	;
	; If there is only one arg, retrieve the data.
	;
		Assert	fptr	ssbp
		les	bx, ss:[bp].EDAA_retval
		Assert	fptr	esbx
		mov	es:[bx].CD_type, LT_TYPE_INTEGER
		mov	es:[bx].CD_data.LD_integer, 0
		cmp	ss:[bp].EDAA_argc, 1
		mov	dx, offset DeleteItemRealCode
		call	GadgetListDoActionOnArray
		jc	done

	; Tell the list it has one fewer items

		mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
		mov	dx, 1
		call	ObjCallContentNoLock
done:		
		.leave
		ret

GadgetListActionDeleteItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteItemRealCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for operating on an array to delete an item

CALLED BY:	
PASS:		*ds:si = object
		ds:di = instance data

		ss:bp.RHLWSS_tempBX	= 0-based index
				other fields filled from lock
RETURN:		ax 	= -1, to not IncRef on a token
		dx	= token of item to do DecRef on.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteItemRealCode	proc	near
		class	GadgetListClass
		.enter
	;---------------------------------------------------
	; We have the array in memory, shift everything down.
		Assert	fptr	dsdi
		mov	cx, ds:[di].GL_currentItems
		jcxz	done				; if none, do nothing
		dec	ds:[di].GL_currentItems
		mov	bx, ss:[bp].RHLWSS_tempCX	; index, 0-based
		les	di, ss:[bp].RHLS_eptr

	; let es:di point at index to be nuked and ds:si one word after it
	;		Assert	e size RunHeapToken, size word
	; cx = number of items left to copy =
	; total number - (0-based index +1)
		push	cx				; original array size
		push	ds				; object block
		sub	cx, bx
		dec	cx
		
		shl	bx				; change to word offset
		add	di, bx
		segmov	ds, es
		mov	si, di
		add	si, size word
		mov	dx, es:[di]			; save old token
	;						; before deleting
		jcxz	afterCopy
EC <		shl	cx						>
		Assert	okForRepMovsb
EC <		shr	cx						>
		rep	movsw				; copy token at a time
afterCopy:
		pop	ds				; object block
		mov	ax, -1
	;
	; clear end value
	;
		pop	bx				; orignal array size
		les	di, ss:[bp].RHLS_eptr
		dec	bx				; numItems - 1
		js	afterClear
		shl	bx				; map to word offset
		mov	{word} es:[di][bx], 0
afterClear:
	;---------------------------------------------------
	;
	; Decrease the ref count on the string we just deleted
	;
		mov_tr	ax, dx
		call	RunHeapDecRef_asm
done:

		.leave
		ret
DeleteItemRealCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListDoActionOnArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for inserting and deleting

CALLED BY:	GadgetListActionDeleteItem, GadgetListActionAddItem
PASS:		ss:bp	= EntDoActionArgs
		*ds:si	= object
		ds:di	= instance data
		dx	= offset of routine to call
RETURN:		cx	= item deleted or inserted
		CF	= set iff error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListDoActionOnArray	proc	near
		class	GadgetListClass

		uses	bx, dx, si, di, ds, es, bp
		.enter
		
	;
	; Get the item specified by the index passed in.
	; Return the string.
		
		les	bx, ss:[bp].EDAA_argv
		Assert	fptr	esbx
		mov	ax, CAE_WRONG_TYPE
		cmp	es:[bx].CD_type, LT_TYPE_INTEGER
		jne	error

		mov	cx, es:[bx].CD_data.LD_integer
		cmp	ss:[bp].EDAA_argc, 1
		je	afterArgs
	;
	; Remember which string to add.
	; We are out out registers and stack frames so store it as
		mov	ax, es:[bx][size ComponentData].CD_data.LD_integer

afterArgs:

	; *ds:si = object, cx = 0-based item number
		Assert	chunk	si, ds
		Assert	fptr	dsdi

	; allow inserting into an empty list
		jcxz	continue
	;
	; If not in bounds of list, bail
	;
		cmp	cx, ds:[di].GL_currentItems
		jae	badBounds
		cmp	cx, 0
		jnl	continue
		clr	cx			; if negative, insert at start
continue:
		push	cx			; item to return

	;
	; Lock down the array block and shift everything
	;
		push	ax			; second arg, if any
		push	cx			; item
		push	ds:[di].GL_stringArrayToken
		push	dx			; callback
		clr	ax
		pushdw	dsax
		call	RunComponentLockHeap
		add	sp, size fptr

		pop	bp			; callback
		pop	cx			; token
		pop	bx			; item
		pop	di			; second arg, if any
		
		sub	sp, size RunHeapLockWithSpaceStruct
		push	bp			; callback
		mov	bp, sp
		add	bp, size word		; um, ignore that last push \
						; it is not part of the frame.

		movdw	ss:[bp].RHLS_rhi, dxax
		mov	ss:[bp].RHLWSS_tempAX, di	; second arg, string
		lea	ax, ss:[bp].RHLS_eptr
		movdw	ss:[bp].RHLS_dataPtr, ssax
		mov	ss:[bp].RHLS_token, cx
		mov	ss:[bp].RHLWSS_tempCX, bx	; index
		pop	ss:[bp].RHLWSS_tempDX		; callback

		call	RunHeapLock
		mov	bp, sp

		mov	dx, ss:[bp].RHLWSS_tempDX
	;----------------------------------
		mov	di, ds:[si]
		add	di, ds:[di].GadgetList_offset	; rederef di
		call	dx

	;----------------------------------
	;
	; unlock the array
	;
		call	RunHeapUnlock
		add	sp, size RunHeapLockWithSpaceStruct

		clr	dx
		pushdw	dsdx
		call	RunComponentUnlockHeap
		add	sp, size dword

		pop	cx			; item
		clc
done:
		
		.leave
		ret
badBounds:
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
error:
	;
	; Some error, ax contains which one.
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
doneError::
		stc
		jmp	done
		
GadgetListDoActionOnArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListEntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListEntGetClass	method dynamic GadgetListClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetListString
		mov	dx, offset GadgetListString
		ret
GadgetListEntGetClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListActionInsertAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts a new item in the list before the given index.

CALLED BY:	MSG_GADGET_LIST_ACTION_INSERT_ACTION
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
		ss:bp	= EntDoActionArgs
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If the array has room for another element, just shift
		everything up one.
		If not, create an empty element on the end and shift everything
		up.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListActionInsertAction	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_ACTION_INSERT_ITEM
		uses	bp
		.enter
		Assert	fptr	ssbp

	;
	; If there is only one arg, retrieve the data.
	;
		les	bx, ss:[bp].EDAA_retval
		Assert	fptr	esbx
		mov	es:[bx].CD_type, LT_TYPE_INTEGER
		mov	es:[bx].CD_data.LD_integer, 0

	; have we already the max number of items?
		cmp	ds:[di].GL_currentItems, GADGET_LIST_MAX_ITEMS
		je	error
		
	;
	; Ensure we have space for another element
	;
		mov	dx, ds:[di].GL_arraySize
		cmp	ds:[di].GL_currentItems, dx
		jne	okToAdd

		push	bp
		mov	ax, ds:[di].GL_arraySize
		add	ax, 10				; add extra space
		mov	dx, ds:[di].GL_stringArrayToken
		movdw	bxcx, ss:[bp].EDAA_runHeapInfoPtr
		mov	bp, ds:[di].GL_arraySize
		mov	ds:[di].GL_arraySize, ax
		call	GadgetListInitStringArray
		mov	ds:[di].GL_stringArrayToken, ax
		pop	bp


okToAdd:
		mov	dx, offset InsertItemRealCode
		call	GadgetListDoActionOnArray
		jc	done


	; Tell the list it has one more item

		mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
		mov	dx, 1
		call	ObjCallContentNoLock
done:		
		.leave
		ret
error:
	;
	; Some error, ax contains which one.
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
		
GadgetListActionInsertAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertItemRealCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for operating on an array to Insert an item

CALLED BY:	
PASS:		*ds:si = object
		ds:di = instance data

		ss:bp.RHLWSS_tempBX	= 0-based index
				other fields filled from lock
RETURN:		ax	= token to incref on
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	 8/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertItemRealCode	proc	near
		class	GadgetListClass
		.enter
	;---------------------------------------------------
	; We have the array in memory, shift everything up.
		Assert	fptr	dsdi
		mov	cx, ds:[di].GL_currentItems
		inc	ds:[di].GL_currentItems
		mov	bx, ss:[bp].RHLWSS_tempCX	; index, 0-based
		les	di, ss:[bp].RHLS_eptr

	;
	; We need to do a memcpy, but we have to start at the end of the
	; array and work backwords. Otherwise, the movsw will write over the
	; next data we want to copy

	; let es:di point at the empty space at the end and ds:si one word
	; before it.

	; cx = total number in list
	; cx = number of items left to copy =
	; total number - [item to insert before /(0-based index) ] +1
		
		push	ds			; object block

		add	di, cx
		add	di, cx			; after end of array
		mov	si, di			; 
		dec	si
		dec	si			; last element in array

		sub	cx, bx

		segmov	ds, es
		Assert	fptr	dssi
		std	
		rep	movsw				; copy token at a time
		cld
		Assert	fptr	esdi

		pop	ds				; object block
	;
	; Set the new element to the new string
	; Add increment reference count to that string
	;
		les	di, ss:[bp].RHLS_eptr
		shl	bx			; change to word offset
		mov	ax, ss:[bp].RHLWSS_tempAX
		mov	es:[di][bx], ax
		call	RunHeapIncRef_asm
	
	;---------------------------------------------------

		.leave
		ret
InsertItemRealCode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearItemsFromRealCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		ds:di	= GadgetList instance data
		cx	= item to delete from (all items 
			  after this item are toast.)

RETURN:		
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearItemsFromRealCode	proc	near
		class	GadgetListClass
		uses	bx
		.enter

		Assert	fptr	dsdi
		mov	bx, ss:[bp].RHLWSS_tempCX	; index, 0-based
		mov	cx, ds:[di].GL_currentItems
	;
	; Make cx = count of items between passed in index and end of list
	;
		sub	cx, bx
		jle	done		
	;
	; Make es:di = pointer to first list item to delete
	;
		mov	ds:[di].GL_currentItems, bx
		les	di, ss:[bp].RHLS_eptr
		shl	bx, 1
		add	di, bx

deleteItem:
	;
	; Zero out tokens and decrement reference count
	;
		clr	ax
		xchg	es:[di], ax
		call	RunHeapDecRef_asm
		inc	di
		inc	di
		
		loop	deleteItem
done:

		.leave
		ret
ClearItemsFromRealCode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetNumVisibleItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the number of lines in the list.

CALLED BY:	MSG_GADGET_LIST_SET_NUM_VISIBLE_ITEMS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
GadgetListSetNumVisibleItems	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_SET_NUM_VISIBLE_ITEMS
		.enter

		call	GadgetUtilReturnReadOnlyError
	;
	; Get the number of lines the user wants the list to be.
	;
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi

		mov	bx, es:[di].CD_data.LD_integer
		cmp	bx, 1
		jle	done			; FIXME should RTE here...
		cmp	bx, 25
		jg	done			; FIXME should RTE here...

		call	GetListSize

		mov	ax, bx
		call	SetListSize
done:
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetListSetNumVisibleItems	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetListSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks up the HINT_FIXED_SIZE values for the list

CALLED BY:	INTERNAL
PASS:		*ds:si = GadgetList object
RETURN:		ax = CSHA_count
		cx = CSHA_width
		dx = CSHA_height
DESTROYED:	nothing
SIDE EFFECTS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetListSize	proc	near
	class	GadgetListClass
	uses	bx, di, si
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
		mov	si, ds:[di].GAI_contentObj.chunk
		
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
EC <		ERROR_NC	-1					>
		mov	ax, ds:[bx].CSHA_count
		mov	cx, ds:[bx].CSHA_width
		mov	dx, ds:[bx].CSHA_height

		.leave
		ret
GetListSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetListSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the number of elements in a list

CALLED BY:	GadgetListSetNumVisibleItems, GadgetListEntInitialize
PASS:		cx	= SpecWidth
		dx	= SpecHeight
		ax	= number of desired items
		*ds:si	= GenDynamicListClass object
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Sends a VUM_DELAYED_xxx to the list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetListSize	proc	near
	.enter

	;
	; Setup args for setting property
	;
		sub	sp, size SetSizeArgs
		mov	bp, sp
		mov	ss:[bp].SSA_width, cx
	;okay, its a weird way of setting the field.
		mov	ss:[bp].SSA_height, dx
	;		or	ss:[bp].SSA_height, cx
		mov	ss:[bp].SSA_count, ax
		mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_APP_QUEUE
		mov	dx, size SetSizeArgs

		mov	ax, MSG_GEN_SET_FIXED_SIZE
		call	ObjCallContentNoLock

		add	sp, size SetSizeArgs
		
	.leave
	ret
SetListSize	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListGetNumVisibleItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of visible items.

CALLED BY:	MSG_GADGET_LIST_GET_NUM_VISIBLE_ITEMS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListGetNumVisibleItems	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_GET_NUM_VISIBLE_ITEMS
		uses	bp
		.enter

		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi

		call	GetListSize
gotNumVisible::
	;		Assert	ge ax, 1
	;		Assert	le ax, 25
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax	; num items
		
		.leave
		Destroy	ax, cx, dx
		ret

GadgetListGetNumVisibleItems	endm


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GLGenRemoveGeometryHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a bug in the UI that causes crashes when
		twiddling geometry hints on scrolling lists while they're
		not usable.  See CopySizeToViewIfSpecified::50$:.  The
		code tries to send a message to ds:[si].OLSLI_view, which
		will be 0 in this case.

CALLED BY:	MSG_GEN_REMOVE_GEOMETRY_HINT
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #

PSEUDO CODE/STRATEGY:
		Lets just do the ObjVarDeleteData part, and forget about
		MSG_SPEC_RESCAN_GEO_AND_UPDATE (see GenRemoveGeometryHint,
		the default handler).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GLGenRemoveGeometryHint	method dynamic GadgetListClass, 
					MSG_GEN_REMOVE_GEOMETRY_HINT
		.enter

		mov	si, ds:[di].GAI_contentObj.chunk
		mov	ax, cx
		call	ObjVarDeleteData

		Destroy	ax, cx, dx, bp
		
		.leave
		ret
GLGenRemoveGeometryHint	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetWidthHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_SET_WIDTH
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetAggClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListSetWidthHeight	method dynamic GadgetListClass, 
					MSG_GADGET_SET_WIDTH,
					MSG_GADGET_SET_HEIGHT
		uses	bp, es
		.enter
	;
	; Get argument and make it positive.
	;
		call	GLCheckWidthHeightArg		; bx = value
							; es:di = data
		jc	callSuper			; Let superclass
							; handle type error.
	;
	; restuff the current unspecified value back in.
	; We have to get the current width and height so we
	; can set it again as we can't set one without the other.
	;
		push	ax, bp				; save message, args
		cmp	ax, MSG_GADGET_SET_WIDTH
		pushf
		call	GetListSize			; ax, cx, dx set
		popf

	; ax = child count (numVisibleItems)
	; bx = new dimension value
	; cx = SpecWidth
	; dx = SpecHeight (should SST_LINES_OF_TEXT if scrollable)

		je	setWidth	; set width always uses common case
		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
		cmp	ds:[di].GL_look, LOOK_LIST_SCROLLABLE
		je	setScrollableHeight
setHeight::
		clr	ax		; no # items for non-scrollables!
		mov	dx, bx
		or	dx, SpecWidth <SST_PIXELS, 0>
		jmp	setCommon

setWidth:
		mov_tr	cx, bx
		or	cx, SpecWidth <SST_PIXELS, 0>
setCommon:
	;
	; cx - SpecWidth, dx - SpecHeight, ax = numVisibleItems
	;
		call	SetListSize

		pop	ax, bp			; original message, args
		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
		cmp	ds:[di].GL_look, LOOK_LIST_SCROLLABLE
		je	scrollable
callSuper:
		mov	di, offset GadgetListClass
		segmov	es, dgroup, cx
		call	ObjCallSuperNoLock
scrollable:
		.leave
		ret

setScrollableHeight:
	;
	; cx - current SpecWidth, dx - current SpecHeight,
	; ax - current numVisibleItems, bx = new height in pixels
	;
	; If we're scrollable, we need to convert the pixel height into some
	; number of lines of text.  Otherwise, just use the pixel values.
	;
		mov_tr	dx, bx			; dx = new height 
		mov_tr	bx, ax			; bx = numVisItems
	;	clr	ax			; ax = numVis for pulldown
	;	CheckHack <SST_PIXELS eq 0>
	;	mov	di, ds:[si]
	;	add	di, ds:[di].Gadget_offset
	;	tst	ds:[di].GL_look
	;	jz	setCommon
		
		push	bx, cx			; numVisItems, width
		push	dx			; new height to convert
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		mov	di, bp
		
		mov	ax, SpecSizeSpec <SST_LINES_OF_TEXT, 1>
		call	VisConvertSpecVisSize
						; ax = value in pixels
		mov	cx, ax
		pop	ax			; new height to convert
		Assert	e ch, 0
		div	cl			; al = num lines
		clr	dx
		mov	dl, al
		
		call	GrDestroyState
		pop	ax, cx			; numVisItems, width
		cmp	dl, GADGET_LIST_MAX_ITEMS
		jbe	validSize
		mov	dl, GADGET_LIST_MAX_ITEMS
validSize:
	;
	; Change numVisItems to match our new height, convert height to
	; SpecHeight.
	;
	; no no no
	;
	;		mov	ax, dx
		or	dx, SpecHeight <SST_LINES_OF_TEXT, 0>
		jmp	setCommon
GadgetListSetWidthHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GLCheckWidthHeightArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the argument passed to the list's
		SET_WIDTH/HEIGHT is acceptable.

		width:  Must be positive.
			Must be >=5
			The regions characterizing normalButtons
			are parameterized.  Since width < 5 will
			make the regions unhealthy, we filter out
			those widthes here.  Note that the spui
			provides a min height in BWButtonRegionSet
			Struct, but nothing for min widthes.
			Also note that the MenuDownMarkBitmap (the
			black horizontal line) requires 14 bits,
			so lists probably won't be narrower than ~14.

		height: Must be positive.
			Must be >=6
			If height is less than 6, vertical lines
			appear when the main button is drawn.
			I tried fixing this the way a similar problem
			with buttons was fixed -- set the normalButton's
			minHeight to 6.  But something (possibly
			OLMBSpecGetExtraSize in copenMenuButton.asm) is
			causing this value to be ignored.  This is
			probably a temporary fix.


CALLED BY:	GadgetListSetWidthHeight only
PASS:		ax	= MSG_GADGET_SET_WIDTH/HEIGHT
		ss:bp	= SetPropertyArgs
RETURN:		es:di	= ComponentData from SetPropertyArgs
		bx	= dimension
		es:di.CD_DATA.LD_integer
				= stuffed with legitimate value
		carry	= set if error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 6/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GLCheckWidthHeightArg	proc	near
		uses	cx
		.enter
	;
	; Fetch argument, check type.
	;
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error
	;
	; Check for legitimate values.
	;
		mov	bx, es:[di].CD_data.LD_integer
		cmp	bx, 0
		jg	checkWidthArg
		mov	bx, 1
checkWidthArg:
		mov	cx, 6			; height must be >=6
		cmp	ax, MSG_GADGET_SET_HEIGHT
		je	doCompare
		dec	cx			; width must be >=5
doCompare:
		cmp	bx, cx
		jge	doneOK
		mov	bx, cx

doneOK:
		mov	es:[di].CD_data.LD_integer, bx
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
GLCheckWidthHeightArg	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListActionClearAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_LIST_ACTION_CLEAR_ALL
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListActionClearAll	method dynamic GadgetListClass, 
					MSG_GADGET_LIST_ACTION_CLEAR_ALL
		.enter
	;
	; Enumerate the items and delete them
	;
		les	bx, ss:[bp].EDAA_argv
		Assert	fptr	esbx
		mov	es:[bx].CD_type, LT_TYPE_INTEGER
		clr	es:[bx].CD_data.LD_integer	
		mov	ss:[bp].EDAA_argc, 1	; stuff arguments to work w/
						; GadgetListDoActionOnArray 

		mov	cx, ds:[di].GL_currentItems
		jcxz	done			; if no items, do nothing
		push	cx
		mov	dx, offset ClearItemsFromRealCode
		call	GadgetListDoActionOnArray	

		pop	dx
		mov	cx, GDLP_FIRST
		mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
		call	ObjCallContentNoLock
done:
		.leave
		ret

GadgetListActionClearAll	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_LIST_SET_LOOK
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If look not valid, set to 0

		Remove all unneeded hints for given look.
		Add needed hints for look.

		Pass message up to spui so it knows how draw
		the arrows for pcv.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListSetLook	method dynamic GadgetListClass, 
					MSG_GADGET_SET_LOOK
		.enter

		push	ax, si, es
	;
	; setup to use list
	;
		les	bx, ss:[bp].SPA_compDataPtr
		mov	cx, es:[bx].CD_data.LD_integer
		mov	si, ds:[di].GAI_contentObj.chunk
	;
	; call utility to add and remove hints as necessary
	;
		mov	ax, GadgetListLook		;ax <- maximum look
		mov	cx, length listHints		;cx <- length of hints
		segmov	es, cs
		mov	dx, offset listHints		;es:dx <- ptr to hints
		call	GadgetUtilSetLookHints
	;
	; have our superclass finish up
	;
		pop	ax, si, es
		mov	di, offset GadgetListClass
		call	ObjCallSuperNoLock
		
		.leave
		Destroy	ax, cx, dx
		ret

listHints word \
	HINT_ITEM_GROUP_DISPLAY_CURRENT_SELECTION,
	HINT_ITEM_GROUP_SCROLLABLE,
	HINT_DO_NOT_USE_MONIKER,
	HINT_ITEM_GROUP_TOOLBOX_STYLE,
	HINT_ITEM_GROUP_MINIMIZE_SIZE
popupHints nptr \
	GadgetAddHint,		;display current selection
	GadgetRemoveHint,	;no: scrollable
	GadgetRemoveHint,	;no: do not use moniker
	GadgetAddHint,		;toolbox style
	GadgetAddHint		;minimize size
scrollableHints nptr \
	GadgetRemoveHint,	;no: display current selection
	GadgetAddHint,		;scrollable
	GadgetAddHint,		;do not use moniker
	GadgetRemoveHint,	;no: toolbox style
	GadgetRemoveHint	;no: minimize size

CheckHack <length popupHints eq length listHints>
CheckHack <length scrollableHints eq length listHints>
CheckHack <offset popupHints eq offset listHints+size listHints>
CheckHack <offset scrollableHints eq offset popupHints+size popupHints>

ForceRef popupHints
ForceRef scrollableHints

GadgetListSetLook	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetSizeHControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept these messages so we can forward hints on to our
		child object

CALLED BY:	MSG_GADGET_SET_SIZE_HCONTROL
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	First, let the superclass do all the work.
	Second, check the hints that we have set and pass the relevant ones
	onto our child.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListSetSizeControl	method dynamic GadgetListClass, 
					MSG_GADGET_SET_SIZE_HCONTROL,
					MSG_GADGET_SET_SIZE_VCONTROL
		.enter

		mov	dx, ds:[di].GAI_contentObj.chunk
		push	dx

		mov	di, offset GadgetListClass
		call	ObjCallSuperNoLock

		pop	di			; the object of our advances

		clr	cx
		mov	ax, HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
		call	GLForwardHintIfFound

		mov	ax, HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
		call	GLForwardHintIfFound

		mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
		call	GLForwardHintIfFound

		mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		call	GLForwardHintIfFound
				
		.leave
		ret
GadgetListSetSizeControl	endm

GLForwardHintIfFound		proc	near
		call	ObjVarFindData
		xchg	si, di
		jnc	deleteIt
		call	ObjVarAddData
done:
		xchg	si, di
		ret
deleteIt:
		call	ObjVarDeleteData
		jmp	done
GLForwardHintIfFound		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetListSetNumSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the common error routine

CALLED BY:	MSG_GADGET_LIST_SET_NUM_SELECTIONS
PASS:		*ds:si	= GadgetListClass object
		ds:di	= GadgetListClass instance data
		ds:bx	= GadgetListClass object (same as *ds:si)
		es 	= segment of GadgetListClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetListHandleReadonlyProperty	method dynamic GadgetListClass, \
				MSG_GADGET_LIST_SET_NUM_SELECTIONS, \
				MSG_GADGET_LIST_SET_NUM_VISIBLE_ITEMS,\
				MSG_GADGET_LIST_SET_NUM_ITEMS
		.enter

		call	GadgetUtilReturnReadOnlyError
		
		.leave
		ret
GadgetListHandleReadonlyProperty	endm
