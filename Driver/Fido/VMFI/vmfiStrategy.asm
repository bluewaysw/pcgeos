COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Input driver
FILE:		vmfiStrategy.asm

AUTHOR:		Paul DuBois, Nov 29, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB VMFIStrategy		Strategy routine

    INT FIInit			Initialize driver -- create LMem heap
    INT FIExit			Shut down driver -- destroy LMem heap
    INT FIDoNothing		Do nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/29/94   	Initial revision

DESCRIPTION:
	Strategy routine and first four routines that all drivers
	must support

	$Id: vmfistra.asm,v 1.1 97/12/02 11:37:30 gene Exp $
	$Revision: 1.1 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;		dgroup DATA for driver info table
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idata	segment
DriverTable		FidoiDriverInfoStruct <
    <				; FDIS_common
	VMFIStrategy,			; DIS_strategy
	0,				; DIS_driverAttributes
	DRIVER_TYPE_FIDO_INPUT		; DIS_driverType
    >,
    MT_VM_FILE,			; FDIS_type
    offset vmfiName		; FDIS_name
>
vmfiName	TCHAR	"DOS", 0

public	DriverTable

idata	ends


ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFIStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine

CALLED BY:	GLOBAL
PASS:		di	- command
RETURN:		see routines
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The command is passed in di.  Look up the far pointer
		to the routine that handles that command in a jump table
		and calls it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMFIStrategy	proc	far
	uses	ds
	.enter
		cmp	di, FidoInDriverFunction
		jae	badCall
		test	di, 0x0001
		jnz	badCall

		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		shl	di		; index into table of fptrs
		
		movdw	bxax, cs:[fiFunctions][di]
		call	ProcCallFixedOrMovable
done::
	.leave
	ret
badCall:
EC <		ERROR	VM_FIDO_INPUT_INVALID_DRIVER_FUNCTION		>
NEC <		stc							>
NEC <		jmp	done						>

VMFIStrategy	endp

DefFIFunction	macro	routine, constant
.assert (($-fiFunctions)/2) eq constant, <Routine for constant in the wrong slot>
.assert (type routine eq far), <Routine not declared far>
                fptr    routine
endm

fiFunctions	label	fptr.far

DefFIFunction	FIInit,			DR_INIT
DefFIFunction	FIExit,			DR_EXIT
DefFIFunction	FIDoNothing,		DR_SUSPEND
DefFIFunction	FIDoNothing,		DR_UNSUSPEND

DefFIFunction	VMFIOpen,		DR_FIDOI_OPEN
DefFIFunction	VMFIClose,		DR_FIDOI_CLOSE
DefFIFunction	VMFIGetHeader,		DR_FIDOI_GET_HEADER
DefFIFunction	VMFIGetPage,		DR_FIDOI_GET_PAGE
DefFIFunction	VMFIGetComplexData,	DR_FIDOI_GET_COMPLEX_DATA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize driver -- create LMem heap

CALLED BY:	Strategy Routine
PASS:		cx	- di passed to GeodeLoad.
			  Garbage if loaded via GeodeUseDriver
		dx	- bp passed to GeodeLoad.
			  Garbage if loaded bia GeodeUseDriver

RETURN:		carry clear if initialization successful.
		carry set if initializiation failed.

DESTROYED:	(allowed) bp, ds, es, ax, di, si, cx, dx
		(destroyed) ax, cx, ds

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FIInit	proc	far
	uses	bx
	.enter
		mov	bx, handle dgroup
		call	MemDerefDS

		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, 0		; default header size
		call	MemAllocLMem

		mov	ax, handle 0
		call	HandleModifyOwner

		mov	ax, mask HF_SHARABLE	; ah cleared
		call	MemModifyFlags
		
		mov	ds:[stateHeap], bx
		clc
	.leave
	ret
FIInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut down driver -- destroy LMem heap

CALLED BY:	Strategy Routine

PASS:		nothing
RETURN:		nothing

DESTROYED:	(allowed) ax, bx, cx, dx, si, di, ds, es
		(destroyed) bx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FIExit	proc	far
	.enter
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[stateHeap]
		call	MemFree
	.leave
	ret
FIExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing

CALLED BY:	Strategy routine
PASS:		nothing
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	
		none
PSEUDO CODE/STRATEGY:
		return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/ 1/92    	Initial version
	dubois	11/29/94    	Streamlined

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FIDoNothing	proc	far
	clc
	ret
FIDoNothing	endp

ResidentCode	ends

