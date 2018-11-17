COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3AddrBook.asm

AUTHOR:		Andy Chiu, Nov 14, 1993

	Name			Description
	----			-----------

METHODS:
	AddressBookVisOpen	Does set up on the dynamic list if it's needed.

	AddressBookVisClose	Does some clean up on the address book when
				it closes down

	AddressBookListSetCurrentSelection
				Is used when someone selects a name from 
				the address book.

	AddressBookListRequestItemMoniker
				The dynamic list calls this method
				requesting a moniker. This method puts the
				moniker in the list.

	AddressBookListOpenAddressBook
				Opens an address book and saves the handle
				to the address book.

	AddressBookListMakeEntryList
				This message is used to initialize the list. 
				This should make a list off all the entries 
				that is available for the user
	AddressBookListCloseBook
				Makes sure that the address book is closed.

	AddressBookListGetItemClass
				Used to change the font of the gen dynamic list

	AddressBookListItemVisDraw
				Made so the items draw themselves with 
				different fonts.

	AddressBookListIsAddressBookUsed
				Tells if the address book has been used
				recently.

	AddressBookListSetAddressNotUsed
				Marks the address book as not being used.

	AddressBookListSetAddressUsed
				Marks the address book as being used.

	AddressBookFileSelectorGetFile
				Get the file selected by the user with
				the file selector.
	AddressBookFileSelectorOpenPressed
				This is the message sent when the user
				presses open on the dialog.


ROUTINES:
	CheckIfText		Just checks to see if the item requested is 
				a text field.

	AddElementToTable	Add an element to our chunk array

        DoDialog		Puts up a standard dialog

	CopyAddressBookFileInfo	Copies address book

	CopyDefaultAddressBookFileInfo
				Copies the default address book information
				into a AddressBookFileInfo structure
				begining at es:di
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/14/93   	Initial revision


DESCRIPTION:

	Code to handle all stuff pertaining to the address book.	
		

	$Id: group3AddrBook.asm,v 1.1 97/04/18 11:52:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallAddressBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the address book when needed.

CALLED BY:	INTERNAL
PASS:		ax 	= Routine to call
RETURN:		whatever the routine is supposed to return
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallAddressBook	proc	near
	uses	ax
	.enter

		push	bx	
		mov	bx, handle pabapi
		call	ProcGetLibraryEntry	; bx:ax <- library entry point

		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx

		pop	bx
		
	.leave
	ret
CallAddressBook	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does set up on the dynamic list if it's needed.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookVisOpen	method dynamic AddressBookListClass, 
					MSG_VIS_OPEN

	;
	; Call the super class and make sure its open
	;
		mov	di, offset AddressBookListClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].AddressBookList_offset
	;
	; if this is the first time the address book has been open,
	; then make sure the list has been initialized.
	;
		tst	ds:[di].ABLI_addrBookHandle
	jnz	short	clearEntries

	;
	; See if we can open a new address book.  First find the
	; address book information that's in the fax information file
	;
		sub	sp, size AddressBookFileInfo
		mov	dx, sp
		mov	cx, ss
		push	si			; save handle to self
		mov	ax, MSG_FAX_INFO_GET_ADDRESS_BOOK_USED
		mov	si, offset FaxDialogBox
		call	ObjCallInstanceNoLock	; cx:dx <- filled

		pop	si			; handle to self
		mov	ax, MSG_ADDRESS_BOOK_LIST_OPEN_ADDRESS_BOOK
		call	ObjCallInstanceNoLock
		jc	noAddressBook

		add	sp, size AddressBookFileInfo
	;
	; Make sure the list has been initialized.
	;
		mov	ax, MSG_ADDRESS_BOOK_LIST_MAKE_ENTRY_LIST
		call	ObjCallInstanceNoLock
exit:
		ret

clearEntries:
	;
	; Make sure none of the entries are selected
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		call	ObjCallInstanceNoLock
		jmp	short	exit

noAddressBook:
		add	sp, size AddressBookFileInfo
		mov	ax, CustomDialogBoxFlags <1, CDT_ERROR,
			GIT_NOTIFICATION, 0>
		mov	si, offset NoAddressBook
		call	DoDialog
		jmp	exit

AddressBookVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does some clean up on the address book when it closes down

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookVisClose	method dynamic AddressBookListClass, 
					MSG_VIS_CLOSE
	;
	; Call the super class.
	;
		mov	di, offset AddressBookListClass
		call	ObjCallSuperNoLock
	;
	; Free the memory that was used to make the address book
	;
		mov	ax, MSG_ADDRESS_BOOK_LIST_CLOSE_BOOK
		call	ObjCallInstanceNoLock

		ret
AddressBookVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListSetCurrentSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Is used when someone selects a name from the address
		book.

CALLED BY:	MSG_ADDRESS_BOOK_LIST_SET_CURRENT_SELECTION
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
		cx 	= current selection, or first selection in item 
			  group, if more than one selection, or GIGS_NONE 
		      	  of no selection
		bp 	= number of selections
		dl	=  GenItemGroupStateFlags

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Important:  Add one to tempBuf size so that we can blindly 
		add a space character after getting the first name without
		checking to see if it will overflow the buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListSetCurrentSelection	method dynamic AddressBookListClass, 
					MSG_ADDRESS_BOOK_LIST_SET_CURRENT_SELECTION

instHandle	local	word	push si			; handle to instance
instSegment	local	word	push ds			; segment of instance
tempBuf		local	FAX_MAX_FIELD_LENGTH + 1  dup (char)	; char buffer
isTextName	local	byte	
		.enter

		mov	{byte} ss:[isTextName], 0
		push	bp			; save for local vars
	;
	; Convert the list element number into an address book entry.
	;
		call	ElementToAddrBookID	; cx = addr book entry ID
						; bx = addrbook handle
	;
	; Now we have to get the element out of the address book.
	;
		mov	dl, ADT_FIRST_NAME
		segmov	es, ss
		lea	di, ss:[tempBuf]
		mov	{byte}es:[di], 0	; Make a null string

		call	CheckIfText
	jc	short	getLastName

		mov	ax, FAX_MAX_TO_NAME_FIELD_LENGTH - 1
		mov	{byte} ss:[isTextName], 1
		call	AddressBookGetPageEntryTextDataFptr
						; dx <- length of string
		call	DeformatName		
		
		add	di, dx
		mov	{word} es:[di], (C_NULL shl 8) or C_SPACE
		
		inc	di
		
		sub	ax, dx			; ax = amount of space remaining
		dec	ax			; include the space character
		
		tst	ax			; reached our limit?
		je	placeNameInCoverPage
	;
	; Copy the last name if it's text
	;
getLastName:
		mov	dl, ADT_NAME
		call	CheckIfText
	jc	short	placeNameInCoverPage

		mov	{byte} ss:[isTextName], 1		
		call	AddressBookGetPageEntryTextDataFptr
		call	DeformatName
	;
	; Put the name in the appropiate place for the cover page.
	;
placeNameInCoverPage:
		mov	ds, ss:[instSegment]	; ds <- segment of UI
		push	cx			; save address book idents

		push	bp
		mov	dx, es		
		lea	bp, ss:[tempBuf]	; dx:bp <- tempBuf
		clr	cx			; string null terminated
		mov	si, offset Group3NameText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; Find the fax number and put that into the proper field
	;
		pop	cx			; bx:cx address book idents
		lea	di, ss:[tempBuf]	; es:di = buffer for number
		mov	ax, FAX_MAX_TO_PHONE_FIELD_LENGTH - 1
		mov	dl, ADT_FAX
		call	AddressBookGetPageEntryTextDataFptr
		call	DeformatPhoneNumber
	;
	; Put the fax number into the write place in the print
	; dialog box.
	;
		movdw	dxbp, esdi		; dx:bp <- tempBuf
		clr	cx			; string null terminated
		mov	si, offset Group3NumberText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
	;
	; The quick list is cleared.  This will be vital later when 
	; deterimining if the address book is used.
	; 
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		mov	si, offset Group3QuickNumbersList
		call	ObjCallInstanceNoLock
	;
	; Check to see if there was a text field associate with the number.
	; If there was, then we'll make sure that the instance variable
	; that indicates if the address book was used, is marked.
	;
		pop	bp				; for local vars
		mov	di, ss:[instHandle]
		mov	di, ds:[di]
		add	di, ds:[di].AddressBookList_offset
		mov	al, {byte} ss:[isTextName]
		mov	{byte} ds:[di].ABLI_addrBookUsed, al

		.leave
		ret
AddressBookListSetCurrentSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ElementToAddrBookID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a list element number into an address book entry.

CALLED BY:	INTERNAL

PASS:		ds:di	= AddressBookListClass instance data
		cx	= list element number

RETURN:		cx	= address book entry ID
		bx	= handle of address book

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/15/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ElementToAddrBookID	proc	near
		class	AddressBookListClass

		uses	ax, dx, di, si, ds
		.enter
		
		mov	bx, ds:[di].ABLI_entryTableHandle
		call	MemLock				; ax = segment of table
		mov	si, ds:[di].ABLI_entryTableChunk
		mov	dx, ds:[di].ABLI_addrBookHandle	
		mov	ds, ax				; *ds:si = chunk array
		
		mov_tr	ax, cx				; ax = element #
		call	ChunkArrayElementToPtr		; ds:di = element
		mov	cx, ds:[di]			; cx = entry ID
		
		call	MemUnlock
		mov_tr	bx, dx				; bx = addr book handle
		
		.leave
		ret
ElementToAddrBookID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeformatName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deformats the name taken from the Palm Address book
		to replace carriage returns with spaces.

CALLED BY:	INTERNAL
		AddressBookListSetCurrentSelection
		AddressBookListRequestItemMoniker

PASS:		es:di	= buffer pointing at location to start deformatting

RETURN:		es:di	= containts deformatted string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Replace every carriage return we find with a space.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/15/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeformatName	proc	near
		uses	ax, cx, di
		.enter

replaceLoop:
	;
	; Find length of remaining string.
	;		
		push	di				
		LocalStrSize				; cx = # of bytes
		pop	di				
		jcxz	done

		mov	ax, C_CR
		LocalFindChar				
		jnz	done
	;
	; Replace C_CR with C_SPACE.
	;
		LocalPrevChar	esdi			; es:di points to C_CR

		mov	ax, C_SPACE
		LocalPutChar	esdi, ax
		jmp	replaceLoop
done:
		.leave
		ret
DeformatName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeformatPhoneNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deformats the phone number taken from the Palm Address
		book so it only show's numbers and stuff

CALLED BY:	AddressBookListSetCurrentSelection
PASS:		es:di	= string to deformat
RETURN:		es:di	= string is deformated
		dx	= length of the deformated string.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

- ds:si will always point to the begining of the string
- Look at character pointed to at ds:di
- if ds:di is a CR or 0 then exit.
- compare that character with the text filter.
- if the character is in the text filter, then that's the end of the string.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeformatPhoneNumber	proc	near
	uses	bx,cx,si
	.enter

	;
	; es:di  will always mark the begining of the string.
	; characters into it.
	; es:si will be used to find the current character to read.
	;
		mov	si, di			; ds:di <- character to read
		clr	dx			; dx <- length of string
	;
	; Loop through the string.  A sub-loop below will loop through the
	; filter.  Conditions of this loop is es:si already points to
	; the character it must check for.
getNextChar:
		mov	{byte} cl, es:[si]	; dx <- char to look at
		inc	dx
	;
	; Make sure jl isn't a null or CR.  If it is, then
	; that will be the end of the string.
	;
		cmp	cl, C_NULL
		jz	endString
		cmp	cl, C_CR
		jz	endString

		mov	bx, (length PhoneTextFilterList - 1) * \
				size PhoneTextFilter
	;
	; This loops throught the filter and first checks if the upper bound
	; on any of the filters is >= to the target char (dx).
	; If so, then it checks if the lower bound is <= the target.
	; If both checks work, it copies that character into the spot indexed
	; by bp.
getFilter:
		cmp	cs:[PhoneTextFilterList].[bx].PTE_upperBound, cl
		jc	short	nextFilterLoop

	;
	; Checking the lower bound here.
	; If it made it through both checks here, then we know it shouldn't
	; be in the string at all.  Loop to get the next character.
	;
		cmp	cl, cs:[PhoneTextFilterList].[bx].PTE_lowerBound
		jnc	short	endString
		
	;
	; Loop to get the next filter
nextFilterLoop:
		dec	bx
		dec	bx
	;
	; This is an anal check, but just in case someone makes
	; PhoneTextFilter
	; larger or smaller than a word.
	;
		CheckHack <size PhoneTextFilter eq 2>

		jns	getFilter

	;
	; If the character went through all the filters without
	; getting nuked and ending up here, then we know we should
	; copy it into the string we want to pass out.
	;
		inc	si			; ds:si <- next character
		jmp	getNextChar

	;
	; The string is completed at this stage.  All it needs is
	; a null to terminate the string.
endString:
		mov	{byte}es:[si], C_NULL

		.leave
		ret
DeformatPhoneNumber	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListRequestItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The dynamic list calls this method requesting a moniker.
		This method puts the moniker in the list.

CALLED BY:	MSG_ADDRESS_BOOK_LIST_REQUEST_ITEM_MONIKER
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
		^lcx:dx = the dynamic list requesting the moniker
		bp      = the position of the item requested
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListRequestItemMoniker	method dynamic AddressBookListClass, 
					MSG_ADDRESS_BOOK_LIST_REQUEST_ITEM_MONIKER

	; save's the optr to the calling dynamic list
addrListOptr		local	optr	push 	cx, dx

	; saves the buffer to keep the item
addrItemBuf		local	ADDRESS_TOTAL_SIZE	dup (char)

	; length of the name up to that point
nameLength	local	word
		.enter

		push	bp				; save for locals

		clr	ss:nameLength
		
	;
	; Now get the element requested by the user and
	; Get a handle to the address book.
	;
		mov	cx, ss:[bp]			; cx = element #
		call	ElementToAddrBookID		; cx = addr book entry ID
							; bx = addr book handle
	;
	; Get the data from the file.  First get the name and put it into
	; the buffer if it's text.
	;
		mov	dl, ADT_NAME
		segmov	es, ss
		lea	di, ss:[addrItemBuf]
		mov	si, di				; save begining point

		call	CheckIfText
	jc	short	getFirstName

	;
	; The first name is a text field.  Copy the text into the field and
	; put it into the buffer.  
	;
		mov	ax, ADDRESS_MAX_NAME_FIELD_LENGTH - 1
		call	AddressBookGetPageEntryTextDataFptr
						; dx <- string length
		call	DeformatName
		add	ss:nameLength, dx
	;
	; Check to see if we have maxed out the space for the name.
	; if it is maxed out, then we're going to skip the first name
	; We're comparing against ADDRESS_NAME_MAX_FIELD_LENGTH - 1 to
	; see if there's space for the ","
	;
		add	di, dx

		cmp	dx, ADDRESS_MAX_NAME_FIELD_LENGTH - 1
		jge	getFaxNumber

		mov	{word} es:[di], ADDRESS_NAME_SEPARATOR
		inc	di
		inc	di
		add	ss:nameLength, size word
	;
	; Get the firstname into the buffer that will be an element
	; in our address book list.  The size of how much we can fit in
	; will be in ax.
getFirstName:
		mov	ax, ADDRESS_MAX_NAME_FIELD_LENGTH - 1
		sub	ax, ss:nameLength
		jle	getFaxNumber

		mov	dl, ADT_FIRST_NAME
		call	CheckIfText
	jc	short	getFaxNumber

		call	AddressBookGetPageEntryTextDataFptr
						; dx <- string length
		call	DeformatName

		add	di, dx
		add	ss:nameLength, dx
	;
	; Copy the fax number into the appropiate place in the buffer.
	; We have to pad the buffer with spaces between the fax number
	; and the 
getFaxNumber:
		push	cx			; save entry id
		mov	cx, ADDRESS_FAX_PHONE_LOCATION
		sub	cx, ss:nameLength
		mov	al, C_SPACE
		rep	stosb
	;
	; Add in the phone number to the line
	;
		pop	cx			; restore entry ID
		mov	dl, ADT_FAX
		mov	ax, ADDRESS_MAX_FAX_PHONE_FIELD_LENGTH - 1
		call	AddressBookGetPageEntryTextDataFptr
		call	DeformatPhoneNumber
						; dx <- string length
	;
	; Now put the text into the gen dynamic list
	;
		mov	cx, ss			
		lea	dx, ss:[addrItemBuf]	; cx:dx <- string
;;		pop	bx, si			; ^lbx:si <- dynamic list
		mov	bx, ss:[addrListOptr].handle
		mov	si, ss:[addrListOptr].chunk
		mov	bp, ss:[bp]		; item number
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjMessage

		pop	bp			; for local vars
		
		.leave
		ret
AddressBookListRequestItemMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just checks to see if the item requested is a text field.

CALLED BY:	INTERNAL (AddressBookListRequestItemMoniker)
PASS:		bx	= addr book handle
		cx	= entry id
		dl	= AddrDataType
RETURN:		carry set if not text. 
		carry clear if text
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/24/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfText	proc	near
	uses	ax,cx,dx
	.enter
	;
	; Check to see if the item is a text.
	;
		call	AddressBookGetEntryInfo		; al <- FieldDataType
		cmp	al, FDT_TEXT
		jnz	short 	setCarry

		clc
		
exit:
		.leave
		ret

setCarry:
		stc
		jmp	exit
		
CheckIfText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListOpenAddressBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens an address book and saves the handle to the address
		book.

CALLED BY:	MSG_ADDRESS_BOOK_LIST_OPEN_ADDRESS_BOOK
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
		cx:dx	= AddressBookFileInfo
RETURN:		carry set if address book not changed
DESTROYED:	nothing
SIDE EFFECTS:	
	New address book will be used if there is no error.
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListOpenAddressBook	method dynamic AddressBookListClass, 
					MSG_ADDRESS_BOOK_LIST_OPEN_ADDRESS_BOOK
		uses	ax, cx, dx, bp
		.enter
	;
	; Address book was opened.  Close the previous address book if any.
	;
		push 	cx, dx
		mov	ax, MSG_ADDRESS_BOOK_LIST_CLOSE_BOOK
		call	ObjCallInstanceNoLock
		pop	cx, dx
	;
	; See if it's possible to open the requested address book.
	;
		segmov	es, ds
		push	si			; save handle to self
		mov	ds, cx
		mov	si, dx			; ds:si <- AddrBookFileInfo
		call	FilePushDir

		mov	bx, ds:[si].ABFI_diskHandle
		lea	dx, ds:[si].ABFI_path	; ds:dx <- path name
		call	FileSetCurrentPath	; ax <- FileError (if error)
						
		lea	dx, ds:[si].ABFI_name	; ds:dx <- file name
		call	AddressBookOpen		; bx <- address book handle
;;		mov	ax, enum AddressBookOpen
;;		call	CallAddressBook
		jc	couldNotOpenAddressBook	
	;
	; Save the address book that is used in the instance data of our
	; vis parent FaxInfoClass
	;
		mov	dx, si			; cx:dx <- AddressBookFileInfo
		mov	si, offset FaxDialogBox
		mov	ax, MSG_FAX_INFO_SET_ADDRESS_BOOK_USED
		segmov	ds, es
		call	ObjCallInstanceNoLock
		pop	si
	;
	; Save the handle to the new address book
	;
		mov	es:[di].ABLI_addrBookHandle, bx
exit::
		lahf				; preserve carry flag
		call	FilePopDir
		sahf	

		.leave
		ret

couldNotOpenAddressBook:
		pop	si			; restore stack
		stc
		jmp	exit
		
AddressBookListOpenAddressBook	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListMakeEntryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is used to initialize the list.  This should make
		a list off all the entries that is available for the user


CALLED BY:	MSG_ADDRESS_BOOK_LIST_MAKE_ENTRY_LIST
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
RETURN:		nothing	
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddressBookListMakeEntryList	method dynamic AddressBookListClass, 
					MSG_ADDRESS_BOOK_LIST_MAKE_ENTRY_LIST

		push	si			; save chunk handle to object
	;
	; Make sure that if we already opened a different address book that
	; we deallocate the space for the old address book
	;
		mov	bx, ds:[di].ABLI_entryTableHandle
		tst	bx
		jz	createTable

		call	MemFree
createTable:
	;
	; Make a local memory heap for the chunk array
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx			; default block header
		call	MemAllocLMem		; bx <- block handle
		mov	ds:[di].ABLI_entryTableHandle, bx
	;
	; Lock down the block and create the chunk array
	;
		call	MemLock			; ax <- locked segment
		push	bx			; save handle to mem block
		segmov	es, ds			; es <- segment of this block
		mov	ds, ax
		mov	bx, size hptr		; size of element
		clr	cx			; default size for header
		clr	al			; non ObjChunkFlags
		clr	si			; create chunk handle
		call	ChunkArrayCreate	; *ds:si <- chunk array
		mov	es:[di].ABLI_entryTableChunk, si
	;
	; save the addressbook ID
	;
		mov	bx, es:[di].ABLI_addrBookHandle
	;
	; Make the table.  *ds:si is passed into the routine
	;
		mov	cx, cs
		mov	dx, offset AddElementToTable
		call	AddressBookEnumerateEntries	; *ds:si <- carray
	;
	; Find the number of elements to we have in the chunk array and
	; then unlock it.
	;
		call	ChunkArrayGetCount
		pop	bx
		call	MemUnlock
	;
	; Find the number of entries in the address book and initialize
	; the dynamic list.
	;
		pop	si
		segmov	ds, es			; *ds:si <- object
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock

		ret

AddressBookListMakeEntryList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddElementToTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element to our chunk array

CALLED BY:	AddressBookEnumerateEntries
PASS:		cx	= entry ID (page number)
		bx	= address book ID
		*ds:si	= chunk array of the routine
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddElementToTable	proc	far
		uses	ax,bx,cx,dx,di,bp
		.enter
	;
	; Make sure that *ds is a chunk array and that si is a valid handle
	;
	;	Assert ChunkArray dssi
	;
	; See if each entry is a text field or not.
	;
		mov	dl, ADT_FAX
		push	cx
		call	AddressBookGetEntryInfo	; al <- entry field data type
						; cx:dx <- field ID
		pop	cx
	;
	; If the field data type is Text, then we'll use it.  Otherwise
	; don't enter it in our table.
	;
		cmp	al, FDT_TEXT
		jnz	exit
		call	ChunkArrayAppend	; ds:di <- new element
		mov	ds:[di], cx		; save page number
exit:
		clc
		.leave
		ret
AddElementToTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListCloseBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure that the address book is closed.

CALLED BY:	MSG_ADDRESS_BOOK_LIST_CLOSE_BOOK
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListCloseBook	method dynamic AddressBookListClass, 
					MSG_ADDRESS_BOOK_LIST_CLOSE_BOOK
	
	;
	; See if any address book was open.  If none was, just exit
	; peacefully.
	;
		clr	bx
		xchg	bx, ds:[di].ABLI_addrBookHandle
		tst	bx
	jz	short	exit
	;
	; Find the file handle of the address book and close the file.
	;
		call	AddressBookClose
;;		mov	ax, enum AddressBookClose
;;		call	CallAddressBook

	;
	; Deallocate the block for the chunk array in the address book
	;
		mov	bx, ds:[di].ABLI_entryTableHandle
		call	MemFree

exit:
		clr	ds:[di].ABLI_entryTableHandle
		
		ret
AddressBookListCloseBook	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListGetItemClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used to change the font of the gen dynamic list

CALLED BY:	MSG_GEN_DYNAMIC_LIST_GET_ITEM_CLASS
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
RETURN:		cx, dx	= class to use for item
DESTROYED:	ax, bp	= destroyed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListGetItemClass	method dynamic AddressBookListClass, 
					MSG_GEN_DYNAMIC_LIST_GET_ITEM_CLASS
	;
	; Make the list know it's items are instances of
	; AddressBookListItemClass
	;
		mov	cx, segment dgroup
		mov	dx, offset AddressBookListItemClass

		ret
AddressBookListGetItemClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListItemVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Made so the items draw themselves with different fonts.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= AddressBookListItemClass object
		ds:di	= AddressBookListItemClass instance data
		ds:bx	= AddressBookListItemClass object (same as *ds:si)
		es 	= segment of AddressBookListItemClass
		ax	= message #
		bp	= GState
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListItemVisDraw	method dynamic AddressBookListItemClass, 
					MSG_VIS_DRAW
		uses	ax, bx, cx, dx
		.enter
	;	
	; Change the font of the GState. Use the system font size for
	; moniker
	;
		call	GrGetDefFontID		; cx <- font id
						; dx.ah <- font size
						; bx <- handle to font data

		mov	di, bp
		mov	cx, ADDRESS_ITEM_FONT
		call	GrSetFont
	;
	; Call the super class
	;
		.leave
		mov	di, offset AddressBookListItemClass
		call	ObjCallSuperNoLock

		ret
AddressBookListItemVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListIsAddressBookUsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells if the address book has been used recently.

CALLED BY:	MSG_ADDRESS_BOOK_LIST_IS_ADDRESS_BOOK_USED
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
RETURN:		carry if the address book has been used
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListIsAddressBookUsed	method dynamic AddressBookListClass, 
					MSG_ADDRESS_BOOK_LIST_IS_ADDRESS_BOOK_USED
	uses	ax
	.enter

	;
	; Carry will be set by the compare function
	;
		clr	al
		cmp	al, ds:[di].ABLI_addrBookUsed
		
	.leave
	ret
AddressBookListIsAddressBookUsed	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListSetAddressNotUsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the address book as not being used.

CALLED BY:	MSG_ADDRESS_BOOK_LIST_SET_ADDRESS_NOT_USED
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListSetAddressNotUsed	method dynamic AddressBookListClass, 
					MSG_ADDRESS_BOOK_LIST_SET_ADDRESS_NOT_USED

		mov	ds:[di].ABLI_addrBookUsed, 0
		
	ret
AddressBookListSetAddressNotUsed	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookListSetAddressUsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the address book as being used.

CALLED BY:	MSG_ADDRESS_BOOK_LIST_SET_ADDRESS_USED
PASS:		*ds:si	= AddressBookListClass object
		ds:di	= AddressBookListClass instance data
		ds:bx	= AddressBookListClass object (same as *ds:si)
		es 	= segment of AddressBookListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookListSetAddressUsed	method dynamic AddressBookListClass, 
					MSG_ADDRESS_BOOK_LIST_SET_ADDRESS_USED

		mov	ds:[di].ABLI_addrBookUsed, 1
	ret
AddressBookListSetAddressUsed	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookFileSelectorGetFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the file selected by the user with the file selector.

CALLED BY:	MSG_ADDRESS_BOOK_FILE_SELECTOR_GET_FILE
PASS:		*ds:si	= AddressBookFileSelectorClass object
		ds:di	= AddressBookFileSelectorClass instance data
		ds:bx	= AddressBookFileSelectorClass object (same as *ds:si)
		es 	= segment of AddressBookFileSelectorClass
		ax	= message #
		cx	= entry # of selection made
		bp	= GenFileSelectorEntryFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookFileSelectorGetFile	method dynamic AddressBookFileSelectorClass, 
					MSG_ADDRESS_BOOK_FILE_SELECTOR_GET_FILE
	;
	; Make sure the message was sent by a double click
	;
		test	bp, mask GFSEF_OPEN
		jz	done
	;
	; Make sure a file was selected
	;
		test	bp, mask GFSEF_TYPE
		jnz	done
	;
	; Find out the file info and use it to open a new Address book
	;
		sub	sp, size AddressBookFileInfo
		mov	di, sp
		segmov	es, ss

		mov	cx, PATH_BUFFER_SIZE
		mov	dx, ss
		lea	bp, es:[di].ABFI_path
		mov	ax, MSG_GEN_PATH_GET
		call	ObjCallInstanceNoLock	; dx:bp <- filled
						; cx <- disk handle
		mov	es:[di].ABFI_diskHandle, cx

		mov	cx, dx
		lea	dx, es:[di].ABFI_name
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		call	ObjCallInstanceNoLock	; cx:dx <- filled
	;
	; Open the address book.
	;
		mov	dx, di			; cx:dx <- AddressBookFileInfo
		mov	si, offset AddrBookList
		mov	ax, MSG_ADDRESS_BOOK_LIST_OPEN_ADDRESS_BOOK
		call	ObjCallInstanceNoLock
		jc	cannotOpenNewAddressBook

	;
	; Make the new list. With the new address book.
	;
		mov	ax, MSG_ADDRESS_BOOK_LIST_MAKE_ENTRY_LIST
		call	ObjCallInstanceNoLock
	;
	; Close the file selector.
	;
		mov	cx, IC_DISMISS
		mov	si, offset AddrBookFileSelector
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjCallInstanceNoLock
		
restoreStack:
		add	sp, size AddressBookFileInfo
done:
		ret

cannotOpenNewAddressBook:
		mov	ax, CustomDialogBoxFlags <1, CDT_ERROR,
			GIT_NOTIFICATION, 0>
		mov	si, offset NoAddressBook
		call	DoDialog
		jmp	restoreStack
		
AddressBookFileSelectorGetFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddressBookFileSelectorOpenPressed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the message sent when the user presses open on the
		dialog.

CALLED BY:	MSG_ADDRESS_BOOK_FILE_SELECTOR_OPEN_PRESSED
PASS:		*ds:si	= AddressBookFileSelectorClass object
		ds:di	= AddressBookFileSelectorClass instance data
		ds:bx	= AddressBookFileSelectorClass object (same as *ds:si)
		es 	= segment of AddressBookFileSelectorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressBookFileSelectorOpenPressed	method dynamic AddressBookFileSelectorClass, MSG_ADDRESS_BOOK_FILE_SELECTOR_OPEN_PRESSED

pathBuffer	local	PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE	dup (char)
		uses	ax, cx, dx, bp
		.enter
	;
	; Check the file selector to see what state it was at when the
	; user pressed the open button.
	;
		mov	cx, ss
		lea	dx, ss:pathBuffer		; cx:dx <- path
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
		mov	bx, bp				; save for local vars
		call	ObjCallInstanceNoLock		; cx:dx <- selection
							; ax <- disk handle
							; bp <- GenFileSelectorEntryFlags
	;
	; If the selection was a directory, we want to open that
	; directory.  If it was a file, we want to send it to
	; our method to open the file.
	;
		test	bp, mask GFSEF_PARENT_DIR
		jnz	changeToParentDirectory

		test	bp, GenFileSelectorEntryFlags \
				<GFSET_SUBDIR, 0, 0, 0, 0, 0, 0, 0, 0 >
		jnz	changeDirectory

		or	bp,  GenFileSelectorEntryFlags \
				<GFSET_FILE, 1, 0, 0, 0, 0, 0, 0, 0 >
		mov	ax, MSG_ADDRESS_BOOK_FILE_SELECTOR_GET_FILE
		call	ObjCallInstanceNoLock
		
exit:
		mov	bp, bx			; for local vars
		
		.leave
		ret

changeToParentDirectory:
		mov	ax, MSG_GEN_FILE_SELECTOR_UP_DIRECTORY
		call	ObjCallInstanceNoLock

		jmp	exit

changeDirectory:
		mov	bp, ax
		mov	ax, MSG_GEN_PATH_SET
		call	ObjCallInstanceNoLock

		jmp	exit
		
AddressBookFileSelectorOpenPressed	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyAddressBookFileInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies address book

CALLED BY:	INTERNAL
PASS:		ds:si	= src
		es:di	= dest
RETURN:		ds:si is copied to es:di
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/30/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyAddressBookFileInfo	proc	near
		uses	ax,bx,cx,si,di,bp
		.enter
	;
	; Copy the strings for the fields
	;
		mov	bp, si
		mov	bx, di
		lea	si, ds:[si].ABFI_name
		lea	di, es:[di].ABFI_name

		LocalCopyString

		lea	si, ds:[bp].ABFI_path
		lea	di, ds:[bx].ABFI_path

		LocalCopyString

		mov	ax, {word} ds:[bp].ABFI_diskHandle
		mov	{word} es:[bx].ABFI_diskHandle, ax

		.leave
		ret
CopyAddressBookFileInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDefaultAddressBookFileInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the default address book information into a
		AddressBookFileInfo structure begining at es:di

CALLED BY:	INTERNAL
PASS:		es:di	= where to copy the default information
RETURN:		information filled
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDefaultAddressBookFileInfo	proc	near
		uses	ax,bx,si,di,ds
		.enter

	;
	; Copy the address book file name.
	; es:di - where to put the default file name
	; save begining of structure in bx
	;
		mov	bx, di
		lea	di, es:[bx].ABFI_name
	;
	; ds:si - default file name to use
	;
		segmov	ds, cs
		mov	si, offset addressBookFileName
		LocalCopyString
	;
	; Copy the address book path
	;
		lea	di, es:[bx].ABFI_path
		mov	si, offset addressBookPath
		LocalCopyString

	;
	; Copy the disk handle.
	;
		mov	es:[bx].ABFI_diskHandle, ADDRESS_BOOK_DISK_HANDLE
		
		.leave
		ret
CopyDefaultAddressBookFileInfo	endp









