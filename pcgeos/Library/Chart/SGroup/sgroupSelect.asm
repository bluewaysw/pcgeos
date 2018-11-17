COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sgroupSelect.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

DESCRIPTION:
	

	$Id: sgroupSelect.asm,v 1.1 97/04/04 17:46:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesGroupSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send the message to the desired series object	

PASS:		*ds:si	= SeriesGroupClass object
		ds:di	= SeriesGroupClass instance data
		es	= Segment of SeriesGroupClass.

		cx	= series # to call

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesGroupSelect	method	dynamic	SeriesGroupClass, 
					MSG_CHART_OBJECT_SELECT,
					MSG_CHART_OBJECT_UNSELECT
	uses	ax,cx,dx,bp
	.enter
	call	SeriesGroupFindSeriesByNumber
	mov	si, ax
	.leave
	GOTO	ObjCallInstanceNoLock

SeriesGroupSelect	endm

