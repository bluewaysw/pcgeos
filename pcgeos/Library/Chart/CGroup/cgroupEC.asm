COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupEC.asm

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
	CDB	12/20/91	Initial version.

DESCRIPTION:
	

	$Id: cgroupEC.asm,v 1.1 97/04/04 17:45:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckChartGroupDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckChartGroupDSSI	proc near
	uses	es,di
	.enter
	pushf

	segmov	es, <segment ChartGroupClass>, di
	mov	di, offset ChartGroupClass
	call	ObjIsObjectInClass
	ERROR_NC DS_SI_WRONG_CLASS

	popf
	.leave
	ret
ECCheckChartGroupDSSI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckChartGroupDSDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that ds:di points to the TemplateChartGroup
		object. 

CALLED BY:

PASS:		ds:di - TemplateChartGroup ?

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckChartGroupDSDI	proc near	
	uses	si
	.enter
	pushf
	assume	ds:ChartUI

	mov	si, ds:[TemplateChartGroup]
	cmp	si, di
EC <	ERROR_NE	DS_DI_NOT_POINTING_TO_INSTANCE_DATA >

	assume	ds:dgroup
	popf
	.leave
	ret
ECCheckChartGroupDSDI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckParamsBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that the params block is set up correctly

CALLED BY:

PASS:		es - params block

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

CHECKS:
	make sure endOfData pointer is set correctly.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/20/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckParamsBlock	proc near	
	uses	ax,dx,di
	.enter
	pushf
	mov	ax, es:[CD_nRows]	
	mul	es:[CD_nColumns]	
	dec	ax			
	mov	di, ax
	shl	di, 1
	mov	di, es:CD_cellOffsets[di]
	cmp	di, es:CD_endOfData
	ERROR_G	INCORRECT_END_OF_DATA_FIELD
	popf
	.leave
	ret
ECCheckParamsBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSeriesNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the passed series number is valid

CALLED BY:

PASS:		*ds:si - ChartGroup
		cl - series number

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckSeriesNumber	proc near	
	uses	ax,cx
	.enter
	pushf
	mov	al, cl
	call	ChartGroupGetSeriesCount
	cmp	al, cl
	ERROR_AE ILLEGAL_SERIES_NUMBER
	popf
	.leave
	ret
ECCheckSeriesNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCategoryNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/31/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckCategoryNumber	proc near	
	uses	cx
	.enter
	pushf
	call	ChartGroupGetCategoryCount
	cmp	dx, cx
	ERROR_AE ILLEGAL_CATEGORY_NUMBER
	popf
	.leave
	ret
ECCheckCategoryNumber	endp


