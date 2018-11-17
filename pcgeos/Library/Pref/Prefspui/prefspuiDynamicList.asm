COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Pref
MODULE:		Prefspui
FILE:		prefspuiDynamicList.asm

AUTHOR:		David Litwin, Sep 27, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/27/94   	Initial revision


DESCRIPTION:
	Code for the PrefSpuiDynamicListClass
		

	$Id: prefspuiDynamicList.asm,v 1.1 97/04/05 01:43:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLPrefInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up some standard vardata for this class.

CALLED BY:	MSG_PREF_INIT
PASS:		*ds:si	= PrefSpuiDynamicListClass object
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLPrefInit	method dynamic PrefSpuiDynamicListClass, 
					MSG_PREF_INIT
	uses	ax, cx
	.enter

	mov	cx, cs
	mov	dx, offset demoCategory
	mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
	call	ObjCallInstanceNoLock

	clr	cx				; no data hints:
	mov	ax, HINT_PLACE_MONIKER_ABOVE
	call	ObjVarAddData
	mov	ax, HINT_ITEM_GROUP_SCROLLABLE
	call	ObjVarAddData
	mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
	call	ObjVarAddData

	mov	cx, size word
	mov	ax, ATTR_GEN_ITEM_GROUP_CUSTOM_DOUBLE_PRESS
	call	ObjVarAddData
	mov	{word} ds:[bx], 0

	mov	ax, MSG_PREF_INIT
	mov	di, offset PrefSpuiDynamicListClass
	call	ObjCallSuperNoLock

	.leave
	ret
PSDLPrefInit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLBuildArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the dynamic list by doing a fileEnum and
		yanking the info string out of the .ini files it produces.

CALLED BY:	MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
PASS:		*ds:si	= PrefSpuiDynamicListClass object
		ds:di	= PrefSpuiDynamicListClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLBuildArray	method dynamic PrefSpuiDynamicListClass, 
					MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
	.enter

	call	FilePushDir
	call	PSDLEnumDir
	jc	popDir				; count left zero, handle null
	jcxz	informList

	mov	di, ds:[si]
	add	di, ds:[di].PrefSpuiDynamicList_offset
	mov	ds:[di].PSDLI_nameArray, bx

	;
	; grab the description etc. from each .ini file and stuff it in
	;
	call	PSDLGetItemInfo

	call	PSDLCompressItemList
	
	;
	; inform ourselves as to the number of items in our list
	;
informList:
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjCallInstanceNoLock

popDir:
	call	FilePopDir

	.leave
	ret
PSDLBuildArray	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLEnumDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the object's path and enum the directory for
		*.ini files.

CALLED BY:	PSDLInitList

PASS:		*ds:si	= PrefSpuiDynamicListClass object

RETURN:		carry	= set on error
			= clear if successful
				bx	= hptr of buffer, or 0 if no files
				cx	= number of files
DESTROYED:	ax, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLEnumDir	proc	near
	.enter

	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	cmc
EC<	WARNING_C	WARNING_PSDL_BAD_SEARCH_PATH	>
	jc	exit

	mov	dx, bx
	mov	bx, ds:[bx].GFP_disk
	add	dx, offset GFP_path
	call	FileSetCurrentPath
EC<	WARNING_C	WARNING_PSDL_BAD_SEARCH_PATH	>
	jc	exit

	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_searchFlags, mask FESF_NON_GEOS or \
						mask FESF_CALLBACK
	mov	ss:[bp].FEP_returnAttrs.segment, cs
	mov	ss:[bp].FEP_returnAttrs.offset, offset PSDLReturnAttrs
	mov	ss:[bp].FEP_returnSize, size NameAndLabel
	clr	ss:[bp].FEP_matchAttrs.segment	; no match attrs, use callback
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	clr	ss:[bp].FEP_skipCount		; don't skip any
	clr	ss:[bp].FEP_callback.segment
	mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
	mov	ss:[bp].FEP_cbData1.segment, cs
	mov	ss:[bp].FEP_cbData1.offset, offset PSDLStarDotINIString
	mov	ss:[bp].FEP_cbData2.low, -1	; case insensitive
	call	FileEnum

exit:
	.leave
	ret
PSDLEnumDir	endp


PSDLReturnAttrs	FileExtAttrDesc \
	<FEA_NAME, offset NAL_filename, size NAL_filename>,
	<FEA_END_OF_LIST>

LocalDefNLString	PSDLStarDotINIString	<'*.ini', 0>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLGetItemInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the item info for each .ini file by setting
		up a loop through all the item's .ini files.

CALLED BY:	PSDLMetaInitialize

PASS:		*ds:si	= PrefSpuiDynamicListClass object
		ds:di	= PrefSpuiDynamicListClass instance data
		bx	= handle of block of NameAndLabel structures
		cx	= item count
RETURN:		nothing
DESTROYED:	ax, dx, bp, di, es

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLGetItemInfo	proc	near
	uses	cx, ds, si
objPtr		local	optr	push	ds, si
itemCount	local	word	push	cx
itemNAL		local	fptr
iniFileHandle	local	hptr
iniBufHandle	local	hptr
iniBufSptr	local	sptr
iniBufSize	local	word
iniBufNumChars	local	word			; # of chars in buffer, which 
ForceRef	iniBufSptr			;  could be less than its size
ForceRef	iniBufSize
ForceRef	iniBufNumChars
	.enter

	push	bx				; save PSDLI_nameArray hptr
	call	PSDLGetItemInfoPrep

	;
	; Top of loop, where we read the file into the buffer and pass
	; it to our MSG_PSDL_INIT_ITEM handler.
	;
loopTop:
CheckHack< (offset NAL_filename) eq 0 >
	lds	dx, ss:[itemNAL]
	mov	al, FILE_ACCESS_R or FILE_DENY_NONE
	call	FileOpen
EC<	WARNING_C	WARNING_PSDL_BAD_ITEM_INFO_READ	>
	jnc	gotFile
	PSDLNullEntry
	jmp	nextItem

gotFile:
	mov	ss:[iniFileHandle], ax
	call	PSDLLoadBufferWithIniFileData
	jnc	gotData
	PSDLNullEntry
	jmp	closeFile

	;
	; got the buffer of .ini for this item, so process it
	;
gotData:
	mov	ax, MSG_PSDL_INIT_ITEM
	lds	si, ss:[objPtr]
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp
	jnc	closeFile

EC<	WARNING	WARNING_PSDL_BAD_ITEM_INFO_READ	>
	PSDLNullEntry				; null it out on error

closeFile:
	clr	ax				; no flags
	mov	bx, ss:[iniFileHandle]
	call	FileClose
EC<	WARNING_C	WARNING_PSDL_BAD_ITEM_INFO_READ	>

nextItem:
	add	ss:[itemNAL].offset, size NameAndLabel
	dec	ss:[itemCount]
	jnz	loopTop

	;
	; loop cleanup
	;
	mov	bx, ss:[iniBufHandle]
	call	MemFree
	pop	bx				; restore PSDLI_nameArray hptr
	call	MemUnlock

	.leave
	ret
PSDLGetItemInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLGetItemInfoPrep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare for our loop by setting up a bunch of stack
		locals and allocating our initial demo .ini file buffer.

CALLED BY:	PSDLGetItemInfo

PASS:		ss:[bp]	= inherited local stack frame
		bx	= block handle of our PSDLI_nameArray
RETURN:		locals filled appropriately
DESTROYED:	ax, bx, cx, ds

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLGetItemInfoPrep	proc	near
	.enter	inherit PSDLGetItemInfo

	call	MemLock
	mov	ss:[itemNAL].segment, ax
	mov	ds, ax
CheckHack< (offset NAL_filename) eq 0 >
	clr	ss:[itemNAL].offset		; first filename

	;
	; allocate and re-use a block of memory for the item's
	; .ini file to be read into.
	;
	mov	ax, INITIAL_DEMO_INI_BUFFER_SIZE
	mov	ss:[iniBufSize], ax

	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
EC<	ERROR_C	ERROR_CANT_I_EVEN_ALLOCATE_A_SIMPLE_BLOCK	>
	mov	ss:[iniBufHandle], bx
	mov	ss:[iniBufSptr], ax

	.leave
	ret
PSDLGetItemInfoPrep	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLLoadBufferWithIniFileData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the demo .ini into our buffer, reallocating it as
		neccessary.  Return carry for any errors

CALLED BY:	PSDLGetItemInfo

PASS:		ss:[bp]	= inherited stack frame
		ax	= file handle of demo .ini file
RETURN:		carry	= set on error, skip to next item in loop after closing
				file
			= clear if successful, buffer (iniBufHandle) filled
DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLLoadBufferWithIniFileData	proc	near
	.enter	inherit PSDLGetItemInfo

	mov	bx, ax
	call	FileSize

	tst	dx				; dxax is filesize
	stc
EC<	WARNING_NZ	WARNING_PSDL_FILE_IS_JUST_TOO_DAMN_BIG		>
	jnz	exit

	cmp	ax, 20000
	stc
EC<	WARNING_GE	WARNING_PSDL_FILE_IS_JUST_TOO_DAMN_BIG		>
	jge	exit

DBCS< PrintMessage<The filesize isn't correct in DBCS, so you will have to> >
DBCS< PrintMessage set iniBufNumChars after translating the buffer to DBCS> >
	mov	ss:[iniBufNumChars], ax		; characters in file

	cmp	ax, ss:[iniBufSize]
	jle	readToBuffer

	push	ax				; save file size
	mov	bx, ss:[iniBufHandle]
	mov	ch, mask HAF_LOCK
	call	MemReAlloc
EC<	WARNING_C	WARNING_PSDL_GRRRR_NOT_ENOUGH_MEMORY		>
	mov	ss:[iniBufSptr], ax		; new sptr
	pop	ax				; restore file size
	jc	exit

readToBuffer:
	mov	cx, ax				; put file size in ax for read
	clr	ax				; no flags
	mov	bx, ss:[iniFileHandle]
	mov	ds, ss:[iniBufSptr]
	clr	dx				; ds:dx is beginning of buffer
	call	FileRead
	jnc	gotData

	cmp	ax, ERROR_SHORT_READ_WRITE
	stc
EC<	WARNING_NE	WARNING_PSDL_BAD_ITEM_INFO_READ	>
	jne	exit

gotData:
DBCS< PrintMessage<In DBCS you will have to convert this from ASCII>	>
DBCS< PrintMessage<to GEOS form if you want things to work correctly>	>
	clc
exit:
	.leave
	ret
PSDLLoadBufferWithIniFileData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLInitItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the structures for an item.  This includes
		grabbing the item's label from its .ini file and stuffing
		it in the the NameAndLabel structure.

CALLED BY:	MSG_PSDL_INIT_ITEM
PASS:		*ds:si	= PrefSpuiDynamicListClass object
		ss:[bp]	= inherited stack frame from PSDLGetItemInfo
RETURN:		bp	= same as passed
		carry set on error
DESTROYED:	ax, cx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLInitItem	method dynamic PrefSpuiDynamicListClass, 
					MSG_PSDL_INIT_ITEM
	.enter	inherit PSDLGetItemInfo

	mov	es, ss:[iniBufSptr]
	mov	cx, ss:[iniBufNumChars]
	segmov	ds, cs, si
	mov	si, offset demoCategory
	call	PSDLFindCategory
	jc	exit

	mov	si, offset labelKey
	call	PSDLFindKey
	jc	exit

	segmov	ds, es, si
	mov	si, di				; ds:si is our label

	les	di, ss:[itemNAL]
	add	di, offset NAL_label
	mov	cx, bx				; length of key
	cmp	cx, size LabelText
	jl	gotSize

EC<	WARNING	WARNING_PSDL_LABEL_MUST_BE_TRUNCATED_TO_FIT		>
	mov	cx, (size LabelText) - 1	; we need room for null term.

gotSize:
	LocalCopyNString			; copy into our structure
	LocalLoadChar	ax, C_NULL
	LocalPutChar	esdi, ax		; null terminate

	clc
exit:
	.leave
	ret
PSDLInitItem	endm

LocalDefNLString	demoCategory	<'demo', 0>
LocalDefNLString	labelKey	<'label', 0>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLFindCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the file postion in which a certain category starts
		and return a near pointer in the buffer to the beginning
		of the line after that category.

CALLED BY:	INTERNAL

PASS:		es	= segment pointer of buffer to check
		cx	= # of characters of buffer
		ds:si	= category string to find
RETURN:		carry	= set if not found
				di = destroyed
			= clear if found
				es:di	= fptr to first line of category
				cx	= # of chars left in buffer
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLFindCategory	proc	near
	uses	ax, bx, dx, bp, ds
	.enter

	push	es
	segmov	es, ds, di
	mov	di, si
	mov	bp, cx
	call	LocalStringLength
	xchg	bp, cx			; bp is # chars in category 
	pop	es

	clr	di			; start from the beginning

searchLoop:
	LocalLoadChar	ax, C_LEFT_BRACKET
	LocalFindChar
	stc
	jne	exit			; exit if not found

	;
	; found a bracket, compare to passed category
	;
	xchg	bp, cx			; # chars to compare
	call	LocalCmpStringsNoCase
	xchg	bp, cx			; # chars to compare
	jne	searchLoop

	;
	; category checks, assert final bracket
	;
DBCS<	shl	bp, 1							>
	sub	cx, bp
	add	di, bp
DBCS<	shr	bp, 1							>
	LocalCmpChar	es:[di], C_RIGHT_BRACKET
	jne	searchLoop

	LocalLoadChar	ax, C_CR
	LocalFindChar
	stc
EC<	WARNING_NE	WARNING_PSDL_NO_CR_FOUND_AFTER_CATEGORY	>
	jne	exit			; no linefeed after our category

	clc
exit:		
	.leave
	ret
PSDLFindCategory	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLFindKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Once in a category, find a key and return an nptr
		to the first non-whitespace character after the "="

CALLED BY:	INTERNAL

PASS:		es:di	= nptr to first line of category
		cx	= # of chars left in the buffer
		ds:si	= key to search for
RETURN:		es:di	= fptr to first non-whitespace char after the "="
		cx	= # of chars left in the buffer
		carry	= set if not found
				cx	= 0 if end of buffer reached
				bx	= destroyed
			= clear if found:
				bx	= # of chars in the key's data
						(# chars until end of line)
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLFindKey	proc	near
	uses	ax, dx, si, bp
	.enter

	push	es, di
	segmov	es, ds, di
	mov	di, si
	mov	bp, cx
	call	LocalStringLength
	xchg	bp, cx			; bp is # chars in key
	pop	es, di

lineLoop:
	call	PSDLSkipWhiteSpace
	jc	exit

	;
	; found a non-whitespace char, so check the string for the key
	;
	LocalCmpChar	es:[di], C_LEFT_BRACKET
	stc
	je	exit

	xchg	bp, cx			; # chars to compare
	call	LocalCmpStringsNoCase
	xchg	bp, cx
	je	foundKey

	;
	; not the key, skip to next line
	;
	LocalLoadChar	ax, C_CR
	LocalFindChar
	stc
	jcxz	exit
	jmp	lineLoop		; try again on next line

	;
	; found the key read in, so skip past the "="
	;
foundKey:
	LocalLoadChar	ax, C_EQUAL
	LocalFindChar
	stc
	jcxz	exit
	call	PSDLSkipWhiteSpace
	mov	bx, di
	mov	bp, cx				; # chars remaining
	LocalLoadChar	ax, C_CR
	LocalFindChar
	xchg	di, bx				; swap nptrs
	sub	bx, di				; get length of to end of line
	dec	bx				; - end of line itself
	mov	cx, bp				; restore # characters

exit:
	.leave
	ret
PSDLFindKey	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLSkipWhiteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next non-whitespace character.

CALLED BY:	INTERNAL

PASS:		es:di	= fptr to buffer
		cx	= # of chars left in the buffer
RETURN:		carry	= set if buffer end was reached
			= clear if non-whitespace found:
				es:di	= fptr updated to non-whitespace
				cx	= # of chars left in buffer
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLSkipWhiteSpace	proc	near
	.enter

	jcxz	endOfBuffer

skipLoop:
	LocalCmpChar	es:[di], C_SPACE
	je	skipThisChar
	LocalCmpChar	es:[di], C_TAB
	je	skipThisChar
	LocalCmpChar	es:[di], C_CR
	je	skipThisChar
	LocalCmpChar	es:[di], C_LINEFEED
	clc
	jne	exit

skipThisChar:
	LocalNextChar	esdi
	dec	cx
	jnz	skipLoop

endOfBuffer:
	stc
exit:
	.leave
	ret
PSDLSkipWhiteSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLCompressItemList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Any items that failed processing will have a null name, 
		and we want to take them out of the list of items.
		Loop, calling a message for subclasses to intercept, and
		then compress the NameAndLabel array block.

CALLED BY: 	PSDLMetaInitialize

PASS:		ds:si	= PrefSpuiDynamicListClass object
		bx	= handle of the block of NameAndLabel structures
		cx	= number of items
RETURN:		block updated

DESTROYED:	ax, bx, dx, bp, di

PSEUDO CODE/STRATEGY:

		Loop through the list and call our hook message for each
		item that will be deleted, then compress our block.

		X is end of compressed section
		Y is begining of chunk to move up to X
		Z is ending of chunk to move up to X

		X = find first marked item
			no files marked? exit!
		Y = X
	loopTop:
		Y = next unmarked item or end of list
			end of list? exit!
		Z = next marked item after Y or end of list
		move entries between Y and Z to X
		X = X + (|Z - Y|) (increment X to end of compressed)
		Y = Z
		jmp loopTop
	exit!
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/18/92		Initial version
	dlitwin	8/28/94		copied and mod. from CompressFileQuickTransfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLCompressItemList	proc	near
	uses	ds, si
	.enter

	push	bx
	call	MemLock
	mov	es, ax
	clr	di
	clr	bp

hookLoopTop:
CheckHack< (offset NAL_filename) eq 0 >
	tst	<{byte} es:[di]>
	jnz	nextItem

	push	cx, bp
	mov	ax, MSG_PSDL_REMOVE_ITEM
	call	ObjCallInstanceNoLock
	pop	cx, bp

nextItem:
	add	di, size NameAndLabel
	inc	bp
	cmp	bp, cx
	jne	hookLoopTop

	;
	; compress the block
	;
	segmov	ds, es, ax			; ds and es point to same seg.
CheckHack< (offset NAL_filename) eq 0 >
	clr	di
	mov	dx, size NameAndLabel

	; di will be X, si will be Y

	;
	; X = find first marked item
	;
xLoop:
	tst	<{byte} es:[di]>
	jz	xSet
	add	di, dx				; dx is item size
	loop	xLoop
		;
		; no items marked?
		;
	jmp	done				; exit!

xSet:	;
	; Y = X
	;
	mov	si, di

loopTop:		; **** loopTop ****
		; Y = next unmarked item or end of list
yLoop:
	tst	<{byte} es:[si]>		; is item marked?
	jnz	ySet
	add	si, dx				; go to next item
	dec	bp				; update file count because
	loop	yLoop				;   we just skiped an item
		; end of list? exit!
	jmp	done

ySet:
	push	cx				; save Y item position
	mov	bx, si
zLoop:
	tst	<{byte} es:[bx]>
	jz	zSet
	add	bx, dx				; next item
	loop	zLoop
		; reached end of items
zSet:
	mov	cx, bx
	sub	cx, si				; get length to copy into cx
	;
	; move entries between Y and Z to X
	;
	rep	movsb
	; 
	; X (di) is updated properly to be X + |Y - Z|
	; Y (si) is updated properly to be Z
	; so just loop...
	;
	pop	cx				; restore Y item position
	jmp	loopTop

done:
	mov	cx, bp				; reset to new number of items
	pop	bx
	call	MemUnlock

	.leave
	ret
PSDLCompressItemList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the demo's chosen .ini file name to the master .ini
		file.

CALLED BY:	MSG_GEN_SAVE_OPTIONS
PASS:		*ds:si	= PrefSpuiDynamicListClass object
		ds:di	= PrefSpuiDynamicListClass instance data
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLSaveOptions	method dynamic PrefSpuiDynamicListClass, 
					MSG_GEN_SAVE_OPTIONS
	uses	ax, cx, dx, bp
	.enter

	mov	bx, ds:[di].PSDLI_nameArray	; get from Pref master group

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GIGI_numSelections	; get from Gen master group
	jz	exit

	call	MemLock
	mov	es, ax

	mov	cx, ds:[di].GIGI_selection
	mov	al, size NameAndLabel
	mul	cl				; assume cx <= 255
CheckHack< (offset NAL_filename) eq 0 >
	mov	di, ax				; es:di is our demo .ini name

	mov	cx, ss
	lea	dx, ss:[bp].GOP_key		; cx:dx is our .ini key
	mov	ds, cx
	lea	si, ss:[bp].GOP_category	; ds:si is our .ini category
	mov	bp, size FileLongName
	call	InitFileWriteString

	call	MemUnlock

exit:
	.leave
	ret
PSDLSaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the array of NameAndLabel structures for the name of
		the saved demo .ini, and select the corresponding item in
		the dynamic list.

CALLED BY:	PSDLMetaInitialize

PASS:		*ds:si	= PrefSpuiDynamicListClass object
		ds:di	= PrefSpuiDynamicListClass instance data
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLLoadOptions	method dynamic PrefSpuiDynamicListClass, 
					MSG_GEN_LOAD_OPTIONS
	mov	bx, bp				; ss:bx is our GenOptionsParams
objPtr		local	optr	push	ds, si
numItems	local	word
oldIni		local	FileLongName
	class	PrefSpuiDynamicListClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDLI_numItems
	tst	ax
	jz	exit
	mov	ss:[numItems], ax

	mov	cx, ss
	lea	dx, ss:[bx].GOP_key		; cx:dx is key
	mov	ds, cx
	lea	si, ss:[bx].GOP_category	; ds:si is category
	mov	es, cx
	lea	di, ss:[oldIni]			; es:di is old ini buffer

	push	bp				; save our frame pointer
	mov	bp, size FileLongName
	call	InitFileReadString
	pop	bp				; restore our frame pointer
	jc	exit				; no old .ini to have selected

	;
	; OK, we have an old .ini file in the demo category, so check
	; to see if any of our list has that same name
	;
	lds	si, ss:[objPtr]
	mov	di, ds:[si]
	add	di, ds:[di].PrefSpuiDynamicList_offset
	mov	bx, ds:[di].PSDLI_nameArray
	push	bx			; save for unlock
	call	MemLock
	mov	ds, ax
	mov	si, NAL_filename	; ds:si is our first filename
	clr	ax			; loop counter

	;
	; get old .ini string length
	;
	lea	di, ss:[oldIni]
	call	LocalStringLength
	inc	cx			; cx is length + null
	mov	bx, cx			; save for loop comparisons
	lea	di, ss:[oldIni]

loopTop:
	mov	cx, bx			; length to compare
	call	LocalCmpStringsNoCase
	je	gotFile
	
	lea	di, ss:[oldIni]		; restore old .ini nptr
	add	si, size NameAndLabel	; next item
	inc	ax
	cmp	ax, ss:[numItems]
	jne	loopTop

	jmp	afterSet		; failed all items

	;
	; OK, so we found our file, and ax is the item number, so set
	; the list to this item.
	;
gotFile:
	mov	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	movdw	dssi, ss:[objPtr]	; restore our object
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp

afterSet:
	pop	bx			; restore for unlock
	call	MemUnlock

exit:
	.leave
	ret
PSDLLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An item has been requested, so grab the string and
		stuff it in the right place.

CALLED BY:	MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
PASS:		*ds:si	= PrefSpuiDynamicListClass object
		ss:bp	= GetItemMonikerParams
RETURN:		buffer filled
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLGetItemMoniker	method dynamic PrefSpuiDynamicListClass, 
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
	uses	ax, cx, dx, bp
	.enter

	cmp	ss:[bp].GIMP_bufferSize, size LabelText
	jl	notEnoughSpace

	mov	cx, ss:[bp].GIMP_identifier
	mov	al, size NameAndLabel
	mul	cl
	mov	si, ax				; si is our offset

	mov	bx, ds:[di].PSDLI_nameArray
	call	MemLock

	mov	ds, ax				; ds:si is our NameAndLabel
	add	si, offset NAL_label		; ds:si is our label string

	les	di, ss:[bp].GIMP_buffer		; es:di is destination buffer

	LocalCopyString

	call	MemUnlock
exit:
	.leave
	ret			; <--- EXIT HERE

notEnoughSpace:
	clr	bp
	jmp	exit
PSDLGetItemMoniker	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLGetSelectedIniFileText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open up the .ini file of the selected item and read its
		text into a buffer.

CALLED BY:	MSG_PSDL_GET_SELECTED_INI_FILE_TEXT
PASS:		*ds:si	= PrefSpuiDynamicListClass object

RETURN:		carry	= set on error
				dx, cx = destroyed
			= clear on success
				dx	= hptr of block of text
					= garbage if no selections(i.e. no .ini)
				cx	= size of text in block
					= zero if no selections (i.e. no .ini)
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLGetSelectedIniFileText	method dynamic PrefSpuiDynamicListClass, 
					MSG_PSDL_GET_SELECTED_INI_FILE_TEXT
	uses	bp
	.enter

	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	lea	dx, ds:[bx].GFP_path
	mov	bx, ds:[bx].GFP_disk
	call	FileSetCurrentPath
LONG	jc	exit

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GDLI_numItems
	clc
	jcxz	exit				; no items in this list

	clr	ax				; assume first item selected
	mov	cx, ds:[di].GIGI_selection
	cmp	cx, GIGS_NONE
	je	gotNptr	
	mov	ax, size NameAndLabel
	mul	cl				; assume numItems < 255
gotNptr:
	mov	dx, ax				; nptr to NameAndLabel struct

	;
	; open file
	;
	mov	di, ds:[si]
	add	di, ds:[di].PrefSpuiDynamicList_offset
	mov	bx, ds:[di].PSDLI_nameArray
	call	MemLock
CheckHack< (offset NAL_filename) eq 0 >
	mov	ds, ax				; ds:dx is our .ini name
	mov	al, FILE_ACCESS_R or FILE_DENY_W
	call	FileOpen
	call	MemUnlock	
	jc	exit

	;
	; allocate buffer block
	;
	mov	bx, ax				; filehandle in bx
	push	bx
	call	FileSize
	tst	dx
	stc
EC<	WARNING_NZ	WARNING_PSDL_FILE_IS_JUST_TOO_DAMN_BIG		>
	jnz	fileClose

	mov	bp, ax				; save size for later
	mov	dx, bx				; save file handle for later
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	fileClose

	;
	; read file into buffer
	;
	push	bx				; save block handle for unlock
	mov	bx, dx				; restore file handle
	mov	cx, bp				; restore size
	mov	ds, ax
	clr	dx				; ds:dx is our new block
	clr	al				; can handle errors
	call	FileRead

	pop	bx
	call	MemUnlock
	mov	dx, bx				; dx, is buffer block
	mov	cx, bp				; cx is buffer size

fileClose:
	pop	bx
	pushf					; save any error flag
	clr	ah
	call	FileClose
	jnc	checkFlags			; check flags if close succeeded
	pop	ax
	jmp	exit
checkFlags:
	popf
exit:
	call	FilePopDir

	.leave
	ret
PSDLGetSelectedIniFileText	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDLFindItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle this, as we are expected to, but punt to return the
		first item, because I don't have time (and it isn't worth)
		writing the full version.

CALLED BY:	MSG_PREF_DYNAMIC_LIST_FIND_ITEM
PASS:		*ds:si	= PrefSpuiDynamicListClass object
		cx:dx	= null-terminated ASCII string
		bp 	= nonzero to find best fit( ie, ignore case, and
				match up to the length of the passed string),
				zero to find and exact match (should match
				case, and make sure strings are the same length)
RETURN:		if FOUND:
			carry clear
			ax - item #
		ELSE:
			carry set
			ax - first item AFTER requested item  ???????
DESTROYED:	cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDLFindItem	method dynamic PrefSpuiDynamicListClass, 
					MSG_PREF_DYNAMIC_LIST_FIND_ITEM
	.enter

	clr	ax
	clc

	.leave
	ret
PSDLFindItem	endm
