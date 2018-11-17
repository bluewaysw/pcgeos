COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		geodeInit.asm

ROUTINES:
	Name		Description
	----		-----------
   EXT	InitObject	Initialize the Object module
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

DESCRIPTION:
	This module initializes the Object module.  See manager.asm for
documentation.

	$Id: objectInit.asm,v 1.1 97/04/05 01:14:28 newdeal Exp $

-------------------------------------------------------------------------------@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitObject

DESCRIPTION:	Initialize the Object module

CALLED BY:	EXTERNAL
		InitGeos

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

InitObject	proc	near
	ret

InitObject	endp
	public	InitObject
