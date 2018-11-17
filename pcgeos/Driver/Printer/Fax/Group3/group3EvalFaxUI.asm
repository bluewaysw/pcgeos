COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3EvalFaxUI.asm

AUTHOR:		Jacob Gabrielson, Mar 23, 1993

ROUTINES:
	Name			Description
	----			-----------
   	INT FaxEvalMainUI	Evaluates the UI of the printer dialog
				So we can find the name and number amoung other
				things.

	EvalPrintOptions	Reads the print options in the UI.  
				This includes cover page information.

	EvalDialAssistOptions	Sees what dial assist options were chosen
				and saves it.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	3/23/93   	Initial revision
	AC	9/ 8/93		Changed for Group3

DESCRIPTION:
	
		

	$Id: group3EvalFaxUI.asm,v 1.1 97/04/18 11:52:54 newdeal Exp $

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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxEvalMainUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	called to evaluate the data passed in the object tree.

CALLED BY:	DriverStrategy

PASS:
	bx =	PRINT_UI_EVAL_ROUTINE (we are getting stuff from UI objs)
			-- or --
		PRINT_UI_STUFF_ROUTINE (we are putting stuff in UI objs)
	bp =	PState segment
	cx =	Handle of the duplicated generic tree
		displayed in the main print dialog box.
	dx =	Handle of the duplicated generic tree
		displayed in the options dialog box
	es:si =	Segment holding JobParameters structure

	ax	= Handle of JobParameters block when called by
		  MSG_PRINT_CONTROL_GET_PRINTER_OPTIONS and junk
		  when called by 
		  MSG_PRINT_CONTROL_GET_PRINTER_MARGINS  
RETURN:
	if no phone number 
	carry set
	cx 	= block containing error string

DESTROYED:
	possibly bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Need error handling routine if out of memory

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
	JAG	3/93		Initial Version
	AC	9/19/93		Modified for Group3

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxEvalMainUI	proc	near
		.enter

	;
	; DR_PRINT_EVAL_UI is called to get the printer options as well as
	; the printer margins.  Unfortunately, when it's called to get the
	; margins, a valid JP block handle isn't passed in ax.  Thus, we
	; to check for the zero-ness of si to differentiate between who's
	; calling this function.  SI = 0 when DR_PRINT_EVAL_UI called
	; to get printer options (at this point, JP and PState are in
	; different segments) and SI != 0 when DR_PRINT_EVAL_UI called to
	; get margins (JP struct is stuck to the end of PState struct).
	;

		tst	si			; carry clear
		LONG	jnz	done

	;
	; Save registers so nothing gets destroyed
	;
		push	ax, bx, bp, di
	;
	; Resize job parameters.  If there is an error in resizing them
	; then we have to abort the job.
	;
		
		mov_tr	bx, ax				; bx <- JobParam Handle
		mov	ax, es:[si].JP_size		; ax <- size of JobPar.
		
		add	ax, size FaxFileHeader

		push	cx				; save handle to UI
		mov	ch, mask HAF_NO_ERR
		call	MemReAlloc			; ax <- new segment
	LONG 	jc	jobParamsAllocError
		
		mov	es, ax

	;
	; Lock the segment that has our duplicated UI so we can
	; freely write to it.
	;
		pop	bx			; bx <_ handle to UI
		call	ObjLockObjBlock		; ax <- UI segment
		mov	ds, ax			; ds <- UI segment
		add	es:[si].JP_size, size FaxFileHeader
	;
	; Because of a quarkiness of Geocalc we are going to disable the
	; FaxInfo UI.
	;
		mov	di, si				; es:di = JobParameters
		mov	si, offset FaxDialogBox
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjCallInstanceNoLock
	;
	; Have es:di point to the FaxFileHeader
	;
		lea	di, es:[di].JP_printerData	; es:di = FaxFileHeader
	;
	; Initialize misc. fields in the new FaxFileHeader structure.
	;
		mov	es:[di].FFH_status, FFS_DISABLED
		clr	es:[di].FFH_flags
	;
	; Find out print options for this print job
	;
		call	EvalPrintOptions
	;	
	; Find out the dialing assist options
	;
		call	EvalDialAssistOptions
	;
	; Unlock the UI segment
	;
		call	MemUnlock
	;
	; Give this job a Fax ID so the fax spooler can identify it.
	; If it's the same as FAX_ERROR_SPOOL_ID, get a new one.
	;
getID:
		call	TimerGetCount		; ax:bx <- system count
		cmpdw	bxax, FAX_ERROR_SPOOL_ID
		jz	getID
		
		movdw	es:[di].FFH_spoolID, bxax
	;
	; Find out the date and time this job is spooled.
	;
		call	TimerGetDateAndTime	; ax..dx returned
		mov	es:[di].FFH_spoolDateTime.FSDT_spoolYear, ax
		mov	es:[di].FFH_spoolDateTime.FSDT_spoolMonth, bl
		mov	es:[di].FFH_spoolDateTime.FSDT_spoolDay, bh
		mov	es:[di].FFH_spoolDateTime.FSDT_spoolDayOfWeek, cl
		mov	es:[di].FFH_spoolDateTime.FSDT_spoolHour, ch
		mov	es:[di].FFH_spoolDateTime.FSDT_spoolMinute, dl
		mov	es:[di].FFH_spoolDateTime.FSDT_spoolSeconds, dh

	;
	; Restore registers that are trashed.
	;
		clc
restoreRegistersAndLeave::
		pop	ax, bx, bp, di
done:
		.leave
		ret

	;
	; This is how we are going to tell if there's an error and abort
	; the job.  Since the FaxJobParameters overlaps 10 words of data
	; with the PState in the JobParamters, we can still put info
	; in FaxSpoolID.  So if it's an error job we'll put a bogus ID
	; in FaxSpoolID and then when PrintStartJob comes around, we'll
	; abort the job.
jobParamsAllocError:
	;
	; Put the bogus ID in the FaxSpoolID.
	;
		.warn -field
		movdw	es:[JP_printerData].FFH_spoolID, \
			FAX_ERROR_SPOOL_ID
		.warn @field

		pop	cx			; restore stack
		clc
		jmp	restoreRegistersAndLeave

FaxEvalMainUI endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalPrintOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads the print options in the UI.  This includes cover
		page information.  Puts the information in the job parameters.

CALLED BY:	FaxEvalMainUI

PASS:		es:di	= FaxFileHeader (in JobParameters)
		ds	= segment of UI

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Counts on the receiver's fax number being last in the
		tables so that we can check if there's no fax number
		when we exit the loop.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalPrintOptions	proc	near
		uses	ax,bx,cx,dx,si,bp
		.enter
	;
	; Check to see if a cover sheet is needed
	;
		mov	si, offset CoverPageUseCoverPageItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock		; ax <- selection
		cmp	ax, TRUE
		jz	yesCover			; has a selection!
noCover::
		BitClr	es:[di].FFH_flags, FFF_COVER_PAGE
		jmp	doneCover
yesCover:
		BitSet	es:[di].FFH_flags, FFF_COVER_PAGE
doneCover:
	;
	;  Get the name and number and write the data to the
	;  FaxFileHeader in the FaxJobParameters structure.
	;
		mov	dx, es
		mov	bx, size word * (length FJPTextObjects - 1)
getUIInformation:
		mov	si, cs:FJPTextObjects[bx]	; *ds:si <- object
		mov	bp, di
		add	bp, cs:FJPTextOffsets[bx]	; dx:bp <- text buffer
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock		; cx <- string length

		dec	bx
		dec	bx
		jns	getUIInformation
	;
	; The last item is the receiver's fax number.  Check if there's a #.
	;
EC <		cmp	si, offset Group3NumberText			>
EC <		ERROR_NE RECEIVER_FAX_NUMBER_MUST_BE_FIRST_IN_TABLE 	>
		
		jcxz	noFaxNum
exit:
		.leave
		ret

noFaxNum:
	;
	; Put up a dialog to warn the user that there is no fax number.
	;
		mov	si, offset NoFaxNumber
		mov	ax, CustomDialogBoxFlags \
				<1,CDT_NOTIFICATION,GIT_NOTIFICATION,0>
		call	DoDialog
		jmp	exit


EvalPrintOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvalDialAssistOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sees what dial assist options were chosen and saves it.

CALLED BY:	FaxEvalMainUI

PASS:		es:di	= FaxFileHeader
		ds	= segment of UI

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/13/93    	Initial version
	stevey	3/4/94		rewrote to use new FaxFileHeader structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EvalDialAssistOptions	proc	near
		uses	ax,cx,dx,si,bp
		.enter
	;
	;  Get the various numbers (if any) into the fax file header.
	;
		mov	dx, es
		lea	bp, es:[di].FFH_access		; dx.bp = buffer
		mov	si, offset DialAssistAccessText
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock		; destroys ax
	
		mov	si, offset DialAssistLongDistanceText
		lea	bp, es:[di].FFH_longDistance
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock

		mov	si, offset DialAssistBillingCardText
		lea	bp, es:[di].FFH_billCard
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock
	;
	;  Record whether access code was selected.
	;
		mov	si, offset DialAssistAccessItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	noAccess

		BitSet	es:[di].FFH_flags, FFF_ACCESS_CODE
		jmp	doneAccess
noAccess:
		BitClr	es:[di].FFH_flags, FFF_ACCESS_CODE
doneAccess:
	;
	;  Record whether billing card was selected.
	;
		mov	si, offset DialAssistBillingCardItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	noBilling

		BitSet	es:[di].FFH_flags, FFF_BILL_CARD
		jmp	doneBilling
noBilling:
		BitClr	es:[di].FFH_flags, FFF_BILL_CARD
doneBilling:
	;
	;  Record whether long-distance was selected.
	;
		mov	si, offset DialAssistLongDistanceItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	noLongDist

		BitSet	es:[di].FFH_flags, FFF_LONG_DIST
		jmp	doneLongDist
noLongDist:
		BitClr	es:[di].FFH_flags, FFF_LONG_DIST
doneLongDist:

if 0
	;
	;  See if any dialing assist options were wanted.
	;
		mov	si, offset Group3DialAssistItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	noDialAssist			; no selection

		BitSet	es:[di].FFH_flags, FFF_DIAL_ASSIST
		jmp	doneDialAssist
noDialAssist:
		BitClr	es:[di].FFH_flags, FFF_DIAL_ASSIST
doneDialAssist:
endif
		
		.leave
		ret
EvalDialAssistOptions	endp

















