COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetGeometry.asm

AUTHOR:		Gene Anderson, Mar 21, 1991

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/21/91		Initial revision

DESCRIPTION:
	

	$Id: spreadsheetGeometry.asm,v 1.1 97/04/07 11:13:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetUpdateGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update our geometry (do nothing)
CALLED BY:	MSG_VIS_UPDATE_GEOMETRY

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetUpdateGeometry	method dynamic SpreadsheetClass, \
							MSG_VIS_UPDATE_GEOMETRY

	add	bx, ds:[bx].Vis_offset
	and	ds:[bx].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
						mask VOF_GEO_UPDATE_PATH)

	ret
SpreadsheetUpdateGeometry	endm

InitCode	ends
