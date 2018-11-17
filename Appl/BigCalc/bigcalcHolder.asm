COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcHolder.asm

AUTHOR:		Christian Puscasiu, Jun 17, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT PCFHolderBringPCFToTopCB looks for the

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/17/92		Initial revision
	andres	10/29/96	Don't need this for DOVE
	andres	11/18/96	Don't need this for PENELOPE

DESCRIPTION:
	
		

	$Id: bigcalcHolder.asm,v 1.1 97/04/04 14:37:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%% DON'T NEED THIS FOR RESPONDER %%%%%%%%%%%%%%%%%%%%%%@

ProcessCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFHolderBringPCFToTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks the 3rd through last child for the PCF_ID
		brings it to top, if found

CALLED BY:	
PASS:		*ds:si	= PCFHolderClass object
		ds:di	= PCFHolderClass instance data
		ds:bx	= PCFHolderClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= PreCannedFunctionID
RETURN:		cx:dx	= PCF that was revitalized
		carry	set, if found
			unset, if not
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFHolderBringPCFToTop method dynamic PCFHolderClass, 
					MSG_PCF_HOLDER_BRING_PCF_TO_TOP
	uses	ax, bp
	.enter

	;
	; set up the ObjCompProcessChildren
	;
	clr	ax
	push	ax
	clr	ax			; start with the 1st child
	push	ax
	mov	ax, offset GI_link
	push	ax
	push	cs
	mov	ax, offset PCFHolderBringPCFToTopCB
	push	ax
	;cx	== PreCannedFunctionID

	mov	bx, offset Gen_offset
	mov	di, offset GI_comp

	call	ObjCompProcessChildren

	.leave
	ret
PCFHolderBringPCFToTop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFHolderBringPCFToTopCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call back function for PCFHolderBringPCFToTop

CALLED BY:	PCFHolderBringPCFToTop
PASS:		*ds:si	-- PreCannedFunction object
		cx	-- PreCannedFunctionID
RETURN:		carry set -- if PCF was found
		      unset, if not
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFHolderBringPCFToTopCB	proc	far
	uses	ax,bx,si,di,bp
	class	PreCannedFunctionClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].PreCannedFunction_offset
	cmp	ds:[di].PCFI_ID, cx
	clc					; assume not found
	jne	done				; if different, keep going

	; We found the form. Set is usable, and display it.
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjCallInstanceNoLockES

	; Return useful information
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	stc					; stop searching
done:
	.leave
	ret
PCFHolderBringPCFToTopCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFHolderClosePCF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	closes the PCF

CALLED BY:	MSG_PCF_HOLDER_CLOSE_PCF
PASS:		*ds:si	= PCFHolderClass object
		ds:di	= PCFHolderClass instance data
		ds:bx	= PCFHolderClass object (same as *ds:si)
		es 	= segment of PCFHolderClass
		ax	= message #
		^cx:dx	= the PCF to be closed
		bp=0	= set it not usable
		bp=1	= destroy it
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFHolderClosePCF	method dynamic PCFHolderClass, 
					MSG_PCF_HOLDER_CLOSE_PCF
	uses	ax, cx, dx, bp
	.enter

	; Either we dismiss the dialog, or free it.
	;
	tst	bp
	jz	dismiss
	call	BigCalcDestroyPCF
	jmp	done
	
	; Dismiss the current dialog, but we can't do this via an
	; InteractionCommand as we end up in an endless loop. So,
	; just set the form NOT_USABLE.
dismiss:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	movdw	bxsi, cxdx
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
done:
	.leave
	ret
PCFHolderClosePCF	endm

ProcessCode	ends
