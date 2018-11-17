COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		os2Utils.asm

AUTHOR:		Adam de Boor, Jun 21, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/21/92		Initial revision


DESCRIPTION:
	Utility routines for OS/2 driver
		

	$Id: os2Utils.asm,v 1.1 97/04/10 11:55:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Resident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPointToSFTEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the numbered SFT entry (must be resident so
		FSHandleInfo can work)

CALLED BY:	EXTERNAL
PASS:		al	= SFN of entry to find
RETURN:		carry clear if ok:
			es:di	= SFTEntry for the thing
		carry set if SFN invalid
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We can't get to the SFT for OS/2, so always return carry set

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPointToSFTEntry proc	far
		.enter
		stc
		.leave
		ret
DOSPointToSFTEntry endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCompareSFTEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two entries in the file table.

CALLED BY:	DOSCompareFiles
PASS:		ds:si	= SFTEntry 1
		es:di	= SFTEntry 2
RETURN:		ZF set if ds:si and es:di refer to the same disk file
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		Should never be called, since no one should have gotten
		an SFT entry from us, but...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCompareSFTEntries proc near
	or	al, 1
	ret
DOSCompareSFTEntries endp

Resident	ends
