COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		(Generic) Font Installation
FILE:		fontInstall.asm

AUTHOR:		John D. Mitchell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.16	Initial version
	JDM	91.04.29	Reworked for FontConvertEntry.
	JDM	91.05.06	Interfaced with conversion code,
				added thread spawning for conversion.
	JDM	91.05.14	Added list removal/clean-up code.
	JDM	91.05.16	Fixed memory allocation bug.
	JDM	91.05.17	Changed style & weight arguments.
	JDM	91.05.17	Fixed off-by-one error in UpdateFCEntry.
	JDM	91.05.20	Strings made case-insensitive.
	JDM	91.05.21	Added duplicate font checking.
	JDM	91.05.22	Added unnormalized name string.
	JDM	91.05.29	Fixed Weight/Styles finding.
	JDM	91.06.04	Added EC code.
	JDM	91.06.05	Fixed block segment changing bug.

DESCRIPTION:
	This file contains the code to handle the dynamic font selection
	list.

	$Id: fontInstall.asm,v 1.1 97/04/04 16:16:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


FontInstallListCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the internal state of the list.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.

RETURN:		Carry Flag:
			Set iff error.
			Clear otherwise.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Minimal stack usage.

PSEUDO CODE/STRATEGY:
	Save the handle of list object for later hacking.
	Allocate an initial global block to hold the chunk array and
	its attendant font and font file name strings.
	Save the block's handle for later use.
	Make the block a standard Local memory heap.
	Create a chunk array in the block.
	Save the block's handle for later use.
	Unlock the global block.
	Tell ourself to purge all of the monikers.
	Return carry set iff error.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	If you don't invoke this *before* using anything else then you
	get hosed!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.16	Initial version
	JDM	91.05.01	Added register preservation.
	JDM	91.05.14	Added list moniker purging.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListInit	method	dynamic	FontInstallListClass,
				METHOD_FONT_INSTALL_LIST_INIT
	uses	ax,cx,dx,bp

	.enter

	; Save the handle of the list object for later hacking.
	mov	ds:[di].FIL_listHandle, si

	; Allocate the initial global block with a single element
	; in it.
	mov	ax, size FontConvertEntry	; Size to allocate.
	mov	cx, ALLOC_DYNAMIC_LOCK		; Block type.
	call	MemAlloc
	jc	badExit				; Bail!

	; Save the block handle.
	mov	ds:[di].FIL_fontInfoBlockHandle, bx

	; Initialize the block to be a memory heap.
	; It's just a standard ol' local block.
	push	si				; Save instance access.
	DoPush	ds,di
	mov	ds, ax				; Segment of global block.
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, STD_INIT_HANDLES
	mov	dx, size LMemBlockHeader
	mov	si, STD_INIT_HEAP
	clr	di
	clr	bp
	call	LMemInitHeap

	; Create the chunk array.
	; NOTE:  DS already set.
	clr	al				; No ObjChunkFlags.
	mov	bx, size FontConvertEntry	; Size of each element.
	call	ChunkArrayCreate
	DoPopRV	ds,di				; Restore instance access.

	; Well, since there are no possible errors returned...  :-)
	; Save the chunk handle of the chunk array.
	mov	ds:[di].FIL_fontInfoArrayHandle, si

	; Unlock the global block.
	mov	bx, ds:[di].FIL_fontInfoBlockHandle	; Retrieve handle.
	call	MemUnlock

	; Tell ourself to get rid of all the monikers.
	; NOTE:	DS already set.
	mov	ax, METHOD_GEN_LIST_PURGE_MONIKERS
	clr	cx				; No list entries.
	mov	dx, cx				; None selected.
	pop	si
	call	ObjCallInstanceNoLock

	; That's all folks!
	clc
	jmp	exit
	
badExit:
	; Signal error to caller.
	stc

exit:
	.leave
	ret
FontInstallListInit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListKill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Terminate the list with extreme prejudice.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Minimal stack usage.

PSEUDO CODE/STRATEGY:
	Get rid of the global data memory block that we've been using.
	Reset all of the instance variables to the pristine state.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This assumes that the list initialization function has already
	been invoked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.14	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListKill	method	dynamic	FontInstallListClass,
				METHOD_FONT_INSTALL_LIST_KILL
	uses	ax,cx,dx,bp

	.enter

	; Free up the global block.
	mov	bx, ds:[di].FIL_fontInfoBlockHandle
	call	MemFree

	; Reset all of the instance data.
	clr	ax
	mov	ds:[di].FIL_fontInfoBlockHandle, ax
	mov	ds:[di].FIL_fontInfoArrayHandle, ax
	mov	ds:[di].FIL_fontNumElements, ax
	mov	ds:[di].FIL_listHandle, ax

	; That's all folks!
	clc

	.leave
	ret
FontInstallListKill	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListConvertSelectedFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Pass the selected FontConvertEntry to the conversion
		code.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Dynamic method register file saving.
	Everything.

PSEUDO CODE/STRATEGY:
	Call ourself to find out what is currently selected.
	Allocate a FontThreadInfoEntry.
	Fill it with the appropriate information.
	Invoke the method catcher running under the application's thread
	to do the conversion.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The list must already have been built and there must be a currently
	selected item.
	The allocated FontThreadInfoEntry must be freed by the receiver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.06	Initial version
	JDM	91.05.16	Fixed FontInfoEntry allocation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListConvertFont	method	dynamic	FontInstallListClass,
			METHOD_FONT_INSTALL_LIST_CONVERT_SELECTED_FONT
	uses	cx,dx,bp

	.enter

	; Figure out what base (typeface) name the user selected.
	mov	ax, METHOD_FONT_INSTALL_LIST_GET_SELECTED_FONT
	call	ObjCallInstanceNoLock
	mov	dx, cx				; Save it.

	; Allocate a block to pass information to the new thread.
	; NOTE:	Block must be sharable because it will be freed
	;	by a different thread.
	mov	ax, size FontThreadInfoEntry
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	jc	exit

	; Otherwise, set up the information to pass to the catcher.
	push	bx				; Save block handle.
	mov	es, ax
	mov	si, offset FTIE_infoBlock
	mov	bx, ds:[di].FIL_fontInfoBlockHandle
	mov	es:[si], bx
	mov	si, offset FTIE_arrayHandle
	mov	bx, ds:[di].FIL_fontInfoArrayHandle
	mov	es:[si],  bx
	mov	si, offset FTIE_currItem
	mov	es:[si], dx

	; We're done with the block.
	pop	bx				; Restore the handle.
	call	MemUnlock
	
	; Invoke an application thread method handler to do the
	; actual conversion.
	mov	cx, bx				; BX from above.
	mov	ax, METHOD_FONT_INSTALL_LIST_CONVERT_FONT
	mov	bx, handle 0
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

exit:
	.leave
	ret
FontInstallListConvertFont	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListPutEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Add the Font in the given FontInfoEntry into the List.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.
		CX:DX	= Pointer to FontInfoEntry.

RETURN:		Carry Flag:
			Set iff error.
			Clear otherwise.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Two temprary fptr's.
	Everything.

PSEUDO CODE/STRATEGY:
	Save the critical arguments into locals.
	Normalize the FontInfoEntry strings.
	Lock the global data block with the font information.
	Figure out the style(s), weight, and the typeface of the font.
	Update the chunk array.
	Unlock the global data block with the font information.
	Restore the critical arguments from the locals.
	Return with the carry flag indicating our success/failure.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	NOTE:	FontInfoEntry and it's information must be locked.
		Fields of the FontInfoEntry *will* be modified!
	NOTE:	The Style and Weight tables are assumed to be in
		the same normalized form as if NormalizeFontInfoEntry
		had modified them!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.16	Initial version
	JDM	91.04.29	Reworked for FontInfo- & FontConvertEntry.
	JDM	91.05.01	Added register preservation.
	JDM	91.05.17	Fixed local variable declarations.
	JDM	91.05.20	Added string normalization.
				Added checking of weight string for
				TextStyles information.
	JDM	91.05.22	Added normalized name support.
	JDM	91.06.05	Fixed stupid saved segment bug!
				(Thanks Gene!)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListPutEntry	method	dynamic	FontInstallListClass,
				METHOD_FONT_INSTALL_LIST_PUT_ENTRY
	uses	ax, cx, dx

	; Local variables.
	FIEPtr		local	fptr.FontInfoEntry
	ObjInstance	local	fptr

	.enter

	; Save the args into locals.
	mov	ss:[FIEPtr].offset, dx
	mov	ss:[FIEPtr].segment, cx
	mov	ss:[ObjInstance].offset, di
	mov	ss:[ObjInstance].segment, ds

	; Lock the Global block that contains our stuff.
	mov	si, di				; DS:SI = ObjInstance.
	mov	bx, ds:[si].FIL_fontInfoBlockHandle
	call	MemLock				; AX = Block segment.
	jc	death				; Serious error!

	; Normalize the FontInfoEntry.
	; 	The FontInfoEntry.FIE_normFont will contain a chunk handle,
	;	relative to the global font information block, of the
	;	normalized font name string.
	mov	es, cx				; ES:DI = FontInfoEntry.
	mov	di, dx
	mov	dx, ax				; DX = Global block seg.
	call	NormalizeFontInfoEntry		; DX fixed up.

	; Figure out the font's style(s) and typeface.
	; NOTE:	DS:SI, ES:DI already set.
	call	FindFontStylesTypeface		; AL = TextStyles.
	mov	bx, ax				; Save it.
	push	cx				; Save length of name.

	; Figure out the font's weight.
	; NOTE:	DS:SI, ES:DI already set.
	call	FindFontWeight			; AL = FontWeight.

	; Update the chunk array information.
	; NOTE:
	;	AL	== TextStyles.
	;	BL	== FontWeight.
	;	CX	== Length of FIE_font (including terminator).
	;	DX	== Segment of locked global data block.
	;	ES:DI	== FontInfoEntry.
	;	DS:SI	== ObjInstance.
	xchg	ax, bx				; Order the attributes.
	pop	cx				; Restore name length.
	call	FontUpdateChunkArray

	; Unlock the global block.
	mov	bx, ds:[si].FIL_fontInfoBlockHandle
	call	MemUnlock

	; Skip death sentence.
	clc					; Everything O'Tay!
	jmp	exit

death:
	stc					; Signal error.

exit:
	; Restore the args from the locals.
	mov	dx, ss:[FIEPtr].offset
	mov	cx, ss:[FIEPtr].segment
	lds	di, ss:[ObjInstance]

	.leave
	ret
FontInstallListPutEntry	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListSetSelectedFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the internal current element index.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.
		CX	= List entry selected.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	AX, BP.

PSEUDO CODE/STRATEGY:
	Send ourself a METHOD_GEN_LIST_SET_EXCL to force the list
	to be the currently displayed selection.
	Send a message to the process class so that it can do any
	other processing.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The ListFlags passed in BP are such that if this method is
	invoked from the AD of the list, it won't screw things up.
	(I.e. this method works correctly if it is called from either
	the application, internally, or from the actual user selection
	action descriptor for the list.)
	Having the list have to send this method out is a by product of
	the insanity of the dynamic GenList world.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.17	Initial version
	JDM	91.05.01	Added register preservation.
	JDM	91.05.08	Added process class invocation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListSetSelectedFont	method	dynamic	FontInstallListClass,
				METHOD_FONT_INSTALL_LIST_SET_SELECTED_FONT
	uses	ax,cx,dx,bp

	.enter

	; Save the entry selected.
	push	cx

	; Send ourself the set exclusive message.
	; NOTE:  DS, DI, SI, CX already set.
	mov	ax, METHOD_GEN_LIST_SET_EXCL	; Message.
	mov	bp,	mask LF_SUPPRESS_APPLY or \
			LET_POSITION shl offset LF_ENTRY_TYPE or \
			mask LF_REFERENCE_USER_EXCL
	call	ObjCallInstanceNoLock

	; Pass on the method to the process for any additional work.
	pop	cx				; Restore entry index.
	mov	ax, METHOD_APP_INSTALL_LIST_SET_SELECTED_FONT
	mov	bx, handle 0			; Process.
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
FontInstallListSetSelectedFont	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListGetSelectedFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the current element index.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.

RETURN:		CX	= List entry selected. (-1 if none selected.)
		Carry Flag:
			Set if fatal error.
			Clear otherwise.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	No stack.
	AX, BP, CX, Carry Flag.

PSEUDO CODE/STRATEGY:
	Get the index of the currently selected item in the list by
	calling ourself with the appropriate flags.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Huh??  If there's something wrong with this I didn't do it! Or not!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.17	Initial version
	JDM	91.05.01	Added register preservation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListGetSelectedFont	method	dynamic	FontInstallListClass,
				METHOD_FONT_INSTALL_LIST_GET_SELECTED_FONT
	uses	ax,dx,bp

	.enter

	; Send ourself the get exclusive message.
	; NOTE:  DS, DI, SI, CX already set.
	mov	ax, METHOD_GEN_LIST_GET_EXCL
	mov	bp,	LET_POSITION shl offset LF_ENTRY_TYPE or \
			mask LF_REFERENCE_USER_EXCL
	call	ObjCallInstanceNoLock

	.leave
	ret
FontInstallListGetSelectedFont	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListGetFontName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the font name string associated with the given
		list entry index..

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.
		CX:DX	= Buffer to store the font name string.
		BP	= List entry index.

RETURN: 	CX:DX	= Font name of requested list entry.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file saving.
	Everything.

PSEUDO CODE/STRATEGY:
	Lock the block containing the global list data.
	Get access to the requested list entry's font name.
	Copy the font name into the given buffer.
	Unlock the global list data block.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	NOTE:
		If the list entry index given is invalid then the
		font name returned will be for the last list entry.
		The buffer passed is assumed to be big enough to hold
		the font name string (MAX_FONT_NAME_LENGTH).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.08	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListGetFontName	method	dynamic	FontInstallListClass,
				METHOD_FONT_INSTALL_LIST_GET_FONT_NAME
	uses	ax,cx,dx,bp

	.enter

	; Save access to the passed buffer.
	push	cx				; Segment.
	push	dx				; Offset.

	; Lock the global block.
	mov	bx, ds:[di].FIL_fontInfoBlockHandle
	call	MemLock
	
	; Get a pointer to the requested element.
	mov	si, ds:[di].FIL_fontInfoArrayHandle	; Chunk arr.
	mov	ds, ax				; *DS:SI = chunk array.
	mov	ax, bp				; Requested element.
	call	ChunkArrayElementToPtr		; DS:DI == element.
	
	; Point to the actual name string.
	mov	si, ds:[di].FCE_name		; DS:SI = name string.
	mov	si, ds:[si]			; Indirect through lmem.

	; Point to the buffer to copy the name string into.
	pop	di				; ES:DI = destination.
	pop	es

	; Copy the name string into the given buffer.
	clr	ax				; Makes checking faster.
copyLoop:
	; ASSUMED:
	;	DS:SI = current position in null-terminated source string.
	;	ES:DI = current position in destination buffer that is
	;		assumed to be big enough to hold the source string.

	; Get a character.
	; NOTE:	SI automatically advanced.
	lodsb					; AL = character.

	; Copy the character to the output buffer.
	; NOTE:	DI automatically advanced.
	stosb

	; Are we done yet?
	tst	ax
	jnz	copyLoop			; Nope.  Next!

	; Otherwise we're done copying the string.

	; Unlock the global data block.
	; NOTE:  BX assumed already set.
	call	MemUnlock

	.leave
	ret
FontInstallListGetFontName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListSetFontName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the font base (typeface) name string associated with
		the given list entry index.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.
		CX:DX	= Font base (typeface) name string.
		BP	= List entry index.

RETURN:		Carry Flag:
			Set iff error.
			Clear otherwise.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file saving.
	Everything.

PSEUDO CODE/STRATEGY:
	Figure out how big a chunk to allocate to hold the new string.
	Lock the block containing the global list data.
	Allocate a new chunk to hold the new name string.
	Copy the font name from the given buffer into the chunk.
	Get access to the appropriate list entry.
	Free the old name string's chunk.
	Set the requested list entry's font name to the new chunk.
	Unlock the global list data block.
	Inform ourself that the monikers have been updated.

CHECKS:
	Non null-terminated strings.
	Null-strings.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	If the requested list entry index is out of range than this will
	promptly use the last entry in the list.
	If the user entered a null-string for the name then we abort.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.08	Initial version
	JDM	91.05.14	Added abortion for null-strings.
	JDM	91.06.04	Added EC code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListSetFontName	method	dynamic	FontInstallListClass,
				METHOD_FONT_INSTALL_LIST_SET_FONT_NAME
	uses	ax,cx,dx

	; Local variables.
	ListObj		local	fptr		; *ListObj = list object.
	NewNameString	local	fptr.char

	.enter

	; Save arguments into locals.
	; NOTE:	The requested list entry index value is at ss:[bp]
	;	due to the fact that bp is used for the local stack frame.
	mov	ss:[NewNameString].segment, cx
	mov	ss:[NewNameString].offset, dx
	mov	ss:[ListObj].segment, ds
	mov	ss:[ListObj].offset, di

	; Find out how big the string is.
	mov	es, cx				; ES:DI = name string.
	mov	di, dx
	clr	ax				; Search for terminator.
	mov	cx, -1				; Could be big! :-(
	repne	scasb

	; Check for non-terminated string.
	tst	cx
EC <	ERROR_E	STRING_TOO_BIG						>
	jz	exitBad				; NO terminator!!!!!

	; Otherwise, calculate the length.
	mov	ax, -1
	sub	ax, cx				; AX = 0xffff-ending count.
	mov	cx, ax				; CX = string length.

	; Check for a null-string.
	cmp	ax, 1				; Only null-terminator?
EC <	ERROR_E	STRING_CANT_BE_NULL					>
	jz	exitBad

	; Lock the global block.
	lds	di, ss:[ListObj]
	mov	bx, ds:[di].FIL_fontInfoBlockHandle
	call	MemLock
EC <	ERROR_C	CANT_LOCK_GLOBAL_BLOCK					>
	jc	exitBad

	push	si			; Save the handle of list object.
	push	bx			; Save global block access.
	
	; Allocate a new chunk to hold the new name string.
	; NOTE:	CX already set.
	mov	ds, ax
	clr	ax
	call	LMemAlloc
	push	ax				; Save chunk handle.
	push	ds				; Save data block segment.

	; Copy the new name string into the chunk.
	; NOTE:	CX already set.
	segmov	es, ds				; ES:DI = chunk.
	mov	di, ax				; Block handle.
	mov	di, es:[di]
	lds	si, ss:[NewNameString]		; DS:SI = font name string.
	rep	movsb

	; Get a pointer to the requested element.
	lds	di, ss:[ListObj]
	mov	si, ds:[di].FIL_fontInfoArrayHandle	; Chunk arr.
	segmov	ds, es	 			; *DS:SI = chunk array.
	mov	ax, ss:[bp]			; Requested element.
	call	ChunkArrayElementToPtr		; DS:DI == element.
	
	; Get the chunk handle of the old name string.
	; Save the chunk handle of the new name string.
	; Free the old name string chunk.
	pop	es				; Restore chunk segment.
	pop	bx				; Restore chunk handle.
	mov	ax, ds:[di].FCE_name		; Old name string chunk.
	mov	ds:[di].FCE_name, bx		; New name string chunk.
	segmov	ds, es				; *DS:AX = old string.
	call	LMemFree

	; Unlock the global data block.
	pop	bx				; Restore block access.
	call	MemUnlock

	; Tell ourself that the monikers have been updated.
	pop	si				; Restore obj. handle.
	push	bp				; Save stack frame.
	mov	ax, METHOD_GEN_LIST_REQUEST_ENTRY_MONIKER
	lds	di, ss:[ListObj]		; Get object access.
	mov	bp, ss:[bp]			; Get entry index.
	call	ObjCallInstanceNoLock
	pop	bp				; Restore stack frame.

	; Skip death.
	jmp	exit

exitBad:
	stc					; Heinous error.

exit:
	.leave
	ret
FontInstallListSetFontName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListSetSelectedFontName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the font base (typeface) name string associated
		with the currently selected list item.

PASS:		*DS:SI	= List object.
		DS:DI	= List object instance data.
		CX:DX	= Font base (typeface) name string.

RETURN:		Carry Flag:
			Set iff error.
			Clear otherwise.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file saving.
	Everything.

PSEUDO CODE/STRATEGY:
	This is basically just a front end for FontInstallListSetFontName.
	Query ourself for the index of the currently selected list entry.
	Invoke ourself to actually do the grunge work.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	If the requested list entry index is out of range than this will
	promptly use the last entry in the list.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.08	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListSetSelectedFontName	method	dynamic	\
			FontInstallListClass,
			METHOD_FONT_INSTALL_LIST_SET_SELECTED_FONT_NAME
	uses	ax,cx,dx,bp

	.enter

	; What's the currently selected list entry?
	DoPush	cx,dx				; Save new name string.
	mov	ax, METHOD_FONT_INSTALL_LIST_GET_SELECTED_FONT
	call	ObjCallInstanceNoLock		; CX = current index.

;	; This jc commented out due to bug in GenList code.
;	jc	exit				; Most egregious error!

	; Pawn off the work.
	mov	bp, cx
	DoPopRV	cx,dx				; Restore new name string.
	mov	ax, METHOD_FONT_INSTALL_LIST_SET_FONT_NAME
	call	ObjCallInstanceNoLock

	; Fall through!
	; NOTE:	The return values are already set up.

; exit:
	.leave
	ret
FontInstallListSetSelectedFontName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListVisBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Hack to get the dynamic GenList to have something
		always selected.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	One register file stack usage.

PSEUDO CODE/STRATEGY:
	Call super to do it's thing.
	Invoke METHOD_FONT_INSTALL_LIST_SET_SELECTED_FONT to make the
	first entry the currently selected entry.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This routine assumes that there is a 'first entry' in existence
	when invoked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.03	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListVisBuild	method	dynamic	FontInstallListClass,
				METHOD_VIS_BUILD
	uses	ax,cx,dx,bp

	.enter

	; Save the goodies.
	DoPush	bx,dx,bp,si,di

	; Invoke the super.
	mov	di, offset FontInstallListClass
	call	ObjCallSuperNoLock

	; Restore the goodies.
	DoPopRV	bx,dx,bp,si,di

	; Select first entry.
	mov	ax, METHOD_FONT_INSTALL_LIST_SET_SELECTED_FONT
	mov	cx, 0				; A-number-one!
	call	ObjCallInstanceNoLock

	.leave
	ret
FontInstallListVisBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListGetNumElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Figure out the text for a specific dynamic font selector
		list entry.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	AX, CX.

PSEUDO CODE/STRATEGY:
	Get our internal count of elements and pass that to ourself
	(actually goes up to super).

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	What could possibly go wrong with this!?!  :-)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.17	Initial version
	JDM	91.05.01	Added register preservation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListGetNumElements	method	dynamic	FontInstallListClass,
				METHOD_GEN_LIST_GET_NUMBER_OF_ENTRIES
	uses	ax,cx,dx,bp

	.enter

	; Get the count of elements from our instance data.
	mov	cx, ds:[di].FIL_fontNumElements

	; Tell ourself about it.
	mov	ax, METHOD_GEN_LIST_SET_NUMBER_OF_ENTRIES
	call	ObjCallInstanceNoLock

	.leave
	ret
FontInstallListGetNumElements	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInstallListGetFontMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Figure out the text for a specific dynamic font selector
		list entry.

PASS:		*DS:SI	= List Class.
		DS:DI	= Font Install List instance data.
		BP	= List entry to build.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Temporary CopyListEntryMonikerFrame on stack.

PSEUDO CODE/STRATEGY:
	Lock the global block containing the chunk array and the
	associated font file and name strings.
	Build a CopyListEntryMonikerFrame on the stack and fill it with
	the appropriate stuff for the call to METHOD_GEN_LIST_SET_MONIKER.
	Unlock the global block.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.16	Initial version
	JDM	91.05.01	Added register preservation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInstallListGetFontMoniker	method	dynamic	FontInstallListClass,
				METHOD_GEN_LIST_REQUEST_ENTRY_MONIKER
	uses	ax,cx,dx,bp

	.enter

	; Save our object data accessibility.
	DoPush	ds,si

	; Lock the global block.
	mov	bx, ds:[di].FIL_fontInfoBlockHandle
	call	MemLock
	
	; Get a pointer to the requested element.
	mov	si, ds:[di].FIL_fontInfoArrayHandle	; Chunk arr.
	mov	ds, ax				; *DS:SI = chunk array.
	mov	ax, bp				; Requested element.
	call	ChunkArrayElementToPtr		; DS:DI == element.
	
	; Point to the actual name string.
	mov	di, ds:[di].FCE_name		; Get string lmem handle.
	mov	cx, ds				; CX:DX = name string.
	mov	dx, ds:[di]			; Indirect through lmem.

	; Build a CopyListEntryMonikerFrame on the stack to
	; send to ourself.
	DoPopRV	ds,si				; Restore obj. access.
	sub	sp, size CopyListEntryMonikerFrame
	mov	bp, sp
	mov	ss:[bp].CLEMF_source.offset, dx	; Pointer to name string.
	mov	ss:[bp].CLEMF_source.segment, cx
	mov	ss:[bp].CLEMF_entryIndex, ax	; Entry number.
	mov	ss:[bp].CLEMF_searchFlags, 0
	mov	ss:[bp].CLEMF_updateMode, VUM_NOW	; Do it now!
        mov     ss:[bp].CLEMF_copyFlags, CCM_STRING shl offset CCF_MODE	

	; Send the frame to ourself.
	mov	ax, METHOD_GEN_LIST_SET_ENTRY_MONIKER	; Message.
	mov	dx, size CopyListEntryMonikerFrame	; # bytes to send.
	call	ObjCallInstanceNoLock

	; Clear stack frame.
	add	sp, size CopyListEntryMonikerFrame

	; Unlock the global data block.
	; NOTE:  BX assumed already set.
	call	MemUnlock

	.leave
	ret
FontInstallListGetFontMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Utility Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontUpdateChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the chunk array with the given font.

CALLED BY:	FontInstallListPutEntry.

PASS:		AL	= TextStyles.
		BL	= FontWeight.
		CX	= Length of FIE_font (including terminator).
		DX	= Segment of locked global data block.
		ES:DI	= FontInfoEntry.
		DS:SI	= ObjInstance.

RETURN:		Carry Flag:
			Set iff error.
			Clear otherwise.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Search the ChunkArray for the typeface.
	if (found) then
		Add the new font information.
	else
		Create a new array element with the typeface and the
		new font's information.
		Update the font list information.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This procedure will increment FIL_fontNumElements as appropriate.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.30	Initial version
	JDM	91.05.03	Added font count updating.
	JDM	91.05.14	Added list count updating.
	JDM	91.05.17	Fixed arguments and local variables.
	JDM	91.05.23	Added normalized font name support.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontUpdateChunkArray	proc	near	uses	ax,bx
			class	FontInstallListClass

	; Locals variables.
	listObj		local	fptr
	FIEPtr		local	fptr.FontInfoEntry
	globalBlockSeg	local	sptr
	nameLength	local	word
	weight		local	FontWeight
	styles		local	TextStyles

	.enter

	; Save arguments into locals.
	mov	ss:[listObj].segment, ds
	mov	ss:[listObj].offset, si
	mov	ss:[FIEPtr].segment, es
	mov	ss:[FIEPtr].offset, di
	mov	ss:[globalBlockSeg], dx
	mov	ss:[nameLength], cx
	mov	ss:[weight], bl
	mov	ss:[styles], al

	; Search for the base (typeface) name in the chunk array.
	; Use the normalized font name.
	; NOTE:	CX already set.
	push	bp				; Save stack access.
	mov	di, es:[di].FIE_normFont	; DI = name chunk.
	mov	es, dx				; *ES:DI = name string.
	mov	bp, es:[di]			; ES:BP = name string.
	mov	si, ds:[si].FIL_fontInfoArrayHandle	; *DS:SI = array.
	mov	ds, dx
	mov	bx, cs				; BX:DI = Callback routine.
	mov	di, offset CompareFontNames
	call	ChunkArrayEnum
	pop	bp				; Restore stack access.
	jc	elementFound			; We found it!

	; Otherwise, we have to create, initialize, and insert
	; a new FontConvertEntry into the chunk array.

	; Allocate a chunk to hold the font name string.
	mov	ds, ss:[globalBlockSeg]		; Segment of locked block.
	clr	ax				; No ObjChunkFlags.
	mov	cx, ss:[nameLength]
	call	LMemAlloc			; DS fixed-up.

	; Save the fixed up global block Seg.
	mov	ss:[globalBlockSeg], ds

	; Copy the base (typeface) name into the FontConvertEntry.
	; NOTE:	CX already set.
	mov	di, ax				; *DS:DI = Destination.
	mov	di, ds:[di]			; DS:DI = Destination.
	segmov	es, ds				; ES:DI = Destination.
	lds	si, ss:[FIEPtr]			; DS:SI = FontInfoEntry.
	mov	bx, ds:[si].FIE_normFont	; BX = normalized chunk.
	lds	si, ds:[si].FIE_font		; DS:SI = Source string.
	rep	movsb

	; This is a new base (typeface) name so increment the list count.
	les	di, ss:[listObj]		; Object access.
	inc	es:[di].FIL_fontNumElements

	; Create a new FontConvertEntry in the chunk array.
	mov	ds, ss:[globalBlockSeg]		; *DS:SI = array.
	mov	si, es:[di].FIL_fontInfoArrayHandle
	call	ChunkArrayAppend

	; Initialize the new FontConvertEntry.
	; NOTE:
	;	AX = Handle of block for the base (typeface) name string.
	;	BX = Chunk handle of the normalized name string.
	;	DS:DI = FontConvertEntry in chunk array.
	mov	ds:[di].FCE_name, ax
	mov	ds:[di].FCE_normName, bx
	clr	ax
	mov	ds:[di].FCE_fontID, ax
	mov	ds:[di].FCE_activeEntries, ax

	; Now insert the first font information into the FontConvertEntry.
	; Set up for the elementFound code.
	segmov	es, ds, ax			; ES:DX = FontConvertEntry.
	mov	dx, di

	; Tell ourself that there is another entry in the list.
	DoPush	es,dx,bp			; Save FontConvertEntry.
	lds	di, ss:[listObj]		; Instance data access.
	mov	si, ds:[di].FIL_listHandle
	mov	ax, METHOD_GEN_LIST_GET_NUMBER_OF_ENTRIES
	call	ObjCallInstanceNoLock
	DoPopRV	es,dx,bp			; Restore FontConvertEntry.

	; FALL THROUGH!

elementFound:
	; NOTE:	ES:DX = FontConvertEntry with the same base (typeface)
	;	name.

	; Go update the FontConvertEntry.
	mov	di, dx				; ES:DI = FontConvertEntry.
	lds	si, ss:[FIEPtr]			; DS:SI = FontInfoEntry.
	mov	bl, ss:[weight]
	mov	al, ss:[styles]
	call	UpdateFontConvertEntry
	jc	exitBad				; Some heinous error!

	; Everything's copacetic.
	clc
	jmp	exit

exitBad:
	; Let the caller know that we chowed.
	stc

exit:
	; Restore arguments from locals.
	lds	si, ss:[listObj]
	les	di, ss:[FIEPtr]
	mov	dx, ss:[globalBlockSeg]
	mov	cx, ss:[nameLength]

	.leave
	ret
FontUpdateChunkArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFontConvertEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the information from the FontInfoEntry and arguments
		to the FontCovertEntry given.

CALLED BY:	FontUpdateChunkArray.

PASS:		AL	= TextStyles.
		BL	= FontWeight.
		ES:DI	= FontConvertEntry.
		DS:SI	= FontInfoEntry.

RETURN:		Carry Flag:
			Set iff error.
			Clear otherwise.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Check for a free spot in the FontStyleEntrys' array.
	If (there's no room) || (the entry's a duplicate) then
		Bail.
	else
		Increment the activeEntries counter.
		Set the appropriate FontStyleEntry's weight and style
		and then copy the file name from the FontInfoEnty.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The buffer being written to will be null-terminated and will
	not overflow.
	FontStyleEntry must be <= 255 bytes in size.
	NOTE:	The carry flag will be *clear* if there is already
		a font of the given weight and style in the
		FontConvertEntry.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.30	Initial version
	JDM	91.05.17	Fixed arguments.
	JDM	91.05.17	Fixed off-by-one activeEntry check.
	JDM	91.05.21	Added duplicate entry checking.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateFontConvertEntry	proc	near	uses	ax,bx,cx,dx,si,di,es,ds
	.enter

	; Are there any open FontStyleEntrys'?
	mov	cl, al				; Save it.
	mov	ax, length FCE_font
	cmp	ax, es:[di].FCE_activeEntries
	jbe	exitBad				; No free spots! Bail!

	; Check to see if this is a duplicate font file entry.
	; NOTE:
	;	BL	= FontWeight.
	;	CL	= TextStyles.
	;	ES:DI	= FontConvertEntry.
	call	CheckDuplicateFCEntry
	jc	exitGood			; Duplicate!  Done!

	; Otherwise, update the FontConvertEntry.
	mov	ax, es:[di].FCE_activeEntries	; Index of in-active entry.
	inc	es:[di].FCE_activeEntries	; Account for new entry.

	; Get access to the FontStyleEntry to use.
	mov	dl, size FontStyleEntry		; Sizeof each entry.
	mul	dl				; Offset to entry.
	add	ax, offset FCE_font		; Array start.
	add	di, ax

	; Set the style and weight fields.
	; NOTE:	ES:DI = FontConvertEntry.FCE_font[newEntry].
	mov	es:[di].FSE_style, cl
	mov	es:[di].FSE_weight, bl

	; Get access to the filename field in the FontStyleEntry.
	mov	ax, offset FSE_filename
	add	di, ax

	; Get access to the filename from the FontInfoEntry.
	lds	si, ds:[si].FIE_file

	; Copy the filename from the FontInfoEntry to the FontStyleEntry.
	; NOTE:
	;	DS:SI = FontInfoEntry.FIE_file,
	;	ES:DI = FontConvertEntry.FCE_font[newEntry].FSE_filename.
	mov	cx, (length FSE_filename) - 1	; Max. length-1 for NUL.
	
copyLoop:
	; Get a character and increment pointer.
	lodsb

	; Are we done yet?
	tst	al				; Null-terminator?
	jz	copyDone			; Yep!

	; Save the character and increment pointer.
	stosb

	; Next!  Will stop if it has copied a full fields worth.
	loop	copyLoop

copyDone:
	; Null-terminate the string.
	clr	ax
	stosb

exitGood:
	clc					; Everything o-tay!
	jmp	exit

exitBad:
	stc					; Heinous error!

exit:
	.leave
	ret
UpdateFontConvertEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDuplicateFCEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the given FontConvertEntry for a FontStyleEntry
		that matches the given style and weight.

CALLED BY:	UpdateFontConvertEntry

PASS:		BL	= FontWeight.
		CL	= TextStyles.
		ES:DI	= FontConvertEntry.

RETURN:		Carry flag:
			Set iff duplicate entry found.
			Clear otherwise.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Count = Number activeEntries.
	while (Count--)
	  {
	  if ((FontConvertEntry.FCE_font[Count].FSE_style = Style) &&
	      (FontConvertEntry.FCE_font[Count].FSE_weight = Weight)) then
	    return (Duplicate Found);
	  }
	return (Duplicate NOT Found);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Would probably be better (faster) to do an additive loop.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.21	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckDuplicateFCEntry	proc	near	uses	ax,bx,cx,dx,di,es

	; Local variable(s).
	FCEFontStyleTableOffset	local	nptr	; Offset only.

	.enter

	; Initialize the pointer to the FontStyleEntry table.
	mov	ax, offset FCE_font		; Offset of table.
	add	ax, di				; ES:AX = table.
	mov	ss:[FCEFontStyleTableOffset], ax	; Save it.

	; Get count of active FontStyleEntrys.
	mov	bh, cl				; BH = TextStyles.
	mov	cx, es:[di].FCE_activeEntries	; Index of in-active entry.
	jcxz	exitNotDuplicate		; No valid entrys.

	; Otherwise correct for zero origin.
	dec	cx

checkLoop:
	; NOTE:
	;	BH	= TextStyles.
	;	BL	= FontWeight.
	;	CX	= Current FontStyleEntry table index (Zero origin).
	;	ES	= Segment of FontConvertEntry.

	; Get access to the FontStyleEntry to use.
	mov	ax, cx				; AX = Entry index.
	mov	dl, size FontStyleEntry		; Sizeof each entry.
	mul	dl				; Offset to entry.
	add	ax, ss:[FCEFontStyleTableOffset]
	mov	di, ax				; ES:DI = FontStyleEntry.

	; Check the style and weight fields.
	; NOTE:	ES:DI = FontConvertEntry.FCE_font[current].
	cmp	es:[di].FSE_style, bh
	jne	nextLoop			; No match here!
	cmp	es:[di].FSE_weight, bl
	jne	nextLoop			; No match here!

	; Otherwise there the same!
	stc					; Signal caller.
	jmp	exit				; Bail!

nextLoop:
	; Are we done?  Have we looked at all of the entrys?
	jcxz	exitNotDuplicate		; Yep. 

	; Otherwise, no match here, so move down to the next entry.
	dec	cx
	jmp	checkLoop

exitNotDuplicate:
	clc

exit:
	.leave
	ret
CheckDuplicateFCEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareFontNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the base (typeface) name in the given chunk
		array element with the given string.

CALLED BY:	FontUpdateChunkArray (ChunkArrayEnum callback).

PASS:		CX	= Length of check-string (including terminator).
		ES:BP	= String to check.
		*DS:SI	= Chunk array.
		DS:DI	= Element to check (FontConvertEntry).

RETURN:		Carry Flag:
			Set iff perfect match.
			Clear otherwise.
		ES:DX = Matching element (iff perfect match).

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Compare the font base (typeface) name passed in with the
	normalized name stored in the FontConvertEntry.
	If they're equal then
		Return a pointer to that FontConvertEntry and
		Halt the ChunkArrayEnum.
	else
		Continue enumerating through the chunk array.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ES:DX as the return seems kinda odd.
	The comparison is case-sensitive.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.30	Initial version
	JDM	91.05.23	Added normalized font name support.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CompareFontNames	proc	far	uses	cx,ds,si,di
	.enter

	; Save access to the FontConvertEntry.
	push	di

	; Get access to the base name field of the FontConvertEntry.
	; NOTE:	DS assumed to be segment of block containing both
	;	chunk array and name strings.
	mov	si, ds:[di].FCE_normName	; *DS:SI = name-string.
	mov	si, ds:[si]			; DS:SI = name-string.
	mov	di, bp				; ES:DI = check-string.

	; Check the strings for equality.
	; NOTE: DS:SI == name-string.
	;	ES:DI == check-string.
	;	CX = Length of check string (including terminator).
	jcxz	exit				; Null-string?!?
	repe	cmpsb
	jnz	exitContinueSearch		; No match.

	; Otherwise we found it!
	segmov	es, ds				; ES:DX = FontConvertEntry.
	pop	dx
	push	dx				; Fake it for exit.
	stc					; Halt enumeration.
	jmp	exit				; Skip death.

exitContinueSearch:
	clc					; Keep looking for match.

exit:
	pop	di				; Restore FCE access.

	.leave
	ret
CompareFontNames	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CleanFontString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a bunch of neat things to normalize the passed
		in string.

CALLED BY:	FindFontWeight,
		FindFontStylesTypeface,
		NormalizeFontInfoEntry.

PASS:		ES:DI	= String to clean.

RETURN:		CX	= Length of the updated string.
		ES:DI	= Updated string (not moved or anything).

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Convert all hyphens into spaces.
	Get rid of any excess spaces.
	Get rid of all trailing spaces.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Huh?!?  Like what!?!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.29	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CleanFontString	proc	near	uses	bx
	.enter

	; Convert hyphens into spaces.
	; NOTE:	ES:DI already set.
	mov	bl, C_MINUS			; Replace hyphens with
	mov	bh, C_SPACE			; spaces.
	call	ReplaceCharString		; CX = Length of string.

	; Nuke any excess spaces.
	; NOTE:	ES:DI already set.
	call	CollapseSpaceString		; CX = Length of string.

	; Nuke all trailing spaces.
	; NOTE:	ES:DI already set.
	call	TrimTrailingSpaceString		; CX = Length of string.

	.leave
	ret
CleanFontString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeStringAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for and delete any strings in the array of
		FontStringAttributeEntrys' from the passed in string
		and return the appropriate attribute to indicate what
		all was found.

CALLED BY:	Local

PASS:		DS:SI	= NULL-terminated FontStringAttrTableEntrys' array.
		ES:DI	= String to convert.

RETURN:		AX	= Or'ed together attribute fields.
		CX	= Length of converted string.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	i = 0;
	while (FSATEArray[i].FSATE_string != NULL)
	  {
	  if (RemoveString (FSATEArray[i].FSATE_string, ConvertString))
	    {
	    Length = strlen (ConvertString) + 1;
	    Attribute |= FSATEArray[i].FSATE_attribute;
	    }
	  i++;
	  }
	return (Attribute, Length, ConvertString);

CHECKS:
	Non null-terminated strings.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Block containing the FontStringAttrTableEntrys' array and the
	string to be converted must already have been locked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.26	Initial version
	JDM	91.06.04	Added EC code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NukeStringAttributes	proc	near	uses	bx, dx, si, ds

	; Local variable.
	FSATEArrayOffset	local	word

	.enter

	; Set up for the search and destroy loop.
	; NOTE:
	;	AX = Attribute.
	;	FSATEArray block already locked.
	clr	ax
	mov	cx, ax
	mov	ss:[FSATEArrayOffset], si	; Save arrray access.

searchDestroyLoop:
	; ASSUMED:
	;	AX = Current attribute.
	;	BX = Tentative attribute addition.
	;	CX = Current length of main-string (including terminator).
	;	ES:DI = Main-string.
	;	DS:SI = FontStringAttrTableEntry.

	; Get the new tentative attribute addition while we have access.
	mov	bx, ds:[si].FSATE_attribute

	; Get to the sub-string to search for.
	mov	si, ds:[si].FSATE_string	; *DS:SI == string.

	; Are we done yet?
	tst	si
	jz	done				; Yep.

	; Otherwise, indirect through lmem handle to string.
	mov	si, ds:[si]			; DS:SI == string.

	; Go delete the sub-string from the main-string (if possible).
	; NOTE: DS:SI, ES:DI already set.
	call	RemoveSubString

	; Was the string found and deleted?
	jc	nextString			; Nope!  Go to next one.

	; Otherwise, update the attribute.
	or	ax, bx

nextString:
	; Next table entry!
	add	ss:[FSATEArrayOffset], size FontStringAttrTableEntry
	mov	si, ss:[FSATEArrayOffset]

	; Next!
	jmp	searchDestroyLoop

done:
	; NOTE:	CX = Length of main-string (from RemoveString).
	;	If CX == 0 then there wasn't anything in the damn
	;	FontStringAttrTable!  (This works because RemoveSubString
	;	includes the terminator in its count.)
	tst	cx
	jnz	exit				; Nope.  Get outta here!

	; Otherwise, figure out how big the damn string is.
	DoPush	ax, di				; Save return values.
	clr	ax				; Search for terminator.
	mov	cx, -1				; Could be big! :-(
	repne	scasb

	; Check for non-terminated string.
	tst	ax
EC <	ERROR_E	STRING_TOO_BIG						>
	jz	exit				; NO terminator!!!!!

	; Otherwise, calculate the length.
	mov	ax, -1
	sub	ax, cx				; AX = 0xffff-ending count.
	xchg	ax, cx				; CX = length of string.

	DoPopRV	ax, di				; Restore return values.

exit:
	.leave
	ret
NukeStringAttributes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchStringAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for any strings in the array of
		FontStringAttributeEntrys' from the passed in string
		and return the appropriate attribute to indicate what
		all was found.

CALLED BY:	Local

PASS:		DS:SI	= NULL-terminated FontStringAttrTableEntrys' array.
		ES:DI	= String to convert.

RETURN:		AX	= Or'ed together attribute fields.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	i = 0;
	while (FSATEArray[i].FSATE_string != NULL)
	  {
	  if (IsSubString (FSATEArray[i].FSATE_string, ConvertString))
	    {
	    Attribute |= FSATEArray[i].FSATE_attribute;
	    }
	  i++;
	  }
	return (Attribute, ConvertString);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Block containing the FontStringAttrTableEntrys' array and the
	string to be converted must already have been locked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.20	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchStringAttributes	proc	near	uses	bx,dx,si,ds,di

	; Local variable.
	FSATEArrayOffset	local	word

	.enter

	; Set up for the search and destroy loop.
	; NOTE:
	;	AX = Attribute.
	;	FSATEArray block already locked.
	clr	ax
	mov	ss:[FSATEArrayOffset], si	; Save arrray access.

searchDestroyLoop:
	; ASSUMED:
	;	AX = Current attribute.
	;	BX = Tentative attribute addition.
	;	ES:DI = Main-string.
	;	DS:SI = FontStringAttrTableEntry.

	; Get the new tentative attribute addition while we have access.
	mov	bx, ds:[si].FSATE_attribute

	; Get to the sub-string to search for.
	mov	si, ds:[si].FSATE_string	; *DS:SI == string.

	; Are we done yet?
	tst	si
	jz	done				; Yep.

	; Otherwise, indirect through lmem handle to string.
	mov	si, ds:[si]			; DS:SI == string.

	; Go delete the sub-string from the main-string (if possible).
	; NOTE: DS:SI, ES:DI already set.
	DoPush	es,di				; Save main-string.
	call	IsSubString
	DoPopRV	es,di				; Restore main-string.

	; Was the string found and deleted?
	jc	nextString			; Nope!  Go to next one.

	; Otherwise, update the attribute.
	or	ax, bx

nextString:
	; Next table entry!
	add	ss:[FSATEArrayOffset], size FontStringAttrTableEntry
	mov	si, ss:[FSATEArrayOffset]

	; Next!
	jmp	searchDestroyLoop

done:
	.leave
	ret
SearchStringAttributes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFontWeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the weight of the font from the given
		FontInfoEntry.

CALLED BY:	FontInstallListPutEntry

PASS:		ES:DI	= FontInfoEntry.

RETURN:		AL	= FontWeight.
		CX	= Length of font name string.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Lock the block contianing the font weight-attribute and strings
	data table.
	Call NukeStringAttributes to figure out what weights the
	FontInfoEntry.FIE_weight string represents (destructive find).
	Clean (normalize) the string.
	Unlock the block.
	Return the font weight.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:  Some fields in the FontInfoEntry may be modified by this
		routine.
	NOTE:	This routine must be called *after* any call to
		FindFontStylesTypeface due to it's side effects.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.29	Initial version
	JDM	91.05.17	Fixed return value size.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindFontWeight	proc	near	uses	bx,dx,di,si,ds,es
	.enter

	; Get access to and lock the Font weight data.
	mov	bx, handle WeightStringAttrTable
	push	bx				; Save it for later.
	call	GeodeLockResource		; AX = Segment of table.
	mov	ds, ax				; DS:SI = weight data.
	mov	si, offset WeightStringAttrTable
	mov	si, ds:[si]

	; Get access to the weight string from the FontInfoEntry.
	les	di, es:[di].FIE_weight

	; Go figure out the weight.
	; NOTE:	ES:DI, DS:SI already set.
	call	NukeStringAttributes		; AX = FontWeight

	; Clean (normalize) the string.
	call	CleanFontString			; CX = length of string.

	; Unlock the weight data block.
	pop	bx				; Restore block handle.
	call	MemUnlock

	; NOTE:	AL, CX already set for return.

	.leave
	ret
FindFontWeight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFontStylesTypeface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the style(s) and the base (typeface) name of
		the font from the given FontInfoEntry.

CALLED BY:	FontInstallListPutEntry

PASS:		DS:SI	= List instance data.
		ES:DI	= FontInfoEntry.

RETURN: 	AL	= TextStyles.
		CX	= Length of FontInfoEntry.FIE_font string.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Lock the block contianing the font styles-attribute and strings
	data table.
	Make a local copy of the FontInfoEntry.FIE_weight string.
	Call NukeStringAttributes to figure out what styles the
	local string represents.
	Lock the global font install list data block.
	Call NukeStringAttributes to figure out what styles the
	FontInfoEntry.FIE_font string represents (destructive find).
	Coalesce and trim the spaces in the resultant string to leave
	us with the base (typeface) name for the font.
	Get rid of any text style attributes from the virgin name string.
	Unlock the global data block.
	Unlock the font styles block.
	Return the font styles.

CHECKS:
	Non null-terminated strings.
	Null-strings.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	Some fields in the FontInfoEntry may be modified by this
		routine.
	The weight string is searched because some typefaces (e.g.
	Garamond) don't contain the style information in the name field.
	The nuking of the style attributes from the virgin name string
	is reliant on the fact that the string attribute table contains
	the strings in whatever forms are necessary (i.e. all caps, first
	letter capitalized, etc.).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.29	Initial version
	JDM	91.05.17	Fixed return values and documentation.
	JDM	91.05.20	Added search of weight string for styles.
	JDM	91.05.23	Added normalized name support.
	JDM	91.05.24	Added virgin name attribute nuking.
	JDM	91.05.29	Added local font weight string.
	JDM	91.06.04	Added EC code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindFontStylesTypeface	proc	near	uses	bx,dx,di,si,ds,es
	class	FontInstallListClass

	; Local variables.
	FIEPtr	local	fptr.FontInfoEntry	push	es \
						push	di
	listObj	local	fptr			push	ds \
						push	si
	weightStringHandle	local	hptr

	.enter

	; Get access to and lock the Font style data.
	mov	bx, handle StyleStringAttrTable
	push	bx				; Save it for later.
	call	GeodeLockResource		; AX = Segment of table.
	mov	ds, ax				; DS:SI = style data.
	mov	si, offset StyleStringAttrTable	; LMem handle.
	mov	si, ds:[si]
	DoPush	ds,si				; Save Style table access.

	; Get access to the weight string from the FontInfoEntry.
	les	di, es:[di].FIE_weight

	; Figure out the length of the weight string.
	push	di				; Save weight access.
	clr	ax				; Search for terminator.
	mov	cx, -1				; Could be big! :-(
	repne	scasb

	; Check for non-terminated string.
	tst	cx
EC <	ERROR_E	STRING_TOO_BIG						>
	jnz	calcWeightStringLength

exitWeightString:
	; Otherwise, clean up the stack and exit.
	pop	di				; Weight offset.
	DoPopRV	ds,si				; Style data table access.
	jmp	exitBad

calcWeightStringLength:
	; Calculate the length.
	mov	ax, -1
	sub	ax, cx				; AX = 0xffff-ending count.

	; Check for a null-string.
	cmp	ax, 1				; Only null-terminator?
EC <	ERROR_E	STRING_CANT_BE_NULL					>
	jz	exitWeightString

	push	ax				; Save string length.
	
	; Allocate a block to hold the weight string.
	; NOTE:	AX already set.
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK	; Block type.
	call	MemAlloc
	mov	ss:[weightStringHandle], bx	; Save handle for later.

	; Copy the weight string.
	pop	cx				; Restore string length.
	segmov	ds, es				; DS:SI = original weight.
	pop	si				; Restore weight offset.
	mov	es, ax				; ES:DI = new block.
	clr	di
	rep	movsb

	; Go figure out the weight.
	; NOTE:	ES already set.
	clr	di				; Block paragraph aligned.
	DoPopRV	ds,si				; Restore table access.
	call	NukeStringAttributes		; AL = TextStyles.

	; Get rid of the temporary weight string block.
	mov	bx, ss:[weightStringHandle]
	call	MemFree

	; Get access to the normalized font name string.
	; Lock the global block.
	les	di, ss:[listObj]		; Save List access.
	mov	bx, es:[di].FIL_fontInfoBlockHandle
	les	di, ss:[FIEPtr]			; Restore *FontInfoEntry.
	push	bx				; Save handle.
	push	ax				; Save TextStyles.
	DoPush	ds,si				; Save String table access.
	call	MemLock
	mov	di, es:[di].FIE_normFont	; DI = name chunk handle.
	mov	es, ax				; *ES:DI = name string.
	mov	di, es:[di]			; ES:DI = name string.

	; Go figure out the styles.
	; NOTE:	ES:DI already set.
	DoPopRV	ds,si				; Restore *(string table).
	DoPush	ds,si				; Save it again.
	call	NukeStringAttributes		; AL = TextStyles.

	; Clean (normalize) the string.
	call	CleanFontString			; CX = Length of string.

	; Combine the TextStyles found.
	DoPopRV	ds,si				; Restore *(string table).
	pop	bx				; Initial TextStyles.
	or	ax, bx
	DoPush	ax,cx				; Return values.

	; Get rid any attribute strings from the virgin name string.
	; NOTE:	DS:SI already set.
	les	di, ss:[FIEPtr]
	les	di, es:[di].FIE_font
	call	NukeStringAttributes

	; Tidy it up.
	; NOTE:	ES:DI already set.
	call	CleanFontString

	; Unlock the global font information block.
	DoPopRV	ax,cx				; Restore return values.
	pop	bx
	call	MemUnlock

	; Unlock the style data block.
	pop	bx				; Restore block handle.
	call	MemUnlock

	; NOTE:	AX, CX already set for return.
	clc					; Signify okay.
	jmp	exit				; Bail.

exitBad:
	stc

exit:
	.leave
	ret
FindFontStylesTypeface	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NormalizeFontInfoEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make all of the FontInfoEntry's fields adhere to a
		standard format.  Take care of a bunch of housecleaning
		while we're at it.

CALLED BY:	FontInstallListPutEntry

PASS:		ES:DI	= FontInfoEntry.
		DX	= Segment of locked font information block.

RETURN:		Carry Flag:
			Set iff error.
			Clear otherwise.
		DX	= (Fixed-up) Segment of font information block.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Clean the font name string.
	Figure out how long the name string is.
	Create a buffer for the normalize font name.
	Copy the font name into the normalized name buffer.
	Upper case the font name in the normalize name buffer (we copied
	an already cleaned string).
	Normalize the weight string in the FontInfoEntry.
	(Normalization consists of replacing all hyphens with spaces,
	collapsing runs of multiple spaces to a single space,
	removing all trailing spaces, and converting characters to
	upper-case.)

CHECKS:
	Non null-terminated strings.
	Null-strings.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	I don't need to muck with the font file name string
		because of the DOS naming convention.
	The normalized buffer is allocated as a local memory chunk in
	the font information global block.
	The allocation of the chunk does not check for errors.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.20	Initial version
	JDM	91.05.23	Added normalized name support.
	JDM	91.05.24	Fixed buffer allocation size.
	JDM	91.06.04	Added EC code.
	JDM	91.06.05	Added font information block segment
				argument and fixing-up.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NormalizeFontInfoEntry	proc	near	uses	ax,bx,cx,si,ds,es,di
	class	FontInstallListClass

	; Local variables.
	FIEPtr	local	fptr.FontInfoEntry	push	es \
						push	di
	globalBlockSeg	local	sptr		push	dx
	strLength	local	word

	.enter

	; Clean the font name string.
	les	di, es:[di].FIE_font
	call	CleanFontString

	; Figure out the length of the name string.
	; NOTE:	ES:DI already set.
	clr	ax				; Search for terminator.
	mov	cx, -1				; Could be big! :-(
	repne	scasb

	; Check for non-terminated string.
	tst	cx
EC <	ERROR_E	STRING_NOT_TERMINATED					>
	jz	exitBad				; NO terminator!!!!!

	; Calculate the length.
	mov	ax, -1
	sub	ax, cx				; AX = 0xffff-ending count.
	mov	ss:[strLength], ax		; Save it.

	; Check for a null-string.
	cmp	ax, 1				; Only null-terminator?
EC <	ERROR_E	STRING_CANT_BE_NULL					>
	jz	exitBad

	; Allocate a block to hold a font name in the fontInfoBlock.
	mov	ds, dx				; DX passed in.
	clr	ax
	mov	cx, ss:[strLength]
	call	LMemAlloc			; AX = Chunk handle.
	
	; Save the (possibly) fixed-up block segment.
	mov	ss:[globalBlockSeg], ds

	; Save the handle of the chunk into the private field of the
	; FontInfoEntry.
	segmov	es, ds				; *ES:AX = New buffer.
	lds	si, ss:[FIEPtr]			; FontInfoEntry access.
	mov	ds:[si].FIE_normFont, ax	; AX from above.

	; Copy the font name into the new buffer.
	lds	si, ds:[si].FIE_font		; DS:SI = font name string.
	mov	di, ax				; *ES:DI = new name buffer.
	mov	di, es:[di]			; ES:DI = new name buffer.
	push	di				; Save new buffer access.
	mov	cx, ss:[strLength]		; Copy this much.
	rep	movsb

	; Upper case the new normalized name string.
	segmov	ds, es, ax			; DS:SI = new name string.
	pop	si				; Restore new buff access.
	clr	cx				; Null-terminated.
	mov	di, DR_LOCAL_UPCASE_STRING
	call	SysLocalInfo

	; Clean the font weight string.
	les	di, ss:[FIEPtr]
	les	di, es:[di].FIE_weight
	call	CleanFontString

	; Upper case it.
	segmov	ds, es, ax			; DS:SI = weight string.
	mov	si, di				; ES:DI from above.
	clr	cx				; Null-terminated.
	mov	di, DR_LOCAL_UPCASE_STRING
	call	SysLocalInfo

	; Everthing copacetic.
	clc
	jmp	exit

exitBad:
	stc

exit:
	; Restore the global font information block segment.
	mov	dx, ss:[globalBlockSeg]

	.leave
	ret
NormalizeFontInfoEntry	endp


FontInstallListCode	ends
