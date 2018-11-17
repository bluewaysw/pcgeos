COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cbodyTarget.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/12/93   	Initial version.

DESCRIPTION:
	

	$Id: cbodyTarget.asm,v 1.1 97/04/04 17:48:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyTargetChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartBodyClass object
		ds:di	- ChartBodyClass instance data
		es	- segment of ChartBodyClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyTargetChange	method	dynamic	ChartBodyClass, 
					MSG_META_LOST_TARGET_EXCL,
					MSG_META_GAINED_TARGET_EXCL

	mov	di, offset ChartBodyClass
	call	ObjCallSuperNoLock

	mov	cl, ChartUpdateUIFlags
	mov	ax, MSG_CHART_BODY_UPDATE_UI
	GOTO	ObjCallInstanceNoLock
	
ChartBodyTargetChange	endm
