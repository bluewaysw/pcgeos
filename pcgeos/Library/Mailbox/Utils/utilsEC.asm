COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		utilsEC.asm

AUTHOR:		Adam de Boor, May 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/26/94		Initial revision


DESCRIPTION:
	Utility error-checking routines
		

	$Id: utilsEC.asm,v 1.1 97/04/05 01:19:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECUtilAssertNotRealized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the generic object at *ds:si is not on-screen

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= generic object
RETURN:		only if object not realized
DESTROYED:	nothing (except flags)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECUtilAssertNotRealized proc	far
		uses	di
		class	GenClass
		.enter
		mov	di, ds:[si]
		tst	ds:[di].Vis_offset
		jz	notVisible	; => not built, so ok
		add	di, ds:[di].Vis_offset
		test	ds:[di].VI_attrs, mask VA_REALIZED
		ERROR_NZ CANNOT_MANGLE_MONIKER_OF_REALIZED_OBJECT
notVisible:
		.leave
		ret
ECUtilAssertNotRealized endp
endif ; ERROR_CHECK

UtilCode	ends
