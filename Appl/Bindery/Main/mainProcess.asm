COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		mainProcess.asm

ROUTINES:
	Name			Description
	----			-----------
    INT EncapsulateToTargetVisText 
				Send a message to the target VisText

    INT GetNowAsTimeStamp	Convert the current date and time into two
				16-bit records (FileDate and FileTime)

    INT StudioProcessInsertVariableCommon 
				Common routine to handle inserting a
				number, date, or time

METHODS:
	Name			Description
	----			-----------
    StudioProcessUIInstallToken	Install the tokens for Studio

				MSG_GEN_PROCESS_INSTALL_TOKEN
				StudioProcessClass

    StudioProcessInsertColumnBreak  
				Insert a C_COLUMN_BREAK character

				MSG_STUDIO_PROCESS_INSERT_COLUMN_BREAK
				StudioProcessClass

    StudioProcessInsertTextualDateTime  
				Insert a textual representation of the
				current date or time into the document at
				the current insertion point.

				MSG_STUDIO_PROCESS_INSERT_TEXTUAL_DATE_TIME
				StudioProcessClass

    StudioProcessInsertNumber	Insert a number

				MSG_STUDIO_PROCESS_INSERT_NUMBER
				StudioProcessClass

    StudioProcessInsertDate	Insert a date

				MSG_STUDIO_PROCESS_INSERT_DATE
				StudioProcessClass

    StudioProcessInsertTime	Insert a time

				MSG_STUDIO_PROCESS_INSERT_TIME
				StudioProcessClass

    StudioProcessInsertVariableGraphic  
				Insert a variable type graphic

				MSG_STUDIO_PROCESS_INSERT_VARIABLE_GRAPHIC
				StudioProcessClass

    StudioProcessPrintDialog	MSG_STUDIO_PROCESS_PRINT_DIALOG
				StudioProcessClass

    StudioProcessMergeFile	MSG_STUDIO_PROCESS_MERGE_FILE
				StudioProcessClass

    MergeFileCheck		Checks to see if the current selection is a
				directory or a normal file and enables or
				disables the "OK" button accordingly.  Also
				edits or creates double-clicked file.

				MSG_STUDIO_PROCESS_MERGE_FILE_CHECK
				StudioProcessClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for StudioProcessClass

	$Id: mainProcess.asm,v 1.1 97/04/04 14:39:42 newdeal Exp $

------------------------------------------------------------------------------@

idata segment

	StudioProcessClass

miscSettings	StudioMiscSettings

idata ends

AppInitExit segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioProcessUIInstallToken -- MSG_GEN_PROCESS_INSTALL_TOKEN
						for StudioProcessClass

DESCRIPTION:	Install the tokens for Studio

PASS:
	*ds:si - instance data
	es - segment of StudioProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/18/92		Initial version

------------------------------------------------------------------------------@
StudioProcessUIInstallToken	method dynamic	StudioProcessClass,
						MSG_GEN_PROCESS_INSTALL_TOKEN
	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset StudioProcessClass
	call	ObjCallSuperNoLock

	; install Bindery datafile token

	mov	ax, ('S') or ('D' shl 8)	; ax:bx:si = token used for
	mov	bx, ('A') or ('T' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	installBookToken			; yes, do nothing
	mov	cx, handle DatafileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset DatafileMonikerList
	clr	bp				; list is in data resource, so
						;  it's already relocated
	call	TokenDefineToken		; add icon to token database

installBookToken:

	mov	ax, ('c') or ('n' shl 8)	; ax:bx:si = token used for
	mov	bx, ('t') or ('b' shl 8)	;	Book datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
	mov	cx, handle BookFileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset BookFileMonikerList
	clr	bp				; list is in data resource, so
						;  it's already relocated
	call	TokenDefineToken		; add icon to token database
		
done:
	ret

StudioProcessUIInstallToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The app is being closed, save book name to state block

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioProcessClass
		ax - the message
RETURN:		cx - handle of extra state block
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessCloseApplication		method dynamic StudioProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION

	
	; get name of current book (this assumes because name is in
	; GenText that book file has been created for it, which might
	; not be the case if user has not closed the dialog yet...)

		clr	bp			;no state block yet
		sub	sp, size FileLongName
		mov	dx, sp
		mov	cx, ss
		mov	di, offset BookNameText
		call	GetNameFromText
		jz	noBook
	
	; allocate a block

		mov	ax, size FileLongName
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		mov	es, ax
		clr	di	
		
		segmov	ds, ss, ax
		mov	si, dx
		mov	cx, size FileLongName / 2
		rep	movsw

		call	MemUnlock
		mov	bp, bx
noBook:
		mov	cx, bp
		add	sp, size FileLongName

		ret
StudioProcessCloseApplication		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The app is being closed, save book name to state block

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioProcessClass
		ax - the message
		bp - handle of extra state block
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessOpenApplication		method dynamic StudioProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION


	; let our superclass actually open the sucker

		push	bp
		mov	di, offset StudioProcessClass
		call	ObjCallSuperNoLock
	;	
	; Make the StudioPageNameControl enablable.
	;
		GetResourceHandleNS	StudioPageNameControl, bx
		mov	si, offset StudioPageNameControl
		mov	cx, TRUE
		mov	ax, MSG_SLPNC_SET_ALLOW_ENABLE
		clr	di
		call	ObjMessage
	;
	; if there is an extra state block, get the book name from it
	; and copy it to the BookNameStatusBar
		
		pop	bp
		mov	ax, MSG_STUDIO_APPLICATION_RESET_BOOK_INFO
		tst	bp
		jz	noStateBlock

		mov	bx, bp
		call	MemLock
		mov	cx, ax
		clr	dx
		mov	si, offset BookNameStatusBar
		call	SetText
		call	MemUnlock

	; now that the Book name is in the text field, we can
	; restore UI state based on its contents

		mov	cx, si			;pass chunk of BookNameText
		mov	ax, MSG_STUDIO_APPLICATION_LOAD_BOOK
		
noStateBlock:
		call	GenCallApplication

		ret
StudioProcessOpenApplication		endm

AppInitExit ends

;---

DocDrawScroll segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNowAsTimeStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the current date and time into two 16-bit records
		(FileDate and FileTime)

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ax	= FileDate
		bx	= FileTime
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/4/92		Stolen from primary IFS drivers (hence the
				formatting)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNowAsTimeStamp	proc	far
		uses	cx, dx
		.enter
		call	TimerGetDateAndTime
	;
	; Create the FileDate record first, as we need to use CL to the end...
	; 
		sub	ax, 1980	; convert to fit in FD_YEAR
			CheckHack <offset FD_YEAR eq 9>
		mov	ah, al
		shl	ah		; shift year into FD_YEAR
		mov	al, bh		; install FD_DAY in low 5 bits
		
		mov	cl, offset FD_MONTH
		clr	bh
		shl	bx, cl		; shift month into place
		or	ax, bx		; and merge it into the record
		xchg	dx, ax		; dx <- FileDate, al <- minutes,
					;  ah <- seconds
		xchg	al, ah
	;
	; Now for FileTime. Need seconds/2 and both AH and AL contain important
	; stuff, so we can't just sacrifice one. The seconds live in b<0:5> of
	; AL (minutes are in b<0:5> of AH), so left-justify them in AL and
	; shift the whole thing enough to put the MSB of FT_2SEC in the right
	; place, which will divide the seconds by 2 at the same time.
	; 
		shl	al
		shl	al		; seconds now left justified
		mov	cl, (8 - width FT_2SEC)
		shr	ax, cl		; slam them into place, putting 0 bits
					;  in the high part
	;
	; Similar situation for FT_HOUR as we need to left-justify the thing
	; in CH, so just shift it up and merge the whole thing.
	; 
		CheckHack <(8 - width FT_2SEC) eq (8 - width FT_HOUR)>
		shl	ch, cl
		or	ah, ch
		mov_tr	bx, ax		; bx <- time
		mov_tr	ax, dx		; ax <- date
		.leave
		ret
GetNowAsTimeStamp	endp

DocDrawScroll ends

;---

DocMiscFeatures segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessInsertTextualDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a textual representation of the current date or
		time into the document at the current insertion point.

CALLED BY:	MSG_STUDIO_PROCESS_INSERT_TEXTUAL_DATE_TIME
PASS:		cx	= DateTimeFormat to use
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessInsertTextualDateTime method dynamic StudioProcessClass, 
				MSG_STUDIO_PROCESS_INSERT_TEXTUAL_DATE_TIME
	.enter
	;
	; Allocate a block into which we can put the text, since we can't
	; make this call synchronous.
	; 
	push	cx
	mov	ax, DATE_TIME_BUFFER_SIZE
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	pop	si			; si <- DateTimeFormat
	jc	done
	
	;
	; Format the current time appropriately.
	; 
	mov	es, ax
	push	bx
	clr	di			; es:di <- destination
	call	TimerGetDateAndTime	; get now
	call	LocalFormatDateTime	; format now
	pop	dx		; dx <- handle
	mov	bx, dx
	call	MemUnlock	; guess what?

	;
	; Now send the block off to the target text object to replace the
	; current selection.
	; 
	mov	ax, 1
	call	MemInitRefCount		; set reference count to 1 so when the
					;  target vistext decrements it for us
					;  it will go away
	mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION_BLOCK
	mov	di, mask MF_RECORD
	push	dx
	call	EncapsulateToTargetVisText
	pop	cx
	
	;
	; Send a message to the same place to decrement the reference count
	; for that block so it goes away when the text object is done with it.
	; 
	mov	ax, MSG_META_DEC_BLOCK_REF_COUNT
	clr	dx			; no second handle
	mov	di, mask MF_RECORD
	call	EncapsulateToTargetVisText
done:
	.leave
	ret
StudioProcessInsertTextualDateTime endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessTOCContextListVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_STUDIO_PROCESS_TOC_CONTEXT_LIST_VISIBLE
PASS:		^lcx:dx	= list
		bp	= non-zero if visible
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessTOCContextListVisible	method dynamic StudioProcessClass,
				MSG_STUDIO_PROCESS_TOC_CONTEXT_LIST_VISIBLE
		.enter
		tst	bp
		jz	done
		mov	ax, MSG_STUDIO_DOCUMENT_TOC_CONTEXT_LIST_VISIBLE
		mov	bx, es
		mov	si, offset StudioDocumentClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_MODEL
		GetResourceHandleNS	StudioDocGroup, bx
		mov	si, offset StudioDocGroup
		mov	di, mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret
StudioProcessTOCContextListVisible		endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioProcessInsertNumber -- MSG_STUDIO_PROCESS_INSERT_NUMBER
							for StudioProcessClass

DESCRIPTION:	Insert a number

PASS:
	*ds:si - instance data
	es - segment of StudioProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
StudioProcessInsertNumber	method dynamic	StudioProcessClass,
						MSG_STUDIO_PROCESS_INSERT_NUMBER

	mov	si, offset NumberTypeList
	mov	di, offset NumberFormatList
	GOTO	StudioProcessInsertVariableCommon
StudioProcessInsertNumber	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioProcessInsertNumber -- MSG_STUDIO_PROCESS_INSERT_DATE
							for StudioProcessClass

DESCRIPTION:	Insert a date

PASS:
	*ds:si - instance data
	es - segment of StudioProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
StudioProcessInsertDate	method dynamic	StudioProcessClass,
						MSG_STUDIO_PROCESS_INSERT_DATE

	mov	si, offset DateTypeList
	mov	di, offset DateFormatList
	GOTO	StudioProcessInsertVariableCommon
StudioProcessInsertDate	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioProcessInsertTime -- MSG_STUDIO_PROCESS_INSERT_TIME
							for StudioProcessClass

DESCRIPTION:	Insert a time

PASS:
	*ds:si - instance data
	es - segment of StudioProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
StudioProcessInsertTime	method dynamic	StudioProcessClass,
						MSG_STUDIO_PROCESS_INSERT_TIME

	mov	si, offset TimeTypeList
	mov	di, offset TimeFormatList
	FALL_THRU	StudioProcessInsertVariableCommon
StudioProcessInsertTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessInsertVariableCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to handle inserting a number, date, or time

CALLED BY:	(INTERNAL) StudioProcessInsertNumber,
			   StudioProcessInsertDate,
			   StudioProcessInsertTime
PASS:		^lbx:si	= GenItemGroup with selected number/date/time
		^lbx:si = GenItemGroup with selected format
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessInsertVariableCommon proc	far
		CheckHack <segment NumberTypeList eq segment DateTypeList>
		CheckHack <segment NumberTypeList eq segment TimeTypeList>

	GetResourceHandleNS	NumberTypeList, bx
	push	di
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = type
	pop	si
	push	ax

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = format
	mov_tr	bp, ax				;bp = format
	pop	dx
	mov	cx, MANUFACTURER_ID_GEOWORKS

	FALL_THRU	StudioProcessInsertVariableGraphic
StudioProcessInsertVariableCommon endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioProcessInsertVariableGraphic --
		MSG_STUDIO_PROCESS_INSERT_VARIABLE_GRAPHIC for StudioProcessClass

DESCRIPTION:	Insert a variable type graphic

PASS:
	*ds:si - instance data
	es - segment of StudioProcessClass

	ax - The message

	cx - manufacturer ID
	dx - VisTextVariableType
	bp - data

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
StudioProcessInsertVariableGraphic	method StudioProcessClass,
				MSG_STUDIO_PROCESS_INSERT_VARIABLE_GRAPHIC

	mov	bx, bp				;bx = data

	sub	sp, size ReplaceWithGraphicParams
	mov	bp, sp

	; zero out the structure

	segmov	es, ss
	mov	di, bp
	push	cx
	mov	cx, size ReplaceWithGraphicParams
	clr	ax
	rep	stosb
	pop	cx

	mov	ss:[bp].RWGP_graphic.VTG_type, VTGT_VARIABLE
	mov	ss:[bp].RWGP_graphic.VTG_flags, mask VTGF_DRAW_FROM_BASELINE
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_manufacturerID,
									cx
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_type, dx
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData, bx

	;
	; If it's MANUFACTURER_ID_GEOWORKS:VTVT_STORED_DATE_TIME, we need to get
	; the current date and time and store them in the 2d and 3d words of
	; private data.
	; 
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	doReplace
	cmp	dx, VTVT_STORED_DATE_TIME
	jne	doReplace
	call	GetNowAsTimeStamp
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[2],
			ax	; date
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[4],
			bx	; time
doReplace:

	mov	ax, VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].RWGP_range.VTR_start.high, ax
	mov	ss:[bp].RWGP_range.VTR_end.high, ax

	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	mov	dx, size ReplaceWithGraphicParams
	mov	di, mask MF_RECORD or mask MF_STACK
	call	EncapsulateToTargetVisText

	add	sp, size ReplaceWithGraphicParams
	ret
		
StudioProcessInsertVariableGraphic	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioProcessInsertColumnBreak --
		MSG_STUDIO_PROCESS_INSERT_COLUMN_BREAK for StudioProcessClass

DESCRIPTION:	Insert a C_COLUMN_BREAK character

PASS:
	*ds:si - instance data
	es - segment of StudioProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 9/92		Initial version

------------------------------------------------------------------------------@
StudioProcessInsertColumnBreak	method dynamic	StudioProcessClass,
					MSG_STUDIO_PROCESS_INSERT_COLUMN_BREAK

SBCS <	mov	cx, (VC_ISCTRL shl 8) or VC_ENTER			>
DBCS <	mov	cx, C_SYS_ENTER						>
	mov	dx, (mask SS_LCTRL) shl 8
	mov	ax, MSG_META_KBD_CHAR

	mov	di, mask MF_RECORD
	call	EncapsulateToTargetVisText
	ret

StudioProcessInsertColumnBreak	endm

DocMiscFeatures ends

;---

DocSTUFF	segment resource

EncapsulateToTargetVisText	proc	far

	;
	; Encapsulate the message the caller wants, sending it to a VisText
	; object.
	; 
	push	si
	mov	bx, segment VisTextClass
	mov	si, offset VisTextClass
	call	ObjMessage
	pop	si

	;
	; Now queue the thing to the app target, since we can't rely on the
	; model hierarchy to match the target hierarchy (e.g. when editing
	; a master page, the StudioDocument still has the model, but the
	; StudioMasterPageContent object has the target). This bones anything
	; that must be synchronous, but such is life.
	; 
	mov	cx, di
	mov	dx, TO_APP_TARGET
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_FORCE_QUEUE		;keep that stack usage down
	call	ObjMessage
	ret

EncapsulateToTargetVisText	endp

DocSTUFF	ends

;---

HelpEditCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPStudioProcessLoadBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has selected something in BookFileSelector.
		If they have opened a file, call
		MSG_STUDIO_APPLICATION_LOAD_BOOK

CALLED BY:	MSG_STUDIO_PROCESS_LOAD_BOOK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioProcessClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPStudioProcessLoadBook		method dynamic StudioProcessClass,
						MSG_STUDIO_PROCESS_LOAD_BOOK

		GetResourceHandleNS	BookFileSelector, bx
		mov	si, offset BookFileSelector
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		clr	cx				;Don't need name.
		call	HE_ObjMessageCall
	;
	; See if something is being opened.  Exit if not.
	;
		test	bp, mask GFSEF_OPEN
		jz	noOpen
	;
	; Close the file selector's GenInteraction
	;
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	si, offset BookFileSelector
		call	HE_ObjMessageCall
	;
	; Tell the app to load the Book.
	;
		mov	cx, si
		mov	ax, MSG_STUDIO_APPLICATION_LOAD_BOOK
		call	GenCallApplication
noOpen:		
		ret
SPStudioProcessLoadBook		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessGenerateBookFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a content Book file from

CALLED BY:	MSG_STUDIO_PROCESS_GENERATE_BOOK_FILE
PASS:		*ds:si - instance data
		es - seg addr of StudioProcessClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessGenerateBookFile		method dynamic StudioProcessClass,
					MSG_STUDIO_PROCESS_GENERATE_BOOK_FILE
bookFile 	local	hptr
bookName	local	FileLongName
		.enter

	; go to the directory where the book file is located.

		call	SetBookFilePath
		cmp	ax, OBFE_NONE
		mov	ax, offset ErrorCreatingBookFileString
		jne	error

		clr	ss:bookFile
		mov	cx, ss
		lea	dx, ss:bookName
		mov	di, offset BookNameStatusBar
		call	OpenBookFile
		cmp	ax, OBFE_NONE
		je	haveFile
		
		mov	al, HFT_BOOK
		call	CreateFileLow		;bx <- file
		mov	ax, offset ErrorCreatingBookFileString
		jc	error

		mov	cx, (size BookFileHeader)	;cx <- size of block
		mov	ax, 0
		call	VMAlloc				;ax <- vm block
		call	VMSetMapBlock
		
haveFile:
		mov	ss:bookFile, bx
		push	bp
		call	VMGetMapBlock
		call	VMLock
		mov	es, ax
		mov	es:[BFH_protocolMajor], BOOK_FILE_PROTO_MAJOR
		mov	es:[BFH_protocolMinor], BOOK_FILE_PROTO_MINOR
		call	GenerateBookFileLow	;ax <- error string chunk 
		pushf
		call	VMDirty
		call	VMUnlock
		popf
		pop	bp
		jc	error			;destroy file on error???
		
done:
		tst	ss:bookFile
		jz	noFile
		mov	bx, ss:bookFile
		mov	al, FILE_NO_ERRORS
		call	VMClose

noFile:		
		call	FilePopDir
		.leave
		ret

error:
		call	DisplayError
		jmp	done
StudioProcessGenerateBookFile		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenBookFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a book file 

CALLED BY:	
PASS:		cx:dx - buffer for filename
		di - chunk handle of object with book name
RETURN:		carry flag clear if file was opened
			bx = file handle
			ax = OBFE_NONE
		carry set if couldn't open book
			ax = OBFE_NAME_NOT_FOUND if no name in passed object
			ax = OBFE_FILE_NOT_FOUND if no such file
			ax = OBFE_WRONG_PROTOCOL if wrong protocol
			ax = OBFE_ERROR_OPENING_FILE if file exists but can't
				be opened
DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenBookFile		proc	far
		uses	cx, dx
		.enter 

	; go to the directory where the book file is located.

		call	SetBookFilePath
		cmp	ax, OBFE_NONE
		jne	noBook

		call	GetBookName			;cx:dx <- filled w/name
		mov	ax, OBFE_NAME_NOT_FOUND
		jc	noBook

		mov	ds, cx				;ds:dx <- file name
		mov	ah, VMO_OPEN
		mov	al, mask VMAF_FORCE_READ_WRITE
		clr	cx
		call	VMOpen				;^hbx <- file
		jnc	verify
		mov	bx, OBFE_FILE_NOT_FOUND
		cmp	ax, VM_FILE_NOT_FOUND
		je	$10
		mov	bx, OBFE_ERROR_OPENING_FILE
$10:
		mov	ax, bx
		stc
		jmp 	noBook

verify:
		call	VerifyBookFile			;ax <- OpenBookFileErr
		cmp	ax, OBFE_NONE
		je	noBook
		push	ax
		mov	al, FILE_NO_ERRORS
		call	VMClose
		pop	ax
noBook:		
		call	FilePopDir
		.leave
		ret
OpenBookFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBookFilePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the proper director for the book file
		(as found in BookFileSelector)

CALLED BY:	OpenBookFile, StudioProcessGenerateBookFile
PASS:		nothing
RETURN:		ax = OBFE_NONE if no error setting path
			caller must call FilePopDir
		ax = OBFE_PATH_NOT_FOUND if could not set path

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBookFilePath		proc	far
		uses	cx, dx, si, ds, bp
		.enter

		call	FilePushDir
		
		sub	sp, size PathName
		mov	dx, ss
		mov	bp, sp				;dx:bp <- path buffer
		GetResourceHandleNS	BookFileSelector, bx
		mov	si, offset BookFileSelector
		mov	ax, MSG_GEN_PATH_GET		;cx <- disk handle
		call	HE_ObjMessageCall

		mov	ds, dx
		mov	dx, bp				;ds:dx <- path buffer
		mov	bx, cx
		call	FileSetCurrentPath		;carry set if error
		mov	ax, OBFE_NONE
		jnc	done
		mov	ax, OBFE_PATH_NOT_FOUND
done:
		add	sp, size PathName
		.leave
		ret
SetBookFilePath		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBookName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get book name from text object or file selector.

CALLED BY:	OpenBookFile
PASS:		di - chunk of object which has book name
		cx:dx - buffer to hold name
RETURN:		carry set if no book name
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBookName		proc	near
		uses	si,cx,dx,bp
		.enter
		cmp	di, offset BookFileSelector	
		je	fileSelector
		call	GetNameFromText			; Z set if no name
		jz	error
		clc
done:
		.leave
		ret

fileSelector:
		call	GetFileSelectorSelection
		jnz	error			; any selection?
		andnf	bp, mask GFSEF_TYPE	
		cmp	bp, (GFSET_FILE shl offset GFSEF_TYPE)	
		jne	error
		clc
		jmp	done

error:
		stc
		jmp	done
GetBookName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyBookFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for right protocol.  Destroy map block if out
		of date.

CALLED BY:	StudioProcessGenerateBookFile
PASS:		^hbx - book file
RETURN:		ax = OpenBookFileError
			= OBFE_NONE if is a valid book file
			= OBFE_NOT_BOOK_FILE if not a book file
			= OBFE_WRONG_PROTOCOL if out of date
DESTROYED:	cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyBookFile		proc	near
		uses	bp
		.enter
	;
	; Check the token for the file
	;
		mov	cx, (size GeodeToken)	
		sub	sp, cx
		segmov	es, ss, ax
		mov	di, sp			;es:di <- ptr to buffer
		mov	ax, FEA_TOKEN		;ax <- FileExtendedAttribute
		call	FileGetHandleExtAttributes
		mov	ax, OBFE_NOT_BOOK_FILE
		jc	restoreStack

		cmp	es:[di].GT_manufID, MANUFACTURER_ID_GEOWORKS
		jne	restoreStack
		cmp	{word}es:[di].GT_chars, 'c' or ('n' shl 8)
		jne	restoreStack
		cmp	{word}es:[di+2].GT_chars, 't' or ('b' shl 8)
		jne	restoreStack
		add	sp, size GeodeToken
	;
	; Check the file protocol
	;
		call	VMGetMapBlock
		call	VMLock
		mov	es, ax
		mov	ax, OBFE_WRONG_PROTOCOL
		cmp	es:[BFH_protocolMajor], BOOK_FILE_PROTO_MAJOR
		jne	done
		cmp	es:[BFH_protocolMinor], BOOK_FILE_PROTO_MINOR
		jne	done
		mov	ax, OBFE_NONE
done:
		call	VMUnlock
exit:		
		.leave
		ret
restoreStack:		
		add	sp, size GeodeToken
		jmp	exit
VerifyBookFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNameFromText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name for the book 

CALLED BY:	INTERNAL
PASS:		cx:dx - buffer for name
		di - chunk handle of text object
RETURN:		zero flag set if no name
DESTROYED:	ax, bx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNameFromText		proc	far
		uses	bx, cx, dx, si, bp
		.enter inherit 

		mov	bp, cx
		xchg	dx, bp			; dx:bp <- name buffer

		GetResourceHandleNS	BookNameText, bx
		mov	si, di
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	HE_ObjMessageCall
		tst	cx
		.leave
		ret
GetNameFromText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateBookFileLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the dirty work of writing stuff to file

CALLED BY:	StudioProcessGenerateBookFile
PASS:		^hbx - book file
		es - segment of map block
RETURN:		carry set if error,
			ax - chunk handle of error string
DESTROYED:	bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateBookFileLow		proc	near
		uses	bp
		.enter 

		mov	si, offset ViewerFeaturesList
		call	GetViewerFlags		;ax <- flags
		mov	es:[BFH_featureFlags], ax
		mov	si, offset ViewerToolsList
		call	GetViewerFlags		;ax <- flags
		mov	es:[BFH_toolFlags], ax

	; book title boolean is set by user in features list, and we
	; want tool flags to have that bit set similarly
		
		ornf	es:[BFH_toolFlags], mask BFF_BOOK_TITLE	
		test	es:[BFH_featureFlags], mask BFF_BOOK_TITLE
		jnz	$10
		andnf	es:[BFH_toolFlags], not mask BFF_BOOK_TITLE
$10:		
		mov	cx, es
		lea	dx, es:[BFH_path]
		mov	di, offset BookPathFileSelector
		call	GetPathName
		jc	error			;no selection? no bookname

		call	GetFirstPageInfo
;;		jc	error

		call	GetFileCount		;cx <- # content files
		tst	es:[BFH_count]		;# of files in old list
		jz	noNames			;no files?
		mov	ax, es:[BFH_nameList]
EC <		tst	ax						>
EC <		ERROR_Z	-1 						>
		call	VMFree
noNames:
		mov	es:[BFH_count], cx	;save # of files in list
	;
	; alloc a new vm block
	;
		call	getListSize			;ax <- list size
		mov	cx, ax				;cx <- size to alloc
		jcxz	noList				;if cx=0, ax=0
		mov	ax, 0
		call	VMAlloc				;ax <- vm block
noList:
		mov	es:[BFH_nameList], ax
		call	GetContentFileNames
		clc
error:
		.leave
		ret

getListSize:
		clr	dx
		mov	ax, size FileLongName
		mul	cx				;ax <- list size
EC <		tst	dx						>
EC <		ERROR_NZ	INVALID_CONTENT_FILE_LIST_LENGTH	>
		retn
GenerateBookFileLow		endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetViewerFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get viewer tool flags

CALLED BY:	GenerateBookFileLow
PASS:		si - chunk handle of GenBooleanGroup
RETURN:		ax - ViewerToolFlags
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetViewerFlags		proc	near
		uses	bx, di
		.enter
	;
	; Get the flags into ax
	;
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		GetResourceHandleNS	ViewerToolsList, bx
		call	HE_ObjMessageCall
		.leave
		ret
GetViewerFlags		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPathName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	
SYNOPSIS:	Get the full pathname from a file selector

CALLED BY:	INTERNAL

PASS:		cx:dx	- buffer for path name
		di - chunk handle of file selector
RETURN:		Carry set did not get the file name,
			cx:dx = null
			ax = error string chunk handle
		Carry clear if got file name
			cx:dx = contains name
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPathName		proc	far
		uses	bx, si, bp, es
		.enter

		GetResourceHandleNS	BookPathFileSelector, bx
		mov	si, di
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
		call	HE_ObjMessageCall

		mov	es, cx
		mov	si, dx
SBCS <		cmp	{byte}es:[si], 0				>
		mov	ax, offset BadBookPathString
		stc				; assume it is NULL
		jz	done
		clc
done:
		.leave
		ret
GetPathName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get number of files currently in list

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		cx - number of files
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileCount		proc	near
		uses	ax, bx, dx, si, di, bp
		.enter

		GetResourceHandleNS	BookContentFileList, bx
		mov	si, offset BookContentFileList
		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		call	HE_ObjMessageCall

		.leave
		ret
GetFileCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFirstPageInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the first page info into the BookFileHeader

CALLED BY:	GenerateBookFileLow
PASS:		es  - segment of BookFileHeader
		cx - number of content files
RETURN:		carry set if error
			ax - error string
DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFirstPageInfo		proc	near
		uses	bx, cx, dx
		.enter

	; get the file name

		call	GetMainFileSelection
		mov	bx, offset NoMainFileWarningString
		jc	warning
		mov	es:[BFH_firstFile], ax

		mov	cx, es
		lea	dx, es:[BFH_firstPage]
		mov	di, offset FirstPageContextName
		call	GetNameFromText
		clc
		jnz	done
		mov	bx, offset FirstPageEmptyWarningString
		stc
warning:
	;
	; Something's wrong...warn the user
	;
;;		pushf
;;		mov	ax, (CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
;;			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
;;		call	PutupHelpBox
;;		popf

done:		
		.leave
		ret
GetFirstPageInfo		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		ax - file number
RETURN:		es:ax - file name
		bx - handle of file list (must be unlocked by caller)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileName		proc	near
		uses	cx
		.enter

		push	ax
		segmov	es, dgroup, ax
		mov	bx, es:contentFileList
		call	MemLock
		mov	es, ax
EC <		mov	ax, MGIT_SIZE					>
EC <		call	MemGetInfo					>
EC <		mov	cl, size FileLongName				>
EC <		div	cl						>
EC <		mov	cx, ax						>
EC <		pop	ax						>
EC <		push	ax						>
EC <		cmp	ax, cx						>
EC <		ERROR_AE INVALID_CONTENT_FILE_LIST_LENGTH		>

		pop	ax
		mov	cl, size FileLongName
		mul	cl			;ax <- offset to entry
		.leave
		ret
GetFileName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMainFileSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selected file number

CALLED BY:	GetFirstPageInfo
PASS:		nothing
RETURN:		ax - file number
		carry set if no selection
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMainFileSelection		proc	near
		uses	bx, si, cx, dx, bp
		.enter

		GetResourceHandleNS	MainFileList, bx
		mov	si, offset MainFileList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	HE_ObjMessageCall
		jc	done
		clc
done:
		.leave
		ret
GetMainFileSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContentFileNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the content file names to the book file

CALLED BY:	GenerateBookFileLow
PASS:		bx - book file handle
		es - map block
RETURN:		nothing
DESTROYED:	ax,cx,dx,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContentFileNames		proc	near
		uses	bx, es
		.enter

		mov	cx, es:[BFH_count]
		jcxz	done
		mov	ax, es:[BFH_nameList]
		call	VMLock			;bp - handle to use for unlock
		mov	es, ax

		GetResourceSegmentNS	dgroup, ds
		mov	bx, ds:contentFileList
EC <		call	ECCheckMemHandle				>
		call	MemLock
		mov	ds, ax

		mov	ax, cx
		mov	cl, size FileLongName
		mul	cl
		shr	ax
		mov	cx, ax
		
		clr	si, di
		rep	movsw

		call	VMDirty
		call	VMUnlock
		call	MemUnlock
done:
		.leave
		ret
GetContentFileNames		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessGetContentFileMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for an entry in the content file list

CALLED BY:	MSG_STUDIO_PROCESS_GET_CONTENT_FILE_MONIKER
PASS:		bp	= index of needed moniker
		^lcx:dx	= list requesting it
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessGetContentFileMoniker method dynamic StudioProcessClass,
			MSG_STUDIO_PROCESS_GET_CONTENT_FILE_MONIKER

		pushdw	cxdx
		mov	ax, bp
		call	GetFileName			;es:ax <- filename
		movdw	cxdx, esax			;cx:dx <- filename
		mov	ax, bx				;ax <- handle of list
		popdw	bxsi

		push	ax
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	HE_ObjMessageCall
		pop	bx

		call	MemUnlock			;unlock file list
		ret
StudioProcessGetContentFileMoniker		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessAddContentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a content file to the Book's list of files

CALLED BY:	MSG_STUDIO_PROCESS_ADD_CONTENT_FILE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioProcessClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessAddContentFile		method dynamic StudioProcessClass,
					MSG_STUDIO_PROCESS_ADD_CONTENT_FILE

	; get the name of the file to add
		
		sub	sp, size FileLongName
		mov	dx, sp
		mov	cx, ss				;cx:dx = buffer

		mov	di, offset ContentFileNameText
		call	GetNameFromText
EC <		ERROR_Z STUDIO_NULL_CONTENT_FILE_NAME			>
		
		mov	bx, es:contentFileList
		call	CheckForDuplicateFile
		jz	noAdd
	;
	; Save the current Main Files list selection so as to restore
	; it later. If the selection is GIGS_NONE, that means we are
	; now adding the very first file, so we'll "restore" the
	; selection to be the first item in the list. Leaving a GIGS_NONE
	; selection around to be saved as the BFH_firstFile index can
	; wind up crashing Book Reader if users forget ever to set the
	; selection themselves. - jenny, 8/03/94
	;
		call	GetMainFileSelection		;ax <- selection #
		cmp	ax, GIGS_NONE
		jne	saveSelection
CheckHack <GIGS_NONE eq -1>
		inc	ax				; ax <- first item
saveSelection:
		mov	bp, ax
	
		movdw	dssi, cxdx
		
	; resize the block to make room for one more entry
		
		call	AllocOrReAllocBlock	;cx:dx = new entry ptr
						;ax = file count, ^hbx = list
		mov	es:contentFileList, bx

	; copy the file name to the list
		
		movdw	esdi, cxdx
		mov	cx, size FileLongName/2
		rep	movsw

		mov	cx, ax				;cx <- new count
		call	InitializeContentFileList

		call	MemUnlock

	; reset the main file selection

		mov	cx, bp	
		call	SetMainFileSelection		

done:
		add	sp, size FileLongName

	; remove the name from the text field
		
		GetResourceHandleNS	ContentFileNameText, bx
		mov	si, offset ContentFileNameText
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	HE_ObjMessageSend

		ret

noAdd:
		mov	ax, offset FileAlreadyInListString
		call	DisplayError
		jmp	done
StudioProcessAddContentFile		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForDuplicateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if passed name is already in file list

CALLED BY:	StudioProcessAddContentFile, 
PASS:		^hbx - file list
		cx:dx - file name
RETURN:		zero flag set if name is in list
			ax - index of name
		zero flag clear if file name is not in list
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForDuplicateFile		proc	near
		uses	cx, dx, si, di, ds, es
		.enter

		movdw	dssi, cxdx
		call	GetFileCount			;cx <- # files in list
		tst	cx
		jz	notFound
		
EC <		call	ECCheckMemHandle				>
		call	MemLock
		mov	es, ax
		clr	di
		mov	dx, cx
		clr	ax, cx				;strings are null-term
		
checkLoop:
		call	LocalCmpStrings
		jz	foundIt
		add	di, size FileLongName
		inc	ax
		cmp	ax, dx
		jne	checkLoop

		call	MemUnlock
notFound:
		or	cx, 1				;clears zero flag
foundIt:		
		.leave
		ret
CheckForDuplicateFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocOrReAllocBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	alloc or realloc block with room for new entry

CALLED BY:	StudioProcessAddContentFile
PASS:		bx - block handle
RETURN:		cx:dx - offset to new entry in block
		bx - block handle
		ax - file count
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocOrReAllocBlock		proc	near
		.enter

		tst	bx
		jz	alloc

		call	GetFileCount		;cx = count
		clr	dx
		mov	ax, size FileLongName
		mul	cx
EC <		tst	dx						>
EC <		ERROR_NZ INVALID_CONTENT_FILE_LIST_LENGTH		>

		inc	cx
		push	cx			;save new count
		push	ax			;save offset to new entry
		add	ax, size FileLongName	;ax = new size
		mov	ch, mask HAF_NO_ERR or mask HAF_LOCK
		call	MemReAlloc
		mov	cx, ax
		pop	dx			;cx:dx <- offset to new entry
		pop	ax			;ax <- # files in list
done:
		.leave
		ret
alloc:
		mov	ax, size FileLongName
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	cx, ax
		clr	dx
		mov	ax, 1
		jmp	done
AllocOrReAllocBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeContentFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the content file list

CALLED BY:	INTERNAL
PASS:		cx - number of items in list
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeContentFileList		proc	far
		uses	bx,cx,si,bp
		.enter
		push	cx
		GetResourceHandleNS	BookContentFileList, bx
		mov	si, offset BookContentFileList
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	HE_ObjMessageSend
		pop	cx
		
		mov	si, offset MainFileList
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	HE_ObjMessageSend

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	si, offset BookContentFileRemoveTrigger
		call 	SetStateLow

		.leave
		ret
InitializeContentFileList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessRemoveContentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a content file from the Book's list of files

CALLED BY:	MSG_STUDIO_PROCESS_REMOVE_CONTENT_FILE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - segment of StudioProcessClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessRemoveContentFile		method dynamic StudioProcessClass,
					MSG_STUDIO_PROCESS_REMOVE_CONTENT_FILE

		call	GetFileCount		;cx <- # entries in list
EC <		tst	cx						>
EC <		ERROR_Z CONTENT_FILE_LIST_IS_EMPTY			>

	;
	; Create a buffer large enough to hold all entries, and one filename
	;
		mov	ax, cx
		mov	bp, ax			;save # selections in bp
		mov	cl, size word
		mul	cl			;ax <- size needed for selects.
		add	ax, size FileLongName	;add room for main file name
		
		sub	sp, ax
		mov	di, sp			;ss:di <- buffer for file name
		mov	dx, di			;ss:dx <- buffer
		push	ax			;save buffer size
	;
	; Copy the name of the Main file to the buffer
	;
		mov	{char}ss:[di], 0	;assume no main file yet
		call	GetMainFileSelection	;ax <- main file #
		cmp	ax, -1
		je	noMainFile
		call	GetFileName		;es:ax <- filename

		push	ds, si
		segmov	ds, es, si
 		mov	si, ax			;ds:si <- filename
		segmov	es, ss, ax		;es:di <- buffer
		mov	cx, size FileLongName
		rep	movsb
		pop	ds, si
		call	MemUnlock		;unlock file list
noMainFile:
		push	dx
		add	dx, size FileLongName
		mov	cx, ss			;cx:dx <-buffer for selections
	;
	; Get the selected file numbers into the buffer
	; 	bp = max number to get (= # items selected)
	;
		GetResourceHandleNS	BookContentFileList, bx
		mov	si, offset BookContentFileList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
		call	HE_ObjMessageCall		;ax = num selections
	;
	; Remove the selected files from the list
	;
		call	RemoveFilesFromList	;cx = num files remaining
						; old list is locked
		segmov	es, dgroup, ax
		xchg	bx, es:contentFileList	;store the new list handle
EC <		call	ECCheckMemHandle				>
		call	MemFree			;free the old list
	;
	; Reinitialize the list with the new number of files
	;
		call	InitializeContentFileList
	;
	; Now that the list has been reinitialized, see if the saved
	; filename appears in the list, and if so, where it appears
	; in the list.
	;
		pop	dx			;ss:dx <- Main file name
		mov	cx, ss			;cx:dx <- main file name
		mov	bx, es:contentFileList	;get the new list handle
		call	CheckForDuplicateFile	;ax <- file number
		jnz	notInList
	;
	; The main file is still in the list, so select it.
	;
		mov	cx, ax
		call	SetMainFileSelection
		
notInList:		
		pop	ax
		add	sp, ax
		ret
StudioProcessRemoveContentFile		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveFilesFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has removed some files from content list.
		Update the contentFileList block.

CALLED BY:	StudioProcessRemoveContentFile
PASS:		ss:dx - list of selections to remove
		ax - number of files in list
		es - dgroup
RETURN:		cx - new number of files
		bx - new block
		old contentFileList is locked
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFilesFromList		proc	near
		uses	bp,es
		.enter

		call	GetFileCount		;cx <- count
		sub	cx, ax			;cx <- number file remaining
		clr	bx			;assume none left
		tst	cx
		LONG	jz	noFiles
		push	cx			;save # entries left

	; lock the old file list

		mov	bp, dx
		mov	cx, ax			;cx <- number of entries 
						;  to remove
		mov	bx, es:contentFileList
EC <		call	ECCheckMemHandle				>
		call	MemLock
		mov	es, ax
		clr	di

	; zero out the names which are to be removed
		
removeLoop:
		mov	ax, ss:[bp]		;ax <- entry to remove
		mov	dl, size FileLongName
		mul	dl
		mov	di, ax			;es:di <- file name
		mov	{char}es:[di], 0	;null it out
		add	bp, size word		;set up for next entry
		loop	removeLoop

	; allocate a block to hold the new list

		segmov	ds, es, ax
		pop	ax			;ax <- # entries in new list
		push	ax
		mov	cl, size FileLongName
		mul	cl
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc		;bx <- new block
		mov	es, ax
		clr	di			;es:di <- new list
		clr	si			;ds:si <- old list

	; copy old list to new list
		call	GetFileCount		;cx <- old count
copyLoop:
		tst	{char}ds:[si]
		jz	noCopy
		push	cx
		mov	cx, size FileLongName / 2
		rep	movsw
		pop	cx
		jmp	continue		;si, di are updated
noCopy:
		add	si, size FileLongName	;ds:si <- next in old list
continue:
		loop	copyLoop

		pop	cx			;cx <- # entries left
		call	MemUnlock		
noFiles:
		.leave
		ret
RemoveFilesFromList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessContentSelectionChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has changed the content file selection.  Update the
		Remove File trigger accordingly.

CALLED BY:	MSG_STUDIO_PROCESS_CONTENT_SELECTION_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - segment of StudioProcessClass
		ax - the message
		cx - entry # of selection
		bp - GenFileSelectorEntryFlags
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessContentSelectionChanged	method dynamic StudioProcessClass,
				MSG_STUDIO_PROCESS_CONTENT_SELECTION_CHANGED
		
		mov	ax, MSG_GEN_SET_ENABLED
		tst	bp
		jnz	setState
		mov	ax, MSG_GEN_SET_NOT_ENABLED

setState:
		mov	si, offset BookContentFileRemoveTrigger
		FALL_THRU 	SetStateLow
StudioProcessContentSelectionChanged		endm

;---

SetStateLow	proc	far
		GetResourceHandleNS	BookContentFileRemoveTrigger, bx
		mov	dl, VUM_NOW
		call	HE_ObjMessageSend
		ret
SetStateLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessDefineBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has just named a new book.

CALLED BY:	MSG_STUDIO_PROCESS_DEFINE_BOOK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioProcessClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessDefineBook		method dynamic StudioProcessClass,
					MSG_STUDIO_PROCESS_DEFINE_BOOK
	;
	; Set BookFileSelector path to SP_DOCUMENT so OpenBookFile()
	; will work properly.
	;
		sub	sp, size FileLongName
		mov	bp, sp
		mov	{char}ss:[bp], 0		;no subdirectory
		mov	cx, ss
		mov	dx, sp				;cx:dx <- subdir

		GetResourceHandleNS	BookFileSelector, bx
		mov	si, offset BookFileSelector
		mov	bp, SP_DOCUMENT
		mov	ax, MSG_GEN_PATH_SET
		call	HE_ObjMessageCall
EC <		ERROR_C -1						>
	;
	; See if we can open a file with this name
	;
		mov	cx, ss
		mov	dx, sp				;cx:dx <- name buffer
		mov	di, offset BookNameText	
		call	OpenBookFile
		cmp	ax, OBFE_FILE_NOT_FOUND
		jne	fileExists
continue:
	;
	; Reset UI for defining a new book
	;
 		call	ResetBookInfoCommon
	;
	; Change the name in the status bar
	;
		mov	si, offset BookNameStatusBar
		call	SetText
		add	sp, size FileLongName
	;
	; Now that a book has been specified, enable other book gadgetry
	;
		mov	ax, MSG_GEN_SET_ENABLED
		mov	si, offset ManageFilesTrigger
		call	SetStateLow
		mov	ax, MSG_GEN_SET_ENABLED
		mov	si, offset BookOptionsTrigger
		call	SetStateLow

		call	StudioProcessSaveBookOptions
		ret
		
		
fileExists:
	;
	; If there was no error when opening the file, bx = file handle
	; and we must close it now.
	;
		mov	si, offset QueryReplaceBookFile
		cmp	ax, OBFE_WRONG_PROTOCOL
		je	$10
		cmp	ax, OBFE_NONE
		jne	$20
		clr	ax
		call	VMClose
$10:
		call	DisplayQuestion
		cmp	ax, IC_YES
		je	continue
		jmp	clearName
$20:
		mov	si, offset NameInUseString
		cmp	ax, OBFE_NOT_BOOK_FILE
		je	$30
		mov	si, offset ErrorCreatingBookFileString
$30:
		mov	ax, si
		call	DisplayError
		jmp	noClear
clearName:
		GetResourceHandleNS	BookNameText, bx
		mov	si, offset BookNameText
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	HE_ObjMessageSend
noClear:
		add	sp, size FileLongName
		ret
StudioProcessDefineBook		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessSaveBookOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has just named a new book.

CALLED BY:	MSG_STUDIO_PROCESS_SAVE_BOOK_OPTIONS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioProcessClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessSaveBookOptions		method StudioProcessClass,
					MSG_STUDIO_PROCESS_SAVE_BOOK_OPTIONS

		mov	ax, MSG_STUDIO_PROCESS_GENERATE_BOOK_FILE
		call	GeodeGetProcessHandle
		clr	si
		mov	di, mask MF_FORCE_QUEUE
		GOTO	ObjMessage
StudioProcessSaveBookOptions		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioProcessBookFeaturesChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has changed the book's features.  Update the 
		Tool features accordingly.

CALLED BY:	MSG_STUDIO_PROCESS_BOOK_FEATURES_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - segment of StudioProcessClass
		ax - the message
		cx - selected booleans

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioProcessBookFeaturesChanged	method dynamic StudioProcessClass,
				MSG_STUDIO_PROCESS_BOOK_FEATURES_CHANGED

		mov	dx, cx
		mov	bx, offset toolFeatureTable
		mov	cx, length toolFeatureTable	;cx <- # table entries
enableLoop:
		mov	ax, MSG_GEN_SET_NOT_ENABLED	;assume not selected
		shr	dx				;get the next flag
		jnc	haveMessage			;is this feature set?
		mov	ax, MSG_GEN_SET_ENABLED		;yes, enable tool bool
haveMessage:
		mov	si, cs:[bx]			;get chunk handle
		tst	si
		jz	noBoolean

		push	bx, cx, dx
	;
	; if we're about to disable the tool item, make sure the tool
	; item is not selected
	;
		cmp	ax, MSG_GEN_SET_ENABLED
		je	setState
		push	ax
		GetResourceHandleNS	ViewerToolsList, bx
		mov	ax, MSG_GEN_BOOLEAN_GET_IDENTIFIER
		mov	di, mask MF_CALL
		call	ObjMessage			;ax <- identifier

		push	si
		mov	cx, ax
		clr	dx				;zero to unselect
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
		mov	si, offset ViewerToolsList
		mov	di, mask MF_CALL
		call	ObjMessage			;ax <- identifier
		pop	si
		pop	ax
		
setState:		
		call	SetStateLow
		pop	bx, cx, dx
noBoolean:
		add	bx, size nptr
		loop	enableLoop
		
		ret		
StudioProcessBookFeaturesChanged		endm

;
; Important: This list of chunks in the ViewerToolFeatures GenBooleanGroup
;	     is in reverse order with respect to the BookFeatureFlags.
;
toolFeatureTable	nptr		\
	offset	ViewerToolBackBoolean,
	offset	ViewerToolPrevNextPageBoolean,
	offset	ViewerToolHistoryListBoolean,
	offset  ViewerToolMainPageBoolean,
	0, 0, 0, 0, 0, 0, 0, 0, 0,
	offset	ViewerToolSendBoolean,
	offset	ViewerToolFindBoolean

.assert (offset BFF_BACK eq 0)
.assert (offset BFF_PREV_NEXT eq 1)
.assert (offset BFF_HISTORY eq 2)
.assert (offset BFF_MAIN_PAGE eq 3)
.assert (offset BFF_UNUSED eq 4)
.assert (offset BFF_SEND eq 13)
.assert (offset BFF_FIND eq 14)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileSelectorSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection from a file selector

CALLED BY:	INTERNAL
PASS:		cx:dx - buffer for name
		di - chunk of file selector
RETURN:		zero flag set if got a selection
		zero flag clear if nothing selected
		bp - GenFileSelectorEntryFlags
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileSelectorSelection		proc	near
		uses	bx, si, di
		.enter

	; get the path name from the file selector (they're all in
	; the same resource)

		GetResourceHandleNS	BookPathFileSelector, bx
		mov	si, di
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		call	HE_ObjMessageCall

		test	bp, mask GFSEF_NO_ENTRIES
		jnz	done
		xor	ax, ax				;sets zero flag
done:
		.leave
		ret
GetFileSelectorSelection		endp

HelpEditCode ends

