COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/Main
FILE:		mainImport.asm

AUTHOR:		Don Reeves, May 28, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/28/92		Initial revision

DESCRIPTION:
	Contains the import code for the Impex library

	$Id: mainImport.asm,v 1.1 97/04/05 00:05:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITPImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up for and do the import.

CALLED BY:	IPSpawnThreadAndImport

PASS:		CX	= ImpexThreadInfo block handle

		Redwood only:
		DX	= FLoppy disk handle (-1 or ffffh = not floppy
						impex library)
			
RETURNED:	Nothing
	
DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:
		* Put up notification dialog box
		* Open source file
		* Create destination VM file
		* Call library to perform import
		* Pass data on to application

Known BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jenny	1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ITPImport	method	dynamic	ImpexThreadProcessClass, MSG_ITP_IMPORT

		; First notify the user of what's going on
		;
		mov	bx, cx			; bx <- ImpexThreadInfo handle
		call	ImpexThreadInfoPLock	; ds <- ImpexThreadInfo segment
		mov	ax, TR_GET_IMPORT_OPTIONS
		call	PrepareToCallLibrary
		jc	error			; if error, quit

		; Now open the source file
		;
		call	PrepareSourceFile
		jc	error			; if error, quit

		; Create the destination VM file.
		;
		call	CreateTransferVMFile
		jc	error

		; Call the translation library to do the import. Note
		; that CallLibrary pushes those values common to the
		; ImportFrame and the ExportFrame before calling the
		; library. We restore the stack pointer here since the
		; ImportFrame and the ExportFrame are of different sizes.
		;
		mov	ax, TR_IMPORT
		call	CallLibrary		; bx <- ClipboardItemFormat,
						; si <- Maufacturer's ID
						; dx:cx <- VM chain w/ data
						; ax <- TransError or 0
		add	sp, size ImportFrame	; restore stack pointer
		tst	ax
		jnz	importError		; if error, display it

		; Now send the import data on to the application
		;
		mov	ax, MSG_IMPORT_CONTROL_IMPORT_COMPLETE
		call	SendMessageToApplication
		jc	error			; if error, abort
done:
		call	ImpexThreadInfoUnlockV	; unlock Info block
		ret

		; Display an error returned to user upon import.
		;
		; If the user clicked on No Idea and Impex started an
		; import using a translation library which wound up
		; rejecting the file after all, we don't want to
		; put up the standard invalid format message, which
		; tells the user that s/he has specified the wrong
		; format; instead, we substitute the message which
		; the user would have seen had no translation
		; library's TransGetFormat routine ever thought it
		; recognized the file in the first place.
importError:
		cmp	ax, TE_INVALID_FORMAT
		jne	displayIt
		test	ds:[ITI_state], mask ITS_IMPORTING_NO_IDEA
		jz	displayIt
		mov	ax, IE_NO_IDEA_FORMAT
		call	DisplayErrorAndBlock
		jmp	error
displayIt:
		call	DisplayTransError

		mov	ax, MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED
		mov	bx, ds:[ITI_appDest].handle
		mov	si, ds:[ITI_appDest].chunk
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
error:
		call	DestroyThread		; destroy the import thread
		jmp	done			; we're done
ITPImport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITPImportToAppComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The application has completed the import process, so clean
		up any loose ends and exit

CALLED BY:	GLOBAL (MSG_ITP_IMPORT_TO_APP_COMPLETE)

PASS: 		SS:BP	= ImpexTranslationParams
		CX	= ImpexThreadInfo handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ITPImportToAppComplete	method dynamic	ImpexThreadProcessClass,
					MSG_ITP_IMPORT_TO_APP_COMPLETE
		.enter

		mov	bx, cx
		call	ImpexThreadInfoPLock

if _ANNOUNCE_NO_IDEA_FORMAT
		; If we've successfully imported a file for which the
		; user selected the No Idea format, we'll want to tell
		; the user what the format was.
		;
		test	ds:[ITI_state], mask ITS_IMPORTING_NO_IDEA
		jz	destroyThread
		test	ds:[ITI_state], mask ITS_TRANSPARENT_IMPORT_EXPORT
		jnz	destroyThread
		or	ds:[ITI_state], mask ITS_WILL_ANNOUNCE_FORMAT
destroyThread:
endif
		; Destroy this thread
		;
		call	DestroyThread		; destroy the thread
		call	ImpexThreadInfoUnlockV

		.leave
		ret
ITPImportToAppComplete	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepareSourceFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open source file and set file position to its start

CALLED BY:	ITPImport

PASS:		DS:0	= ImpexThreadInfo

RETURN:		Carry	= Set if error

DESTROYED:	CX

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:	

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	6/19/91		Initial version.
		jenny	8/91		Added EC code, fixed header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrepareSourceFile	proc	near
		uses	ax, bx, dx, si
		.enter

		; Open the source file
		;
		call	GetAndSetPath		; change to correct directory
		jc	doDialog		; if error, abort

		mov	dx, offset ITI_srcDestName
		mov	al, FileAccessFlags <FE_NONE, FA_READ_ONLY>
		call	FileOpen		; ax <- source file handle
		jc	errorFileOpen

if FLOPPY_BASED_DOCUMENTS
		;
		; Hack to limit the size of a file we can open to a fixed amount
		; for Redwood, based on tables below and the 100K file size
		; limit currently imposed by RedMotif.
		;
		mov_tr	bx, ax

		mov	ax, ds:[ITI_formatDesc].IFD_dataClass
		clr	di
		test	ax, mask IDC_TEXT
		jnz	checkSize
		inc	di
		test	ax, mask IDC_GRAPHICS
		jnz	checkSize
		inc	di
		test	ax, mask IDC_SPREADSHEET
		jz	sizeOK
checkSize:
		shl	di, 1			; multiple for dword count
		shl	di, 1

		call	FileSize
		cmpdw	dxax, cs:maxImportFileSizesTable[di]
		jbe	sizeOK

		mov	al, FILE_NO_ERRORS
		call	FileClose		; too big, close and signal err
		mov	dx, IE_IMPORT_SOURCE_FILE_TOO_LARGE
		jmp	short doDialog
sizeOK:
		mov	ax, bx			; bx <- file handle
endif

		
		; Reset the file position to the start of the file.
		;
		mov	ds:[ITI_srcDestFile], ax
		mov_tr	bx, ax			; bx <- source file handle
		call	ResetFilePos
done:
		call	FilePopDir

		.leave
		ret

		; Display an error on attempting to open the source file
errorFileOpen:
		mov	dx, IE_FILE_ALREADY_OPEN
		cmp	ax, ERROR_SHARING_VIOLATION
		je	doDialog
		mov	dx, IE_TOO_MANY_OPEN_FILES
		cmp	ax, ERROR_TOO_MANY_OPEN_FILES
		je	doDialog
		mov	dx, IE_FILE_MISC_ERROR
doDialog:
		mov_tr	ax, dx			; ax <- ImpexError
		mov	cx, ds
		mov	dx, offset ITI_srcDestName
		call	DisplayErrorAndBlock	; carry <- set
		jmp	done

PrepareSourceFile	endp



if FLOPPY_BASED_DOCUMENTS	;Hack to avoid memory overload

;(PCX library now catches uncompressed bitmaps above the memory limit, hence
; the too-large limit here.)

MAX_IMPORT_GRAPHIC_SIZE		equ	MAX_TOTAL_FILE_SIZE * 35 / 100
MAX_IMPORT_TEXT_SIZE		equ	MAX_TOTAL_FILE_SIZE * 45 / 100
MAX_IMPORT_SPREADSHEET_SIZE	equ	MAX_TOTAL_FILE_SIZE * 40 / 100


maxImportFileSizesTable	label	dword	
	dword	MAX_IMPORT_TEXT_SIZE		;mask IDC_TEXT
	dword	MAX_IMPORT_GRAPHIC_SIZE		;mask IDC_GRAPHICS
	dword	MAX_IMPORT_SPREADSHEET_SIZE	;mask IDC_SPREADSHEET

endif



ImpexCode	ends
