COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseMain.asm

AUTHOR:		John Wedgwood, Jan 16, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/16/91	Initial revision

DESCRIPTION:
	Library entry routine for the parser library

	$Id: parseMain.asm,v 1.1 97/04/05 01:27:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	entry pin

CALLED BY:	GEOS kernel
PASS:		di - LibraryCallType
RETURN:		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LibraryEntry	proc	far
	cmp	di, LCT_ATTACH			;library loading?
	jne	done				;branch if not
	;
	; Localize number formatting / scanning code
	;
	call	ParserLocalizeFormats
done:
	clc
	ret
LibraryEntry	endp

ForceRef	LibraryEntry


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserLocalizeFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	re-initialize localization information

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserLocalizeFormats	proc	far
	uses	ax, bx, cx, dx, ds
	.enter
NOFXIP<	segmov	ds, <segment idata>, ax		;ds = dgroup		>
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov	bx, ax							>
	call	LocalGetNumericFormat
if DBCS_PCGEOS
	mov	ds:decimalSep, cx		;<- decimal separator
	mov	ds:listSep, dx			;<- list separator
	mov	ds:argEndString[0], dx		;<- list separator for format
else
	mov	ds:decimalSep, cl		;<- decimal separator
	mov	ds:listSep, dl			;<- list separator
	mov	ds:argEndString[0], dl		;<- list separator for format
endif
	.leave
	ret
ParserLocalizeFormats	endp

Init	ends
