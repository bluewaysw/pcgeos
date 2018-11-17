COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fsdEC.asm

AUTHOR:		Adam de Boor, Oct 29, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/29/91	Initial revision


DESCRIPTION:
	Error-checking code for the module and users of the module.
		

	$Id: fsdEC.asm,v 1.1 97/04/05 01:17:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FSResident	segment	resource

if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertESIsSharedFSIR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the FSIR is locked shared and its segment
		loaded into ES.

CALLED BY:	EXTERNAL
PASS:		es	= shared FSIR, in theory
RETURN:		nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssertESIsSharedFSIR proc near
		.enter
		tst	{word}ss:[TPD_exclFSIRLocks]
		ERROR_Z		FSD_ES_ISNT_SHARED_FSIR
		cmp	es:[LMBH_handle], handle FSInfoResource
		ERROR_NE	FSD_ES_ISNT_SHARED_FSIR
		.leave
		ret
AssertESIsSharedFSIR endp

endif

FSResident	ends
