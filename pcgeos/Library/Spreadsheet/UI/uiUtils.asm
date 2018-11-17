COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiUtils.asm
FILE:		uiUtils.asm

AUTHOR:		Gene Anderson, May 23, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/23/92		Initial revision

DESCRIPTION:
	

	$Id: uiUtils.asm,v 1.1 97/04/07 11:12:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EditBarControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCSendToSpreadsheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the spreadsheet, register arguments
CALLED BY:	UTILITY

PASS:		*ds:si - controller
		ax - message to send
		cx, dx, bp - data for message
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCSendToSpreadsheet	proc	far
	uses	bx, di
	.enter

	mov	bx, segment SpreadsheetClass
	mov	di, offset SpreadsheetClass
	call	GenControlOutputActionRegs

	.leave
	ret
SSCSendToSpreadsheet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCSendToSpreadsheetStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the spreadsheet, stack arguments

CALLED BY:	UTILITY
PASS:		*ds:si - controller
		ax - message to send
		ss:bp - ptr to data
		dx - size of data
		cx - data for message
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSCSendToSpreadsheetStack		proc	far
	uses	bx, di
	.enter

	mov	bx, segment SpreadsheetClass
	mov	di, offset SpreadsheetClass
	call	GenControlOutputActionStack

	.leave
	ret
SSCSendToSpreadsheetStack		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCGetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get child block and features for a controller
CALLED BY:	UTILITY

PASS:		*ds:si - controller
RETURN:		ax - features
		bx - handle of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCGetChildBlockAndFeatures	proc	far
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
SSCGetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCGetToolBlockAndTools
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get tool block and tool features for a controller
CALLED BY:	UTILITY

PASS:		*ds:si - controller
RETURN:		ax - tool features
		bx - handle of tool block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCGetToolBlockAndTools	proc	far
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_toolboxFeatures
	mov	bx, ds:[bx].TGCI_toolBlock
	ret
SSCGetToolBlockAndTools	endp

EditBarControlCode	ends
