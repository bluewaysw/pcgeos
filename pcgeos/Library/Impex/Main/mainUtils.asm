COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/Main
FILE:		mainUtils.asm

AUTHOR:		Don Reeves, May 28, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/28/92		Initial revision

DESCRIPTION:
	Utilities for the Impex/Main module

	$Id: mainUtils.asm,v 1.1 97/04/04 23:34:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** General Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexThreadInfoPLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock & own an ImpexThreadInfo block

CALLED BY:	INTERNAL

PASS:		BX	= ImpexThreadInfo handle

RETURN:		DS:0	= ImpexThreadInfo

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexThreadInfoPLock	proc	far
		uses	ax
		.enter
	
		call	MemPLock
		mov	ds, ax

		.leave
		ret
ImpexThreadInfoPLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexThreadInfoUnlockV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock & release an ImpexThreadInfo block

CALLED BY:	INTERNAL

PASS:		DS:0	= ImpexThreadInfo

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexThreadInfoUnlockV	proc	far
		uses	bx
		.enter
	
		mov	bx, ds:[ITI_handle]
EC <		call	ECCheckMemHandle	; verify handle		>
		call	MemUnlockV		; unlock & release

		.leave
		ret
ImpexThreadInfoUnlockV	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the translation library to do the import or export

CALLED BY:	ITPImport, ITPExportFromAppComplete 

PASS:		DS	= ImpexThreadInfo segment
		AX	= TR_IMPORT or TR_EXPORT
		If export:
			on stack, EF_transferVMChain

RETURN: 	AX	= TransError (0 = no error)
		BX	= memory handle of error text if ax = TE_CUSTOM
		DS	= ImpexThreadInfo segment (may have moved)

		If import:
			DX:CX	= VMChain containing transfer format
			SI	= ManufacturerID passed back from Library
			BX	= ClipboardFormat

		SP	= original SP - size of ImportFrame

DESTROYED:	DI, SI, BP, ES

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Pop the return address so that, if this is an export,
		EF_transferVMChain is at the top of the stack.
		Push the ImportFrame or the rest of the ExportFrame
		onto the stack.
		Call the translation library.
		Push the return address.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallLibrary	proc	near

		pop	bp			; get return address.
	;
	; Put library handle in bx for ProcGetLibraryEntry.
	; 
		mov	bx, ds:[ITI_libraryHandle]
	;
	; Set up ImportFrame or rest of ExportFrame.
	;
	; First push IF_transferVMFile or EF_transferVMFile:
	;
		CheckHack <offset IF_transferVMFile eq \
				offset EF_transferVMFile and \
			   offset IF_transferVMFile+size IF_transferVMFile eq \
				size ImportFrame and \
			   offset EF_transferVMFile+size EF_transferVMFile eq \
				offset EF_transferVMChain>

		push	ds:[ITI_xferVMFile]
	;
	; Then IF_sourcePathDisk or EF_outputPathDisk:
	;
		CheckHack <offset IF_sourcePathDisk+size IF_sourcePathDisk eq \
				offset IF_transferVMFile and \
			   offset EF_outputPathDisk+size EF_outputPathDisk eq \
				offset EF_transferVMFile>

		push	ds:[ITI_pathDisk]
	;
	; Then IF_sourcePathName or EF_outputPathName:
	;
		CheckHack <offset IF_sourcePathName+size IF_sourcePathName eq \
				offset IF_sourcePathDisk and \
			   offset EF_outputPathName+size EF_outputPathName eq \
				offset EF_outputPathDisk>

		segmov	es, ss
		mov	si, offset ITI_pathBuffer
		mov	cx, size PathName
		sub	sp, cx
		mov	di, sp
		rep	movsb
	;
	; Next IF_sourceFileName or EF_outputFileName:
	;
		CheckHack <offset IF_sourceFileName+size IF_sourceFileName eq \
				offset IF_sourcePathName and \
			   offset EF_outputFileName+size EF_outputFileName eq \
				offset EF_outputPathName>

		mov	si, offset ITI_srcDestName
		mov	cx, size FileLongName
		sub	sp, cx
		mov	di, sp
		rep	movsb
	;
	; And IF_sourceFile or EF_outputFile:
	;
		CheckHack <offset IF_sourceFile+size IF_sourceFile eq \
				offset IF_sourceFileName and \
			   offset EF_outputFile+size EF_outputFile eq \
				offset EF_outputFileName>

		push	ds:[ITI_srcDestFile]
	;
	; And IF_importOptions or EF_exportOptions:
	;
		CheckHack <offset IF_importOptions+size IF_importOptions eq \
				offset IF_sourceFile and \
			   offset EF_exportOptions+size EF_exportOptions eq \
				offset EF_outputFile>

		push	ds:[ITI_formatOptions]
	;
	; And IF_formatNumber or EF_formatNumber:
	;
		CheckHack <offset IF_formatNumber+size IF_formatNumber eq \
				offset IF_importOptions and \
			   offset EF_formatNumber+size EF_formatNumber eq \
				offset EF_exportOptions and \
			   offset IF_formatNumber eq 0 and \
			   offset EF_formatNumber eq 0>

		push	ds:[ITI_formatDesc].IFD_formatNumber
	;
	; Make ds:si point to the thing.
	;
	;
	; Collapse and call the library.
	;
		
		mov	si, sp
		push	ds:[ITI_handle]
		call	ImpexThreadInfoUnlockV	; release ImpexThreadInfo
		segmov	ds, ss			; Import/ExportFrame => DS:SI

EC <		call	ECCheckMemHandle	; check library handle	>
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; ax <- TransError or 0
						; bx <- handle of error msg
						; 	if ax = TE_CUSTOM
		XchgTopStack	bx
		call	ImpexThreadInfoPLock	; ImpexThreadInfo => DS:0
		pop	bx			; custom error msg handle => BX

		push	bp			; save return address
		ret
CallLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepareToCallLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up to call the translation library

CALLED BY:	ITPExport, ITPImport

PASS:		DS	= ImpexThreadInfo segment
		AX	= TR_GET_IMPORT_OPTIONS or TR_GET_EXPORT_OPTIONS
			
RETURNED:	Carry	= Set if error (library could not be loaded)
	
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jenny	1/92		Initial version
		don	5/92		Various changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrepareToCallLibrary	proc	near
		uses	ax, bx, cx, dx, di, si, bp
		.enter

		; Load the library
		;
if ALLOW_FLOPPY_BASED_LIBS
		mov	bx, ds:[ITI_libraryHandle]
		tst	bx
EC <		ERROR_Z	-1			; library missing	>
		jnz	gotLib
endif

		call	FindAndLoadLibrary	; bx <- library handle
		jc	done			; if error, quit
		mov	ds:[ITI_libraryHandle], bx
gotLib::
		; Put up box to tell user export or import is in progress.
		;
		movdw	cxdx, ds:[ITI_notifySource]
		call	NotifyDialogCreate	; duplicate & display dialog box

		; Get the translation options the user has set, if any.
		;
		mov	cx, ds:[ITI_formatDesc].IFD_formatNumber
		mov	dx, ds:[ITI_formatUI]
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; dx <- options block handle
		mov	ds:[ITI_formatOptions], dx
		clc				; success
done:
		.leave
		ret
PrepareToCallLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindAndLoadLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of the translation library from the
		chunk array and load it 

CALLED BY:	PrepareToCallLibrary

PASS:		DS	= ImpexThreadInfo segment

RETURNED:	BX	= Library handle
		Carry	= Clear (success)
			- or -
		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	3/91		Initial version
		jenny	1/92		Cleaned up

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindAndLoadLibrary	proc	near
		uses	ax, di
		.enter

		; Load the translation library
		;
		mov	di, offset ITI_libraryDesc ; get ImpexLibraryDescriptor
		call	ImpexLoadLibrary	; library handle => BX
		jnc	done

		; Put up dialog box if there's an error.
		;
		push	cx, dx
		mov	cx, ds
		mov	dx, di			; library name => CX:DX
		mov	ax, IE_COULD_NOT_LOAD_XLIB
		call	DisplayErrorAndBlock	; returns carry = set
		pop	cx, dx
done:
		.leave
		ret
FindAndLoadLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAndSetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets and sets the path

CALLED BY:	GLOBAL	PrepareSourceFile
			CreateOutputFile
			GetSelectedFile

PASS:		DS	= ImpexThreadInfo segment

RETURNED:	Carry set if error
			DX	= IE_BAD_FILE_PATH
		Carry clear if ok

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* Pushes the current directory before setting the new

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	7/15/91		Initial version.
		don	5/28/92		Major changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetAndSetPath	proc	far
		uses	ax, bx
		.enter

		; Lock down the ImpexThreadInfo, and set the path
		;
		mov	dx, offset ITI_pathBuffer
		mov	bx, ds:[ITI_pathDisk]
		call	FilePushDir
		call	FileSetCurrentPath	; carry <- set if error
		mov	dx, IE_BAD_FILE_PATH	; in case carry is set

		.leave
		ret

GetAndSetPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTransferVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create VM file in which to allocate transfer format

CALLED BY:	ITPImport, ITPGetTransferFormatFromApp

PASS:		DS	= ImpexThreadInfo segment

RETURN:		Carry	= Set if error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/92		Initial verson

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateTransferVMFile	proc	near
		uses	ax, di, es
		.enter

		; Set up to create file
		;
		segmov	es, ds, ax		; AX = non-zero = VM file
		mov	di, offset ITI_xferVMFileName
		call	CreateTempFile		; VM file handle => AX
		jc	error			; if not created, report error
		mov	ds:[ITI_xferVMFile], ax
done:
		.leave
		ret

		; Display error that file count not be created
error:
		mov	ax, IE_COULD_NOT_CREATE_VM_FILE
		call	DisplayErrorAndBlock
		jmp	done
CreateTransferVMFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTempFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a temporary file

CALLED BY:	INTERNAL

PASS:		ES:DI	= File buffer (size ImpexTempFileStruct or larger)
		AX	= 0 (native file) or != 0 (VM file)

RETURN:		ES:DI	= File buffer filled
		AX	= File handle
		Carry	= Clear (success)
			- or -
		Carry	= Set (error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		* Will loop through 100 possible file names

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

tempFileName	ImpexTempFileStruct <>
tempFilePatt	ImpexTempFileStruct<,<'?', '?', 0>>

CreateTempFile	proc	near
		uses	bx, cx, dx, si, bp, ds
		.enter
	
		; Save current directory and go to document directory
		;
		clr	si			; initialize boolean
		mov	bp, offset CreateTempFileNormal
		tst	ax
		jz	common
		mov	bp, offset CreateTempFileVM
common:
		call	FilePushDir
		mov	ax, SP_WASTE_BASKET
		call	FileSetStandardPath

		; Copy in the filename first
startFileLoop:
		push	di
		mov	si, offset cs:tempFileName
		segmov	ds, cs			; source => DS:SI
		mov	cx, size tempFileName
		rep	movsb			; copy them bytes

		; Start out trying a base file, then incrementing
		;
		segmov	ds, es
		pop	di			; destination => ES:DI
		mov	dx, di			; DS:DX points at the file name
tryAnotherFile:	
		CheckHack <IMPEX_TEMP_NATIVE_FILE eq 0>
		call	bp			; file handle => AX
		jnc	done			; if no error, success
		jcxz	nextName		; if acceptable error, try again
done:
		call	FilePopDir

		.leave
		ret

		; Else go to the next logical file name (up to 100 files)
nextName:
SBCS <		mov	bx, 1			; initialize a counter	>
DBCS <		mov	bx, 2			; initialize a counter	>
nextNameLoop:
		inc     ds:[di][bx].ITFS_num	; increment the digit
		cmp     ds:[di][bx].ITFS_num, '9'
		jl      tryAnotherFile		; try again in no rollover
		mov     ds:[di][bx].ITFS_num, '0'
		LocalPrevChar dsbx		; go to the next digit
		jge	nextNameLoop		; jump if not negative

		; If we run out of files, someone probably hasn't emptied
		; his/her wastebasket in a while. So we'll nuke our files
		;
		tst	si
		jnz	cannotCreateFile	; if non-zero, we give up
		inc	si			; we've tried this once
		push	bp
if FULL_EXECUTE_IN_PLACE
		push	ds, si
		segmov	ds, cs, cx
		mov	si, offset tempFilePatt	;ds:si = tempfile patt in cs
		mov	cx, size ImpexTempFileStruct
		call	SysCopyToStackDSSI	;ds:si = tempfile patt in stack
endif
		sub	sp, size FileEnumParams
		mov	bp, sp			; FileEnumParams => SS:BP
		mov	ss:[bp].FEP_searchFlags, FILE_ENUM_ALL_FILE_TYPES or \
						 mask FESF_CALLBACK
		clr	ax
		mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
		mov	ss:[bp].FEP_returnAttrs.segment, ax
		mov	ss:[bp].FEP_returnSize, (size FileLongName)
		mov	ss:[bp].FEP_matchAttrs.segment, ax
		mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
if FULL_EXECUTE_IN_PLACE
		mov	ss:[bp].FEP_cbData1.segment, ds
		mov	ss:[bp].FEP_cbData1.offset, si
else
		mov	ss:[bp].FEP_cbData1.segment, cs
		mov	ss:[bp].FEP_cbData1.offset, offset tempFilePatt
endif
		mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
		mov	ss:[bp].FEP_callback.segment, ax
		mov	ss:[bp].FEP_cbData2.low, TRUE
		mov	ss:[bp].FEP_skipCount, 0
		call	FileEnum		; find each of the files
if FULL_EXECUTE_IN_PLACE
		pop	ds, si
		call	SysRemoveFromStack	;release space back the stack
endif
		pop	bp
		jcxz	cannotCreateFile	; if no files, we're hosed
		call	MemLock			; lock filename buffer
		mov	ds, ax
		clr	dx
deleteFileLoop:
		call	FileDelete
		add	dx, (size FileLongName)	; go to the next filename
		loop	deleteFileLoop				
		call	MemFree			; free filename buffer
		jmp	startFileLoop		; now try to find a file again
cannotCreateFile:
		stc				; error, no file created
		jmp	done			; and we're outta here
CreateTempFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTempFileNormal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a temporary normal "native-mode" file

CALLED BY:	CreateTempFile

PASS:		DS:DX	= Filename

RETURN:		AX	= File handle
		Carry	= Clear (success)
			- or -
		CX	= 0 (continue searching)
		Carry	= Set (error)
			- or -
		CX	= 1 (stop searching, unacceptable error condition)
		Carry	= Set (error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	7/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateTempFileNormal	proc	near
	
		; Try to create the "native-mode" file
		;
	       	mov	ax, (((FE_NONE shl offset FAF_EXCLUDE) or \
			      (FA_READ_WRITE shl offset FAF_MODE)) or \
			    (((mask FCF_NATIVE) or  \
			      (FILE_CREATE_ONLY shl offset FCF_MODE)) shl 8))
		mov     cx, FILE_ATTR_NORMAL	; don't truncate
		call    FileCreate		; attempt to create the file
		jnc	done
		clr	cx			; assume acceptable error
		cmp	ax, ERROR_SHARING_VIOLATION
		je	error
		cmp	ax, ERROR_FILE_EXISTS
		je	error
		cmp	ax, ERROR_ACCESS_DENIED
		je	error
		cmp	ax, ERROR_SHARING_VIOLATION
		je	error
		cmp	ax, ERROR_FILE_IN_USE
		je	error
		cmp	ax, ERROR_FILE_FORMAT_MISMATCH
		je	error
		inc	cx			; unacceptable error - abort
error:
		stc
done:
		ret
CreateTempFileNormal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTempFileVM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a temporary VM file

CALLED BY:	CreateTempFile

PASS:		DS:DX	= Filename

RETURN:		AX	= File handle
		Carry	= Clear (success)
			- or -
		CX	= 0 (continue searching)
		Carry	= Set (error)
			- or -
		CX	= 1 (stop searching, unacceptable error condition)
		Carry	= Set (error)

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	7/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateTempFileVM	proc	near
	
		; Create & open a new VM file
		;
		mov	ax, (VMO_CREATE_ONLY shl 8)
		clr	cx			; default compression threshold
		call	VMOpen			; VM file handle => AX
		xchg	ax, bx			; file handle => AX, error => BX
		jnc	done
		clr	cx			; assume acceptable error
		cmp	bx, VM_FILE_EXISTS
		je	error
		cmp	bx, VM_SHARING_DENIED		
		je	error
		cmp	bx, VM_OPEN_INVALID_VM_FILE
		je	error
		cmp	bx, VM_FILE_FORMAT_MISMATCH
		je	error
		inc	cx			; unacceptable error - abort
error:
		stc
done:
		ret
CreateTempFileVM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Sends a message to the back of an Impex thread's queue

PASS:		AX		= Message to send
		CX, DX, BP, SI	= Data for message

RETURN:		Nothing

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	8/ 8/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendMessageToThread	proc	near
		uses	bx, di
		.enter

		call	GetCurrentThreadHandle	; bx <- thread handle
		mov	di, mask MF_FORCE_QUEUE 
		call	ObjMessage

		.leave
		ret
SendMessageToThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentThreadHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current thread handle

CALLED BY:	GLOBAL

PASS:		SS	= Impex thread's stack segment

RETURN:		BX	= Current thread handle

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	8/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCurrentThreadHandle	proc	far
		uses	ax
		.enter

		mov	ax, TGIT_THREAD_HANDLE
		clr	bx
		call	ThreadGetInfo		; ax <- thread handle
		mov_tr	bx, ax

		.leave
		ret
GetCurrentThreadHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetFilePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set file position to zero

CALLED BY:	INTERNAL

PASS:		BX	= File handle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	7/ 2/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResetFilePos	proc	near
		uses	ax, cx, dx
		.enter

EC <		call	ECCheckFileHandle	; check file handle	>
		clr	cx, dx			; cx:dx = offset = 0, 
		mov	al, cl			; al = 0, FILE_POS_START
		call	FilePos	

		.leave
		ret
ResetFilePos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to an application. The application will, after
		completing it's work, send a message back via the appropriate
		Import/ExportControlClass object

CALLED BY:	INTERNAL

PASS:		DS	= ImpexThreadInfo segment
		AX	= Message to return to Import/ExportControl class
		DX:CX	= VMChain holding transfer format
		BX	= ClipboardItemFormat
		SI	= ManufacturerID

RETURN:		DS	= ImpexThreadInfo segment (may have moved)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note: All the above arguments may not need to be passed
		      to this routine, depending upon whether we are
		      importing or exporting.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendMessageToApplication	proc	near
		uses	ax, bx, cx, dx, di, si, bp
		.enter
	
		; If the application is already detaching, then
		; abort this operation right now
		;
		test	ds:[ITI_state], mask ITS_APP_DETACHING
		stc
		jnz	done

		; Put a ImpexTranslationParams struct on the stack.
		;
		push	bx			; ClipboardItemFormat
		push	si			; ManufacturerId
		push	ds:[ITI_handle]		; ITP_internal.high
		call	GetCurrentThreadHandle
		push	bx			; ITP_internal.low
		pushdw	dxcx			; ITP_transferVMChain
		push	ds:[ITI_xferVMFile]	; ITP_transferVMFile
		push	ds:[ITI_formatDesc].IFD_dataClass	; ITP_dataClass
		push	ax			; ITP_returnMsg
		pushdw	ds:[ITI_impexOD]	; ITP_returnOD
		mov	bp, sp			; ImpexTranslationParams =>SS:BP
		mov	dx, size ImpexTranslationParams

		; Record a message to be sent to application's destination OD
		;
		mov	ax, ds:[ITI_appMessage]
		clr	bx, si
		mov	di, mask MF_STACK or mask MF_RECORD
		call	ObjMessage		; event handle => DI
		add	sp, size ImpexTranslationParams

		; Now send this off to be processed, in case we have
		; TravelOptions instead of an actual OD
		;
		mov	ax, MSG_GEN_OUTPUT_ACTION
		mov	cx, ds:[ITI_appDest].handle
		mov	dx, ds:[ITI_appDest].chunk
		mov	bp, di			; event handle => DI
		movdw	bxsi, ds:[ITI_impexOD]	; generic object => BX:SI

		push	ds:[ITI_handle]
		call	ImpexThreadInfoUnlockV
		clr	di
		call	ObjMessage
		pop	bx
		call	ImpexThreadInfoPLock
		clc
done:
		.leave
		ret
SendMessageToApplication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the import/export thread

CALLED BY:	DS	= ImpexThreadInfo segment

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DestroyThread	proc	near
		uses	ax, cx, dx, bp
		.enter
	
		; See if we need to do anything
		;
		test	ds:[ITI_state], mask ITS_APP_DETACHING
		jnz	done
		or	ds:[ITI_state], mask ITS_THREAD_DETACHING

		; Send off detach message to start the detach process
		;
		mov	cx, ds:[ITI_handle]	; ImpexthreadInfo handle => CX
		movdw	dxbp, ds:[ITI_impexOD]	; destination object => DX:BP
		mov	ax, MSG_META_DETACH
		call	SendMessageToThread
done:
		.leave
		ret
DestroyThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CleanUpImpexThreadInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up all resources referred to by an ImpexThreadInfo
		buffer

CALLED BY:	INTERNAL

PASS:		DS:0	= ImpexThreadInfo

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	8/ 8/91		Initial version
		jenny	9/04/91		Cleaned up
		Don	6/ 1/92		Initial version
		jenny	12/14/92	Added announceFormat
		jenny	2/02/93		Added cancelIfError
		Don	10/17/94	Delete export file if error

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CleanUpImpexThreadInfo	proc	far
		uses	ax, bx, cx, dx, di, si, bp
		.enter
	
		; Close the source/destination file
		;
		clr	bx
		xchg	bx, ds:[ITI_srcDestFile]
		tst	bx
		jz	freeTransferFile
		clr	al			; we'll handle (ignore) errors
		call	FileClose		; close the source/dest file

		; If we have both error condition and am in the middle of
		; exporting, then delete the destination file. For this
		; to be true. ITS_ERROR must be set and ITS_ACTION must
		; be set to ITA_EXPORT (which is defined to be 1).
		;
		CheckHack <ITA_EXPORT eq 1>
		test	ds:[ITI_state], mask ITS_ERROR or mask ITS_ACTION
		jz	freeTransferFile	; if neither set, do nothing
		jnp	freeTransferFile	; if only one is set, do nothing
		call	GetAndSetPath		; switch to correct directory
		jc	doneDeleteFile		; if error, don't delete file
		mov	dx, offset ITI_srcDestName
		call	FileDelete		; delete the destination file
doneDeleteFile:
		call	FilePopDir		; bracket for GetAndSetPath()

		; Free the transfer VM file
freeTransferFile:
		clr	bx
		xchg	bx, ds:[ITI_xferVMFile]	; VM file to delete => BX
		tst	bx
		jz	destroyNotify
		call	FilePushDir
		mov	ax, SP_WASTE_BASKET
		call	FileSetStandardPath
		mov	al, FILE_NO_ERRORS
		call	VMClose			; close the VM file
		mov	dx, offset ITI_xferVMFileName
		call	FileDelete		; delete transfer VM file
		call	FilePopDir

		; Bring down the notification dialog box, if needed
destroyNotify:
		call	NotifyDialogDestroy

		; Allow input to continue to the application, if needed
		;
		call	InputResume

		; Delete any format options
		;
		clr	bx
		xchg	bx, ds:[ITI_formatOptions]
		tst	bx
		jz	freeLibrary
		call	MemFree

		; Free the translation library
freeLibrary:

if ALLOW_FLOPPY_BASED_LIBS
		; We need to have the thread which loaded the library free it.
		;
		clr	cx
		xchg	cx, ds:[ITI_libraryHandle]
		jcxz	announceFormat

		movdw	bxsi, ds:[ITI_impexOD]
		mov	ax, MSG_IMPORT_EXPORT_FREE_LIBRARY_AND_FORMAT_UI
		clr	di
		call	ObjMessage
else
		clr	bx
		xchg	bx, ds:[ITI_libraryHandle]
		tst	bx
		jz	announceFormat
		call	GeodeFreeLibrary
endif

announceFormat:
		; If this was an import for which the user selected No
		; Idea as the format of the source file, tell the user
		; the actual format of that file.
		; 
		test	ds:[ITI_state], mask ITS_WILL_ANNOUNCE_FORMAT
		jz	cancelIfError
		mov	cx, ds
		mov	dx, offset ITI_srcDestName
		mov	si, offset ITI_formatName
		mov	ax, IE_ANNOUNCING_FORMAT
		call	DisplayErrorAndBlock
cancelIfError:

		; If this is a failed import, we need to send off a
		; MSG_IMPORT_CONTROL_CANCEL to the controller so as to
		; return to the app's New/Open dialog box. If this is
		; a failed export, well, the message won't hurt anything.
		;
		movdw	bxsi, ds:[ITI_impexOD]
		clr	cx			; assume failure
		test	ds:[ITI_state], mask ITS_ERROR
		jnz	sendFinal
		dec	cx			; success!
		mov	ax, MSG_IMPORT_CONTROL_CANCEL
		clr	di
		call	ObjMessage
sendFinal:
		mov	ax, MSG_IMPORT_EXPORT_OPERATION_COMPLETED
		clr	di
		call	ObjMessage

		.leave
		ret
CleanUpImpexThreadInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Input ignoring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputIgnore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the application to ignore input, if desired

CALLED BY:	INTERNAL

PASS:		DS	= ImpexThreadInfo segment

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InputIgnore	proc	far
		uses	ax
		.enter

		tst	ds:[ITI_ignoreInput]
		jz	done			; if FALSE, do nothing
		dec	ds:[ITI_inputIgnored]	; set "ignored" boolean TRUE
		mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
		call	InputIgnoreResumeCommon
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	InputIgnoreResumeCommon
done:
		.leave
		ret
InputIgnore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputResume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the application to resume input, if desired

CALLED BY:	INTERNAL

PASS:		DS	= ImpexThreadInfo segment

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InputResume	proc	near
		uses	ax
		.enter
	
		tst	ds:[ITI_inputIgnored]
		jz	done			; if FALSE, do nothing
		inc	ds:[ITI_inputIgnored]	; set back to FALSE
		mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
		call	InputIgnoreResumeCommon
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	InputIgnoreResumeCommon
done:
		.leave
		ret
InputResume	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputIgnoreResumeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell an application to ignore or resume input

CALLED BY:	InputIgnore, InputResume

PASS:		DS	= ImpexThreadInfo segment
		AX	= Message to send to application object

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	7/22/91		Initial version
		Don	6/ 1/92		Changed a bit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InputIgnoreResumeCommon	proc	near
		uses	bx, di, si
		.enter
	
		movdw	bxsi, ds:[ITI_appObject]
		call	ObjMessage_impex_send

		.leave
		ret
InputIgnoreResumeCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Notification dialog box
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyDialogCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a notification dialog box

CALLED BY:	INTERNAL

PASS:		DS	= ImpexThreadInfo segment
		CX:DX	= Notify dialog box template

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NotifyDialogCreate	proc	near
		uses	ax, bx, cx, dx, di, si, bp
		.enter
	
		; Duplicate the resource
		;
		mov	bx, ds:[ITI_impexOD].handle
EC <		call	ECCheckMemHandle				>
		push	cx			; save notify dialog resource
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
		mov_tr	cx, ax			; thread to run dialog => CX
		call	MemOwner		; owner of dialog => BX
		mov_tr	ax, bx
		pop	bx			; restore notify dialog resource
		call	ObjDuplicateResource	; new block => BX
		mov	cx, bx
		movdw	ds:[ITI_notifyDialog], cxdx

		; Make it a child of the Import/Export object
		;
		mov	ax, MSG_GEN_ADD_CHILD
		movdw	bxsi, ds:[ITI_impexOD]
		mov	bp, CCO_LAST
		call	ObjMessage_impex_send

		; Set new UI usable
		;
		mov	ax, MSG_GEN_SET_USABLE
		movdw	bxsi, cxdx		; dialog box OD => BX:SI
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjMessage_impex_send

		; Make new UI visible
		;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage_impex_send

		.leave
		ret
NotifyDialogCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyDialogDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the notify dialog box

CALLED BY:	INTERNAL

PASS:		DS	= ImpexThreadInfo segment

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NotifyDialogDestroy	proc	near
		uses	ax, bx, cx, dx, di, si, bp
		.enter
	
		; Get the handle of the dialog box
		;
		movdw	bxsi, ds:[ITI_notifyDialog]
		clrdw	ds:[ITI_notifyDialog]
		tst	bx			; any dialog box ??
		jz	done			; nope, so we're done

		; Dismiss notification box
		;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjMessage_impex_send

		; Set the object now usable, and remove it from the tree
		;
		mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
		call	ObjMessage_impex_send

done:
		.leave
		ret
NotifyDialogDestroy	endp

ObjMessage_impex_send	proc	near
		clr	di
		call	ObjMessage
		ret
ObjMessage_impex_send	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Status Update
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexUpdateImportExportStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apprise the user of the staus of an import/export

CALLED BY:	GLOBAL

PASS:		DS:SI	= Mesage to be displayed
			  (NULL string to use existing message)
		AX	= Percentage complete (0->100)
			  (-1 to not display percentage indicator)

RETURN:		AX	= Boolean indicating whether or not import/export
			  should continue

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		* Find ImpexThreadInfo
		* Send messages to dialog
		* See if user has requested stop of import/export

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexUpdateImportExportStatus	proc	far
		.enter
	
		; For now, do nothing but return TRUE to continue
		;
		mov	ax, TRUE

		.leave
		ret
ImpexUpdateImportExportStatus	endp

ImpexCode	ends



ErrorCode	segment	resource

include		mainStrings.rdef		; include error strings

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Error Display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayTransError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a TransError returned by a translation library

CALLED BY:	INTERNAL

PASS:		DS:0	= ImpexThreadInfo
		AX	= TransError
		BX	= Custom error message (if AX = TE_CUSTOM)

RETURN:		Nothing

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayTransError	proc	far
		uses	cx, bp, di, es
		.enter
	
		; Lock the error string, and display it to the user
		;
EC <		cmp	ax, TE_NO_ERROR		; no error ??		>
EC <		ERROR_E	IMPEX_PASSED_NO_ERROR_TO_DISPLAY_TRANS_ERROR	>
EC <		cmp	ax, TransError		; maximum error ??	>
EC <		ERROR_AE IMPEX_PASSED_ILLEGAL_TRANS_ERROR		>
		cmp	ax, TE_CUSTOM
		je	customError
		dec	ax
		shl	ax, 1			
		mov	bp, ax			; word offset => BP
		mov	bx, handle TransErrorStrings
		call	MemLock
		mov	es, ax
		assume	es:TransErrorStrings
		mov	di, es:[TransErrorTable]
		assume	es:nothing
		mov	di, es:[di][bp]		; error chunk => DI
		mov	di, es:[di]		; error string => ES:DI
		clr	cx			; no block to free later
common:
		mov	bp, IMPEX_ERROR		; flags => BP
		call	DisplayErrorCommon
		call	MemUnlock		; unlock block in BX
		jcxz	exit			; if no block to free, jump
		mov	bx, cx
		call	MemFree
exit:
		.leave
		ret

		; We have a custom error message. Lock it down
customError:
		call	MemLock
		mov	es, ax
		clr	di			; error message => ES:DI
		mov	cx, bx			; handle to free => CX
		jmp	common
DisplayTransError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayErrorAndBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do error dialog box

CALLED BY:	GLOBAL

PASS:		DS:0	= ImpexThreadInfo
		AX	= ImpexError
		CX:DX	= first optional string argument
		DS:SI	= second optional string argument

RETURNED:	AX	= InteractionCommand
		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayErrorAndBlock	proc	far
		uses	bx, bp, di, es
		.enter

		; Set things up to display an error
		;
		test	ds:[ITI_state], mask ITS_TRANSPARENT_IMPORT_EXPORT
		jz	lockString
		cmp	ax, IE_NO_IDEA_FORMAT
		jne	lockString
		mov	ax, IE_TRANSPARENT_NO_IDEA_FORMAT
lockString:
		mov_tr	bp, ax		; ImpexError => BP
		call	LockImpexError	; error string => ES:DI, flags => AX
		mov_tr	bp, ax		; flags => BP
		mov	ax, IC_NULL	; default return value => AX
		
		; Display an error dialog box to the user
		;
		call	DisplayErrorCommon
		call	MemUnlock	; unlock Strings resource
		stc			; return carry set

		.leave
		ret
DisplayErrorAndBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayErrorCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do error dialog box

CALLED BY:	INTERNAL	DisplayTransError
				DisplayErrorAndBlock

PASS:		DS:0	= ImpexThreadInfo
		ES:DI	= error string
		CX:DX	= first optional string argument
		DS:SI	= second optional string argument
		AX	= IC_NULL
		BP	= word value for SDP_customFlags

RETURNED:	AX	= InteractionCommand
		Carry	= Set

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	3/91		Initial version
		jenny	12/14/92	Added format announcement stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayErrorCommon	proc	near
		uses	bx, si
		.enter
		
		; If the app is detaching, forget it.
		;
		test	ds:[ITI_state], mask ITS_APP_DETACHING
		jnz	done

		; If the thread is detaching, forget it unless the
		; information to be displayed is an announcement of
		; the format of the source file, in which case the
		; thread is bound to be detaching.
		; 
		test	ds:[ITI_state], mask ITS_WILL_ANNOUNCE_FORMAT
		jnz	displayIt

		test	ds:[ITI_state], mask ITS_THREAD_DETACHING
		jnz	done

		; If we're displaying an error message, the import or export
		; has failed. We will need to know this later.
		;
		cmp	bp, IMPEX_ERROR
		jnz	displayIt
		or	ds:[ITI_state], mask ITS_ERROR
displayIt:

	;
	; Release the semaphore on this thing while we've got the
	; dialog up, as, according to Don, no one will resize the
	; block, and we want to avoid a weird deadlock case that
	; happens when the app is detaching and trying to grab the
	; block while we're blocked holding it waiting for the dialog
	; to finish.  Whee.
	;
		
		mov	bx, ds:[ITI_handle]
		call	HandleV
		push	bx
		
		mov_tr	ax, bp
		push	ax
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, ax
		movdw	ss:[bp].SDP_customString, esdi
		movdw	ss:[bp].SDP_stringArg1, cxdx
		movdw	ss:[bp].SDP_stringArg2, dssi
		clr	ss:[bp].SDP_helpContext.segment
		call	UserStandardDialog
		pop	bp

	;
	; Re-grab the semaphore for our caller's benefit.
	;
		
		pop	bx
		call	HandleP
done:
		.leave
		ret
DisplayErrorCommon	endp

ErrorCode	ends
