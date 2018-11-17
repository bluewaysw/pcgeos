COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Drive
FILE:		driveC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: driveC.asm,v 1.1 97/04/05 01:11:23 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_File	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DriveGetStatus

C DECLARATION:	extern word
			 DriveGetStatus(word driveNumber);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DRIVEGETSTATUS	proc	far	; driveNumber:word
	C_GetOneWordArg	ax,   bx,cx	;ax = drive

	call	DriveGetStatusFar
	mov	al, ah
	mov	ah, 0
	jnc	noError
	mov	ax, 0		; return 0, so DS_PRESENT is clear
noError:
	ret

DRIVEGETSTATUS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DriveGetExtStatus

C DECLARATION:	extern word
			 DriveExtGetStatus(word driveNumber);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/26/91		Initial version

------------------------------------------------------------------------------@
DRIVEGETEXTSTATUS	proc	far	; driveNumber:word
	C_GetOneWordArg	ax,   bx,cx	;ax = drive

	call	DriveGetExtStatus
	jnc	noError
	mov	ax, 0		; return 0, so DS_PRESENT is clear
noError:
	ret

DRIVEGETEXTSTATUS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DriveGetDefaultMedia

C DECLARATION:	extern MediaType
			 DriveGetDefaultMedia(word driveNumber);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DRIVEGETDEFAULTMEDIA	proc	far	; driveNumber:word
	C_GetOneWordArg	ax,   bx,cx	;ax = drive

	call	DriveGetDefaultMedia
	mov	al, ah
	mov	ah, 0
	jnc	done
	mov	al, MEDIA_NONEXISTENT
done:
	ret

DRIVEGETDEFAULTMEDIA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DriveTestMediaSupport

C DECLARATION:	extern Boolean		/* true if media supported */
			 DriveTestMediaSupport(word driveNumber,
							MediaType media);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DRIVETESTMEDIASUPPORT	proc	far
	C_GetTwoWordArgs	ax, bx,   cx,dx	;ax = num, bx = media

	mov	ah, bl
	call	DriveTestMediaSupport
	mov	ax, 0
	jc	done		; => not supported
	dec	ax
done:
	ret

DRIVETESTMEDIASUPPORT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DRIVEGETNAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	DriveGetName

C DECLARATION:	extern char *
			 DriveGetName(word driveNumber,
				      char *buffer,
				      word bufferSize);

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DRIVEGETNAME	proc	far	driveNumber:word,
			    	buffer:fptr.char,
				bufferSize:word
		uses	es, di
		.enter
		les	di, ss:[buffer]
		mov	ax, ss:[driveNumber]
		mov	cx, ss:[bufferSize]
		call	DriveGetName
	;
	; Return es:di far pointer in dx:ax, as is proper.
	; 
		mov_tr	ax, di
		mov	dx, es
		jnc	done
	;
	; error -- signal by returning null pointer
	;
		clr	ax
		mov	dx, ax
done:
		.leave
		ret
DRIVEGETNAME	endp

C_File	ends

	SetDefaultConvention
