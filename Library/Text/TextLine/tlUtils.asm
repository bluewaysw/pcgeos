COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlUtils.asm

AUTHOR:		John Wedgwood, Dec 31, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/31/91	Initial revision

DESCRIPTION:
	Misc utilities used by everyone in this module.

	$Id: tlUtils.asm,v 1.1 97/04/07 11:20:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextLine_DerefVis_DI (SI)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference an object to get to the vis-instance data.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
RETURN:		ds:di	= Vis-Instance ptr
	   OR	ds:si	= Vis-Instance ptr
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextLine_DerefVis_DI	proc	near
	class	VisTextClass

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
TextLine_DerefVis_DI	endp

if	0
TextLine_DerefVis_SI	proc	near
	class	VisTextClass

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	ret
TextLine_DerefVis_SI	endp
endif

TextInstance	ends
