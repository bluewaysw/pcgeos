COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3Common.asm

AUTHOR:		Andy Chiu, Feb  7, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 7/94   	Initial revision


DESCRIPTION:
	Common routines that are used at different places in the
	fax printer driver.	
		
	$Id: group3Common.asm,v 1.1 97/04/18 11:53:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                DoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Puts up a standard dialog

CALLED BY:      GLOBAL
PASS:           si - chunk handle of string
                ax - CustomDialogBoxFlags
RETURN:         ax - InteractionCommand
DESTROYED:      nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        atw     11/11/93        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoDialog        proc    near
                uses    bp
                .enter
                
                sub     sp, size StandardDialogOptrParams
                mov     bp, sp
                mov     ss:[bp].SDOP_customFlags, ax
                mov     ss:[bp].SDOP_customString.handle, handle StringBlock
                mov     ss:[bp].SDOP_customString.chunk, si
                clrdw   ss:[bp].SDOP_stringArg1
                clrdw   ss:[bp].SDOP_stringArg2
                clrdw   ss:[bp].SDOP_customTriggers
                clrdw   ss:[bp].SDOP_helpContext
                call    UserStandardDialogOptr
                
                .leave
                ret
DoDialog        endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutThreadInFaxDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the calling thread in the Fax Directory.
		This directory is used to hold fax files and
		put in the fax information file

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set if unable to go to directory
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutThreadInFaxDir	proc	near
		uses	ax,bx,dx,ds
		.enter
	;
	; Try to set the current thread to the current fax directory.
	; Otherwise, make the directory.
	;
		segmov	ds, cs
		mov	dx, offset faxDir
		mov	bx, FAX_DISK_HANDLE
		call	FileSetCurrentPath
		jc	dirError

exit:
		.leave
		ret
dirError:
	;
	; Go to the Standard path of the Fax Dir and make
	; the Fax Dir.
	;
		mov	dx, offset blankString
		mov	bx, FAX_DISK_HANDLE
		call	FileSetCurrentPath
		jc	diskHandleError

		mov	dx, offset faxDir
		call	FileCreateDir
		jc	exit			; return carry set

		call	FileSetCurrentPath
		clc				; return carry unset
		jmp	exit

	;
	; If for some reason the PrivData directory got taken out, re create it.
	;
diskHandleError:
		call	FileCreateDir
		jc	exit
		jmp	dirError

PutThreadInFaxDir	endp


