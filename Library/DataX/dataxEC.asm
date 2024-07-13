COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Hilton	
MODULE:		Data Exchange Library EC Routines
FILE:		dataxEC.asm

AUTHOR:		Taylor Gautier, Jan  2, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tgautier	1/ 2/97   	Initial revision


DESCRIPTION:
		
	

	$Id: dataxEC.asm,v 1.1 97/04/04 17:54:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DataXEC	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECDXCHECKPEH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate Pipe Element Structure

CALLED BY:	anyone
PASS:		on stack
		pointer to pipe element structure
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	 Date		Description
	----	 ----		-----------
	tgautier 1/ 2/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
ECDXCHECKPEH	proc	far 	peh:fptr.PipeElementHeader
ForceRef	ECDXCHECKPEH
ForceRef	peh
	uses	es, di
	.enter		

if ERROR_CHECK
	les	di, peh			; es:di -> peh
	;
	; Sanity check
	;
	Assert fptr esdi

	;
	; check dataXInfo pointer
	;
	Assert fptr es:[di].PEH_dataXInfo

	;
	; check pipeDirection
	;
	Assert record 	es:[di].PEH_pipeDirection, DXPipeDirection
	
	;
	; check PipeToggle
	;	
	Assert record	es:[di].PEH_pipeToggle, DXPipeDirection
	
	; 
	; check intSemaphoreLeft
	;
;	Assert handle  es:[di].PEH_intSemaphoreLeft

	;	
	; check extSemaphoreLeft
	;
;	Assert handle es:[di].PEH_extSemaphoreLeft

	;
	; check intSemaphoreRight
	;	
;	Assert handle  es:[di].PEH_intSemaphoreRight
	
	;
	; check extSemaphoreRight
	
;	Assert handle es:[di].PEH_extSemaphoreRight
endif
	
	.leave
	ret
ECDXCHECKPEH	endp
	SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECDXCHECKDATAXINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate DataXInfo structure

CALLED BY:	anything
PASS:		on stack:
		pointer to DataXInfo structure
RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tgautier	1/ 3/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
ECDXCHECKDATAXINFO	proc	far info:fptr
ForceRef	ECDXCHECKDATAXINFO
ForceRef	info
	uses	ax, bx, es, di
	.enter
if ERROR_CHECK
	les	di, info
	
	;
	; Sanity Check
	;
	Assert fptr esdi

	; 
	; Check DXI_dataBuffer if there is one
	;
	mov	bx, es:[di].DXI_dataBuffer
	cmp	bx, 0
	jz	DontHaveDataBuffer
	Assert handle bx

DontHaveDataBuffer:

	;
	; Check DXI_dataSegment if there is one
	;	
	mov	ax, es:[di].DXI_dataSegment
	cmp	ax, 0
	jz	DontHavePointer
	Assert segment ax

	;
	; Check the buffer size if it is set
	;
	mov	bx, es:[di].DXI_bufferSize
	cmp	bx, 0
	jz	DontHavePointer
	sub 	bx, 1
	Assert	fptr axbx

DontHavePointer:
	;
	; Check DXI_flags
	;
	Assert record es:[di].DXI_flags, DXFlags

	;
	; Can't check DXI_infoWord since this etype is extendable.
	;
endif
	.leave
	ret
ECDXCHECKDATAXINFO	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECDXCHECKDATAXBEHAVIORARGUMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check our arguments

CALLED BY:	behavior
PASS:		on stack a pntr to your DataXBehaviorArguments
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/24/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
ECDXCHECKDATAXBEHAVIORARGUMENTS	proc	far	toArgs:fptr.DataXBehaviorArguments
ForceRef	toArgs
	uses	ds, si, es, di
	.enter
 if ERROR_CHECK
		 lds	si, toArgs
		 Assert_fptr	dssi
	 ;
	 ; Check the PipeElementHeader
	 ;
		 les	di, ds:[si].DXBA_elementHeader
		 Assert_fptr	esdi
		 pushdw	esdi
		 call	ECDXCHECKPEH
	 ;
	 ; and the customData pntr
	 ;
		 les	di, ds:[si].DXBA_customData
		 Assert_fptr	esdi
	 ;
	 ; and DataXInfo
	 ;
		 les	di, ds:[si].DXBA_dataXInfo
		 Assert_fptr	esdi
		 pushdw	esdi
		 call	ECDXCHECKDATAXINFO

endif
	.leave
	ret
ECDXCHECKDATAXBEHAVIORARGUMENTS	endp
	SetDefaultConvention

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECDXCheckRoutineTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify our routineTable

CALLED BY:	Internal
PASS:		es:di = routine Table
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/ 9/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECDXCheckRoutineTable	proc	far
	uses	ax,bx,di
	.enter
loopTop:
		tst	es:[di].RTE_infoWord
		jne	continue
	.leave
	ret
continue:
	;
	; Check for a VSeg
	;
		mov	bx, es:[di].RTE_routine.high
		mov	ax, bx
		and	ax, 0xF000
		cmp	ax, 0xF000
		ERROR_NE	BAD_ROUTINE_TABLE_ENTRY
	;
	; Check the handle that is in the vseg
	;
		shl	bx
		shl	bx
		shl	bx
		shl	bx
		call	ECCheckMemHandle
	;
	; next entry
	;
		add	di, size RoutineTableEntry
		jmp	loopTop
ECDXCheckRoutineTable	endp
endif

DataXEC ends

