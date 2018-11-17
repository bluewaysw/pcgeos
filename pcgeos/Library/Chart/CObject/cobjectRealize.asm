COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectRealize.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/19/92   	Initial version.

DESCRIPTION:
	

	$Id: cobjectRealize.asm,v 1.1 97/04/04 17:46:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectRealize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the size/position/image changed flags.


CALLED BY:	via MSG_CHART_OBJECT_REALIZE

PASS:		*ds:si	= Instance ptr

		ds:di	= Instance ptr
		cx	= Offset in instance to area attributes
		bp	= GState to use when realizing
RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/19/92		Initial version 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectRealize	method dynamic	ChartObjectClass,
			MSG_CHART_OBJECT_REALIZE

EC <	test	ds:[di].COI_state, mask COS_GEOMETRY_INVALID >
EC <	ERROR_NZ	CHART_REALIZE_CALLED_WITH_INVALID_GEOMETRY >
	andnf	ds:[di].COI_state, not mask COS_IMAGE_INVALID
	ret
ChartObjectRealize	endm


