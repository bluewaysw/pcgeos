COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiramisu
MODULE:		Fax
FILE:		faxprintEndJob.asm

AUTHOR:		Jacob Gabrielson, Apr 16, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT PrintEndJob             End routine for Print Driver.  Makes sure
				the file is closed and contact the
				faxspooler.

    INT FaxprintNukeSwathBuffers 
				Frees the swath print buffers, if they
				exist.

    INT FaxprintDeleteFile      Closes the VM fax file.

    INT FaxprintWritePages      Write FFH_numPages to the fax file header.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/16/93   	Initial revision
	AC	9/ 8/93		Changed for Group3
	jdashe	10/19/94	Modified for Tiramisu


DESCRIPTION:
	
		

	$Id: faxprintEndJob.asm,v 1.1 97/04/18 11:53:04 newdeal Exp $

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

		mov	bx, handle dgroup
		call	MemDerefDS		; ds <- dgroup
	;
	; Free the swath buffers.
	;
		call	FaxprintNukeSwathBuffers
	;
	;  See if anything bad happened.
	;
		clr	bx
		xchg	bl, ds:[errorFlag]
		tst	bl
		jnz	handleError
	;
	; Write the number of pages to the file header.
	;
		call	FaxprintWritePages	; cx <- number of pages in file
	;
	; Also write the number of pages to the pstate.
	;
		mov	ds, bp			; ds:0 <- PState
		clc				; all's well.
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
if MAILBOX_DOESNT_HANDLE_THE_OUT_OF_DISK_SPACE_ERROR
	;
	; There's no need for us to put any error box up if the mailbox system
	; will put one up too.  In fact, having the two error boxes up at the
	; same time causes focus problems resulting in the mail box error never
	; leaving the screen!  So we'll not do it.
	;
	;
		mov	si, cs:[PrintDriverErrorCodeMessages].[bx]
		tst_clc	si			; clears carry
		jz	exit			; jump if all's well
CheckHack<size PrintDriverErrorCodeMessages eq PrintDriverErrorCodes>

showErrorDialog::
	;
	; Non-responder: put up a warning via DoDialog.
	;
		mov	ax, \
			CustomDialogBoxFlags <1,CDT_ERROR,GIT_NOTIFICATION,0>
		call	DoDialog
		;
		; FALL THROUGH TO errorOccurred
		;
	; 
	; Both responder and non-responder code falls through to this
	; point!
	;
errorOccurred::
endif ;MAILBOX_DOESNT_HANDLE_THE_OUT_OF_DISK_SPACE_ERROR 
		stc
		jmp	exit
		
		
PrintEndJob	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintNukeSwathBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees the swath print buffers, if they exist.

CALLED BY:	PrintEndJob

PASS:		ds	- dgroup

RETURN:		nothing

DESTROYED:	bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxprintNukeSwathBuffers	proc	near
		.enter

EC <		call	ECCheckDGroupDS					>
		
		clr	bx
		xchg	bx, ds:[compressedLineHandle]
		tst	bx
		jz	freeBuffer1
		call	MemFree
freeBuffer1:
		clr	bx
		xchg	bx, ds:[swathBuffer1Handle]
		tst	bx
		jz	freeBuffer2
		call	MemFree

freeBuffer2:
		clr	bx
		xchg	bx, ds:[swathBuffer2Handle]
		tst	bx
		jz	done
		call	MemFree
done:
		.leave
		ret
FaxprintNukeSwathBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintWritePages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write FFH_numPages to the fax file header.

CALLED BY:	FaxprintEndJob

PASS:		nothing
RETURN:		cx	- number of pages in the file
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
FaxprintWritePages	proc	near
		uses	ax, bx, si, bp, ds
		.enter
	;
	; Get file handle of the file
	;
		mov	bx, handle dgroup
		call	MemDerefDS			; ds <- dgroup
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
FaxprintWritePages	endp


