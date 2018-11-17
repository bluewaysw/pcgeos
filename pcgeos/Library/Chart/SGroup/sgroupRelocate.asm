COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sgroupRelocate.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/30/92   	Initial version.

DESCRIPTION:
	

	$Id: sgroupRelocate.asm,v 1.1 97/04/04 17:46:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle relocation of the OD array managed by the
		series group.

PASS:		*ds:si	= SeriesGroupClass object
		ds:di	= SeriesGroupClass instance data
		es	= segment o fSeriesGroupClass

		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupRelocate	method	dynamic	SeriesGroupClass, reloc

	mov	cx, COMT_DROP_LINES
	call	ChartObjectRelocOrUnRelocArray

	mov	di, offset SeriesGroupClass
	call	ObjRelocOrUnRelocSuper
	ret
SeriesGroupRelocate	endm

