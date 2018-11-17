COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Tiramisu
MODULE:		Preferences
FILE:		preffax2DialingCodeList.asm

AUTHOR:		Peter Trinh, Feb  5, 1995

ROUTINES:
	Name			Description
	----			-----------

PrefDialingCodeListBuildArrays	Creates and initialize data arrays.
PrefDCLNewArrays		Creates and init array for ea. key.
PrefDCLCreateArray		Creates a chunk array of str chunk handles.
PrefDCLInitArray		Init chunk array with str chunk handles.
PrefDCLReadIniFile		Reads into a buf from the ini file.
PrefDialingCodeListGetItemMoniker  	Gets the desired moniker from the list.
PrefDialingCodeListFindItem	Locates an item moniker in the list
PrefDCLPerfectMatchCallback	Used by PrefDialingCodeListFindItem
PrefDCLImperfectMatchCallback	Used by PrefDialingCodeListFindItem
PrefDialingCodeListSelectItem	Called when an item is selected.
PrefDCLDisplayItem		Outputs selected items in output text objs.
PrefDCLGetStrFromArray		Gets str item from a chunk array.
PrefDCLSendStrToTextObj		Sends str to all the output text objs.
PrefDialingCodeListDeleteSelectedItem	Removes the selected item from list.
PrefDCLEnumerateArraysAndTextObjs	Enumerates thru all arrays and text obj
PrefDCLDeleteFromArray		Deletes an item from chunk array
PrefDCLSendMsgToTextObj		Sends a message to all output text objs.
PrefDialingCodeListInsertItem	Inserts an item into the list.
PrefDCLInsertIntoListCallback
PrefDCLGetStrLptrFromTextObj
PrefDCLInsertIntoArray		Inserts a str lptr into array.
PrefDialingCodeListModifySelectedItem	Modifies the selected item in list.
PrefDCLUpdateArrayItemCallback	Updates each array item.
PrefDCLFreeArrayItem		Frees the str lptr from array.
PrefDCLStoreArrayItem		Stores the str lptr into array.
PrefDialingCodeListSaveOptions	Save array into the ini file.
PrefDCLWriteStrSectionCallback	Writes a string section to the ini file.
PrefDCLDeleteKeyEntry		Deletes an empty key entry from ini file.
PrefDialingCodeListPostApply	Clean up after applying.
PrefDialingCodeListDestroyArrays	Destroys all data chunk arrays.
PrefDCLFreeArray		Frees a chunk array.
PrefDCLFreeArrayItemCallback
PrefDCLInitializeList		Inits list w/ num of entries and selected item.
PrefDialingCodeListActivate	Makes a list "active."
PrefDialingCodeListDeactivate	Makes a list not "active."
PrefDCLSendMsgToDeleteModifyTrig	

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/ 5/95   	Initial revision


DESCRIPTION:
	Contains method handlers for the DialingCodeListClass.
		

	$Id: preffax2DialingCodeList.asm,v 1.1 97/04/05 01:43:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFaxCode	segment resource;



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListBuildArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the array(s) from information stored in the
		given ini keys.  Will assume that the information are
		sorted. 

CALLED BY:	MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

	IF( !notesKey ) THEN
		initialize list to size 0;
	createNewArrays
	initializeNewArrays

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListBuildArrays	method dynamic PrefDialingCodeListClass, 
					MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
	.enter

	tst	ds:[di].PDCLI_notesKey
	jz	error				; does not have notesKey

	test	ds:[di].PDCLI_statusFlags, mask PDCLIF_INITIALIZED
	jnz	done				; already initialized

	call	PrefDCLNewArrays
	jc	error

	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	BitSet	ds:[di].PDCLI_statusFlags, PDCLIF_INITIALIZED

initializeListCount:
	mov	ax, GIGS_NONE			; not selecting item
	call	PrefDCLInitializeList

done:
	.leave
EC< 	Destroy	ax,cx,dx,bp	>
	ret

error:
	; Perhaps put up a dialog box telling the user of the error?
	clr	cx
	jmp	initializeListCount

PrefDialingCodeListBuildArrays	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLNewArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a chunk array for each intialized key.

CALLED BY:	PrefDialingCodeListBuildArrays

PASS:		*ds:si	= PrefDialingCodeListClass object

RETURN:		CF	- SET if error creating any arrays at all.
		cx	- total number of items in notes list

		PDCLI_*Array will be initialized if appropriate

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
	build chunk array from notesKey

	if( codeOneKey ) THEN
		build chunk array from codeOneKey

	if( codeTwoKey ) THEN
		build chunk array from codeTwoKey
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLNewArrays	proc	near

	class	PrefDialingCodeListClass

	uses	ax,bx,di,bp
	.enter

	Assert	objectPtr	dssi, PrefDialingCodeListClass

	call	PrefDCLCreateArray		; *ds:bx - chunk array
	jc	error
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	mov	bp, ds:[di].PDCLI_notesKey	; bp = lptr to notes key
	call	PrefDCLInitArray
	jc	error
	mov_tr	ax, cx				; number of items in notes list
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	mov	ds:[di].PDCLI_notesArray, bx


	mov	bp, ds:[di].PDCLI_codeOneKey
	tst	bp
	jz	nextCodeKey
	call	PrefDCLCreateArray		; *ds:bx - chunk array
	jc	error
	call	PrefDCLInitArray
	jc	error

	Assert	e	ax, cx			; num notesList = 
						; num codeOneList

	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	mov	ds:[di].PDCLI_codeOneArray, bx

nextCodeKey:
	mov	bp, ds:[di].PDCLI_codeTwoKey
	tst	bp
	jz	done
	call	PrefDCLCreateArray		; *ds:bx - chunk array
	jc	error
	call	PrefDCLInitArray
	jc	error

	Assert	e	ax, cx			; num notesList = 
						; num codeTwoList

	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	mov	ds:[di].PDCLI_codeTwoArray, bx

done:
	mov_tr	cx, ax				; number of items in notes list
exit:
	.leave
	ret

error:
	; Error handling code?
EC <	mov	cx, 0 >				; preserve flags
	jmp	exit

PrefDCLNewArrays	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLCreateArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a chunk array of chunk handles to text strings.
		
CALLED BY:	PrefDCLNewArrays

PASS:		*ds:si	= PrefDialingCodeListClass object

RETURN:		if CF - CLEAR, then 
			*ds:bx	= ChunkArray
		else error in creating chunk array

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLCreateArray	proc	near

	class	PrefDialingCodeListClass

	uses	ax,cx,si
	.enter

	Assert	objectPtr	dssi, PrefDialingCodeListClass

	mov	bx, size PrefDCLArrayInfo	; size of each element
	clr	cx			; no extra space needed in hdr
	clr	si			; allocate a handle
	clr	ax			; not object chunk
	call	ChunkArrayCreate
	jc	error

	Assert	ChunkArray	dssi
	mov	bx, si			; *ds:bx - new chunkArray
exit:	
	.leave
	ret

error:
	; Not enough memory possibly.  For now, don't initialize the
	; list, but perhaps will do something else
	pushf
	clr	bx
	popf
	jmp	exit
	
PrefDCLCreateArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLInitArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the given array with its respective ini
		data. 

CALLED BY:	PrefDialingCodeListBuildArrays

PASS:		*ds:si	- PrefDialingCodeListClass object
		*ds:bx	- chunk array to initialize
		bp	- lptr of ini key to read from


RETURN:		CF	- SET if error
			else
		The array will be initialized.
		cx 	= total number items in list

DESTROYED:	nothing

SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLInitArray	proc	near

keyLptr		local	word	push	bp
arrayLptr	local	word	push	bx
sectionNumber	local	word
categoryLptr	local	word
newStrLptr	local	word

	ForceRef keyLptr

	class	PrefDialingCodeListClass

	uses	ax,bx,dx,di,si
	.enter

	Assert	objectPtr	dssi, PrefDialingCodeListClass
	Assert	chunk		ss:[keyLptr], ds
	Assert	ChunkArray	dsbx

	clr	ss:[sectionNumber]

	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	mov	ax, ds:[di].PDCLI_category
	mov_tr	ss:[categoryLptr], ax

continueLoop:

	; Allocate a string chunk to hold the new item string.
DBCS <	mov	cx, FAX_DIAL_ASSIST_BUFFER_SIZE+2 >	; room for 
SBCS <	mov	cx, FAX_DIAL_ASSIST_BUFFER_SIZE+1 >	; null-terminator
	clr	al				; no object flags
	call	LMemAlloc			; ax - lptr
	jc	exit				; jump on error
	mov	ss:[newStrLptr], ax		; store new lptr to str buffer

	; Read string item from the ini file into the new string chunk
	call	PrefDCLReadIniFile
	jc	deAllocateMem			; jump if no more sections

	; Make sure no buffer overflow
if DBCS_PCGEOS
	Assert	l cx, FAX_DIAL_ASSIST_BUFFER_SIZE/2 
else
	Assert	l cx, FAX_DIAL_ASSIST_BUFFER_SIZE
endif

	; Append a new item to the list.  If failed, then quit.
	mov	si, ss:[arrayLptr]		; *ds:si - Chunk Array
	call	ChunkArrayAppend		; ds:di - new element
	jc	error				; jump on error
	mov	ax, ss:[newStrLptr]
	mov_tr	ds:[di].PDCLAI_strLptr, ax	; store new string lptr
	mov	ds:[di].PDCLAI_length, cx	; store new string length

	inc	ss:[sectionNumber]		; next section
	jmp	continueLoop

exit:
	mov	cx, ss:[sectionNumber]
EC<	mov	si, ss:[arrayLptr]		>
EC<	Assert	ChunkArray	dssi  		>

	.leave
	ret

error:
	clc
deAllocateMem:
	cmc
	pushf
	mov_tr	ax, ss:[newStrLptr]
	call	LMemFree
	popf
	jmp	exit

PrefDCLInitArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLReadIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	INTERNAL: AUX routine
		Reads a string, specified by the key and category,
		from the ini file into the buffer specified by 
		newStrLptr.

CALLED BY:	PrefDCLInitArray

PASS:		ss:bp	- Local stack frame
		cx	- size of buffer (not length)

RETURN:		CF	- SET if error
			else
		cx	- number characters read into chunk
			  designeated by newStrLptr

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLReadIniFile	proc	near
	uses	bx,dx,si,di,es,bp
	.enter	inherit PrefDCLInitArray

	push	cx				; buffer size

	mov	si, ss:[categoryLptr]		; *ds:si - category string
	mov	si, ds:[si]			; ds:si - category string

	mov	di, ss:[keyLptr]		; *ds:di - key string
	mov	dx, ds:[di]
	mov	cx, ds				; cx:dx - key string

	segmov	es, ds, di
	mov	di, ss:[newStrLptr]
	mov	di, ds:[di]			; es:di - new str buffer

	mov	ax, ss:[sectionNumber]		; target section
	pop	bp				; buffer size
	call	InitFileReadStringSection	; cx - length of string section
	;
	; Note: bp is destroyed and is no longer the stack frame pointer
	;

	.leave
	ret
PrefDCLReadIniFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the moniker of one of the items of a
		PrefItemGroup.  NOTE:  All subclasses of
		PrefDynamicList should make sure they support this
		function! 

CALLED BY:	MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

		ss:bp	= GetItemMonikerParams

RETURN:		bp - number of characters returned.
		Buffer should be filled in with a null-terminated
		string.  If the moniker is larger than the passed
		buffer, object should store nothing and return bp=0

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListGetItemMoniker	method dynamic PrefDialingCodeListClass, 
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
	uses	ax,cx,di,si,es
	.enter

	;
	; Use the given identifier to index into the array of monikers
	; to retrieve the string.
	;
	mov	ax, ss:[bp].GIMP_identifier
	mov	si, ds:[di].PDCLI_notesArray
	call	ChunkArrayElementToPtr
	ERROR_C	<ELEMENT_NOT_IN_ARRAY>

	;
	; Check if the given buffer size is large enuf to accomodate
	; the moniker string.
	;
	mov	ax, ds:[di].PDCLAI_length
DBCS <	shl	ax, 1 >				; double the size
	cmp	ax, ss:[bp].GIMP_bufferSize
	jg	monikerLargerThanBuffer

	push	ds:[di].PDCLAI_length		; store len of src str
	
	;
	; Copy the the string into the buffer
	;
	mov	si, ds:[di].PDCLAI_strLptr
	mov	si, ds:[si]			; ds:si - ptr to src str
	movdw	esdi, ss:[bp].GIMP_buffer	; es:di - ptr to dst buf
	LocalCopyString

	pop	bp				; len of src str

exit:
	.leave
	ret

monikerLargerThanBuffer:
	clr	bp
	jmp	exit

PrefDialingCodeListGetItemMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListFindItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an item given a (possible) item moniker.  The
		dynamic list sends this to itself in two cases --
		when loading options, in which case an exact match is
		desired, and when fielding keyboard events, in which
		case the passed string may only be a few characters,
		and may be of a different case than the desired item. 

CALLED BY:	MSG_PREF_DYNAMIC_LIST_FIND_ITEM
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

		cx:dx 	= null-terminated ASCII string
		bp 	= nonzero to find best fit (ie, ignore case, and
			  match up to the length of the passed string),
			  zero to find an exact match (should match
			  case, and make sure strings are the same length).

RETURN:		if FOUND match:
			carry clear
			ax - item #
		ELSE:
			carry set
			ax - first item AFTER requested item if 

DESTROYED:	cx,dx,bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Assume list is in ascending order and no duplicates.
	Search through the notesArray, or our "moniker" array for the 
		first exact match
			or
		first item string < target string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListFindItem	method dynamic PrefDialingCodeListClass, 
					MSG_PREF_DYNAMIC_LIST_FIND_ITEM
	.enter

	Assert	fptr	cxdx

	mov	si, ds:[di].PDCLI_notesArray	; *ds:si - chunk array
	mov	bx, cs				; current segment
	mov	di, offset PrefDCLPerfectMatchCallback
	tst	bp
	jz	enumerateChunkArray
	mov	di, offset PrefDCLImperfectMatchCallback
enumerateChunkArray:
	clr	ax				; starting item #
	call	ChunkArrayEnum			; ax - item #
	jnc	invertCarry			; not in list

	;
	; In list, but see if perfect match or not.
	;
	tst	bp				; if 0, then found it
	jz	exit				; so CF should be cleared

	; CF - CLEARED
invertCarry:
	cmc

exit:
	.leave
	ret
PrefDialingCodeListFindItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLPerfectMatchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares the item's string with the target string. 
		Returns the item # if found an exact match, or if
		item's string is > target string.
	

CALLED BY:	PrefDialingCodeListFindItem

PASS:		*ds:si 	- chunk array
		ds:di 	- array element being enumerated

		cx:dx	- null-terminated string to match, (target)
		ax	- current item number

RETURN:		CF	- SET if target str <= item's str
			ax - current element #
		bp 	- 0 if target = item

		else
			ax - next element #

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLPerfectMatchCallback	proc	far
	uses	si,es
	.enter

	Assert	ChunkArray	dssi
	Assert	fptr		dsdi
	Assert	fptr		cxdx

	clr	bp				; assume equal
	push	di				; ptr to current element
	mov	si, ds:[di].PDCLAI_strLptr
	mov	si, ds:[si]			; ds:si - item's str

	movdw	esdi, cxdx
	call	LocalCmpStrings			; dssi - src, esdi - target
	pop	di				; ptr to current element
	je	stopEnumeration
	jg	greaterThan

	inc	ax				; next item #
	clc
exit:
	.leave
	ret

greaterThan:
	mov	bp, GIGS_NONE
stopEnumeration:
	;
	; Now find the current item's index
	;
	stc
	jmp	exit

PrefDCLPerfectMatchCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLImperfectMatchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the current item# if found a partial
		match.  A partial match is one that is case insensitive
		and the target string is a substring of the matched
		string. 

		NOTE: not yet implemented.  For now, will always
		return 0.

CALLED BY:	PrefDialingCodeListFindItem

PASS:		*ds:si 	- chunk array
		ds:di 	- array element being enumerated

		cx:dx	- null-terminated string to match

RETURN:		CF	- SET to terminate enumeration
			ax - current element #

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLImperfectMatchCallback	proc	far
	.enter

	Assert	ChunkArray	dssi
	Assert	fptr		dsdi
	Assert	fptr		cxdx

	clr	ax
	stc

	.leave
	ret
PrefDCLImperfectMatchCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListSelectItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When an item in the list is selected, this message
		will be sent to the PrefDialingCodeListClass.  When
		this message is received, it will output the
		corresponding information in it's arrays to the
		attached text object.

CALLED BY:	MSG_PREF_DIALING_CODE_LIST_SELECT_ITEM
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

		cx 	= current selection, or first selection in item 
			  group, if more than one selection, or GIGS_NONE 
			  of no selection
		bp 	= number of selections
		dl 	= GenItemGroupStateFlags

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	Assumes	that the text objects are located in the same segment
	as the list object.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListSelectItem	method dynamic PrefDialingCodeListClass, 
					MSG_PREF_DIALING_CODE_LIST_SELECT_ITEM
	.enter

	Assert	chunk	si, ds

	cmp	cx, GIGS_NONE
	je	exit

	;
	; Go through each array, retrieve the text string, and then send
	; to the respective output objects.
	;
	mov_tr	ax, cx				; item #
	mov	di, offset PrefDCLDisplayItem
	call	PrefDCLEnumerateArraysAndTextObjs
	ERROR_C	<PREF_DIALING_CODE_LIST_ENUM_PREMATURE_TERMINATION>
	
exit:
	;
	; Set the DELETE and MODIFY triggers ENNABLED.
	;
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	PrefDCLSendMsgToDeleteModifyTrig

	.leave
EC <	Destroy ax,cx,dx,bp	>
	ret
PrefDialingCodeListSelectItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLDisplayItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the array and the text object and the selected
		item #, will "display" the text string in the text
		object. 

CALLED BY:	PrefDailingCodeListSelectItem

PASS:		*ds:si	- current chunk array
		*ds:di	- corresponding text object
		(The above are either null or a valid lptr so the
		callback should check.) 

		ax	- selected item #

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLDisplayItem	proc	near
	uses	bx,dx,bp,si
	.enter

	tst	si
	jz	done				; no chunk array
	tst	di
	jz	done				; no text object

	Assert	ChunkArray	dssi
	Assert	objectPtr	dsdi, GenTextClass

	mov	bx, di				; text object
	call	PrefDCLGetStrFromArray		; ^ldx:bp - text str
	mov	si, di				; text object
	call	PrefDCLSendStrToTextObj

done:
	clc
	.leave
	ret
PrefDCLDisplayItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLGetStrFromArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the element number, will retrieve the text
		string of that element of the given chunk array.

CALLED BY:	PrefDialingCodeListSelectItem
PASS:		*ds:si	- Chunk array
		ax	- element #

RETURN:		^ldx:bp	- null-terminated str of item
		( dx is the handle of ds segment )

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLGetStrFromArray	proc	near
	uses	cx,di
	.enter

	Assert	ChunkArray	dssi

	call	ChunkArrayElementToPtr
	ERROR_C <ELEMENT_NOT_IN_ARRAY>

	mov	dx, ds:[LMBH_handle]
	mov	bp, ds:[di].PDCLAI_strLptr	; ^ldx:bp -  null-
						; terminated string
	.leave
	ret
PrefDCLGetStrFromArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLSendStrToTextObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will send the given text string to the given text object.

CALLED BY:	PrefDialingCodeListSelectItem
PASS:		^ldx:bp	- null-terminated str to send
		*ds:si	- text object to send to

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLSendStrToTextObj	proc	near
	uses	ax,cx,dx,bp
	.enter

	Assert	optr	dxbp
	Assert	objectPtr	dssi, GenTextClass

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	clr	cx				; null-terminated string
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefDCLSendStrToTextObj	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListDeleteSelectedItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will delete the currently selected item.  This is done
		by removing all the corresponding elements in the
		chunk arrays as well as removing the item from the
		list itself.  When removing the elements from the
		arrays, we will free the allocated lptr.
	
CALLED BY:	MSG_PREF_DIALING_CODE_LIST_DELETE_SELECTED_ITEM
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	
	The corresponding items will be removed from the chunk array,
	and their lptr will be freed.

	Everyone of the connected text objects will have their text
	"erased." 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListDeleteSelectedItem	method dynamic PrefDialingCodeListClass, 
				MSG_PREF_DIALING_CODE_LIST_DELETE_SELECTED_ITEM
	uses	ax, cx, dx, bp
	.enter

	;
	; Find out which item is selected.
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	jc	noneSelected

	;
	; Remove the item from the string arrays
	;
	mov	di, offset PrefDCLDeleteFromArray
	call	PrefDCLEnumerateArraysAndTextObjs
	ERROR_C	<PREF_DIALING_CODE_LIST_ENUM_PREMATURE_TERMINATION>

	;
	; Remove from the dynamic list
	;
	mov_tr	cx, ax					; item to remove
	mov	dx, 1
	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
	call	ObjCallInstanceNoLock

	;
	; Set the dirtied flag
	;
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	BitSet	ds:[di].PDCLI_statusFlags, PDCLIF_DIRTIED

noneSelected:	
	;
	; Clear out the text objects.
	;
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	bp, mask MF_FIXUP_DS			; MessageFlags
	mov	di, offset PrefDCLSendMsgToTextObj
	call	PrefDCLEnumerateArraysAndTextObjs
	ERROR_C	<PREF_DIALING_CODE_LIST_ENUM_PREMATURE_TERMINATION>

	;
	; Set the DELETE and MODIFY triggers to be NOT_ENABLED.
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	PrefDCLSendMsgToDeleteModifyTrig

	.leave
	ret
PrefDialingCodeListDeleteSelectedItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLEnumerateArraysAndTextObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	INTERNAL UTILITY ROUTINE
		Calls the callback function (near) for each of the
		chunk array and the respective text object connected
		to PrefDialingCodeList. 

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	callback function:
		PASS:		*ds:si	- current chunk array
				*ds:di	- corresponding text object
			(The above are either null or a valid lptr
			 so the callback should check.)

				ax,cx,dx,bp	- additional data

		RETURN:		CF	- SET if want to abort enumeration

		DESTROYED:	nothing
		SIDE EFFECTS:	none
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	GLOBAL

PASS:		*ds:si	= PrefDialingCodeListClass object
		di	= nptr to callback routine
		ax,cx,dx,bp 	= data to pass to callback routine

NOTE: 	This function assumes that the chunk arrays and the text
	objects are both in the same segment as the
	PrefDialingCodeList object.  

RETURN:		CF	= SET if aborted enumeration, ie. callback
			  returns a CF SET.

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLEnumerateArraysAndTextObjs	proc	near
	class	PrefDialingCodeListClass

	uses	ax,cx,dx,bx,si
	.enter

	Assert	objectPtr	dssi, PrefDialingCodeListClass
	Assert	nptr		di, cs

	DerefInstanceDataDSBX	PrefDialingCodeList_offset
	push	ds:[bx].PDCLI_codeTwoArray
	push	ds:[bx].PDCLI_codeTwoTextObj.chunk
	push	ds:[bx].PDCLI_codeOneArray
	push	ds:[bx].PDCLI_codeOneTextObj.chunk

	;
	;  Call callback routine for notesArray
	;
	mov	si, ds:[bx].PDCLI_notesArray	; *ds:si - notesArray
	mov	bx, ds:[bx].PDCLI_notesTextObj.chunk
	xchg	bx, di				; callback, text chunk
	call	bx
	jc	abortTwo

	;
	;  Call callback routine for codeOneArray
	;
	pop	di				; *ds:di - codeOneTextObj
	pop	si				; *ds:si - codeOneArray
	call	bx
	jc	abortOne

	;
	;  Call callback routine for codeTwoTextObj
	;
	pop	di				; *ds:di - codeOneTextObj
	pop	si				; *ds:si - codeTwoArray
	call	bx

done:
	.leave
	ret

;
;  Aborting enumeration so need to clear out stack
;
abortTwo:
	pop	di				; codeOne text obj
	pop	si				; codeOne array
abortOne:
	pop	di				; codeTwo text obj
	pop	si				; codeTwo array
	jmp	done

PrefDCLEnumerateArraysAndTextObjs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLDeleteFromArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the element #, will remove that element from the
		array, and "destroy" that element.

CALLED BY:	PrefDialingCodeListDeleteSelectedItem

PASS:		*ds:si 	- Chunk array
		ax	- element number to delete
		(si can be either null or a valid lptr)

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	
	Will "free-up" the string lptr stored in the element.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLDeleteFromArray	proc	near
	uses	ax, di
	.enter

	tst	si
	jz	done					; not valid

	Assert	ChunkArray	dssi

	call	ChunkArrayElementToPtr			; ds:di - element

	mov	ax, ds:[di].PDCLAI_strLptr		; free str lptr
	call	LMemFree

	call	ChunkArrayDelete

done:
	clc

	.leave
	ret
PrefDCLDeleteFromArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLSendMsgToTextObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will send a message to the given object.

CALLED BY:	GLOBAL
PASS:		*ds:di		- Object
		bp		- Objmessage Flag
		ax		- Message #
		cx,dx		- Additional data
		(di could either be 0 or a valid lptr)

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLSendMsgToTextObj	proc	near
	uses	ax,cx,dx,bp,si,di,bx
	.enter

	tst	di
	jz	done				; invalid object

	Assert	objectPtr	dsdi, GenTextClass

	;
	;  We have to send via ObjMessage so that we can FORCE_QUEUE
	;  messages.  -- ptrinh 4/17/95
	;
	mov	bx, ds:[LMBH_handle]		; yes, a hack!
	mov	si, di				; object
	mov	di, bp				; Objmessage Flag
	call	ObjMessage

done:
	clc

	.leave
	ret
PrefDCLSendMsgToTextObj	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListInsertItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will insert an item into the list.  The item will be
		sorted by its "notes" string and will be inserted
		accordingly.  The data strings will be grabbed from
		the attached text objects. 

CALLED BY:	MSG_PREF_DIALING_CODE_LIST_INSERT_ITEM
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	The list will contain one additional item.

WARNING:  This routine MAY resize the LMem block, moving it on the
	  heap and invalidating stored segment pointers and current
	  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListInsertItem	method dynamic PrefDialingCodeListClass, 
					MSG_PREF_DIALING_CODE_LIST_INSERT_ITEM

	uses	ax, cx, dx, bp
	.enter

	;
	; Determine whether to insert any item by looking at the
	; length of the notes text object string.
	;
	push	si				; self lptr
	mov	si, ds:[di].PDCLI_notesTextObj.chunk	; notes text object
	call	PrefDCLGetStrLptrFromTextObj	; ax - len, cx - lptr
	pop	si				; self lptr
	push	cx				; new str lptr
	tst	ax				; test length
	jz	done				; jmp if empty string,
						; ie. "nothing" to insert

	;
	; Now find where in the sorted list we should insert our new item
	;
	mov	ax, MSG_PREF_DYNAMIC_LIST_FIND_ITEM
	mov	di, cx				; lptr to str
	mov	dx, ds:[di]			; deref chunk
	mov	cx, ds				; cx:dx null-term str
	clr	bp				; exact match
	call	ObjCallInstanceNoLock		; ax - first item
						; after requested item
	jnc	done				; jmp if duplicate item
if 0
	;
	; For now, just add to the front of the arrays
	;
	clr	ax
endif
	mov	di, offset PrefDCLInsertIntoListCallback
	call	PrefDCLEnumerateArraysAndTextObjs
	jc	abortInsertion

	;
	; Add to the list
	;
	push	ax				; item position
	mov_tr	cx, ax				; position to add new
						; list item
	mov	dx, 1				; # item to add
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	call	ObjCallInstanceNoLock

	pop	ax				; item to select
	clr	cx				; keep current count
	call	PrefDCLInitializeList

	;
	; Set the dirtied flag
	;
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	BitSet	ds:[di].PDCLI_statusFlags, PDCLIF_DIRTIED
	clc					; normal return
	
done:
	pop	ax				; new str lptr
	call	LMemFree

	.leave
	ret

abortInsertion:
	;
	; Set the flag so that we won't commit the changes to the ini
	; file.
	;
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	BitSet	ds:[di].PDCLI_statusFlags, PDCLIF_ABORT
	stc					; error
	jmp	done

PrefDialingCodeListInsertItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLInsertIntoListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will insert an item with the text string of the given
		text object into the given position of the given
		array. 

CALLED BY:	PrefDialingCodeListInsertItem

PASS:		*ds:si	- current chunk array
		*ds:di	- corresponding text object
		(The above are either null or a valid lptr so the
		callback should check.) 

		ax	- element # of item to insert before

RETURN:		CF	- SET if error while inserting

DESTROYED:	nothing
SIDE EFFECTS:	

	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLInsertIntoListCallback	proc	near
	uses	ax,cx,dx,si
	.enter

	tst	si
	jz	done				; no chunk array
	tst	di
	jz	done				; no text object

	Assert	ChunkArray	dssi
	Assert	objectPtr	dsdi, GenTextClass

	push	ax, si				; element #, chunk array
	mov	si, di				; text object
	call	PrefDCLGetStrLptrFromTextObj	; ax - len, cx - lptr
	mov_tr	dx, ax				; length
	pop	ax, si				; element #, chunk array
	call	PrefDCLInsertIntoArray
	jc	abortInsertion

done:
	.leave
	ret

abortInsertion:
	;
	; Insertion failed, so must free the allocated string lptr
	;
	mov_tr	ax, cx				; lptr
	call	LMemFree
	stc
	jmp	done
	
PrefDCLInsertIntoListCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLGetStrLptrFromTextObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the chunk handle of the the text string of
		the target text object.

		Note: must free up this chunk when done using it.

CALLED BY:	PrefDCLInsertIntoListCallback

PASS:		ds	- locked segment of block to allocate chunk
			  from
		*ds:si	- target text object

RETURN:		ax	- length of new string
		cx	- lptr to new str

DESTROYED:	nothing
SIDE EFFECTS:	

	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLGetStrLptrFromTextObj	proc	near
	uses	dx,bp
	.enter

	Assert	segment	ds
	Assert	chunk	si, ds

	mov	dx, ds:[LMBH_handle]
	clr	bp				; need chunk to be allocated
	mov	ax, MSG_VIS_TEXT_GET_ALL_OPTR
	call	ObjCallInstanceNoLock		; cx - lptr, ax - length

	.leave
	ret
PrefDCLGetStrLptrFromTextObj	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLInsertIntoArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the element # after the position we want to
		insert at, we will insert a new item into the array.

CALLED BY:	PrefDCLInsertIntoListCallback

PASS:		*ds:si	- target chunk array
		ax	- element # of item to insert before
		cx	- lptr of new string
		dx	- length of new string

RETURN:		CF	- SET if could not insert
DESTROYED:	nothing
SIDE EFFECTS:	

	The array will contain an additional item.

	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLInsertIntoArray	proc	near
	uses	di
	.enter

	Assert	ChunkArray	dssi
	Assert	chunk		cx, ds

	call	ChunkArrayElementToPtr
	jc	appendItem			; since element# out
						; of bounds
	call	ChunkArrayInsertAt
	jc	done				; jmp if couldn't insert

addItem:
	mov	ds:[di].PDCLAI_length, dx
	mov	ds:[di].PDCLAI_strLptr, cx

done:
	.leave
	ret

appendItem:
	call	ChunkArrayAppend
	jc	done
	jmp	addItem

PrefDCLInsertIntoArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListModifySelectedItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will replace the currently selected item's info with
		the information from the attached text objects.

CALLED BY:	MSG_PREF_DIALING_CODE_LIST_MODIFY_SELECTED_ITEM
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

WARNING:  This routine MAY resize the LMem block, moving it on the
	  heap and invalidating stored segment pointers and current
	  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListModifySelectedItem	method dynamic PrefDialingCodeListClass, 
				MSG_PREF_DIALING_CODE_LIST_MODIFY_SELECTED_ITEM
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		; ax - current selection
	jc	done

	;
	; Update the old lptr
	;
	mov	di, offset PrefDCLUpdateArrayItemCallback
	call	PrefDCLEnumerateArraysAndTextObjs
	jc	error

	;
	; Indicate to the list that the selected item's moniker needs to
	; be re-read.
	;
	clr	cx				; keep current count
	call	PrefDCLInitializeList

	;
	; Set the dirtied flag
	;
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	BitSet	ds:[di].PDCLI_statusFlags, PDCLIF_DIRTIED
	clc					; normal return

done:
	.leave
	ret

error:
	;
	; Got an error during the update (most likely out of memory
	; error), we need to abort and mark the list as invalid.
	;
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	BitSet	ds:[di].PDCLI_statusFlags, PDCLIF_ABORT
	stc					; error
	jmp	done

PrefDialingCodeListModifySelectedItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLUpdateArrayItemCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the selected item of the chunk array, will
		replace that item's string lptr with a new one gotten
		from the given text object.

CALLED BY:	PrefDialingCodeListModifySelectedItem

PASS:		*ds:si	- current chunk array
		*ds:di	- corresponding text object
		(The above are either null or a valid lptr so the
		callback should check.) 

		ax	- selected item #

RETURN:		CF	- SET if no string in text object

DESTROYED:	nothing
SIDE EFFECTS:	

WARNING:  This routine MAY resize the LMem block, moving it on the
	  heap and invalidating stored segment pointers and current
	  register or stored offsets to it.	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLUpdateArrayItemCallback	proc	near
	uses	cx, dx
	.enter

	tst	si
	jz	done				; invalid chunk array
	tst	di
	jz	done				; invalid text obj

	;
	; Clear out old str lptr
	;
	call	PrefDCLFreeArrayItem

	;
	; Get new str lptr
	;			
	push	ax, si				; selected item #,
						; chunk array
	mov	si, di				; text obj
	call	PrefDCLGetStrLptrFromTextObj	; ax - length, cx - lptr
	tst	ax
	jz	abort

	;
	; Put in new str lptr
	mov_tr	dx, ax				; length of stored string
	pop	ax, si				; selected item #,
						; chunk array
	call	PrefDCLStoreArrayItem
	
done:
	.leave
	ret

abort:
	; 
	; Empty string in text object so will abort
	;
	mov	ax, cx				; new str lptr
	call	LMemFree
	pop	ax, si				; selected item #,
						; chunk array
	stc
	jmp	done
	
PrefDCLUpdateArrayItemCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLFreeArrayItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the item number and the target array, will free
		the str lptr from that array's item.

CALLED BY:	GLOBAL

PASS:		*ds:si	- target chunk array
		ax	- item number

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Target item will no longer have a valid strLptr field.

	WARNING - stored lptr of the removed lptr will become invalid.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLFreeArrayItem	proc	near
	uses	ax,di
	.enter

	Assert	ChunkArray	dssi

	call	ChunkArrayElementToPtr
	clr	ax
	xchg	ax, ds:[di].PDCLAI_strLptr	; clear out field
	call	LMemFree

	.leave
	ret
PrefDCLFreeArrayItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLStoreArrayItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will store the new str lptr into the given item's
		strLptr field.

CALLED BY:	PrefDCLUpdateArrayItemCallback

PASS:		*ds:si	- target chunk array
		ax	- item number
		cx	- new str lptr
		dx	- length of new str

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLStoreArrayItem	proc	near
	uses	di
	.enter

	Assert	ChunkArray	dssi
	Assert	chunk		cx, ds

	call	ChunkArrayElementToPtr
	mov	ds:[di].PDCLAI_strLptr, cx
	mov	ds:[di].PDCLAI_length, dx

	.leave
	ret
PrefDCLStoreArrayItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept this message so that we can save the arrays
		off to the ini file.

CALLED BY:	MSG_META_SAVE_OPTIONS
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	for each array
		for each item in the array
			write out item strings as section of a blob
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListSaveOptions	method dynamic PrefDialingCodeListClass, 
					MSG_META_SAVE_OPTIONS

selfLptr	local	lptr	push	si
codeTwoArray	local	lptr	push	ds:[di].PDCLI_codeTwoArray
codeOneArray	local	lptr	push	ds:[di].PDCLI_codeOneArray
codeTwoKey	local	lptr.char	push	ds:[di].PDCLI_codeTwoKey
codeOneKey	local	lptr.char	push	ds:[di].PDCLI_codeOneKey

	uses	ax, cx, dx, bp
	.enter

	test	ds:[di].PDCLI_statusFlags, mask PDCLIF_ABORT
	jnz	done				; don't save arrays
	test	ds:[di].PDCLI_statusFlags, mask PDCLIF_DIRTIED
	jz	done				; not dirtied

	;
	; Clear the dirty flag so won't try saving again
	;
	BitClr	ds:[di].PDCLI_statusFlags, PDCLIF_DIRTIED
	
	mov	cx, ds:[di].PDCLI_category

	;
	; Enumerate through the notes array
	;
	mov	si, ds:[di].PDCLI_notesArray
	Assert	chunk	si, ds
	mov	ax, ds:[di].PDCLI_notesKey
	call	PrefDCLDeleteKeyEntry
	mov	bx, cs				; bx:di - callback routine
	mov	di, offset PrefDCLWriteStrSectionCallback	
	call	ChunkArrayEnum
	ERROR_C <CHUNK_ARRAY_ENUM_PREMATURE_TERMINATION>

	;
	; Enumerate through the code one array
	;
	mov	si, ss:[codeOneArray]
	tst	si
	jz	enumCodeTwoArray		; no code one array
	mov	ax, ss:[codeOneKey]
	call	PrefDCLDeleteKeyEntry
	mov	bx, cs				; bx:di - callback routine
	mov	di, offset PrefDCLWriteStrSectionCallback
	call	ChunkArrayEnum
	ERROR_C <CHUNK_ARRAY_ENUM_PREMATURE_TERMINATION>

enumCodeTwoArray:
	;
	; Enumerate through the code two array
	;
	mov	si, ss:[codeTwoArray]
	tst	si
	jz	done				; no code Two array
	mov	ax, ss:[codeTwoKey]
	call	PrefDCLDeleteKeyEntry
	mov	di, offset PrefDCLWriteStrSectionCallback
	mov	bx, cs				; bx:di - callback routine
	call	ChunkArrayEnum
	ERROR_C <CHUNK_ARRAY_ENUM_PREMATURE_TERMINATION>

done:
	mov	ax, MSG_META_SAVE_OPTIONS
	mov	si, ss:[selfLptr]
	mov	di, offset PrefDialingCodeListClass
	push	bp				; local stack frame
	call	ObjCallSuperNoLock
	pop	bp				; local stack frame

	.leave
	ret
PrefDialingCodeListSaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLWriteStrSectionCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will be called for each chunk array item.  When
		called, will append the item's string to the ini
		string that will be written out.

CALLED BY:	PrefDialingCodeListSaveOptions

PASS:		*ds:si 	- chunk array
		ds:di 	- array element being enumerated

		*ds:ax	- key string
		*ds:cx	- category string

RETURN:		CF	- CLEAR

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLWriteStrSectionCallback	proc	far
	uses	cx,dx,si,di,bp,es
	.enter

	Assert	ChunkArray	dssi
	Assert	fptr		dsdi
	Assert	chunk		ax, ds
	Assert	chunk		cx, ds

	mov	bp, cx
	mov	si, ds:[bp]			; ds:si - category str
	mov	bp, ax
	mov	dx, ds:[bp]			; key str offset
	mov	cx, ds				; cx:dx - key str
	mov	es, cx				; target str segment
	mov	di, ds:[di].PDCLAI_strLptr
	mov	di, ds:[di]			; es:di - target str
	call	InitFileWriteStringSection

	clc

	.leave
	ret
PrefDCLWriteStrSectionCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLDeleteKeyEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the key entry from the given category.

CALLED BY:	PrefDialingCodeListSaveOptions

PASS:		*ds:ax	- key string chunk
		*ds:cx	- category string chunk

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	The target key section is removed from the ini file.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLDeleteKeyEntry	proc	near
	uses	si,cx,dx
	.enter

	Assert	chunk	ax, ds
	Assert	chunk	cx, ds

	mov	si, ax
	mov	dx, ds:[si]			; key lptr
	mov	si, cx
	mov	si, ds:[si]			; ds:si - category str
	mov	cx, ds				; cx:dx - key str
	call	InitFileDeleteEntry

	.leave
	ret
PrefDCLDeleteKeyEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListPostApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out by properties dialogs after
		MSG_GEN_APPLY.  This can be used to clean up after
		"apply"ing of changes.  Ie., time for the list to
		clean up.

CALLED BY:	MSG_GEN_POST_APPLY
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListPostApply	method dynamic PrefDialingCodeListClass, 
					MSG_GEN_POST_APPLY
	uses	ax, cx, dx, bp
	.enter

	mov	di, offset PrefDialingCodeListClass
	call	ObjCallSuperNoLock

	;
	; Now clean up all the arrays, only if the list hasn't been
	; initialized already.
	;
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	test	ds:[di].PDCLI_statusFlags, mask PDCLIF_INITIALIZED
	jz	done

	mov	ax, MSG_PREF_DIALING_CODE_LIST_DESTROY_ARRAYS
	call	ObjCallInstanceNoLock

	;
	; Don't clean up this list again if gets another post-apply
	; message.
	;
	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	BitClr	ds:[di].PDCLI_statusFlags, PDCLIF_INITIALIZED

done:
	.leave
	ret
PrefDialingCodeListPostApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListDestroyArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will go through all of the arrays and free up
		each item of the chunk arrays and free the chunk array
		as well.

CALLED BY:	MSG_PREF_DIALING_CODE_LIST_DESTROY_ARRAYS
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

	The PDCLIF_INITIALIZED flag will be cleared.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListDestroyArrays	method dynamic PrefDialingCodeListClass, 
				MSG_PREF_DIALING_CODE_LIST_DESTROY_ARRAYS
	.enter

	mov	di, offset PrefDCLFreeArray
	call	PrefDCLEnumerateArraysAndTextObjs

	DerefInstanceDataDSDI	PrefDialingCodeList_offset
	BitClr	ds:[di].PDCLI_statusFlags, PDCLIF_INITIALIZED

	.leave
	ret
PrefDialingCodeListDestroyArrays	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLFreeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the chunk array, will free up all the items
		stored in it as well as free itself.

CALLED BY:	PrefDialingCodeListDestroyArrays

PASS:		*ds:si	- current chunk array
		(si - 0 or valid lptr)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Ptrs to the array or the array's items are now invalid.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLFreeArray	proc	near
	uses	ax,bx,di
	.enter

	tst	si
	jz	done				; invalid lptr

	Assert	ChunkArray	dssi

	mov	di, offset PrefDCLFreeArrayItemCallback
	mov	bx, cs				; bx:di - callback routine
	call	ChunkArrayEnum

	mov	ax, si				; chunk array lptr
	call	LMemFree

done:
	.leave
	ret
PrefDCLFreeArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLFreeArrayItemCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will free the string lptr of the item.

CALLED BY:	PrefDCLFreeArray

PASS:		*ds:si 	- chunk array
		ds:di 	- array element being enumerated

RETURN:		CF	- CLEAR

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLFreeArrayItemCallback	proc	far
	uses	ax
	.enter

	Assert	ChunkArray	dssi
	Assert	fptr		dsdi

	mov	ax, ds:[di].PDCLAI_strLptr
	call	LMemFree

	call	ChunkArrayDelete

	clc

	.leave
	ret
PrefDCLFreeArrayItemCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLInitializeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will initialize the list with the given number of
		entries as well as setting an item to be selected.

CALLED BY:	GLOBAL

PASS:		*ds:si	- PrefDialingCodeListClass
		ax	- item position to select, or GIGS_NONE if none
		cx	- non-zero, new item count to initialize the
			  list with, else keep current count
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLInitializeList	proc	near
	uses	ax,cx,dx,bp
	.enter

	Assert	objectPtr	dssi, PrefDialingCodeListClass
	
	push	ax				; item to select
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	tst	cx
	jnz	newItemCount
	mov	cx, GDLI_NO_CHANGE
newItemCount:
	call	ObjCallInstanceNoLock

	pop	cx				; item to select
	cmp	cx, GIGS_NONE
	je	noSelection
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; determinate
	call	ObjCallInstanceNoLock	
noSelection:

	.leave
	ret
PrefDCLInitializeList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListActivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the list USABLE and all the linked text objects
		USABLE as well. 

CALLED BY:	MSG_PREF_DIALING_CODE_LIST_ACTIVATE
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListActivate	method dynamic PrefDialingCodeListClass, 
					MSG_PREF_DIALING_CODE_LIST_ACTIVATE
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	bp, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	di, offset PrefDCLSendMsgToTextObj
	call	PrefDCLEnumerateArraysAndTextObjs

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	cmp	ax, GIGS_NONE
	je	done

	;
	; "display" the current selection in the text objects
	;
	mov_tr	cx, ax				; current selection
	mov	bp, 1
	mov	dl, mask GIGSF_INDETERMINATE
	mov	ax, MSG_PREF_DIALING_CODE_LIST_SELECT_ITEM
	call	ObjCallInstanceNoLock

	;
	; Set the DELETE and MODIFY triggers to be ENABLED, cuz we
	; have something for them to act on.
	;
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	PrefDCLSendMsgToDeleteModifyTrig
done:
	.leave
	ret
PrefDialingCodeListActivate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDialingCodeListDeactivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the list NOT_USABLE and all the linked text
		objects NOT_USABLE as well. 

CALLED BY:	MSG_PREF_DIALING_CODE_LIST_DEACTIVATE
PASS:		*ds:si	= PrefDialingCodeListClass object
		ds:di	= PrefDialingCodeListClass instance data
		ds:bx	= PrefDialingCodeListClass object (same as *ds:si)
		es 	= segment of PrefDialingCodeListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDialingCodeListDeactivate	method dynamic PrefDialingCodeListClass, 
					MSG_PREF_DIALING_CODE_LIST_DEACTIVATE
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	bp, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	di, offset PrefDCLSendMsgToTextObj
	call	PrefDCLEnumerateArraysAndTextObjs

	;
	; Clear out the text objects of residue.
	;
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	bp, mask MF_FIXUP_DS
	mov	di, offset PrefDCLSendMsgToTextObj
	call	PrefDCLEnumerateArraysAndTextObjs
	ERROR_C	<PREF_DIALING_CODE_LIST_ENUM_PREMATURE_TERMINATION>

	;
	; Make the MODIFY and  DELETE trig NOT ENABLED as well.
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	PrefDCLSendMsgToDeleteModifyTrig

	.leave
	ret
PrefDialingCodeListDeactivate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDCLSendMsgToDeleteModifyTrig
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the given message number to the Delete and
		Modify Trigger, which at this point is hard-coded.
		Calls ObjCallInstanceNoLock.

CALLED BY:	global

PASS:		ax - message number
		cd, dx, bp - additional data
		ds - locked segment of the object is in

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	See message being sent.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDCLSendMsgToDeleteModifyTrig	proc	near
	uses	ax,cx,dx,bp
	.enter

EC <	Assert	segment ds					>
	push	ax, cx, dx, bp				; message data
	mov	si, offset DialingCodeEditDeleteB
	call	ObjCallInstanceNoLock

	pop	ax, cx, dx, bp				; message data
	mov	si, offset DialingCodeEditModifyB
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefDCLSendMsgToDeleteModifyTrig	endp


PrefFaxCode	ends



