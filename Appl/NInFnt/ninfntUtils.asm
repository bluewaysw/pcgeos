COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Converter
FILE:		ninfntUtils.asm

AUTHOR:		Gene Anderson, Apr 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/26/91		Initial revision
	JDM	91.05.10	Fixed ReportError carry trashing.
	JDM	91.05.13	Added conversion status support.

DESCRIPTION:
	This file contains a bunch of miscellaneous routines that
	perform various asundry things.

	$Id: ninfntUtils.asm,v 1.1 97/04/04 16:16:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFilePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current offset in file
CALLED BY:	UTILITY

PASS:		dx - file handle
RETURN:		cx:ax - offset in file
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetFilePos	proc	near
	uses	bx, dx
	.enter

	mov	bx, dx				;bx <- file handle
	mov	al, FILE_SEEK_RELATIVE		;al <- file flags
	clr	cx
	clr	dx				;cx:dx <- offset 0
	call	FilePos
	mov	cx, dx				;cx:ax <- offset in file

	.leave
	ret
GetFilePos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFilePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current offset in file
CALLED BY:	UTILITY

PASS:		dx - file handle
		cx:ax - offset in file
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetFilePos	proc	near
	uses	ax, bx, cx, dx
	.enter

	mov	bx, dx				;bx <- file handle
	mov	dx, ax				;cx:dx <- offset in file
	mov	al, FILE_SEEK_START		;al <- file flags
	call	FilePos

	.leave
	ret
SetFilePos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReportError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up annoying DB to inform user something went wrong
CALLED BY:	ConvertNimbusFont()

PASS:		ax - NimbusError
RETURN:		Void.
DESTROYED:	Nada (flags preserved).

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/26/91		Initial version
	JDM	91.05.10	Added flags preservation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReportError	proc	near
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter

	; Save the flags.
	pushf

	mov	si, ax				;si <- Nimbus Error
	add	si, offset FIRST_ERROR		;si <- chunk handle
	mov	bx, handle ErrorStrings		;thanks to single-launchability
	call	GeodeLockResource
	mov	di, ax				;di <- seg addr of error
	mov	ds, ax
	mov	bp, ds:[si]			;di:bp <- ptr to string

	mov	al, SDBT_CUSTOM
	mov	ah, SRS_ACKNOWLEDGE or (CDT_ERROR shl offset CDBF_TYPE)
	call	UserStandardDialog

	call	MemUnlock			;done with resource

	; Restore the flags.
	popf

	.leave
	ret
ReportError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertStatusInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Let the application know that we're beginning to
		process the font file.

PASS:		Void.

RETURN:		Void.

DESTROYED:	Nada (flags preserved).

REGISTER/STACK USAGE:
	Full register file saved.
	AX, BX, DI.

PSEUDO CODE/STRATEGY:
	Call the process to let it know that we're doing things.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Relys on being single-launchable.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.14	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertStatusInit	proc	near	uses	ax,bx,cx,dx,di,si,es,ds,bp
	.enter

	; Save the flags.
	pushf

	; Let the process class know what's happening.
	mov	ax, METHOD_CONVERSION_STATUS_INIT
	mov	bx, handle 0
	mov	di, mask MF_CALL
	call	ObjMessage

	; Restore the flags
	popf

	.leave
	ret
ConvertStatusInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertStatusSetFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Let the application know that we're starting to process
		a font file.

PASS:		AX = Font file number being processed (zero based).

RETURN:		Void.

DESTROYED:	Nada (flags preserved).

REGISTER/STACK USAGE:
	Full register file saved.
	AX, BX, DI.

PSEUDO CODE/STRATEGY:
	Call the process to let it know what we're doing.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Relys on being single-launchable.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.14	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertStatusSetFile	proc	near	uses	ax,bx,cx,dx,di,si,es,ds,bp
	.enter

	; Save the flags.
	pushf

	; Let the process class know what's happening.
	mov	cx, ax				; File being processed.
	mov	ax, METHOD_CONVERSION_STATUS_SET_FILE
	mov	bx, handle 0
	mov	di, mask MF_CALL
	call	ObjMessage

	; Restore the flags
	popf

	.leave
	ret
ConvertStatusSetFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertStatusSetChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Let the application know that a(nother) character is
		being processed.

PASS:		DL = Character about to be converted.

RETURN:		Void.

DESTROYED:	Nada (flags preserved).

REGISTER/STACK USAGE:
	Full register file saved.
	AX, BX, DI.

PSEUDO CODE/STRATEGY:
	Call the process to let it know what we're doing.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Relys on being single-launchable.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.14	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertStatusSetChar	proc	near	uses	ax,bx,cx,dx,di,si,es,ds,bp
	.enter

	; Save the flags.
	pushf

	; Let the process class know what's happening.
	mov	cx, dx				; Character being beaten.
	mov	ax, METHOD_CONVERSION_STATUS_SET_CHAR
	mov	bx, handle 0
	mov	di, mask MF_CALL
	call	ObjMessage

	; Restore the flags
	popf

	.leave
	ret
ConvertStatusSetChar	endp


ConvertCode	ends
