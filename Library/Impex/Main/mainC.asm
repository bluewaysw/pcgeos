COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex
FILE:		mainC.asm

AUTHOR:		Maryann Simmons, Jul 30, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/30/92		Initial revision


DESCRIPTION:
	Contains C stubs for Impex routines


	$Id: mainC.asm,v 1.1 97/04/04 23:49:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetGeosConvention

ImpexCode	segment resource

COMMENT @--------------------------------------------------------------------
C FUNCTION:	ImpexCreateTempFile

C DECLARATION:	extern TransErrorInfo
			ImpexCreateTempFile(char *buffer, word fileType,
					    FileHandle *file)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	maryann 7/30		Initial version
	jenny	10/30/92	Changed to return TransErrorInfo type

-----------------------------------------------------------------------------@

IMPEXCREATETEMPFILE	proc far buffer:fptr, fileType:word, file:fptr
	uses	di, bp, es
	.enter

	les	di, buffer		; ES:DI <- filename buffer
	mov	ax, fileType		; AX <- IMPEX_TEMP_VM_FILE or
					;       IMPEX_TEMP_NATIVE_FILE
	push	bp			; save to access local variables
	call	ImpexCreateTempFile	; returns AX = TransError
	mov	cx, bp			; CX <- file handle
	pop	bp			; restore to access locals
	les	di, file
	mov	es:[di], cx		; return file handle
	mov	dx, bx			; DX <- handle of error
					;  message, if any
	.leave
	ret

IMPEXCREATETEMPFILE	endp
		
COMMENT @--------------------------------------------------------------------
C FUNCTION:	ImpexDeleteTempFile

C DECLARATION:	extern TransErrorInfo 
			ImpexDeleteTempFile(char *buffer, FileHandle metafile,
				     word fileType)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	maryann 7/30		Initial version
	jenny	10/30/92	Changed to return TransErrorInfo type

-----------------------------------------------------------------------------@
IMPEXDELETETEMPFILE	proc far buffer:fptr, metafile:hptr, 
					fileType:word
	uses	di, ds
	.enter

	lds	dx, buffer		; DS:DX <- filename buffer
	mov	bx, metafile		; BX <- handle of file to delete
	mov	ax, fileType		; AX <- IMPEX_TEMP_VM( or NATIVE )_FILE
	call	ImpexDeleteTempFile	; return AX <- TransError
	mov	dx, bx			; DX <- handle of error
					;  message, if any
	.leave
	ret
IMPEXDELETETEMPFILE endp

COMMENT @--------------------------------------------------------------------
C FUNCTION:	ImpexImportFromMetafile

C DECLARATION:	extern TransErrorInfo 
			ImpexImportFromMetafile(Handle xlatLib,word routine,
				   VMFileHandle xferFile, FileHandle metafile,
				   dword *xferFormat, word arg1, word arg2)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	maryann 7/30		Initial version
	jenny	10/30/92	Changed to return TransErrorInfo type

-----------------------------------------------------------------------------@
IMPEXIMPORTFROMMETAFILE	proc far xlatLib:hptr, routine:word,
			xferFile:hptr, metafile:hptr,
			xferFormat:fptr, arg1:word, arg2:word
	uses	si, di, bp, ds
	.enter

	push	bp			; save to access locals
	mov	ax, routine		; AX <- entry point number of routine
	mov	di, xferFile		; DI <- VMFile to hold xfer Format
	mov	bx, metafile		; BX <- handle of metafile
	mov	ds, arg1		; extra args??
	mov	si, arg2
	mov	bp, xlatLib		; BP <- handle xlatLib
	call	ImpexImportFromMetafile	; returns AX <- TransError
					; 	 DX:CX <- transfer format
	pop	bp			; restore BP to access locals
	lds	si, xferFormat
	movdw	ds:[si], dxcx		; return transfer format 
	mov	dx, bx			; DX <- handle of error
					;  message, if any
	.leave
	ret

IMPEXIMPORTFROMMETAFILE endp

COMMENT @--------------------------------------------------------------------
C FUNCTION:	ImpexExportToMetafile

C DECLARATION:	extern TransErrorInfo
			ImpexExportToMetafile(Handle xlatLib,word routine,
				   VMFileHandle xferFile, FileHandle metafile,
				   dword xferFormat, word arg1, word arg2)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	maryann 7/30		Initial version
	jenny	10/30/92	Changed to return TransErrorInfo type

-----------------------------------------------------------------------------@
IMPEXEXPORTTOMETAFILE	proc far xlatLib:hptr, routine:word,
			xferFile:hptr, metafile:hptr,xferFormat:dword,
			arg1:word, arg2:word
	uses	si, di, bp, ds
	.enter

	push	bp			; save BP to access locals
	mov	bx, xlatLib		; BX <- handle xlatLib
	mov	ax, routine		; AX <- entry point number if routine
	movdw	dxcx, xferFormat	; DXCX <- VMFile for transfer Format
	mov	di, xferFile		; DI <- handle of transferFile
	mov	ds, arg1		; extra args??
	mov	si, arg2
	mov	bp, metafile		; BP <- metafile Handle
	call	ImpexExportToMetafile	; returns AX <- TransError

	pop	bp			; restore BP to access locals
	mov	dx, bx			; DX <- handle of error
					;  message, if any
	.leave
	ret
IMPEXEXPORTTOMETAFILE endp

COMMENT @--------------------------------------------------------------------
C FUNCTION:	ImpexUpdateImportExportStatus

C DECLARATION:	extern Boolean
			ImpexUpdateImportExportStatus(fptr *message,
							word *percent)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	maryann 7/30		Initial version
	jenny	10/30/92	Changed to return TransErrorInfo type

-----------------------------------------------------------------------------@
IMPEXUPDATEIMPORTEXPORTSTATUS	proc far	message:fptr, percent:word
	uses	ds
	.enter

	movdw	dxsi, message
	mov	ds, dx			; message => DS:SI
	mov	ax, percent
	call	ImpexUpdateImportExportStatus

	.leave
	ret
IMPEXUPDATEIMPORTEXPORTSTATUS	endp

ImpexCode ends

	SetDefaultConvention
