COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/Main
FILE:		mainMetafile.asm

AUTHOR:		Jenny Greenwood, 17 February 1992

ROUTINES:
	Name				Description
	----				-----------
    GLB	ImpexCreateTempFile		Create metafile in the waste directory.
    GLB	ImpexDeleteTempFile		Close and delete metafile.
    GLB	ImpexExportToMetafile		Convert transfer format to metafile.
    GLB	ImpexImportFromMetafile		Convert metafile to transfer format.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	2/92		Initial version

DESCRIPTION:
	$Id: mainMetafile.asm,v 1.1 97/04/05 00:00:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexCreateTempFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Create and open a unique metafile in the waste directory.

CALLED BY:	GLOBAL

PASS:		ES:DI	= File name buffer (FILE_LONGNAME_BUFFER_SIZE)
		AX	= IMPEX_TEMP_VM_FILE or IMPEX_TEMP_NATIVE_FILE

RETURN:		ES:DI	= File name buffer filled
		BP	= File handle
		AX	= TransError (0 = no error)
		BX	= memory handle of error text if ax = TE_CUSTOM

DESTROYED:	Nothing

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:
		Code courtesy of Jim (via Don).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.
	jenny	4/09/92		Rewrote to deal with file system changes.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexCreateTempFile	proc	far
	.enter

	; Call to create temporary file
	;
EC <	cmp	ax, IMPEX_TEMP_VM_FILE					>
EC <	je	doneEC							>
EC <	cmp	ax, IMPEX_TEMP_NATIVE_FILE				>
EC <	ERROR_NE IMPEX_INVALID_ARG_PASSED_TO_CREATE_TEMP_FILE		>
EC <doneEC:								>
	call	CreateTempFile			; file handle => AX
	mov_tr	bp, ax				; file handle => BP
	mov	ax, TE_NO_ERROR			; assume the best
	jnc	done				; if no error, we're done
	mov	ax, TE_METAFILE_CREATION_ERROR	; else we couldn't create file
done:
	.leave
	ret
ImpexCreateTempFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexDeleteTempFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Close and delete metafile in the waste directory.

CALLED BY:	GLOBAL

PASS:		DS:DX	= File name buffer
		BX	= File handle
		AX	= IMPEX_TEMP_VM_FILE or IMPEX_TEMP_NATIVE_FILE

RETURN:		AX	= TransError (0 = no error)
		BX	= Memory handle of error text if ax = TE_CUSTOM

DESTROYED:	Nothing

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:
		We ignore any problems in closing/deleting the metafile,
		as this shouldn't affect the user.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexDeleteTempFile	proc	far
	uses	bp
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dsdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	; Close the temporary file, and then delete it
	;
EC <	cmp	ax, IMPEX_TEMP_VM_FILE					>
EC <	je	doneEC							>
EC <	cmp	ax, IMPEX_TEMP_NATIVE_FILE				>
EC <	ERROR_NE IMPEX_INVALID_ARG_PASSED_TO_CREATE_TEMP_FILE		>
EC <doneEC:								>
	mov_tr	bp, ax				; file type argument => BP
	call	FilePushDir
	mov	ax, SP_WASTE_BASKET
	call	FileSetStandardPath
	CheckHack <IMPEX_TEMP_NATIVE_FILE eq 0>
	tst	bp
	jnz	vmFile
	clr	al				; we can handle errors
	call	FileClose			; ignore the errors returned :)
common:
	call	FileDelete
	clr	ax				; returning no error
	call	FilePopDir

	.leave
	ret

	; Delete the VM file
vmFile:
	mov	al, FILE_NO_ERRORS
	call	VMClose				; close the VM file
	jmp	common
ImpexDeleteTempFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexImportFromMetafile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert a metafile to a transfer format

PASS:		bx	- handle of the metafile (open for read)
		ax	- entry point number of library routine to call
		di	- handle of VM file to hold transfer format
		bp	- handle of metafile translation library to use
		ds	- additional data for metafile library as needed
		si	- additional data for metafile library as needed

RETURN:		dx:cx	- VM chain containing transfer format
		ax	- TransError code (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM

DESTROYED:	Nothing

PSEUDOCODE/STRATEGY:	

		Reset file position to start of metafile and
		 call the metafile library.

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/12/91		Initial version.
	jenny	9/19/91		Added some comments and EC code.
	jenny	2/92		Rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexImportFromMetafile	proc	far
	uses	bp
	.enter

	; Reset file position to start of metafile.
	;
	call	ResetFilePos
	xchg	bx, bp				; bx <- library handle
						; bp <- metafile handle

	; Import from the metafile to a transfer format

	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable		; dx:cx	<- VM chain containing
						;	transfer format
						; ax <- TransError or 0
						; bx <- error msg handle
						;	if ax = TE_CUSTOM
	.leave
	ret
ImpexImportFromMetafile	endp



Comment @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexExportToMetafile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert a transfer format to a metafile.

PASS:		bx	- handle of metafile translation library to use
		ax	- entry point number of library routine to call
		dx:cx	- VM chain containing transfer format
		di	- VM file handle of transfer format
		bp	- handle of the metafile (open for read/write)
		ds	- additional data for metafile as needed
		si	- additional data for metafile as needed

RETURN:		ax	- TransError code (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/ 8/91		Initial version
	jenny	2/92		Rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexExportToMetafile	proc	far
	uses	ds, si, di, bp
	.enter

	; Translate transfer format into metafile format
	; and free transfer format.
	;
	push	bp				; save metafile handle
	push	di				; save vm file handle
	pushdw	dxcx
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable		; ax <- TransError or 0
						; bx <- error msg handle
						;	if ax = TE_CUSTOM
	mov	di, bx				; di <- save error msg handle
	mov_tr	cx, ax				; CX <- TransError
	popdw	axbp				; ax:bp <- VM chain
	pop	bx				; bx <- VM file handle
	call	VMFreeVMChain			; free transfer format

	; Reset file position to start of metafile.
	;
	pop	bx				; bx <- metafile handle
	call	ResetFilePos

	; Return TransError in ax and error msg, if any, in bx.
	;
	mov_tr	ax, cx
	mov	bx, di

	.leave
	ret
ImpexExportToMetafile	endp

ImpexCode	ends
