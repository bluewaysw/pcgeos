COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosConvertDBCS.asm

AUTHOR:		Gene Anderson, Aug 17, 1993

ROUTINES:
	Name			Description
	----			-----------
    GLB LocalDosToGeos		Convert DOS text to GEOS

    GLB LocalGeosToDos		Convert GEOS text to DOS

    INT ConvertBuffer		Convert a buffer of text to or from
				DOS/GEOS

    GLB LocalDosToGeosChar	Map a single character from DOS

    GLB LocalGeosToDosChar	Map a single character to DOS

    INT ConvertCharacter	Do conversion of a single character to or
				from GEOS

    GLB LocalGetCodePage	Get the current code page in use by DOS

    GLB LocalIsDosChar		Check to see if character in the DOS
				character set.

    GLB LocalIsCodePageSupported Checks to see if the passed code page is a
				supported one.

    INT LocalCallFSD		Call DR_FS_CONVERT_STRING in the
				appropriate FSD

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/17/93		Initial revision


DESCRIPTION:
	Routines for mapping text between DOS and GEOS

	$Id: dosConvertDBCS.asm,v 1.1 97/04/05 01:16:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSConvert	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalDosToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert DOS text to GEOS
CALLED BY:	GLOBAL

PASS:		ds:si - ptr to text (DOS character set)
>		es:di - ptr to dest buffer (Unicode)
		cx - size (0 for NULL-terminated)
		ax - default character for substitutions
>		bx - DosCodePage to use (0 for current)
>		dx - disk handle to use (0 for primary FSD)
RETURN:		carry - set if error
			ah - 0 or # of bytes to back up
			al - DosToGeosStringStatus
		cx - new length of text
		bx - DosCodePage (may have changed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	To propagate information about modal character standards such
	as JIS, a DosCodePage value is returned by this function, which
	may be different than the DosCodePage that was passed in.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDosToGeos	proc	far
		push	bp, ax
		mov	ah, FSCSF_CONVERT_TO_GEOS
		jmp	ConvertBuffer
LocalDosToGeos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGeosToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert GEOS text to DOS
CALLED BY:	GLOBAL

PASS:		ds:si - ptr to text (Unicode)
>		es:di - ptr to dest buffer (DOS character set)
		cx - max # of chars (0 for NULL-terminated)
		ax - default character for substitutions
>		bx - DosCodePage to use (0 for current)
>		dx - disk handle to use (0 for primary FSD)
RETURN:		carry - set if error
			ah - 0 or # of bytes to back up
			al - DosToGeosStringStatus
		cx - new size of text
		bx - DosCodePage (may have changed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	To propagate information about modal character standards such
	as JIS, a DosCodePage value is returned by this function, which
	may be different than the DosCodePage that was passed in.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGeosToDos	proc	far
		push	bp, ax
		mov	ah, FSCSF_CONVERT_TO_DOS
		REAL_FALL_THRU	ConvertBuffer
LocalGeosToDos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a buffer of text to or from DOS/GEOS
CALLED BY:	LocalDosToGeos(), LocalGeosToDos()

PASS:		ah - FSConvertStringFunction to call
		ds:si - ptr to text
		es:di - ptr to dest buffer
		cx - max # of chars (0 for NULL-terminated)
		bx - DosCodePage to use (0 for current)
		dx - disk handle (0 for primary FSD)
		on stack:
			ax - default character to use for substitutions
			bp - saved bp
RETURN:		carry - set if error
			ah - 0 or # of bytes to back up
			al - DosToGeosStringStatus
		bx - DosCodePage (may have changed)
		cx - new length (to GEOS) or size (to DOS)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertBuffer	proc	far

EC <		call	ECCheckBounds					>
	;
	; Set up args
	;
						;FSCSA_defaultChar (on stack)
		pushdw	esdi			;FSCSA_dest
		pushdw	dssi			;FSCSA_source
		push	bx			;FSCSA_codePage
		push	cx			;FSCSA_length
			CheckHack <(size FSConvertStringArgs) eq 14>
		mov	bx, sp
	;
	; Call the appropriate FSD with DR_FS_CONVERT_STRING
	;
		call	LocalCallFSD
	;
	; Clean up the stack, preserving the carry
	;
		mov	bp, sp
		lea	sp, ss:[bp][(size FSConvertStringArgs)]
		pop	bp
		ret
ConvertBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalDosToGeosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a single character from DOS to GEOS
CALLED BY:	GLOBAL

PASS:		ax - character to map
		bx - DosCodePage to use (0 for current)
		dx - disk handle to use (0 for primary FSD)
RETURN:		carry - set if error
			ah - 0 or # of bytes to back up
			al - DosToGeosStringStatus
		else:
			ax - mapped character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDosToGeosChar	proc	far
		push	cx, ax
		mov	ah, FSCSF_CONVERT_TO_GEOS_CHAR
		jmp	ConvertCharacter
LocalDosToGeosChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGeosToDosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a single character from GEOS to DOS

CALLED BY:	GLOBAL
PASS:		ax - character to map
		bx - DosCodePage to use (0 for current)
		dx - disk handle to use (0 for primary FSD)
RETURN:		carry - set if error
			al - DosToGeosStringStatus
		else:
			ax - mapped character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGeosToDosChar	proc	far
		push	cx, ax
		mov	ah, FSCSF_CONVERT_TO_DOS_CHAR
		REAL_FALL_THRU	ConvertCharacter
LocalGeosToDosChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do conversion of a single character to or from GEOS
CALLED BY:	LocalDosToGeosChar(), LocalGeosToDosChar()

PASS:		ah - FSConvertStringFunction to call
		bx - DosCodePage (0 for current)
		dx - disk handle to use (0 for primary FSD)
		on stack:
			ax - character to map
			cx - saved cx
RETURN:		carry - set if error
			al - DosToGeosStringStatus
		else:
			ax - mapped character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: any DOS we support has ASCII in the values < 0x80
	and hence mapping is a nop.  Heaven help us if we ever try to
	sit on top of an EBCIDIC-based file system.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertCharacter	proc	far
		pop	cx			;cx <- character to map
	;
	; Check for the easy case...
	;
		cmp	cx, 0x80		;ASCII?
		jb	isASCII			;branch if so
	;
	; ...otherwise do it the hard way
	;
		call	LocalCallFSD
done:
		mov_tr	ax, cx			;ax <- error or mapped char
		pop	cx			;cx <- saved cx
		ret

isASCII:
		clc				;carry <- no error
		jmp	done
ConvertCharacter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current code page in use by DOS
CALLED BY:	GLOBAL

PASS:		none
RETURN:		ax - DosCodePage
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGetCodePage	proc	far
		uses	cx
		.enter

		mov	ah, FSCSF_GET_CURRENT_CODE_PAGE
		call	LocalCallFSD
		mov_tr	ax, cx				;ax <- DosCodePage

		.leave
		ret
LocalGetCodePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsDosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if character in the DOS character set.
CALLED BY:	GLOBAL

PASS:		ax - character to check
		bx - DosCodePage to use (0 for current)
		dx - disk handle to use (0 for primary)
RETURN:		carry - set if error (ie. not a DOS character)
			al - DosToGeosStringStatus
		z flag - clear (nz) if valid DOS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalIsDosChar	proc	far
		uses	cx
		.enter

		mov_tr	cx, ax				;cx <- GEOS character
		mov	ah, FSCSF_CONVERT_TO_DOS_CHAR
		call	LocalCallFSD
		jc	notDOS				;branch if not DOS char
		test	cx, 0xffff			;clear z flag, carry
done:

		.leave
		ret

notDOS:
		clr	cx				;set z flag
		stc					;carry <- not DOS
		jmp	done
LocalIsDosChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsCodePageSupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed code page is a supported one.

CALLED BY:	GLOBAL
PASS:		bx - DosCodePage to check
		dx - disk handle to use (0 for primary FSD)
RETURN:		carry - set if error (ie. code page not supported)
			al - DosToGeosStringStatus
DESTROYED:	none
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalIsCodePageSupported	proc	far	
		.enter

		mov	ah, FSCSF_CHECK_CODE_PAGE_SUPPORTED
		call	LocalCallFSD

		.leave
		ret
LocalIsCodePageSupported	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCallFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call DR_FS_CONVERT_STRING in the appropriate FSD

CALLED BY:	UTILITY
PASS:		ah - FSConvertStringFunction to call
		other parameters as appropriate
RETURN:		return values depend on subfunction
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalCallFSD		proc	near
		uses	di, si, bp
		.enter

		mov	si, dx				;si <- disk handle
		mov	di, DR_FS_CONVERT_STRING	;di <- FSFunction
		call	DiskCallFSD

		.leave
		ret
LocalCallFSD		endp

DOSConvert	ends
