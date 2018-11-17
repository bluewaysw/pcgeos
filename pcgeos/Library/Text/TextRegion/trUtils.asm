COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trUtils.asm

AUTHOR:		John Wedgwood, Feb 18, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/18/92	Initial revision

DESCRIPTION:
	Common utility routines.

	$Id: trUtils.asm,v 1.1 97/04/07 11:21:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextRegion_DerefVis_DI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the vis-instance

CALLED BY:	Utility
PASS:		*ds:si	= Instance
RETURN:		ds:di	= Instance
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion_DerefVis_DI	proc	far
	class	VisTextClass
EC <	call	T_AssertIsVisText					>
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
TextRegion_DerefVis_DI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextRegion_DerefVis_SI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the vis-instance

CALLED BY:	Utility
PASS:		*ds:si	= Instance
RETURN:		ds:si	= Instance
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion_DerefVis_SI	proc	far
	class	VisTextClass
EC <	call	T_AssertIsVisText					>
	
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	ret
TextRegion_DerefVis_SI	endp


TextRegion	ends
