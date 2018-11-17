COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calculator
FILE:		calcTrigger.asm

AUTHOR:		Adam de Boor, Jun  8, 1990

ROUTINES:
	Name			Description
	----			-----------
	CalcDataTriggerClass	Subclass of GenTrigger to permit more than
				one keyboard accelerator for a single trigger.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 8/90		Initial revision


DESCRIPTION:
		

	$Id: calcTrigger.asm,v 1.1 97/04/04 14:46:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment
	CalcDataTriggerClass	; Declare the class record
idata		ends

Main		segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDataTriggerFindKbdAccelerator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si	= instance
		ds:bx	= CalcDataTriggerBase
		ds:di	= CalcDataTriggerInstance
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low 	= Toggle state
		bp high	= scan code
RETURN:		carry set if accelerator found and dealt with
DESTROYED:	not cx, dx or bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDataTriggerFindKbdAccelerator method dynamic CalcDataTriggerClass,
				  		 MSG_GEN_FIND_KBD_ACCELERATOR
		.enter
	;
	; Check our regular keyboard accelerator first.
	;
		mov	di, offset CalcDataTriggerClass
		CallSuper	MSG_GEN_FIND_KBD_ACCELERATOR
		jc	done

	;
	; Check both the extra shortcuts at once.
	;
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].CalcDataTrigger_offset
		lea	si, ds:[di].CDT_accelerator1
		mov	ax, 2
		call	FlowCheckKbdShortcut
		pop	si
		jnc	done		; Neither matched
		
	;
	; Got a match. Activate ourselves.
	;
		DoPush	cx, dx, bp
		mov	ax, MSG_GEN_ACTIVATE
		call	ObjCallInstanceNoLock
		DoPopRV	cx, dx, bp
		stc			; Signal keystroke handled.
done:
		.leave
		ret
CalcDataTriggerFindKbdAccelerator endp


Main		ends
