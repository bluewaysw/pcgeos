COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		libInit.asm

AUTHOR:		Jim DeFrisco, 26 March 1990

ROUTINES:
	Name			Description
	----			-----------
	LibraryEntry		init routine for spool library

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/26/90		Initial revision


DESCRIPTION:
	This file contains code to initialize the spool library
		

	$Id: libInit.asm,v 1.1 97/04/07 11:10:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolInit	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry/initialization point for spool library

CALLED BY:	GLOBAL
		(Kernel calls upon loading library)

PASS:		di	- LibraryCallType

RETURN:		carry	- clear if everything ok

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0
SpoolLibraryEntry proc	far
		.enter

		; if we're getting the init call, make sure there is a
		; spool directory

		cmp	di, LCT_ATTACH		; lib being loaded ?
		jne	done

		; the library is being started. Initalize the paper stuff.
		call	SpoolInitPaperSizeOrder	; initialize all paper orders
done:
		clc
		.leave
		ret
SpoolLibraryEntry endp
endif

SpoolInit	ends




