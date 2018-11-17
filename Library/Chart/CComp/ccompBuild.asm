COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ccompBuild.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/17/92   	Initial version.

DESCRIPTION:
	

	$Id: ccompBuild.asm,v 1.1 97/04/04 17:48:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartCompClass object
		ds:di	= ChartCompClass instance data
		es	= Segment of ChartCompClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompBuild	method	dynamic	ChartCompClass, 
					MSG_CHART_OBJECT_BUILD

EC <	mov	di, 1200						>
EC <	call	ThreadBorrowStackSpace					>
EC <	push	di							>
	mov	di, offset ChartCompClass
	call	ObjCallSuperNoLock
NEC <	GOTO	ChartCompCallChildren					>
EC <	call	ChartCompCallChildren					>
EC <	pop	di							>
EC <	call	ThreadReturnStackSpace					>
EC <	ret								>
ChartCompBuild	endm

