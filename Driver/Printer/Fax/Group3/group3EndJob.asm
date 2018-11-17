COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3EndJob.asm

AUTHOR:		Jacob Gabrielson, Apr 16, 1993

ROUTINES:
	Name			Description
	----			-----------
	PrintEndJob		End routine for Print Driver.  Makes sure 
				the file is closed and contact the faxspooler.

	Group3CloseFile		Closes the VM fax file.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/16/93   	Initial revision
	AC	9/ 8/93		Changed for Group3


DESCRIPTION:
	
		

	$Id: group3EndJob.asm,v 1.1 97/04/18 11:52:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End routine for Print Driver.  Makes sure the file is 
		closed and contact the faxspooler.

CALLED BY:	DriverStrategy
PASS:		bp	= PState segment
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEndJob	proc	far
		uses	ax, bx, dx, bp, si, ds
		.enter
	;
	;  See if anything bad happened.
	;
		mov	ax, segment dgroup
		mov	ds, ax

		clr	bx
		xchg	bl, ds:[errorFlag]
		tst	bl
		jnz	handleError
	;
	;  Make the cover page (if any) and prepend it to the fax file.
	;
		call	Group3CreateCoverPage
		jc	closeFile
	;
	;  Write the number of pages to the file header.
	;
		call	Group3WritePages
	;
	; Close the VM fax file.  If carry is returned your file is hosed
	;
closeFile:
		call	Group3CloseFile

	;
	; Notify the spooler that a fax has been printed out and ready
	; to spool.  First, set up the following:
	; 	ds:si <- fax file name
	; 	bxax <- fax spool id
	;
		mov	ds, bp

		.warn	-field
		lea	si, ds:[PS_jobParams].JP_printerData.FFH_fileName
		movdw	bxax, ds:[PS_jobParams].JP_printerData.FFH_spoolID
		.warn	@field		

		mov	dx, GWNT_FAX_NEW_JOB_COMPLETED
		call	IACP_NotifySpooler	; carry set on error

exit:
		.leave
		ret

	;
	;	---------------------------
	;	E R R O R   H A N D L E R S
	;	---------------------------
	;

	;
	; These check a table to see what string it should pop up if an error
	; occurs.  If the offset to the string is 0, then it will not
	; pop up an error message.
	;
handleError:
		push	bx, ax
		movdw	bxax, FAX_ERROR_SPOOL_ID
		mov	dx, GWNT_FAX_NEW_JOB_COMPLETED
		call	IACP_NotifySpooler	; carry set on error
		pop	bx, ax

		mov	si, cs:[PrintDriverErrorCodeMessages].[bx]
		tst	si
		jz	exit

showErrorDialog::
		mov	ax, \
			CustomDialogBoxFlags <1,CDT_ERROR,GIT_NOTIFICATION,0>
		call	DoDialog
	;
	;  Note:  if the error was PDEC_RAN_OUT_OF_DISK_SPACE, we
	;  have to delete the output (fax) file.  Doing it here
	;  may not be the best architecture in the world, but ...
	;
		cmp	bx, PDEC_RAN_OUT_OF_DISK_SPACE
		jne	exit
		call	Group3DeleteFile
		
		jmp	exit
		
PrintEndJob	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3CloseFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the VM fax file.

CALLED BY:	PrintEndJob
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3CloseFile	proc	near
		uses	ax, bx, bp, ds, si
		.enter
	;
	;  Get file handle of the file.
	;
		mov	ax, segment dgroup
		mov	ds, ax
		mov	bx, ds:[outputVMFileHan]
	;
	;  Get the file header so we can write that this is 
	;  a valid fax file.
	;
		call	FaxFileGetHeader		; ds:si <- FaxFileHeader
							; bp <- mem block handle
		mov	ds:[si].FFH_status, FFS_READY
		
		call	VMDirty
		call	VMUnlock
	;
	;  Close the VM file.
	;
		mov	al, FILE_NO_ERRORS
		call	VMClose
		
		.leave
		ret
Group3CloseFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3DeleteFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the VM fax file.

CALLED BY:	PrintEndJob

PASS:		ds = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3DeleteFile	proc	near
		uses	ax, bx, cx, dx, ds
		.enter
	;
	;  Get file handle of the file.
	;
		mov	bx, ds:[outputVMFileHan]	; bx = vm file handle
	;
	;  Get the filename.
	;
		sub	sp, FILE_LONGNAME_BUFFER_SIZE
		movdw	cxdx, sssp			; cx:dx = buffer
		call	FaxFileGetName			; cx:dx = filled
	;
	;  Switch to Ye Olde Fax Directory.
	;
		call	FilePushDir
		call	PutThreadInFaxDir
	;
	;  Delete the file.  We should probably care if it's not
	;  deleted properly...hmmm...
	;
		call	VMRevert
		clr	al				; flags
		call	VMClose				; close for delete
		mov	ds, cx				; ds:dx = filename
		call	FileDelete			; nukes ax
		call	FilePopDir			; restore working dir

		add	sp, FILE_LONGNAME_BUFFER_SIZE	; clean up stack
		
		.leave
		ret
Group3DeleteFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3WritePages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write FFH_numPages to the fax file header.

CALLED BY:	Group3EndJob

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:
		- modifies fax file header
		- requires that the file already be open

PSEUDO CODE/STRATEGY:

	- get the header
	- get the number of pages
	- write pages to header (includes cover page if any)
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3WritePages	proc	near
		uses	ax, bx, cx, si, bp, ds
		.enter
	;
	; Get file handle of the file
	;
		mov	ax, segment dgroup
		mov	ds, ax
		mov	bx, ds:[outputVMFileHan]
	;
	; Get the file header so we can write that this is a valid fax file
	;
		call	FaxFileGetPageCount		; cx = # pages
		call	FaxFileGetHeader		; ds:si = header
							; bp = mem block
		mov	ds:[si].FFH_numPages, cx
		
		call	VMDirty
		call	VMUnlock			; unlock map block

		.leave
		ret
Group3WritePages	endp


