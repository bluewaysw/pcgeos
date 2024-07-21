COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Input driver
FILE:		tfiStrategy.asm

AUTHOR:		Paul DuBois, Nov 29, 1994

ROUTINES:
	Name			Description
	----			-----------
	TFIStrategy		The Strategy for the driver
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/29/94   	Initial revision


DESCRIPTION:
	Strategy routine and first four routines that all drivers
	must support

	$Revision:   1.2  $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;		dgroup DATA for driver info table
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idata	segment
DriverTable		FidoiDriverInfoStruct <
    <				; FDIS_common
	TFIStrategy,			; DIS_strategy
	0,				; DIS_driverAttributes
	DRIVER_TYPE_FIDO_INPUT		; DIS_driverType
    >,
    MT_ASCII			; FDIS_type
>
public	DriverTable

idata	ends


ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFIStrategy
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
TFIStrategy	proc	far
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
EC <		ERROR	TEXT_FIDO_INPUT_INVALID_DRIVER_FUNCTION		>
NEC <		stc							>
NEC <		jmp	done						>

TFIStrategy	endp

DefFIFunction	macro	routine, constant
.assert (($-fiFunctions)/2) eq constant, <Routine for constant in the wrong slot>
.assert (type routine eq far), <Routine not declared far>
                fptr    routine
endm

fiFunctions	label	fptr.far

DefFIFunction	FIInit,			DR_INIT
DefFIFunction	FIDoNothing,		DR_EXIT
DefFIFunction	FIDoNothing,		DR_SUSPEND
DefFIFunction	FIDoNothing,		DR_UNSUSPEND

DefFIFunction	TFIOpen,		DR_FIDOI_OPEN
DefFIFunction	TFIClose,		DR_FIDOI_CLOSE
DefFIFunction	TFIGetSymbols,		DR_FIDOI_GET_HEADER
	;; was DR_FIDOI_GET_SYMBOLS long ago...
DefFIFunction	TFIGetPage,		DR_FIDOI_GET_PAGE
DefFIFunction	FIDoNothing,		DR_FIDOI_GET_COMPLEX_DATA
	;; was DR_FIDOI_GET_PAGE_FROM_SYMBOL long ago...


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize driver the 1st time its loaded

CALLED BY:	Strategy Routine
PASS:		cx	- di passed to GeodeLoad.
			  Garbage if loaded via GeodeUseDriver
		dx	- bp passed to GeodeLoad.
			  Garbage if loaded bia GeodeUseDriver

RETURN:		carry clear if initialization successful.
		carry set if initializiation failed.

DESTROYED:	(allowed) bp, ds, es, ax, di, si, cx, dx
		(destroyed) nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FIInit	proc	far
	.enter
;;		do nothing
		clc
	.leave
	ret
FIInit	endp

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

