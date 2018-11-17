COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		ConView -- Book
FILE:		bookMain.asm

AUTHOR:		Martin Turon, August 1, 1994

METHODS:
		Name			Description
		----			-----------

	INT	BookEnumContentFiles	enumerates the content files of a book

	EXT	BookOpen		opens a book file
	EXT	BookClose		closes a book file 
	EXT	BookDelete		deletes all content files of a book
	EXT	BookGetFirstContentFile	grab first content file out of book

	INT	BookPushDir		cd to where given book resides
	INT	BookDeleteSingleFile	delete one content file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/1/94		Initial version

DESCRIPTION:
	This module deals with operations on the book level--actions that
	span all the content files of a given book.  Some examples include
	deleting a book (must delete all content files within that book) and
	searching a book for a specific piece of text. 

	$Id: mainBook.asm,v 1.1 97/04/04 17:49:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BookFileCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVLoadBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the book name and load it.

CALLED BY:	MSG_CGV_LOAD_BOOK
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

RETURN:		carry set if error loading book
			ax = LoadFileError

DESTROYED:	cx dx bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVLoadBook	method dynamic ContentGenViewClass, 
					MSG_CGV_LOAD_BOOK

	;
	; Close the file selector's GenInteraction
	;
	mov	bx, ds:[di].CGVI_fileSelector
	call	CGVDismissSummons
	;
	; Set up stack parameters for when we call the
	; ContentGenView.
	;
	sub	sp, (size ContentTextRequest)
	mov	bp, sp

	call	MBGetBookName
	mov	ax, LFE_ERROR_NO_BOOK_SELECTED
	jc	exit				;Not loading new book.

	mov	ss:[bp].CTR_flags, mask CTRF_needContext
	mov	ax, MSG_CGV_LOAD_BOOK_LOW
	call	ObjCallInstanceNoLock
	jnc	exit
	;
	; Notify user that the Book couldn't be opened
	;	pass ax - LoadFileError
	;
	call	ReportLoadFileError
	;
	; If the book was not successfully opened, try again.
	; 
	mov	ax, MSG_CGV_INIT_FILE_SELECTOR
	call	ObjCallInstanceNoLock

exit:
	add	sp, (size ContentTextRequest)
	ret

CGVLoadBook	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVLoadBookLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the ContentGenView to open the book
		whose name and path are passed in ContentTextRequest.

CALLED BY:	MSG_CGV_LOAD_BOOK_LOW
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
		ss:bp - ContentTextRequest 
			- CTR_flags set
			- CTR_bookname set to book file 
			- CTR_pathname set to book path
			- CTR_diskhandle set to book disk
RETURN:		carry set if error opening book
			ax = LoadFileError
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVLoadBookLow			method dynamic ContentGenViewClass, 
				MSG_CGV_LOAD_BOOK_LOW

	call	AppMarkBusy
	call	CGVDeleteTextVardata
	;
	; Delete current filename and link name so that MLDisplayText
	; doesn't try to redisplay them if loading this book fails. 
	; (Redisplay won't work, because we will muck with book-related
	; vardata below.)
	;
	push	bp
	mov	cx, CONTENT_FILENAME
	mov	dx, CONTENT_LINK
	clr	bp		
	call	ObjVarDeleteDataRange
	pop	bp
	;
	; Save bookname, book path and disk handle to vardata
	;
	mov	bx, ss
	mov	ax, CONTENT_BOOKNAME or mask VDF_SAVE_TO_STATE
	lea	dx, ss:[bp].CTR_bookname
	call	ContentAddStringVardata

	mov	ax, CONTENT_BOOK_PATHNAME or mask VDF_SAVE_TO_STATE
	lea	dx, ss:[bp].CTR_pathname
	call	ContentAddStringVardata

	mov	cx, size StandardPath
	mov	ax, CONTENT_BOOK_DISK_HANDLE or mask VDF_SAVE_TO_STATE
	call	ObjVarAddData
	mov	ax, ss:[bp].CTR_diskhandle
	mov	ds:[bx], ax
	;
	; Get the book's main file, cover page, and feature and tool flags
	;		
	call	MBGetFirstFileForBook		;pull info out of book
	jc	error				;exit if error opening book
	;
	; Save main file and cover page to vardata
	;
	mov	bx, ss
	mov	ax, CONTENT_MAIN_FILE or mask VDF_SAVE_TO_STATE
	lea	dx, ss:[bp].CTR_filename
	call	ContentAddStringVardata
	;
	; Turn off Begin tool and feature if there is no TOC page.
	;
	call	CGVCheckToDisableBegin
	;
	; Save book feature and tool flags to instance data
	;
	mov	di, ds:[si]
	add	di, ds:[di].ContentGenView_offset
	mov	ax, ss:[bp].CTR_featureFlags
	mov	ds:[di].CGVI_bookFeatures, ax
	mov	ax, ss:[bp].CTR_toolFlags
	mov	ds:[di].CGVI_bookTools, ax
	;
	; Send a book change notification
	;
	call	ContentSendBookNotification
	;
	; Set proper flags and load the content file.
	;	
	BitClr	ss:[bp].CTR_flags, CTRF_noBookFile
	BitSet	ss:[bp].CTR_flags, CTRF_resetPath
	mov	ax, MSG_CGV_LOAD_CONTENT_FILE
	call	ObjCallInstanceNoLock		; ax <- LoadFileError
	;
	; MSG_CGV_LOAD_CONTENT_FILE reports the error itself, so
	; we won't report it again, change it to LFE_NO_ERROR
	;
	mov	ax, LFE_NO_ERROR
	jc	error
exit:
	pushf					; save carry flag
	push	ax				; save LoadFileError
	call	AppMarkNotBusy
	pop	ax
	popf
	ret

error:
	;
	; Error opening book or content file - remove all vardata and
	; send a null notification so that controllers reset themselves.
	;
	push	ax, bp			; save LoadFileError
	call	RemoveBookLow		
	;
	; Free storage because we have dorked CGView state enough
	; that we can't follow links from this page or anything.
	; Add TEMP_TEXT_NO_DRAW to text object, because if it
	; tries to redraw after freeing the text, it will crash.
	; Mark the View as invalid so that it clears the existing text.
	;
	call	CGVAddTextVardata
	call	MBFreeText
	mov	cl, mask VOF_WINDOW_INVALID
	mov	dl, VUM_NOW
	mov	ax, MSG_VIS_MARK_INVALID
	call	ObjCallInstanceNoLock
	pop	ax, bp			; restore LoadFileError
	stc				; carry <- error
	jmp	exit

CGVLoadBookLow	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveBookLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all traces of a book - delete vardata and
		send a null book change notification

CALLED BY:	INTERNAL
PASS:		*ds:si - ContentGenView
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveBookLow		proc	near
	uses	bx, bp
	.enter
	mov	cx, CONTENT_BOOKNAME
	mov	dx, CONTENT_LINK
	clr	bp		
	call	ObjVarDeleteDataRange
	call	ContentSendNullNotification
	.leave
	ret
RemoveBookLow		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MBFreeText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the text if the not is not currently attaching.
		This is done so that if the book is not successfully
		loaded, the previous text is not still displayed.

CALLED BY:	CGVLoadBookLow
PASS:		*ds:si - ContentGenView
RETURN:		nothing
DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MBFreeText		proc	near
		uses	ax, si, bp
		.enter

		push	si
		clr	bx				
		call	GeodeGetAppObject			;^lbx:si <- app
		mov	ax, MSG_GEN_APPLICATION_GET_STATE	; ax - state
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
		test	ax, mask AS_ATTACHING
		jnz	done
		
		mov	ax, MSG_CGV_GET_TEXT_OD
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx
		jc	done
	;
	; DO NOT use MF_CALL here, as it can cause deadlock when 
	; MSG_CGV_LOAD_BOOK and MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS
	; are both executing in different threads.
	;		
		clr	bp, cx
		mov	ax, MSG_CT_FREE_STORAGE_AND_FILE
;;		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:		
		.leave
		ret
MBFreeText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVDeleteBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the book currently selected in the file selector.
		All content files associated with the book are also deleted. 

CALLED BY:	MSG_CGV_DELETE_BOOK

PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVDeleteBook	method dynamic ContentGenViewClass, 
							MSG_CGV_DELETE_BOOK

	;
	; Set up stack parameters for when we call the
	; ContentGenView.
	;
		sub	sp, (size ContentTextRequest)
		mov	bp, sp

		call	MBGetBookName
		jc	exit				; nothing selected
	;
	; See if the user is trying to delete something from a non-writable
	; disk, and if so, put up a special error.
	;
		call	IsBookReadOnly
		jnc	readOnlyBook
	;
	; See if we are in the process of deleting the current book
	;
		mov	ax, TEMP_DELETING_CURRENT_BOOK
		call	ObjVarFindData
		jc	deleteIt
	;
	; Bring up confirmation dialog
	;
		mov	di, offset ConfirmDeleteBookString
		lea	ax, ss:[bp].CTR_bookname ;ss:ax <- 1st string arg
		call	MUQueryUser
		cmp	ax, IC_YES
		jne	exit
	;
	; If the book we wish to delete is open, close it first.
	;
		mov	ax, CONTENT_BOOKNAME
		call	ObjVarFindData
		jnc	deleteIt			; no book if carry clr
		
		push	si
		mov	si, bx
		lea	di, ss:[bp].CTR_bookname
		segmov	es, ss, ax			; es:di = book file
		call	LocalCmpStrings
		pop	si				; *ds:si = View
		je	close
deleteIt:
	;
	; Delete it!
	;
		call	BookDelete
	;
	; Bring up the Book file selector.
	;
		mov	ax, MSG_CGV_INIT_FILE_SELECTOR
		call	ObjCallInstanceNoLock

exit:	
		add	sp, (size ContentTextRequest)
		ret
close:
	;
	; Add this vardata to ContentText so that it knows 
	; not to draw itself after the text has been deleted.
	;
		call	CGVAddTextVardata
	;
	; Have the text object close the current content file, and send the
	; delete message again when it is done.
	;
		clr	bx
		mov	cx, MSG_CGV_DELETE_BOOK		; notification msg
		call	MFSetFileCloseOld
		clr	cx
		mov	ax, TEMP_DELETING_CURRENT_BOOK
		call	ObjVarAddData
		jmp	exit
		
readOnlyBook:
	;
	; Notify the user they cannot delete a read-only book.
	;
		push	ds:[LMBH_handle]
		segmov	ds, ss, ax
		lea	dx, ss:[bp].CTR_bookname
		mov	ax, offset ErrorDeletingBookInROM
		call	ReportFileError
		pop	bx
		call	MemDerefDS
		stc
		jmp	exit
CGVDeleteBook	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsBookReadOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if book is on a read-only disk and therefore
		not deletable.

CALLED BY:	CGVDeleteBook
PASS:		ss:bp - ContentTextRequest with bookname
RETURN:		carry set if disk is writable
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 7/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsBookReadOnly		proc	near
		uses	cx,dx,si,di,ds
		.enter

	;
	; Temporarily copy the bookname to the pathname, to create
	; the full tail. If no pathname, just pass the bookname as tail.
	;
		segmov	es, ss, ax
		mov	ds, ax
		lea	di, ss:[bp].CTR_pathname
		call	LocalStringLength	; cx <- # chars in string

		lea	si, ss:[bp].CTR_bookname; ds:si <- bookname
		jcxz	constructIt		; no path, use bookname

EC <		mov	ax, di						>
EC <		add	ax, size PathName	; ax <- end of buffer	>
		add	di, cx			; location for backslash

EC <		push	ax						>
DBCS <		mov	ax, C_BACKSLASH					>
DBCS <		stosw							>
SBCS <		mov	al, C_BACKSLASH					>
SBCS <		stosb							>
EC <		pop	ax						>

		LocalCopyString
EC <		cmp	di, ax			; did buffer overflow?	>
EC <		ERROR_AE -1						>
		lea	si, ss:[bp].CTR_pathname

constructIt:
		sub	sp, size PathName
		mov	di, sp			; es:di <- dest buffer

		push	cx			; save CTR_pathname size
		
		mov	bx, ss:[bp].CTR_diskhandle
		mov	dx, 1			; include drive letter
		mov	cx, size PathName
		call	FileConstructActualPath ; bx <- diskHandle

		cmc				; carry *clear* if error
		jnc	done			; if error, say its ReadOnly

		test	al, mask FA_RDONLY
		clc				; assume it's read only
		jnz	done
		
		call	DiskCheckWritable	; carry set if writable

done:
		pop	cx			; pathname string length
		
		lahf
		add	sp, size PathName
		jcxz	exit
	;
	; Need to restore null in CTR_pathname
	;
		lea	di, ss:[bp].CTR_pathname
		add	di, cx
SBCS <		mov	{byte} es:[di], 0				>
DBCS <		mov	{word} es:[di], 0				>

exit:		
		sahf
		.leave
		ret
IsBookReadOnly		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVAddTextVardata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add TEMP_CONTENT_TEXT_NO_DRAW vardata to prevent
		ContentText from drawing itself while in the process
		of deleting a book.  Necessary because with certain
		books (eg. Napa Wine Guide), the text object still
		believes it has lines, even after MSG_VIS_TEXT_DELETE_ALL
		has been called.  

		This vardata will be removed in CGVLoadBookLow

CALLED BY:	CGVDeleteBook
PASS:		*ds:si - ContenGenView
RETURN:		ds fixed up
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVAddTextVardata		proc	near
		uses	ax, bx, cx, dx, bp, si
		.enter

		mov	ax, MSG_CGV_GET_TEXT_OD
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx

		mov	dx, size AddVarDataParams
		sub	sp, dx
		mov	bp, sp
		movdw	ss:[bp].AVDP_data, 0
		mov	ss:[bp].AVDP_dataSize, 0
		mov	ss:[bp].AVDP_dataType, TEMP_CONTENT_TEXT_NO_DRAW
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	di, mask MF_INSERT_AT_FRONT or mask MF_FORCE_QUEUE \
				or mask MF_STACK 
		call	ObjMessage
		add	sp, size AddVarDataParams

		.leave
		ret
CGVAddTextVardata		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVDeleteTextVardata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete TEMP_CONTENT_TEXT_NO_DRAW.

CALLED BY:	CGVLoadBook.
PASS:		*ds:si - ContentGenView
RETURN:		ds fixed up
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVDeleteTextVardata		proc	near
		uses	bp, si
		.enter

		mov	ax, MSG_CGV_GET_TEXT_OD
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx

		mov	cx, TEMP_CONTENT_TEXT_NO_DRAW
		mov	ax, MSG_META_DELETE_VAR_DATA
		mov	di, mask MF_FIXUP_DS 
		call	ObjMessage

		.leave
		ret
CGVDeleteTextVardata		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVInitFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the CGView's book file selector.

CALLED BY:	MSG_CGV_INIT_FILE_SELECTOR
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVInitFileSelector	method dynamic ContentGenViewClass, 
					MSG_CGV_INIT_FILE_SELECTOR

; jfh 12/04/03 - set the default path here
	push  di
	mov	bx, handle ContentStrings
	call	MemLock
	mov	es, ax
	mov	di, offset defaultPath
	mov	cx, es
	mov	dx, es:[di]			; cx:dx <- default path
	push	bx 					; save the memhandle for unlock
	mov	bp, SP_DOCUMENT
; there's prolly a better way, but I need to get di back
; and save it again for the INIT, so I pop and push thru bx
; hey - I'm new to ESP - so sue me
	pop	bx
	pop	di
	push	di
	push	bx
	mov	bx, ds:[di].CGVI_fileSelector
	mov	si, offset BookFileSelector
	mov	ax, MSG_GEN_PATH_SET
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage			; carry set if path invalid

; now I want to see if the path was set OK - if not, I want to revert
; to document
	jnc	goodSet

	mov	di, offset nullPath
	mov	cx, es
	mov	dx, es:[di]			; cx:dx <- null path
	pop	bx
	pop	di
	push	di
	push	bx
	mov	bx, ds:[di].CGVI_fileSelector
	mov	si, offset BookFileSelector
	mov	ax, MSG_GEN_PATH_SET
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage			; carry set if path invalid


goodSet:
	pop	bx
	call	MemUnlock
	pop   di


; original code
		mov	bx, ds:[di].CGVI_fileSelector
		mov	si, offset BookFileDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		ret
CGVInitFileSelector	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVEvalFileSelectorPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has selected a book.  Open it.

CALLED BY:	MSG_CGV_EVAL_FILE_SELECTOR_PRESS
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVEvalFileSelectorPress		method dynamic ContentGenViewClass, 
					MSG_CGV_EVAL_FILE_SELECTOR_PRESS
	;
	; get the current selection
	;
	push	si
	mov	bx, ds:[di].CGVI_fileSelector
	mov	si, offset BookFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	clr	cx					;Don't need name.
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; we enable the Open & Delete triggers only if something has
	; been selected, and that something is a file
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	bp, mask GFSEF_NO_ENTRIES
	jnz	setState
	CheckHack <GFSET_FILE eq 0>
	test	bp, mask GFSEF_TYPE
	jnz	setState
	mov	ax, MSG_GEN_SET_ENABLED
setState:
	mov	dl, VUM_NOW
	mov	si, offset BookFileSelectorOK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, offset BookFileSelectorDelete
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	;
	; See if something is being opened.  Exit if not.
	;
	test	bp, mask GFSEF_OPEN
	jz	done
	;
	; Load the selected book.  
	;
	mov	ax, MSG_CGV_LOAD_BOOK
	call	ObjCallInstanceNoLock
done:
	ret
CGVEvalFileSelectorPress	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVDismissSummons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the book file selector dialog from the screen.

CALLED BY:	INTERNAL
PASS:		bx - handle of file selector summons
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVDismissSummons		proc	near
		uses	si
		.enter

		mov	si, offset BookFileSelector
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	si, offset BookFileSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	.leave
	ret
CGVDismissSummons		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MBGetBookName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the name of the selected book

CALLED BY:	CGVLoadBook, CGVDeleteBook
PASS:		*ds:si	- ContentGenViewClass instance
		ss:bp	- ContentTextRequest structure
RETURN:		ss:bp	- CTR_bookname set to book file to open
			- CTR_pathname set to book's path
			- CTR_diskhandle set to book's disk
		carry	- set if book not selected
			- clear if a book is selected
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MBGetBookName	proc	near
	class	ContentGenViewClass
	uses	si, bp
	.enter
	;
	; Need to get the book file from the file selector.
	;
	push	si, bp
	mov	di, ds:[si]
	add	di, ds:[di].ContentGenView_offset
	mov	bx, ds:[di].CGVI_fileSelector
	mov	si, offset BookFileSelector		;^lbx:si <- file sel.
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	cx, ss
	lea	dx, ss:[bp].CTR_bookname
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, bp
	pop	si, bp
	;
	; See if new book file is being loaded.  Exit if not.
	;
	andnf	ax, mask GFSEF_TYPE
	cmp	ax, GFSET_FILE shl offset GFSEF_TYPE
	stc
	jne	exit
	cmp	{TCHAR}ss:[bp].CTR_bookname, 0
	stc
	je	exit
	;
	; Get the path/disk handle from the file selector.
	;
	push	si,bp
	mov	si, offset BookFileSelector
	mov	dx, ss
	lea	bp, ss:[bp].CTR_pathname
	mov	cx, (size PathName)
	mov	ax, MSG_GEN_PATH_GET
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si,bp
EC <	ERROR_C PATH_CONSTRUCTION_ERROR				>
	mov	ss:[bp].CTR_diskhandle, cx

exit:
	.leave
	ret
MBGetBookName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MBGetFirstFileForBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the initial content file to be opened for the
		specified book.

CALLED BY:	CGVLoadBookLow
PASS:		*ds:si	- ContentGenViewClass instance
		ss:bp	- ContentTextRequest structure
			- CTR_bookname set to book file 
			- CTR_pathname set to book path
			- CTR_diskhandle set to book disk
RETURN:		carry set if couldn't open book file

		ss:bp	- CTR_filename set to content file to open
			  CTR_context set to page to load
			  CTR_pathname set to content file path
			  CTR_diskhandle set to content file disk
			  CTR_featureFlags set to book's feature flags
			  CTR_toolFlags set to book's tool flags
DESTROYED:	ax, bx, dx, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/26/94    	Initial version
	martin	8/2/94		Added support for book files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MBGetFirstFileForBook	proc	near
		uses	cx, bp, si, ds, es
		.enter
EC <		call	AssertIsCGV			>

	;
	; Open the book file and copy over all the relevant stuff
	;
		call	BookOpen
		LONG	jc	exit			;ax <- LoadFileError
	;
	; ds:0	= BookFileHeader
	; cx	= memory handle of BookFileHeader
	; ^hbx	= book VM file
	;
	;
	; Get info we need from the book header
	;
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_context		;name of cover page
		mov	si, offset BFH_firstPage	;source buffer
		LocalCopyString	

		lea	di, ss:[bp].CTR_filename	;get first file
		call	BookGetFirstContentFile
		jc	noFile				;ax <- LoadFileError
	;
	; See if content files are in book file's directory
	;
		call	BookOpenContentFile
		jnc	getTools
copyPath::
	;
	; Couldn't open book's content files in its own directory,
	; so they must have been installed in SP_USER_DATA.
	; Copy the pathname from BookFileHeader to ContentTextRequest.
	;
		lea	di, ss:[bp].CTR_pathname	;path for content files
		mov	si, offset BFH_path		;source buffer
		LocalCopyString	
		mov	ss:[bp].CTR_diskhandle, SP_USER_DATA
getTools:
	;
	; Get features and tools.
	;
		mov	ax, ds:[BFH_featureFlags]
		mov	ss:[bp].CTR_featureFlags, ax
		mov	ax, ds:[BFH_toolFlags]
		mov	ss:[bp].CTR_toolFlags, ax
noFile:
		push	ax
		lahf
		call	BookClose
		sahf
		pop	ax
		
exit:
		.leave
EC <		call	AssertIsCGV			>
		ret

MBGetFirstFileForBook	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the given book file and locks down the 
		BookFileHeader.

CALLED BY:	GLOBAL  - BookDelete, MBGetFirstFileForBook

PASS:		ss:bp	= ContextTextRequest with CTR_pathname,
			CTR_bookname, CTR_diskhandle filled in
RETURN:		if carry clear:
			ds:0	= BookFileHeader
			cx	= memory handle of BookFileHeader
			bx	= VM file handle of book file
			ax	= LFE_NO_ERROR
		otherwise:
			ax	= LoadFileError

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookOpen	proc	far
		uses	bp
		.enter

		call	BookPushDir			;ds <- ss
		jc	errorNoClose			;ax <- LoadFileError

		lea	dx, ss:[bp].CTR_bookname	;ds:dx <- book
		mov	ax, (VMO_OPEN shl 8) or \
				mask VMAF_FORCE_READ_ONLY or \
				mask VMAF_FORCE_DENY_WRITE
		clr	cx
		call	VMOpen
		mov	ax, LFE_BOOK_NOT_FOUND
		jc	errorNoClose

		mov	al, HFT_BOOK
		call	VerifyHelpFile
 		mov	ax, LFE_ERROR_INVALID_BOOK
		jc	errorNoUnlock

		call	VMGetMapBlock
		tst	ax
		jz	noMapBlock
		call	VMLock
		mov	cx, bp			;return block handle in cx
		mov	ds, ax

		mov	ax, LFE_BOOK_PROTOCOL_ERROR
		cmp	ds:[BFH_protocolMajor], BOOK_FILE_PROTO_MAJOR
		jne	error
		cmp	ds:[BFH_protocolMinor], BOOK_FILE_PROTO_MINOR
		jb	error
		clc
		mov	ax, LFE_NO_ERROR
exit:
		call	FilePopDir
		.leave
		ret

error:
		call	VMUnlock
errorNoUnlock:
		push	ax
		mov	al, FILE_NO_ERRORS
		call	VMClose
		pop	ax
errorNoClose:
EC <		clr	bx			;no file handle 	>
		stc
		jmp	exit

noMapBlock:		
		mov	ax, LFE_ERROR_INVALID_BOOK
		stc
		jmp	errorNoUnlock
BookOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks the given BookFileHeader and closes the given 
		book file.

CALLED BY:	INTERNAL - BookDelete

PASS:		^hbx	= VM file handle of book file
		^hcx	= memory handle of BookFileHeader
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookClose	proc	far
		uses	ax, bp
		.enter
		mov	bp, cx
		call	VMUnlock
		mov	al, FILE_NO_ERRORS
		call	VMClose

		.leave
		ret
BookClose	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookOpenContentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempts to open the book's first content file in
		the book file's directory.

CALLED BY:	GLOBAL  - MBGetFirstFileForBook

PASS:		ss:bp	= ContextTextRequest with CTR_pathname,
			CTR_diskhandle, CTR_filename filled in
RETURN:		carry clear if found and opened content file in
			book file's directory:
		carry set if content file not found in book file's
			directory

DESTROYED:	ax, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookOpenContentFile	proc	near
		uses	bx,cx,ds
		.enter

		call	BookPushDir			;ds <- ss
		jc	exit

		lea	dx, ss:[bp].CTR_filename	;ds:dx <- content file
		mov	ax, (VMO_OPEN shl 8) or \
				mask VMAF_FORCE_READ_ONLY or \
				mask VMAF_FORCE_DENY_WRITE
		clr	cx
		call	VMOpen
		jc	exit

		mov	al, HFT_CONTENT
		call	VerifyHelpFile

		pushf	
		mov	al, FILE_NO_ERRORS
		call	VMClose
		popf
exit:
		call	FilePopDir
		.leave
		ret

BookOpenContentFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookPushDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current directory to be the correct one for
		accessing the given book file

CALLED BY:	INTERNAL - BookOpen, BookDelete

PASS:		ss:bp - ContentTextRequest with CTR_diskhandle, CTR_pathname
RETURN:		ds = ss
		carry set if error
			ax = error string 
DESTROYED:	nothing

SIDE EFFECTS:	Pushes the current directory, so it is necessary to call
		FilePopDir eventually...

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookPushDir	proc	near
		uses	bx, dx
		.enter

		call	FilePushDir
		segmov	ds, ss, ax
		lea	dx, ss:[bp].CTR_pathname
		mov	bx, ss:[bp].CTR_diskhandle
		call	FileSetCurrentPath
		mov	ax, LFE_ERROR_SETTING_BOOK_PATH
		.leave
		ret
BookPushDir	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the given book file and all its associated 
		content files.

CALLED BY:	EXTERNAL - CGVDeleteBook

PASS:		*ds:si - ContentGenView
		ss:bp - ContentTextRequest
			CTR_bookname - name of book to delete
			CTR_pathname - its path
			CTR_diskhandle - its disk
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di, es

NOTES:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookDelete	proc	near
		.enter
EC <		call	AssertIsCGV					>

		push	ds:[LMBH_handle], si

		call	BookOpen		; ^hbx = VM file,
						; ^hcx = map block,
						; ds:0 = Book header
		LONG    jc	noDelete	; ax <- LoadFileError
		push	bx, cx
	;
	; Delete all content files within the book...
	;
		push	bp
		mov	ax, SEGMENT_CS
		mov	bp, offset BookDeleteSingleFile
		call	BookEnumContentFiles
		pop	bp
	;
	; Now copy the names of the bookfile and the directory holding all
	; the content files into temporary buffer, so we can close the book
	; file.
	;
		call	Alloc2PathBuffers
		mov	di, offset PB2_path1
		mov	si, offset BFH_path	; ds:si	= path of content files
		LocalCopyString

		mov	di, offset PB2_path2	
		lea	si, ss:[bp].CTR_bookname
		segmov	ds, ss, ax		; ds:si	= book file name
		LocalCopyString

		pop	bx, cx
		call	BookClose
	;
	; switch to the book file's directory...
	;
		call	FilePushDir
		segmov	ds, ss, ax
		mov	bx, ss:[bp].CTR_diskhandle
		lea	dx, ss:[bp].CTR_pathname
		call	FileSetCurrentPath
		mov	ax, offset ErrorDeletingBookString
		jc	error
	;
	; and delete the book file itself
	;
		segmov	ds, es, ax
		mov	dx, offset PB2_path2
		call	BookDeleteSingleFile
	;
	; IF content files are not at top-level of SP_USER_DATA,
	; try to delete their sub-directory
	;
		mov	di, offset PB2_path1
		mov	ax, ds:[di]					
		LocalIsNull ax			
		jz	freeAndExit
		mov	ax, SP_USER_DATA
		call	FileSetStandardPath
		mov	dx, di
		call	TruncatePathName	; get rid of "\." 
		call	FileDeleteDir
		jnc	exit
		cmp	ax, ERROR_DIRECTORY_NOT_EMPTY
		je	freeAndExit
		mov	ax, offset ErrorDeletingBookFolderString
error:
		call	ReportFileError
freeAndExit:
		call	FreePathBuffer
		call	FilePopDir

exit:
		popdw	bxsi
		call	MemDerefDS

		mov	ax, TEMP_DELETING_CURRENT_BOOK
		call	ObjVarFindData
		jnc	done
	;
	; Remove all references to this book and send an empty
	; notification so controllers can reset their UI
	;
		call	RemoveBookLow		

done:
		.leave
		ret

noDelete:
	;
	; The book couldn't be opened, report that error
	;
		call	ReportLoadFileError
		jmp	exit
BookDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookEnumContentFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerates through all the content files of the given 
		book, and calls the given routine on each.

CALLED BY:	INTERNAL - BookDelete

PASS:		^hbx	= VM file handle of book file
		ds:0	= block containing BookFileHeader
		ax:bp	= fptr to procedure to call for each content file

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

	CALLBACK ROUTINE:

		PASS:		ds:dx	= FileLongName of content file
		RETURN:		nothing
		DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookEnumContentFiles	proc	near
		uses	ax, bx, cx, dx, bp, ds
		.enter
		call	FilePushDir
	;
	; ds:0 	= BookFileHeader
	; bx 	= VM File Handle
	;
		push	ax, bx
		mov	bx, SP_USER_DATA
		mov	dx, offset BFH_path
		call	FileSetCurrentPath
		pop	ax, bx
	
		mov	cx, ds:[BFH_count]
		jcxz	noFiles
		mov	dx, ds:[BFH_nameList]
		tst	dx
		jz	noFiles
		push	ax, bp			; save callback fptr
		mov	ax, dx
		call	VMLock
		mov	ds, ax
		clr	dx			; ds:dx = FileLongName

		pop	bx, ax			; bx:ax <- callback fptr
contentFileLoop:
		push	bx, ax
		call	ProcCallFixedOrMovable
		pop	bx, ax
		add	dx, size FileLongName
		loop	contentFileLoop

		call	VMUnlock
noFiles:
		call	FilePopDir
		.leave
		ret
BookEnumContentFiles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookDeleteSingleFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the given content file.  Reports any errors that
		occur with a dialog box.

CALLED BY:	INTERNAL - BookDelete via BookEnumContentFiles

PASS:		ds:dx	= FileLongName of content file to delete 
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookDeleteSingleFile	proc	far
		uses	ax
		.enter
		call	FileDelete
		jc	error
done:
		.leave
		ret
error:
		mov	ax, offset ErrorDeletingBookString
		call	ReportFileError
		jmp	done
BookDeleteSingleFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookGetFirstContentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the FileLongName of the first content file of the
		given book.

CALLED BY:	EXTERNAL - MFGetFileForBook

PASS:		^hbx	= VM file handle of book file
		ds:0	= BookFileHeader
		es:di	= FileLongName to stuff with first content filename

RETURN:		es:di	= FileLongName filled with correct information
		carry set if no name
			ax = LoadFileError
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookGetFirstContentFile	proc	near
		uses	cx, si
		.enter
	;
	; Get BookFileHeader and calculate offset into names buffer
	;
		mov	cx, ds:[BFH_firstFile]
		call	BookGetContentFile
		
		.leave
		ret
BookGetFirstContentFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BookGetContentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a given content file name

CALLED BY:	EXTERNAL - BookGetFirstContentFile, 
			   CSTGetNextContentFile

PASS:		^hbx	= VM file handle of book file
		ds:0	= BookFileHeader
		es:di	= FileLongName to stuff with first content filename
		cx	= # of content file in BFH_nameList to get

RETURN:		es:di	= FileLongName filled with correct information
		carry set if no filename list
			ax = LFE_ERROR_BOOK_HAS_NO_FILES

DESTROYED:	ax, cx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BookGetContentFile	proc	far
		uses	di,si,bp,ds
		.enter

		mov	ax, size FileLongName
		mul	cx
		mov_tr	si, ax	
	;
	; Lock down the names buffer and copy the name of the first content
	; file into the given buffer (es:di).
	;
		mov	ax, ds:[BFH_nameList]
		tst	ax
		jz	noNames
		
		call	VMLock
		mov	ds, ax				; ds:si = content file
		LocalCopyString				; copy it into es:di
		call	VMUnlock
		clc
done:
		.leave
		ret
noNames:
		mov	ax, LFE_ERROR_BOOK_HAS_NO_FILES
		stc
		jmp	done
BookGetContentFile	endp

;----


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreePathBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a path buffer allocated by either
		AllocPathBuffer or Alloc2PathBuffers

CALLED BY:	GLOBAL

PASS:		es - segment of path buffer

RETURN:		nothing 

DESTROYED:	nothing, flags preserved 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreePathBuffer	proc near
	uses	bx
	.enter
	pushf
	mov	bx, es:[PB_handle]
	call	MemFree
	popf

	.leave
	ret
FreePathBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Alloc2PathBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a buffer for 2 paths on the heap

CALLED BY:	GLOBAL

PASS:		nothing 

RETURN:		es:0 - PathBuffer2 structure (es:0 is the handle)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Alloc2PathBuffers	proc near
	uses	ax,bx,cx
	.enter
	mov	ax, size PathBuffer2
	mov	cx, (mask HAF_ZERO_INIT shl 8) or ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es, ax
	mov	es:[PB_handle], bx
	.leave
	ret
Alloc2PathBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReportLoadFileError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a LoadFileError, display the appropriate error message.

CALLED BY:	INTERNAL
PASS:		*ds:si - ConGenView
		ss:bp - ContentTextRequest
		ax - LoadFileError
RETURN:		nothing
DESTROYED:	nothing - flags preserved

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReportLoadFileError		proc	far
		uses	ax, bx, dx, ds, si
		.enter
		pushf
		cmp	ax, LoadFileError
NEC <		jae	noReport					>
EC <		ERROR_AE INVALID_LOAD_FILE_ERROR			>
	;
	; Map the LoadFileError to a string
	;
		shl	ax				;ErrorArray has dword
		shl	ax				; sized entries
		push	ax
		mov	bx, handle ContentStrings
		call	MemLock
		mov	es, ax
		pop	ax
		mov	si, offset ErrorArray
		mov	si, es:[si]			;es:si <- ErrorArray
		add	si, ax				;es:si <- this entry
		mov	ax, es:[si]			;ax <- string offset
		mov	dx, es:[si+2]			;dx <- offset of string
							; argument 1 in CTR
		call	MemUnlock
		tst	ax
		jz	noReport
		segmov	ds, ss, bx
		add	dx, bp				;ds:dx <- string arg1
		call	ReportFileError
noReport:
		popf
		.leave
		ret
ReportLoadFileError		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReportFileError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up an error

CALLED BY:	INTERNAL
PASS:		ax - chunk of error string
		ds:dx - string arg 1
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReportFileError		proc	far
		uses	bx, si, di, dx, es
		.enter
	;
	; Get rid of the annoying "\." at the end of the pathname
	;
		call	TruncatePathName
	;
	; Put up the error
	;
		mov	si, ax
		mov	bx, handle ContentStrings
		call	MemLock
		mov	es, ax

		sub	sp, (size StandardDialogParams)
		mov	di, sp			;ss:di <- params
		mov	ss:[di].SDP_customFlags,
		  (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		  (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE) or \
		  mask CDBF_SYSTEM_MODAL
		movdw	ss:[di].SDP_stringArg1, dsdx
		clr	ax, dx
		movdw	ss:[di].SDP_stringArg2, dxax
		mov	ax, es:[si]		;es:ax <- ptr to error message
		movdw	ss:[di].SDP_customString, esax
		clr	ss:[di].SDP_helpContext.segment
		call	UserStandardDialog

		call	MemUnlock

		.leave
		ret
ReportFileError		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TruncatePathName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes trailing "\." from pathname, if there.

CALLED BY:	ReportFileError, BookDelete
PASS:		ds:dx - pathname
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TruncatePathName		proc	near
		uses	ax, cx, di, es
		.enter
	;
	; Scan up to PATH_BUFFER_SIZE bytes for the null
	;
		mov	cx, PATH_BUFFER_SIZE	
		segmov	es, ds, ax
		mov	di, dx			;es:di <- string argument
		mov	al, 0
		repne	scasb	
EC <		ERROR_NZ PATH_CONSTRUCTION_ERROR		>
NEC <		jnz	done					>
		dec	di			; point at null
		dec	di			; point at last char
		dec	di			; point at 2nd to last char
		cmp	{word}es:[di], (0x5c or (0x2e shl 8))
		jne	done
		mov	{word}es:[di], 0
done:
		.leave
		ret
TruncatePathName		endp


BookFileCode ends
