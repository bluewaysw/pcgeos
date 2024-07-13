COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS	
MODULE:		Data Exchange Library
FILE:		dataxBehaviors.asm

AUTHOR:		Robert Greenwalt, Nov 14, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/14/96   	Initial revision


DESCRIPTION:
		
	

	$Id: dataxBehaviors.asm,v 1.1 97/04/04 17:54:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DataXFixed		segment	resource
DefaultBehaviorTable	RoutineTableEntry \
	<DXIW_IMPORT, DXBMidPassEndError>,
	<DXIW_EXPORT, DXBMidPassEndError>,
	<DXIW_CLEAN_SHUTDOWN, DXBShutdown>,
	<0, 0>
DataXFixed		ends

DataXBehaviors		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXBMidPassEndError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've received an Import, Export or some other
		mid-pass, end-error command

CALLED BY:	DXMain
PASS:		onstack
		DataXBehaviorArguments
RETURN:		ax = DataXErrorType
DESTROYED:	can destroy bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
; Default behaviors:
;	Mid-pipe: do nothing
;	End: return DXIW_ERROR - DXET_INVALID_DXIW
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXBMidPassEndError	proc	far	args:DataXBehaviorArguments
	.enter
		les	di, args.DXBA_elementHeader
		tst	es:[di].PEH_pipeToggle
		jz	error
		mov	ax, DXET_NO_ERROR
done:
	.leave
	ret
error:
		mov	ax, DXET_INVALID_DXIW
		jmp	done
DXBMidPassEndError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXBShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've been told to shutdown.  Do so.

CALLED BY:	DXMain
PASS:		onstack
		DataXBehaviorArgumetns
RETURN:		DONT!  jmp to ThreadDestroy
DESTROYED:	yep.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXBShutdown	proc	far	args:DataXBehaviorArguments
	.enter
		les	di, args.DXBA_dataXInfo
	;
	; Decrement the passed count in the low word of miscInfo
	;
		dec	es:[di].DXIDXI_deathCount
		mov	bx, es:[di].DXIDXI_deathSema
	;
	; Before we V the semaphore we need to clean things up for EC
	;
EC<		segmov	es, ds, ax					>
	;
	; V the passed semaphore
	;
		call	ThreadVSem
	;
	; And die
	;
		clr	cx, dx, bp, si
		jmp	ThreadDestroy
	.leave	.unreached
DXBShutdown	endp

DataXBehaviors	ends
