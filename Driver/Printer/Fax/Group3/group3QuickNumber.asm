COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3QuickNumber.asm

AUTHOR:		Andy Chiu, Oct  6, 1993

ROUTINES:
	Name			Description
	----			-----------
	QuickNumbersListSetCurrentSelection
				Routine that is called when an item has been
				selected from the quick numbers list.  
				This will replace the text in the fax # with 
				the number from the list.

	QuickNumbersListRequestItemMoniker
				Writes the corresponding moniker to the 
				Quick Number List from the file of 
				quick numbers.
	QuickNumbersListVisOpen
				This routine tells the Group3NumberText 
				object to apply it's message if it has 
				been modified.  This way we can unselect an 
				item if the user has modified the number in
				any way.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 6/93   	Initial revision


DESCRIPTION:
	
	Routines to handle the quick number attributes of Fax UI.
		

	$Id: group3QuickNumber.asm,v 1.1 97/04/18 11:53:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickNumbersListSetCurrentSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine that is called when an item has been selected from
		the quick numbers list.  This will replace the text
		in the fax # with the number from the list.

CALLED BY:	MSG_QUICK_NUMBERS_LIST_SET_CURRENT_SELECTION
PASS:		*ds:si	= QuickNumbersListClass object
		ds:di	= QuickNumbersListClass instance data
		ds:bx	= QuickNumbersListClass object (same as *ds:si)
		es 	= segment of QuickNumbersListClass
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
	AC	10/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickNumbersListSetCurrentSelection	method dynamic QuickNumbersListClass, 
				MSG_QUICK_NUMBERS_LIST_SET_CURRENT_SELECTION

		push	ds			; save segment of this obj
		push	cx			; item to get
	;
	; Get the chunk array that contains the quick list.
	;
		mov	si, offset FaxDialogBox
		mov	ax, MSG_FAX_INFO_GET_QUICK_LIST_HANDLES
		call	ObjCallInstanceNoLock	; ax <- heap handle
						; cx <- chunk handle
	;
	; See if the heap is zero. If it is, it means that we couldn't
	; get that information from the fax file information and we
	; have to fake it like there is no information.
	;
		tst	ax
		jz	doNotWriteNumber

	;
	; Else the handles are OK.  Find out the appropiate entry that the
	; user put in.
	;
		
		mov_tr	bx, ax			; bx <- mem handle
		call	MemLock			; ax <- segment

		mov	ds, ax
		mov	si, cx			; *ds:si <- chunk array
	;
	; Make sure an actual number is being selected and not because
	; we put a bogus element in the list
	;
		call	ChunkArrayGetCount	; cx <- # of elements
		jcxz	doNotWriteNumberAndUnlockBlock	; no number to write
	
		pop	ax
		call	ChunkArrayElementToPtr	; ds:di <- element needed
	;
	; Now get the chunk that contains the string and put
	; that element into the number text of the fax ui
	;
		mov	si, ds:[di].QNCH_numberChunk
		mov	bp, ds:[si]		; ds:bp <- string
		
		clr	cx			; null terminated string
		mov	dx, ds
		mov	es, dx

replaceText::
		pop	ds			; *ds:si = obj to call
		mov	si, offset Group3NumberText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
	;
	; If there is a name associated with this number put the name in
	; the text field
	;
		mov	dx, es
		mov	bp, es:[di].QNCH_nameChunk
		tst	bp
		jz	short markUnused
		mov	bp, es:[bp]
		clr	cx			; null terminated string
		mov	si, offset Group3NameText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
if _USE_PALM_ADDR_BOOK
	;
	; Also make set the marker that an address book entry is used
	;
		mov	si, offset AddrBookList
		mov	ax, MSG_ADDRESS_BOOK_LIST_SET_ADDRESS_USED
		call	ObjCallInstanceNoLock
endif
	;
	; Release the VMBlock and exit
	;
		call	MemUnlock

exit:
		ret
markUnused:
if _USE_PALM_ADDR_BOOK
		
	;
	; One last thing.  Tell the address book that an address book element
	; is not being used anymore
	;
		mov	si, offset AddrBookList
		mov	ax, MSG_ADDRESS_BOOK_LIST_SET_ADDRESS_NOT_USED
		call	ObjCallInstanceNoLock
endif
		jmp	exit		
		
	;
	; Release the VMBlock and exit
doNotWriteNumberAndUnlockBlock:
		call	MemUnlock

	;
	; Write a null string into the number text
	;
doNotWriteNumber:
		pop	ax			; just restore the stack
		mov	dx, cs
		mov	bp, offset blankString

		pop	ds			; *ds:si = obj to call
		mov	si, offset Group3UI:Group3NumberText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		jmp	exit

QuickNumbersListSetCurrentSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickNumbersListRequestItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the corresponding moniker to the Quick Number List
		From the file of quick numbers.

CALLED BY:	MSG_QUICK_NUMBERS_LIST_REQUEST_ITEM_MONIKER
PASS:		*ds:si	= QuickNumbersListClass object
		ds:di	= QuickNumbersListClass instance data
		ds:bx	= QuickNumbersListClass object (same as *ds:si)
		es 	= segment of QuickNumbersList
		ax	= message #
		^lcx:dx = the dynamic list requesting the moniker
		bp	= the position of the item requested
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
nn
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickNumbersListRequestItemMoniker	method dynamic QuickNumbersListClass, 
					MSG_QUICK_NUMBERS_LIST_REQUEST_ITEM_MONIKER
	;
	; Save the pointer the list.  This is currently *ds:dx
	;
		push	ds, dx
	;
	; Get the chunk array that we have in memory locally.
	;
		mov	si, offset FaxDialogBox
		mov	ax, MSG_FAX_INFO_GET_QUICK_LIST_HANDLES
		call	ObjCallInstanceNoLock	; ax <- Heap handle for c-array
						; cx <- chunk handle for list
	;
	; See if the heap handle is zero.  If it is, it means we were not
	; able to get the information from the file and we have to fake it
	; as an empty file.
	;
		tst	ax
		jz	writeNoElements 
		
	;
	; We have non zero handles, so they should be pointing to valid
	; chunk arrays.
	;
		mov_tr	bx, ax			; bx <- mem handle
		call	MemLock			; ax <- segment
		mov	ds, ax
		mov	si, cx			; *ds:si <- chunk array
	;
	; See if any items are in the chunk array
	;
		tst	bp
		jnz	getElement
		call	ChunkArrayGetCount	; cx <- number of items
		jcxz	writeNoElementsAndUnlockBlock
	;
	; Get the element that is requested and write it to the
	; dynamic list
	;
getElement:
		mov	ax, bp			; element # wanted
		call	ChunkArrayElementToPtr	; ds:di <- element

		mov	bp, ds:[di].QNCH_nameChunk
		tst	bp
		jnz	replaceText

		mov	bp, ds:[di].QNCH_numberChunk

replaceText:
		mov	dx, ds:[bp]
		mov	cx, ds			; cx:dx <- string to pass
		mov_tr	bp, ax			; bp <- element wanted

		pop	ds, si			; ds:si <- object
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock

	;
	; Unlock the mem block and exit
	;
		call	MemUnlock

exit:
		ret

	;
	; Handle this condition to unlock the block so we can share code with
	; the error that couldn't read from the information file
writeNoElementsAndUnlockBlock:
		call	MemUnlock		

	;
	; There are really no strings in the list, so give the 
	; list a string to show that there aren't any
writeNoElements:
		mov	bx, handle StringBlock
		call	MemLock
		push	es
		mov	es, ax
		mov_tr	cx, ax
;assume	es:StringBlock
		mov	dx, es:[NoQuickNumbers]
;assume	es:nothing
		pop	es
		
		pop	ds, si			; ds:si <- object
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock
		call	MemUnlock

		jmp	exit			; cx:dx <- string to pass

QuickNumbersListRequestItemMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickNumbersListVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine tells the Group3NumberText object to apply 
		it's message if it has been modified.  This way we can
		unselect an item if the user has modified the number in
		any way.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= QuickNumbersListClass object
		ds:di	= QuickNumbersListClass instance data
		ds:bx	= QuickNumbersListClass object (same as *ds:si)
		es 	= segment of QuickNumbersListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickNumbersListVisOpen	method dynamic QuickNumbersListClass, 
					MSG_VIS_OPEN
	;
	; Make sure that the super class is called
	;
		mov	di, offset QuickNumbersListClass
		call	ObjCallSuperNoLock
	;
	; We are checking here if the quick list has to be deselected.
	; If no item in the list is selected, then the point is moot.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	; ax <- selection
		call	ObjCallInstanceNoLock
		mov_tr	bx, ax
		jc	done
	;
	; Well, we know now that an element has been chosen.  Lets check if
	; it should still be selected.  First check to see if the number
	; text has been modified.
	;
		mov	di, si
		mov	si, offset Group3NumberText
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED	; carry set if modified
		call	ObjCallInstanceNoLock
		jc	setNoneSelected
	;
	; If the name has been changed and it's a address book entry in
	; the list, then make the list un-selected.
	;
		mov	si, offset Group3NameText
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED
		call	ObjCallInstanceNoLock
		jnc	done

		mov	bp, bx
		mov	si, di
		mov	ax, MSG_QUICK_NUMBERS_LIST_CHECK_IF_ADDR
		call	ObjCallInstanceNoLock
		jnc	done

setNoneSelected:
	;
	; If it has been modified, then make sure that we have no selections
	;
		mov	si, di
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		call	ObjCallInstanceNoLock

done:
		ret
QuickNumbersListVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickNumbersListCheckIfAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Passed an element number this method will tell if
		that item is a address book entry in the quick list.

CALLED BY:	MSG_QUICK_NUMBERS_LIST_CHECK_IF_ADDR
PASS:		*ds:si	= QuickNumbersListClass object
		ds:di	= QuickNumbersListClass instance data
		ds:bx	= QuickNumbersListClass object (same as *ds:si)
		es 	= segment of QuickNumbersListClass
		ax	= message #
		bp	= entry number wanted
RETURN:		carry set if it's an address book entry
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickNumbersListCheckIfAddr	method dynamic QuickNumbersListClass, 
					MSG_QUICK_NUMBERS_LIST_CHECK_IF_ADDR
	uses	ax, cx, bp
	.enter

		push	bp			; save entry wanted
	;
	; Lock the quick numbers list and get that element.
	;
		mov	si, offset FaxDialogBox
		mov	ax, MSG_FAX_INFO_GET_FILE_HANDLE
		call	ObjCallInstanceNoLock	; ax <- file handle
;;		mov	bx, es:[faxInformationFileHan]
		mov_tr	bx, ax
		call	VMGetMapBlock		; ax <- block handle
		call	VMLock			; ax <- segment
						; bp <- mem handle
		mov	ds, ax
		mov	ds, ax
		mov	ax, ds:[FIFI_heapBlock]
		mov	si, ds:[FIFI_chunkArrayHandle]

		call	VMUnlock
	;
	; Lock down the chunk array.
	;
		call	VMLock			; ax <- segment
						; bp <- mem handle
		mov	ds, ax			; *ds:si <- chunk array
	;
	; Get the element requested and see if it has a name entry
	;
		pop	ax			; element # wanted
		call	ChunkArrayElementToPtr	; ds:di <- element
		tst	ds:[di].QNCH_nameChunk
		clc
		jz	done

		stc
done:
		call	VMUnlock
		.leave
		ret
QuickNumbersListCheckIfAddr	endm












