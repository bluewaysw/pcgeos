
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		uiEval.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintEvalUI		gets ui info from the gewneric tree.
	PrintStuffUI		returns the info from the JobParameters to 
				the generic tree.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial revision
	Dave	3/93		Added stuff routines


DESCRIPTION:

	$Id: uiEval.asm,v 1.1 97/04/18 11:50:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEvalUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	looks in the device info for the appropriate routine to call
		to evaluate the data passed in the object tree.

CALLED BY:	EXTERNAL

PASS:		ax      = Handle of JobParameters block
		cx      = Handle of the duplicated generic tree
			displayed in the main print dialog box.
		dx      = Handle of the duplicated generic tree
			displayed in the options dialog box
		es:si      = JobParameters structure
		bp      = PState segment


RETURN:        nothing

DESTROYED:	ax, bx, cx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		Make sure the JobParameters handle gets through!

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    01/92           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEvalUI	proc    far
	mov	bx,PRINT_UI_EVAL_ROUTINE
	call	PrintCallEvalRoutine
        ret
PrintEvalUI     endp

PrintCallEvalRoutine	proc	near
	uses	bp

	.enter

	push	es,bx
	mov	es,bp		;get hold of PState address.
        mov     bx,es:[PS_deviceInfo]   ; handle to info for this printer.
	push	ax
        call    MemLock
        mov     ds, ax                   ; ds points at device info segment.
	pop	ax

	mov	di, ds:[PI_evalRoutine]
        call    MemUnlock       ; unlock the puppy
	pop	es,bx
	tst	di
	jz	exit			; if no routine, just exit.
	call	di			;call the approp. eval routine.
exit:
	clc
	.leave
        ret
PrintCallEvalRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintStuffUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	stuffs the info stored in JobParameters back into the generic tree.

CALLED BY:
	EXTERNAL

PASS:
			bp      = PState segment
			cx      = Handle of the duplicated generic tree
				displayed in the main print dialog box.
			dx      = Handle of the duplicated generic tree
				displayed in the options dialog box
			es:si      = JobParameters structure
			ax      = Handle of JobParameters block


RETURN:
        nothing

DESTROYED:
        nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    03/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintStuffUI	proc    far
	mov	bx,PRINT_UI_STUFF_ROUTINE
	call	PrintCallEvalRoutine
	ret
PrintStuffUI	endp

