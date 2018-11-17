COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Common power management code
FILE:		powerBattery.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/22/93		Initial revision

DESCRIPTION:
	This is common battery code

	$Id: powerBattery.asm,v 1.1 97/04/18 11:48:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	BatteryPoll

DESCRIPTION:	Poll the battery

CALLED BY:	Timer code

PASS:
	none

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/22/93		Initial version

------------------------------------------------------------------------------@
BatteryPoll	proc	far
	mov	ax, PGST_POLL_WARNINGS
	call	GenerateWarnings
	ret
BatteryPoll	endp

;---



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateWarnings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates warnings for the various error cases.

CALLED BY:	GLOBAL
PASS:		ax - PowerGetStatusType
RETURN:		ax - PowerWarnings
		ds - dgroup
DESTROYED:	bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateWarnings	proc	near

	mov	bx, dgroup
	mov	ds, bx

	; get the warning flags

	mov	di, DR_POWER_GET_STATUS
	call	PowerStrategy			;ax = new, bx = mask
EC <	ERROR_C	FUNCTION_MUST_BE_SUPPORTED				>

	tst	ax
	jz	done

	; there are some new warnings -- handle them

	mov	di, vseg ConveyWarning
	mov	bp, offset ConveyWarning
	call	CallRoutineInUI

done:
	ret

GenerateWarnings	endp
Resident ends

Movable segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConveyWarning

DESCRIPTION:	Convey a warning to the user

CALLED BY:	UI THREAD (via BatteryPoll)

PASS:
	ax - PowerWarnings to convey

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/23/93		Initial version

------------------------------------------------------------------------------@
ConveyWarning	proc	far

	; loop through all bits conveying warnings

	mov	si, offset MainWarningString
	mov	cx, NUMBER_OF_STANDARD_POWER_WARNINGS + \
					NUMBER_OF_CUSTOM_POWER_WARNINGS
findLoop:
	shl	ax
	jnc	next
	push	ax
	mov	ax, mask CDBF_SYSTEM_MODAL or \
			(CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)

	call	DisplayMessage
	pop	ax
next:
	add	si, size word
	loop	findLoop

	ret

ConveyWarning	endp


Movable ends
