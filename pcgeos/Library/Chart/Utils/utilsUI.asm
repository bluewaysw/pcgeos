COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsUI.asm

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
	CDB	1/23/92   	Initial version.

DESCRIPTION:
	

	$Id: utilsUI.asm,v 1.1 97/04/04 17:47:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCombineEtype
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine an etype in the notification block with the
		current object's value

CALLED BY:	ChartGroupCombineChartType,
		ChartGroupCombineGroupFlags

PASS:		ds:si - etype in source object
		es:di - etype in notification block

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCombineEtype	proc far
		uses	ax
		.enter

		EC_BOUNDS	ds si
		EC_BOUNDS	es di

		test	es:[CNBH_flags], mask CCF_FOUND
		jz	firstOne
		mov	al, es:[di]
		cmp	al, ds:[si]
		je	done
		mov	{byte} es:[di], -1
done:	
		.leave
		ret

firstOne:
		mov	al, ds:[si]
		mov	es:[di], al
		jmp	done
UtilCombineEtype	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCombineFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the notification block based on the current
		object's flags -- assume flags are an 8-bit record

CALLED BY:	EXTERNAL

PASS:		ds:si - flags in source object
		es:di - flags in notification block
		es:bp - record of "differences"

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCombineFlags	proc far
		uses	ax
		.enter

		EC_BOUNDS	es bp
		EC_BOUNDS	es di
		
		test	es:[CNBH_flags], mask CCF_FOUND
		jz	firstOne

		mov	al, ds:[si]
		xor	al, es:[di]
		or	es:[bp], al
done:
		.leave
		ret

firstOne:
	; copy source flags directly to destination

		mov	al, ds:[si]
		mov	es:[di], al
		mov	{byte} es:[bp], 0
		jmp	done

UtilCombineFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilStartCombine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the memory block whose handle is in CX,
		set ES to the segment, and move handle into BX

CALLED BY:	EXTERNAL

PASS:		cx - handle of notification block

RETURN:		bx - handle of notification block
		es - segment of notification block

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilStartCombine	proc far
	uses	ax
	.enter
	mov	bx, cx
	call	MemLock	
	mov	es, ax
	.leave
	ret
UtilStartCombine	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilEndCombine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "Found" flag so that the notification block
		will have record  of at least one object dealing with
		it. 

CALLED BY:	EXTERNAL

PASS:		es:0 - ChartNotifyBlockHeader
		bx - handle of notification block at segment ES

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilEndCombine	proc far

if ERROR_CHECK

	;
	; Make sure BX is the handle of the block in ES
	;

	push	ax, bx
	mov	ax, MGIT_ADDRESS
	call	MemGetInfo
	mov	bx, es
	cmp	ax, bx
	ERROR_NE	ILLEGAL_SEGMENT
	pop	ax, bx
endif

	ornf	es:[CNBH_flags], mask CCF_FOUND
	call	MemUnlock	
	ret
UtilEndCombine	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the user interface

CALLED BY:	EXTERNAL

PASS:		cx - UpdateFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilUpdateUI	proc far	
	uses	ax
	.enter
	mov	ax, MSG_CHART_BODY_UPDATE_UI
	call	UtilCallChartBody
	.leave
	ret
UtilUpdateUI	endp

