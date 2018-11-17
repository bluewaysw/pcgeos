COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/Main
FILE:		mainExport.asm

AUTHOR:		Don Reeves, May 28, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/28/92		Initial revision

DESCRIPTION:
	Contains the export code for the Impex library

	$Id: mainExport.asm,v 1.1 97/04/04 23:39:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITPExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up for and do the export.

CALLED BY:	IPSpawnThreadAndExport

PASS:		CX	= ImpexThreadInfo handle
			
RETURNED:	Nothing
	
DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:
		* Create destination file
		* Create intermediate VM file

		Get the transfer format from the app.
		Set up and make the translation library call to export
		the transfer format.
		Detach.

Known BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jenny	1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ITPExport	method	dynamic	ImpexThreadProcessClass, MSG_ITP_EXPORT
		.enter

		; Load the translation library to perform the export
		;
		mov	bx, cx			; ImpexThreadInfo handle => BX
		call	ImpexThreadInfoPLock	; ImpexThreadInfo => DS:0
		mov	ax, TR_GET_EXPORT_OPTIONS
		call	PrepareToCallLibrary
		jc	error			; if error, quit

		; Create the output file & transfer VM file. Do it in
		; this order, as disk full situations seem to be better
		; handled (according to Chris Hawley)
		;
		call	CreateTransferVMFile
		jc	error			; if error, abort
		call	CreateOutputFile
		jc	error			; if error, abort

		; Now request the transfer format from the application
		;
		mov	ax, MSG_EXPORT_CONTROL_EXPORT_COMPLETE
		call	SendMessageToApplication		
		jc	error			; if error, abort
done:
		call	ImpexThreadInfoUnlockV	; unlock & release Info block

		.leave
		ret

		; We encountered an error, so abort
error:
		call	DestroyThread		; destroy the thread
		jmp	done
ITPExport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITPExportFromAppComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The application has completed its export process, so now we
		convert the data into the desired data file

CALLED BY:	GLOBAL (MSG_ITP_EXPORT_FROM_APP_COMPLETE)

PASS: 		SS:BP	= ImpexTranslationParams
		CX	= ImpexThreadInfo handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS

PSEUDO CODE/STRATEGY:
		* Export to destination format
		* Delete source VM file
		* Close destination file
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ITPExportFromAppComplete	method dynamic	ImpexThreadProcessClass,
						MSG_ITP_EXPORT_FROM_APP_COMPLETE
		.enter

		; Prepare to call translation library
		;
		mov	bx, cx			; ImpexThreadInfo handle => BX
		call	ImpexThreadInfoPLock	; ImpexThreadInfo => DS:0

		; Have the translation library export the data. We
		; first push EF_transferVMChain ourselves; CallLibrary
		; then pushes those values common to the ExportFrame and
		; the ImportFrame and calls the library. We restore
		; the stack pointer here since the ExportFrame and the
		; ImportFrame are of different sizes.
		;
		CheckHack <(offset EF_clipboardFormat) +\
			   (size EF_clipboardFormat) eq \
				(size ExportFrame) >

		push	ss:[bp].ITP_clipboardFormat
		push	ss:[bp].ITP_manufacturerID
		pushdw	ss:[bp].ITP_transferVMChain ; EF_transferVMChain
		mov	ax, TR_EXPORT
		call	CallLibrary		; ax <- TransError or 0
		add	sp, size ExportFrame	; restore stack pointer
		tst	ax			; any errors ??
		jz	done			; no, so we're done
		call	DisplayTransError	; display the error value

		; Kill off the thread
done:
		call	DestroyThread
		call	ImpexThreadInfoUnlockV	; unlock & release thread info

		.leave
		ret
ITPExportFromAppComplete	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateOutputFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a file to export to

CALLED BY:	ITPExport

PASS:		DS	= ImpexThreadInfo segment

RETURN:		Carry	= Clear (success)
			- or -
		Carry	= Set (failure)

DESTROYED:	Nothing
		
PSEUDO CODE/STRATEGY:	
		If file exists put up a dialog asking if they
		want to overwrite it.

KNOWN BUGS/SIDEFFECTS/IDEAS:	

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateOutputFile	proc	near	
		uses	ax, cx, dx
		.enter

		; Save current directory and go to document directory
		;
		call	GetAndSetPath
		mov	bp, dx			; bp <- error code
		jc	doDialog
		mov	dx, offset ITI_srcDestName
		mov	ah, FILE_CREATE_ONLY or mask FCF_NATIVE
	       	mov     al, FileAccessFlags <FE_NONE,FA_READ_WRITE>
		clr	cx
		call	FileCreate		; create file
		jnc	done
	
		; If the file exists we want to put up a dialog box asking if
		; the user wants to overwrite it or not
		;
		cmp	ax, ERROR_FILE_EXISTS		 
		jne	creationError		; for any other error, jump
		mov	ax, IE_FILE_ALREADY_EXISTS
		call	DisplayErrorAndBlock	; put up dialog
		cmp	ax, IC_YES		; check for response
		stc				; assume the worst
		jne	exit			; if not yes, abort

		; Truncate current file
		;
	       	mov     ax, FileAccessFlags <FE_NONE,FA_READ_WRITE> or \
			    (FILE_CREATE_TRUNCATE or mask FCF_NATIVE) shl 8
		clr	cx
		mov	dx, offset ITI_srcDestName
		call	FileCreate		; create file over old one
		jc	creationError

		; Restore the current directory
done:
		mov	ds:[ITI_srcDestFile], ax ; store the handle away
exit:
		call	FilePopDir

		.leave
		ret

		; We still couldn't open the file, so report to user & abort
creationError:
		mov	bp, IE_INVALID_FILE_NAME
		cmp	ax, ERROR_INVALID_NAME
		je	doDialog
		mov	bp, IE_FILE_WRITE_PROTECTED
		cmp	ax, ERROR_WRITE_PROTECTED
		je	doDialog
		mov	bp, IE_FILE_NO_DISK_SPACE
		cmp	ax, ERROR_SHORT_READ_WRITE
		je	doDialog
		mov	cx, ds			; cx:dx <- file name
		mov	bp, IE_FILE_ALREADY_OPEN
		cmp	ax, ERROR_SHARING_VIOLATION
		je	doDialog
		mov	bp, IE_FILE_MISC_ERROR
doDialog:
		mov_tr	ax, bp			; ImpexError => AX
		call	DisplayErrorAndBlock	; returns carry = set
		jmp	exit

CreateOutputFile	endp

ImpexCode	ends
