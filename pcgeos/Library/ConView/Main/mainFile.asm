COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	ConView Library
MODULE:		Main
FILE:		mainFile.asm

AUTHOR:		Jonathan Magasin, May 10, 1994

METHODS:
	Name			Description
	----			-----------
MSG_CGV_LOAD_CONTENT_FILE	Load and display a specific content file.

ROUTINES:

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/10/94   	Initial revision


DESCRIPTION:
	Code for dealing with content files.

	$Id: mainFile.asm,v 1.1 97/04/04 17:49:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BookFileCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVLoadContentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load and display a specific content file.

CALLED BY:	MSG_CGV_LOAD_CONTENT_FILE
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #

		ss:bp - ContentTextRequest
			- CTR_diskhandle set to content file disk, 
				or StandardPath constant
			- CTR_pathname set to content file path
			- CTR_bookname set to book file (null if no book
				associated with this content file)
			- CTR_filename set to content file to open
			- CTR_context set to page to load
			- CTR_featureFlags set to the features to enable.
			- CTR_toolFlags set to the tools to enable.
			- CTR_flags 
			    CTRF_noBookFile
				= 1 if there is not a book file associated
				  with this content file, which will disable
				  ability to have the bookname as the primary
				  moniker.
				= 0 if there is a book file associated with
				  this content file.

RETURN:		carry set if error loading file, error message displayed, 
		ax 	- LoadFileError
			  LFE_NO_ERROR if file successfully loaded
			  LFE_ERROR_SETTING_PATH if error setting path
			  LFE_ERROR_DISPLAYING_FILE if error opening and 
				displaying file
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVLoadContentFile	method dynamic ContentGenViewClass, 
					MSG_CGV_LOAD_CONTENT_FILE
	.enter

	test	ss:[bp].CTR_flags, mask CTRF_noBookFile
	jnz	noBookFile

afterBookname:
	;
	; Set path and diskhandle so the ContentGenView knows where 
	; to find files. (DisplayText won't take care of this field.)
	;
	push 	bp
	mov	cx, ss
	lea	dx, ss:[bp].CTR_pathname	;cx:dx <- ptr to path
	mov	bp, ss:[bp].CTR_diskhandle	;bp <- disk handle
	mov	ax, MSG_GEN_PATH_SET
	call	ObjCallInstanceNoLock
	pop	bp
	jc	pathError
	;
	; Ask self to load and display the content file.
	;
	mov	ax, MSG_CGV_DISPLAY_TEXT
	call	ObjCallInstanceNoLock
	mov	ax, LFE_ERROR_DISPLAYING_FILE		; assume error
	jc	exit					; return error

	mov	ax, LFE_NO_ERROR
exit:
	.leave
	ret

noBookFile:
	push	bp
	mov	cx, CONTENT_BOOKNAME
	mov	dx, CONTENT_COVER_PAGE
	clr	bp		
	call	ObjVarDeleteDataRange
	pop	bp
	;
	; Save main file to vardata.
	; The main file is used by the begin tool.
	;
	mov	bx, ss
	mov	ax, CONTENT_MAIN_FILE or mask VDF_SAVE_TO_STATE
	lea	dx, ss:[bp].CTR_filename
	call	ContentAddStringVardata
	;
	; Save feature and tool flags to instance data.
	; If there is no book file associated with this content file,
	; disable the book title feature.
	;
	call	CGVCheckToDisableBegin
EC <	call	AssertIsCGV				>
	mov	di, ds:[si]
	add	di, ds:[di].ContentGenView_offset
	mov	ax, ss:[bp].CTR_featureFlags
	BitClr	ax, BFF_BOOK_TITLE
	mov	ds:[di].CGVI_bookFeatures, ax
	mov	ax, ss:[bp].CTR_toolFlags
	BitClr	ax, BFF_BOOK_TITLE
	mov	ds:[di].CGVI_bookTools, ax

	call	ContentSendBookNotification
	jmp	afterBookname
		
pathError:
	mov	ax, LFE_ERROR_SETTING_PATH
	call	ReportLoadFileError
	stc						; carry <- error
	jmp	exit

CGVLoadContentFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVCheckToDisableBegin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the BFF_MAIN_PAGE flag from ContentTextRequest
		if there is no page named TOC in the main file.

CALLED BY:	CGVLoadBookLow, CGVLoadContentFile
PASS:		*ds:si	= ContentGenViewClass object
		ss:bp - ContentTextRequest
			CTR_filename - name of main file
RETURN:		CTR_flags modified if there is no main page
		ds - fixed up to point at the object block
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVCheckToDisableBegin		proc	near
		uses	si, bp
		.enter
	;
	; First, see if either the Begin tool or feature is desired
	;
		mov	ax, ss:[bp].CTR_featureFlags
		or	ax, ss:[bp].CTR_toolFlags
		test	ax, mask BFF_MAIN_PAGE
		LONG	jz	done
	;
	; Set path and diskhandle since that may not have been done yet
	;
		push 	bp
		mov	cx, ss
		lea	dx, ss:[bp].CTR_pathname	;cx:dx <- ptr to path
		mov	bp, ss:[bp].CTR_diskhandle	;bp <- disk handle
		mov	ax, MSG_GEN_PATH_SET
		call	ObjCallInstanceNoLock
		pop	bp
		LONG	jc	done
	;
	; Try to open the main file
	;
		call	MFOpenFile
		LONG	jc	done

		push	bp
	;
	; Get the name array
	;
		call	DBLockMap
EC <		tst	di				;>
EC <		ERROR_Z HELP_FILE_HAS_NO_MAP_BLOCK	;>
		mov	di, es:[di]		;es:di <- ptr HelpFileMapBlock
		mov	ax, es:[di].CFMB_names	;ax <- VM handle of names
		call	DBUnlock

		push	ds			; save obj block segment
		call	VMLock
		mov	ds, ax
	;
	; See if there is a TOC name defined for this file
	;
		sub	sp, size ContentFileNameData
		mov	si, sp
		push	bx

		mov	bx, handle ContentStrings
		call	MemLock
		mov	es, ax
		mov	di, offset tocString	
		mov	di, es:[di]			;es:di <- ptr to "TOC"

		mov	ax, si
		mov	dx, ss				;dx:ax <- name buffer
		clr	cx 				;name is null-term,
		mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si <- name array
		call	NameArrayFind			;ax <- name token

		call	MemUnlock			;unlock ContentStrings
		mov	bp, ds:[LMBH_handle]
		call	VMUnlock			;unlock NameArray

		pop	bx
		push	ax
		clr	al				;no errors
		call	VMClose				;close the file
		pop	ax
	;
	; If there an element named TOC, it must be a context in
	; the current file, with a help item.
	;
		mov	si, sp
		cmp	ax, CA_NULL_ELEMENT
		je	notFound
		cmp	ss:[si].CFND_text.VTND_type, VTNT_CONTEXT
		jne	notFound
		cmp	ss:[si].CFND_text.VTND_file,VIS_TEXT_CURRENT_FILE_TOKEN
		jne	notFound
		tst	ss:[si].CFND_text.VTND_helpText.DBGI_item
		jz	notFound

		add	sp, size ContentFileNameData
		pop	ds			; restore obj block segment
		pop	bp
done:
		.leave
		ret
notFound:
		add	sp, size ContentFileNameData
		pop	ds			; restore obj block segment
		pop	bp
		BitClr 	ss:[bp].CTR_featureFlags, BFF_MAIN_PAGE
		BitClr	ss:[bp].CTR_toolFlags, BFF_MAIN_PAGE
		jmp	done
CGVCheckToDisableBegin		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MFChangeToBookDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes to the book's content file directory

CALLED BY:	INT - utility
PASS:		*ds:si - ContentGenView
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MFChangeToBookDirectory		proc	near
	uses	ax, bx, dx
	.enter
	;
	; See if there is a custom directory
	;
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	jnc	useHelpDir			;branch if attr does not exist
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	jnc	gotDirectory			;branch if no error
useHelpDir:
	;
	; Change to the help file directory
	;
	mov	ax, SP_HELP_FILES		;ax <- StandardPath
	call	FileSetStandardPath
gotDirectory:
	.leave
	ret
MFChangeToBookDirectory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MFOpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the content file

CALLED BY:	
PASS:		*ds:si - ContentGenView
		ss:bp - ContentTextRequest
			CTR_filename - name of help file to open
RETURN:		bx - handle of help file
		ax - FileFlags
		carry - set if error
		    di - chunk of an appropriate error message
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MFOpenFile		proc	far
	uses	dx, es
	.enter	
EC <	call	AssertIsCGV				>
	;
	; Save The current directory, go to the book's directory
	;
	call	FilePushDir
	call	MFChangeToBookDirectory
	;
	; Try to open the file
	;
	push	bp, ds
	lea	dx, ss:[bp].CTR_filename
	segmov	ds, ss, ax			;ds:dx <- ptr to filename
	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_FORCE_READ_ONLY or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx				;cx <- system compression
	call	VMOpen
	pop	bp, ds
	mov	di, offset ErrorFileNotFound	;di <- chunk of error message
	jc	error

	mov	al, HFT_CONTENT
	call	VerifyHelpFile
	mov	di, offset ErrorInvalidContentFile
	jc	errorCloseFile
	;
	; Get the map block and check the protocol
	;
	call	DBLockMap
	tst	di
	jz	errorNoMap
		
	mov	di, es:[di]
	mov	ax, es:[di].CFMB_flags
	mov	cx, es:[di].CFMB_protocolMajor
	mov	dx, es:[di].CFMB_protocolMinor
	call	DBUnlock
	mov	di, offset ErrorBadProtocol	;di <- chunk of error message
	cmp	cx, CONTENT_FILE_PROTO_MAJOR
	jne	errorCloseFile
	cmp	dx, CONTENT_FILE_PROTO_MINOR
	jb	errorCloseFile

	clc
error:
	;
	; Return to the original directory
	;
	call	FilePopDir			;preserves flags

EC <	call	AssertIsCGV				>
	.leave
	ret

errorNoMap:
	mov	di, offset ErrorInvalidContentFile
errorCloseFile:
	clr	al
	call	VMClose
	stc					;carry <- error
	jmp	error
MFOpenFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the VM file we just opened is a help file

CALLED BY:	MFOpenFile()
PASS:		^hbx - file to check
		al - HelpFileType expected
RETURN:		carry - set if not the right type
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyHelpFile		proc	far
	uses	cx, dx, si, di, ds, es
	.enter

EC <	cmp	al, HelpFileType				>
EC <	ERROR_AE ERROR_INVALID_HELP_FILE_TYPE			>
	clr	dh
	mov	dl, al				;save HelpFileType
	;
	; Get the token for the file
	;
	mov	cx, (size GeodeToken)		;cx <- size of buffer
	sub	sp, cx
	segmov	es, ss, ax
	mov	di, sp				;es:di <- ptr to buffer
	mov	ax, FEA_TOKEN			;ax <- FileExtendedAttribute
	call	FileGetHandleExtAttributes
	jc	done				;branch if no such attribute
	;
	; Make sure it is one of ours
	;
	mov	si, offset tokenTable
	mov	cl, size TokenStruct
	mov	ax, dx
	mul	cl
	add	si, ax
	push	si				;save offset into tokenTable
	segmov	ds, cs, ax			;ds:si <- file token
	mov	cx, size GeodeToken		
	repe	cmpsb				;Do comparison.
	pop	cx				;get original offset 
	je	okay
	;
	; If dl = HFT_BOOK and no match was found, it is possible this
	; is a special book created for the full screen viewer. Check
	; for the full screen book token.
	;
	cmp	dl, HFT_BOOK
	stc					;carry <- assume not OK
	jne	done				;branch if not OK
		
	mov	di, sp				;es:di <- ptr to token buffer
	mov	si, cx				;ds:si pts to book TokenStruct
	add	si, size TokenStruct*2		;ds:si pts to fscr TokenStruct
	mov	cx, size GeodeToken		
	repe	cmpsb				;Do comparison.
	stc					;carry <- assume not OK
	jne	done				;branch if not OK
okay:
	;
	; now ds:si points at Creator token in TokenStruct
	;
	mov	di, sp
	mov	cx, size GeodeToken		
	mov	ax, FEA_CREATOR			;ax <- FileExtendedAttribute
	call	FileGetHandleExtAttributes
	jc	done				;branch if no such attribute
	repe	cmpsb				;Do comparison.
	stc					;carry <- assume not OK
	jne	done				;branch if not OK
	clc		
done:
	mov	di, sp
	lea	sp, ss:[di][(size GeodeToken)]	;preserve carry

	.leave
	ret

VerifyHelpFile		endp

TokenStruct	struct
    TS_token	GeodeToken
    TS_creator	GeodeToken
TokenStruct	ends
;
; Order of this table corresponds to HelpFileType
; in this order: content file, content book file, help file
;
tokenTable	TokenStruct 	\
	<<"cntf", MANUFACTURER_ID_GEOWORKS>,
	 <"cntf", MANUFACTURER_ID_GEOWORKS>>,
	<<"cntb", MANUFACTURER_ID_GEOWORKS>,
	 <"cntv", MANUFACTURER_ID_GEOWORKS>>,
	<<"hlpf", MANUFACTURER_ID_GEOWORKS>,
	 <"hlpv", MANUFACTURER_ID_GEOWORKS>>,
	<<"fscr", MANUFACTURER_ID_GEOWORKS>,
	 <"cntv", MANUFACTURER_ID_GEOWORKS>>

.assert (HFT_CONTENT eq 0)
.assert (HFT_BOOK eq 1)
.assert (HFT_HELP eq 2)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MFSetFileCloseOld
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the new file and close the old one, if any

CALLED BY:	INTERNAL - HelpControlExit, HelpUpdateUI

PASS:		*ds:si 	= ContentGenView instance
		^hbx 	= handle of new file (0 for none)
		cx	= notification message to send to ContentGenView
			  (0 for none)

RETURN:		carry 	= set if error

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: also destroys and text object storage before closing the file
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version
	martin	8/11/94		Added notification

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MFSetFileCloseOld		proc	far
		uses	bx, bp
		class	ContentGenViewClass
		.enter
EC <		call	AssertIsCGV				>

	;
	; If no new file has been specified, get rid of the bookfile
	; information, since we are no longer using that book.
	;
	; NO - don't delete it, because it may be that we are shutting down
	; to state, in which case we want to keep the bookname in vardata.
	; (cassie 8/22)
if 0
		tst	bx
		jnz	continue
		mov	ax, CONTENT_FILENAME
		call	ObjVarDeleteData
endif
		
continue::

		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		xchg	bx, ds:[di].CGVI_curFile	;bx <- old file
		tst_clc	bx				;any old file?
		jz	noClose				;branch if no old file
	;
	; Destroy any old storage 
	;
		mov	bp, bx
		mov	ax, MSG_CT_FREE_STORAGE_AND_FILE
		clr	di				;don't use search text
		call	MUObjMessageSend
done:
		.leave
		ret

noClose:
	;
	; No file is open. Just forward the passed message to the view.
	;
		jcxz	done				;is there a message?
		mov	ax, cx				
		call	MUCallView
		clc					;signal no error
		jmp	done
		
MFSetFileCloseOld		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MFGetFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the handle of the current file

CALLED BY:	UTILITY
PASS:		*ds:si - ContentGenView instance
		ax - ContentTextRequestFlags
		 	if CTRF_searchText is set, use CSD_searchFile
RETURN:		bx - handle of file
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MFGetFile		proc	far
		uses	ax, di
		class	ContentGenViewClass
		.enter
EC <		call	AssertIsCGV				>

		test	ax, mask CTRF_searchText
		jnz	getSearchFile
		
		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		mov	bx, ds:[di].CGVI_curFile	;bx <- current file
done:
		tst	bx					
		jz	noCheck					
EC <		call	ECCheckFileHandle				>
noCheck: 							
		.leave
		ret
getSearchFile:
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
		mov	bx, ds:[bx].CSD_curFile
		jc	done
		clr	bx
		jmp	done
MFGetFile		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SameFile?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current file (stored in the
		ContentGenView's vardata)
		is the same as the file we're about to open

CALLED BY:	UTILITY
PASS:		*ds:si - ContentGenView
		ss:bp - ContentTextRequest
			CTR_filename - name of help file
RETURN:		z flag - set (jz) if same file
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SameFile?		proc	far
	uses	cx, es, di
	.enter	
EC <	call	AssertIsCGV				>

		mov	ax, ss:[bp].CTR_flags
		test	ax, mask CTRF_resetPath
		jnz	fail
	;
	; See if a file is open
	;
		call	MFGetFile
		tst	bx				;any file?
		jz	fail				;branch if no file open
	;
	; Get the filename in vardata.
	;
		mov	ax, CONTENT_FILENAME
		call	ObjVarFindData			; ds:bx <- filename
		jnc	fail
	;
	; See if it's the same filename
	;
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_filename	;es:di <- ptr to name
		push	si
		mov	si, bx				;ds:si <- name
		clr	cx				;cx <- NULL-terminated
		call	LocalCmpStrings			;set Z flag if equal
		pop	si
quit:
		.leave
		ret
fail:
		or	ax, 1				;clear Z flag
		jmp	quit

SameFile?		endp


BookFileCode	ends

