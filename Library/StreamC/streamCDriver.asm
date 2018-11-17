COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Library/StreamC
FILE:		streamCDriver.asm

AUTHOR:		John D. Mitchell

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
Ext	DriverCallEntryPoint	Generic way to call into a GEOS driver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

DESCRIPTION:
	This file contains the implementation of the C routines to
	generically access a GEOS Driver.

	$Id: streamCDriver.asm,v 1.1 97/04/07 11:15:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Code Resource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

StreamCDriver	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriverCallEntryPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generic way to call into a GEOS driver.

CALLED BY:	Global.

PASS:		hptr	driver		= GEOS driver to invoke.
		word	function	= Driver function to execute.
		DriverPassParams *passParams	= Arguments to driver.
		DriverReturnParams *returnParams= Results from driver.

RETURN:		Void.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	Depends on driver and function invoked.

	Asserts:	Depends on driver and function invoked.

CHECKS:		Validates the given driver handle.

PSEUDO CODE/STRATEGY:
	Load up the registers with the given information and invoke the
	given driver function with the given arguments.
	Load up the return structure with the results of the call.

KNOWN DEFECTS/CAVEATS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	DRIVERCALLENTRYPOINT:far
DRIVERCALLENTRYPOINT	proc	far	driver:hptr,
					function:word,
					passParams:fptr.DriverPassParams,
					retParams:fptr.DriverReturnParams
	uses	di,si,ds,es,bp
	.enter

EC <	; First, validate the given driver handle.			>
	mov	bx, driver
EC <	call	ECCheckDriverHandle					>

	; Save some key information for the post invocation code.
	push	bp

	; Get the strategy routine for the given driver.
	; NOTE:	BX already set from above.
	call	GeodeInfoDriver			; DS:SI = DriverInfoStruct.
	
	; Create a stack frame on the stack so that we can do a far return
	; to invoke the driver entry point without using any registers.
	push	ds:[si].DIS_strategy.segment
	push	ds:[si].DIS_strategy.offset

	; Load the driver function arguments...
	mov	di, function			; Driver function.
	lds	si, passParams			; DS:SI = *passParams.
	push	ds:[si].DPP_si			; Don't trash SI yet.
	push	ds:[si].DPP_ds			; Don't trash DS yet.
	mov	ax, ds:[si].DPP_ax
	mov	bx, ds:[si].DPP_bx
	mov	cx, ds:[si].DPP_cx
	mov	dx, ds:[si].DPP_dx
	mov	bp, ds:[si].DPP_bp
	mov	es, ds:[si].DPP_es
	pop	ds
	pop	si
	
	call	PROCCALLFIXEDORMOVABLE_PASCAL

	; Restore key information preserved from above.
	; NOTE:	This slot was created by the push bp from above.  This
	;	xchg will allow us to access the original stack frame (so
	;	that we can actually move this damn data outta here!) but
	;	we'll still need to pop that slot off of the stack later.
	XchgTopStack	bp			; BP = Stack frame.
	push	ds				; Save trashed regs.
	push	si

	; Stuff all them results into the return structure.
	; NOTE:	Nothing that happens before saving the flags does anything
	;	to the flags.  KEEP IT THAT WAY!
	lds	si, retParams			; DS:SI = *retParams.
	pushf					; Save the flags...
	pop	ds:[si].DRP_flags
	mov	ds:[si].DRP_ax, ax		; Save all of the stuff
	mov	ds:[si].DRP_bx, bx		; still in registers...
	mov	ds:[si].DRP_cx, cx
	mov	ds:[si].DRP_dx, dx
	mov	ds:[si].DRP_di, di
	mov	ds:[si].DRP_es, es
	pop	ds:[si].DRP_si			; Store displaced data that
	pop	ds:[si].DRP_ds			; was saved above and clean
	pop	ds:[si].DRP_bp			; up the stack messiness.

	.leave
	ret
DRIVERCALLENTRYPOINT	endp


StreamCDriver	ends

	SetDefaultConvention
