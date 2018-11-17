COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomUI.asm

AUTHOR:		Adam de Boor , February 1, 1991

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/1/91		Initial revision
	Don	5/2/91		Moved into CCom driver

DESCRIPTION:
	Containts the procedures and method handlers that define that action
	of the SpoolFax class, a hack to allow faxing of PC/GEOS documents
	to the Complete Communicator so these OEMs will get off our backs.
		
	$Id: ccomremUI.asm,v 1.1 97/04/18 11:52:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEvalUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks in the device info for the appropriate routine to call
		to evaluate the data passed in the object tree.

CALLED BY:	EXTERNAL

PASS:		ax      = Handle of JobParameters block
		cx      = Handle of the duplicated generic tree
			  displayed in the main print dialog box.
		dx      = Handle of the duplicated generic tree
			  displayed in the options dialog box
		es:si	= JobParameters structure
		bp	= PState segment

RETURN:		carry	= clear
			- or -
		carry	= set
		cx	= handle of block holding error message

DESTROYED:	nothing

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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintStuffUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs the info stored in JobParameters back into the
		generic tree.

CALLED BY:	EXTERNAL

PASS:		bp	= PState segment
		cx	= Handle of the duplicated generic tree
			  displayed in the main print dialog box.
		dx      = Handle of the duplicated generic tree
			  displayed in the options dialog box
		es:si	= JobParameters structure
		ax	= Handle of JobParameters block

RETURN:		nothing

DESTROYED:	nothing

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

; This routine is here as it needs to accurately return the carry flag
;
PrintCallEvalRoutine	proc	near
	uses	bp, di
	.enter

	push	es, bx, ax
	mov	es, bp			; get hold of PState address.
        mov     bx, es:[PS_deviceInfo]	; handle to info for this printer.
        call    MemLock
	mov	es, ax			; es points at device info segment.
	mov	di, es:[PI_evalRoutine]
        call    MemUnlock		; unlock the puppy
	pop	es, bx, ax
	tst	di			; also clears carry
	jz	exit			; if no routine, just exit.
	call	di			; call the appropriate eval routine.
exit:
	.leave
        ret
PrintCallEvalRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UIEvalPrintUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Evaluate the UI displayed in the print dialog box

CALLED BY:	DR_PRINT_EVAL_UI, DR_PRINT_STUFF_UI
	
PASS:		bx	= PRINT_UI_EVAL_ROUTINE, PRINT_UI_STUFF_ROUTINE
		bp	= Segment of PState
		cx	= Handle of the duplicated generic tree
			  displayed in the main print dialog box.
			  (= 0 to indicate do nothing)
		dx	= Handle of the duplicated generic tree
			  displayed in the options dialog box
			  (= 0 to indicate do nothing)
		es:si	= JobParameters structure
		ax	= Handle of JobParameters block when called by
			  MSG_PRINT_CONTROL_GET_PRINTER_OPTIONS and junk
			  when called by 
			  MSG_PRINT_CONTROL_GET_PRINTER_MARGINS  

RETURN:		Carry	= Clear
		first byte of JP_printerData =
			  TRUE or FALSE depending on whether we want a 
			  coversheet
		remaining bytes of JP_printerdata =
			  telephone # to dial
		PS_paperInput = filled in with PaperInputOptions from
				PrinterInfo struct
		PS_paperOutput = filled in with PaperOutputOptions from
				PrinterInfo struct
			- or -
		CX	= Handle of block holding error message
		Carry	= Set

		es	- fixed up if JobParameters moved

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	If telephone # to dial is to big to fit in 19 bytes, we'll
	have to reallocate space for the JP struct and update its size
	in the JP_size field.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UIEvalPrintUI	proc	near
		uses	ax, bx, dx, di, si
		
jobParamsHandle	local	hptr	push	ax
jobParamsFptr	local	fptr.JobParameters push	es, si
optionsHandle	local	hptr	push	dx
		.enter
		
	;
	; Because Dave got lazy (sorry Dave), the printer drivers
	; only contain a single routine for both evaluating the UI
	; (UI -> JobParameters) & stuffing the UI (JobParameters -> UI).
	; The latter is needed for the "Cancel" feature in the Print
	; Options dialog box. So, since this routine does not currently
	; support the "Stuff" option, we'll just abort early.
	;
		cmp	bx, PRINT_UI_STUFF_ROUTINE
		LONG	je	done

	;
	; DR_PRINT_EVAL_UI is called to get the printer options as well as
	; the printer margins.  Unfortunately, when it's called to get the
	; margins, a valid JP block handle isn't passed in ax.  Thus, we
	; to check for the zero-ness of si to differentiate between who's
	; calling this function.  SI = 0 when DR_PRINT_EVAL_UI called
	; to get printer options (at this point, JP and PState are in
	; different segments) and SI != 0 when DR_PRINT_EVAL_UI called to
	; get margins (JP struct is stuck to the end of PState struct).
		

		tst	si			; carry clear
		LONG	jnz	done
		
	;
	; If there's no phone number, null-initialize the cover sheet and
	; phone number fields.
	;
		
		clr	ax
		mov	es:[si].JP_printerData, ax
		mov	{byte} es:[si].JP_printerData[2], al
		
	;
	; Verify the displayed UI is OK
	;
		
		mov	bx, cx
		mov	si, offset FaxDialogBox
		mov	ax, MSG_FAX_INFO_CHECK_INPUT
		push	bp
		call	ObjMessage_obscure_call
		pop	bp

		xchg	cx, ax			; error message => CX
		jc	done			; error - we're done

	;
	; Find out whether we want a coversheet and store this away in first
	; byte of JP_printerdata.  Selection returned in ax.
	;

		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset CoverSheetList

		push	bp
		call	ObjMessage_obscure_call
		pop	bp

		les	si, ss:[jobParamsFptr]
		mov	({JobParamData}es:[si].JP_printerData).JPD_coverSheet,
				al
		
	;
	; Copy the phone number into the remaining 19 bytes of the
	; JobParameters structure.
	;
		
		mov	dx, es

		push	si, bp
		lea	bp, ({JobParamData}es:[si].JP_printerData).JPD_phoneNum
						; buffer => DX:BP

		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	si, offset PhoneNumber
		call	ObjMessage_obscure_call		; fill the buffer
	;
	; Fetch the server name
	; 
		pop	bp
		push	bp
		mov	bx, ss:[optionsHandle]
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset ServerList
		call	ObjMessage_obscure_call
		pop	di, bp
		mov	({JobParamData}es:[di].JP_printerData).JPD_server, al
		
		clc					; show success
done:
		.leave
		ret
UIEvalPrintUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoInitializeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up some things before the window appears

CALLED BY:	UI (MSG_GEN_INITIATE_INTERACTION)

PASS:		ES	= Segment of FaxInfoClass
		DS:*SI	= FaxInfo instance data

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

textObjects	word	PhoneNumber,
			CoverSheetTo,
			CoverSheetFrom,
			CoverSheetCC,
			CoverSheetSubject,
			CoverSheetMessage

FaxInfoInitializeData	method	FaxInfoClass,	\
					MSG_SPEC_BUILD_BRANCH

dateStr		local	9 dup(char)
textRange	local	VisTextRange
	uses	ax, cx, dx, si, es
	.enter

	; Mark all the pertinent text objects completely selected for
	; easy replacement.
	;
	mov	si, offset textObjects
	mov	cx, length textObjects

selectLoop:
	push	bp
	lodsw	cs:
	push	si, cx
	xchg	si, ax
	lea	bp, ss:textRange
	clrdw	ss:[bp].VTR_start
	movdw	cxdx, TEXT_ADDRESS_PAST_END
	movdw	ss:[bp].VTR_end, cxdx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	pop	si, cx
	pop	bp
	loop	selectLoop

	; Create the current date string
	;
	call	TimerGetDateAndTime
	mov	si, DTF_SHORT
	lea	di, dateStr
	segmov	es, ss				; string buffer => ES:DI
	call	LocalFormatDateTime		; load the formatted string

	; Stuff the text object with the date
	;
	push	bp
	clr	cx
	mov	bp, di
	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset CoverSheetDate
	call	ObjCallInstanceNoLock

	; Set the number of pages 
	;
	mov	si, offset FaxDialogBox
	call	FaxInfoSetNumPages
	
	pop	bp

	.leave
	mov	di, offset FaxInfoClass
	CallSuper	MSG_SPEC_BUILD_BRANCH
	ret
FaxInfoInitializeData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoSetNumPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the number of pages in the fax

CALLED BY:	FaxInfoInitializeData

PASS:		*ds:si - FaxInfoClass object

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/02/91		Initial version
	don	5/02/91		Change to request page information

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoSetNumPages	proc	near
	class	FaxInfoClass
npagesString	local	11 dup(char)

	.enter

	; Get the number of pages
	;
	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_TOTAL_PAGE_RANGE
	call	FaxCallSpoolPrintControl
	pop	bp
		
	sub	dx, cx
	inc	dx				; number of pages => DX

	mov	di, ds:[si]
	add	di, ds:[di].FaxInfo_offset
	mov	ds:[di].FII_numPages, dx

	
	; Now convert it to ascii for placing in the CovertSheetPages display
	;
	mov	ax, dx
	inc	ax				; Plus one for the cover sheet
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE
	segmov	es, ss
	lea	di, ss:[npagesString]
	call	UtilHex32ToAscii

	; Put it in the object....
	;
	push	bp
	mov	dx, ss
	mov	bp, di
	clr	cx				; null-terminated
	mov	si, offset CoverSheetPages
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock
	pop	bp

	.leave
	ret
FaxInfoSetNumPages	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoSetCoverSheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set whether cover sheet is desired, enabling or disabling the
		cover sheet group based on this.

CALLED BY:	MSG_FAX_INFO_SET_COVER_SHEET

PASS:		DS:*SI	= FaxInfo object
		DS:DI	= FaxInfoInstance
		cx - TRUE for cover sheet, FALSE otherwise

RETURN:		Nothing

DESTROYED:	AX, CX, DX, SI, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoSetCoverSheet	method	dynamic FaxInfoClass,
					MSG_FAX_INFO_SET_COVER_SHEET
	.enter

	;
	; Adjust the enabled state of the interaction holding the
	; coversheet text.
	;
		
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	changeCoverGroup
	mov	ax, MSG_GEN_SET_ENABLED
changeCoverGroup:
	mov	si, offset CoverSheetDialogBox
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	.leave
	ret
FaxInfoSetCoverSheet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoWantsGeoDex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text from phone number object...if text starts
		with a letter then use IACP mechanism to send GeoDex a
		MSG_ROLODEX_REQUEST_SEARCH. 

CALLED BY:	MSG_FAX_INFO_WANTS_GEODEX
PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		ds:bx	= FaxInfoClass object (same as *ds:si)
		es 	= segment of FaxInfoClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	HL	4/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
geodexToken 	GeodeToken	ROLODEX_TOKEN
emptyString	char	0

FaxInfoWantsGeoDex	method FaxInfoClass, 
					MSG_FAX_INFO_WANTS_GEODEX
		.enter
		
	; See if the current phone number begins with a letter. If so, pass
	; the string to GeoDex to locate.
	;

		mov	ax, PHONE_NUMBER_LENGTH
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc			; bx = handle of block

		mov_tr	dx, ax
		clr	bp				; dx:bp = text buffer

		mov	si, offset PhoneNumber
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock

		
		jcxz	freeSearchBlock

	;
	; Fetch the first character, and see if it's a letter.  If
	; not, bail.  In any event, unlock the block, just to be
	; well-behaved... 
	;
		
		push	ds
		mov	ds, dx
		mov	al, ds:[0]
		pop	ds

		call	MemUnlock
		
		clr	ah
		call	LocalIsAlpha
		jz	freeSearchBlock
		
	; Create a launch block so IACP can launch the app if it's not
	; around yet.
	; 

		push	bx, cx			; text parameters
		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock
		mov	bx, dx			; launch block
		
	;
	; Connect to all GeoDex apps currently functional, using our
	; application object as the client OD
	; 
		segmov	es, cs
		mov	di, offset geodexToken
		mov	ax, IACPSM_USER_INTERACTIBLE shl \
					offset IACPCF_SERVER_MODE
		call	IACPConnect
		mov_tr	ax, cx			; # of connections => AX
		pop	bx, cx			; text parameters
		jc	freeSearchBlock

	;
	; Initialize reference count for block to be the number of servers
	; to which we're connected so we can free the block when they're all
	; done. Then record the message we're going to send.
	;
		
		call	MemInitRefCount
		mov	dx, bx			; text handle => DX
		mov	ax, MSG_ROLODEX_REQUEST_SEARCH
		clr	bx, si			; any class acceptable
		call	ObjMessage_obscure_record
		push	di			; event handle

	;
	; Record completion message for nuking text block
	;
		
		call	GeodeGetProcessHandle
		mov	ax, MSG_META_DEC_BLOCK_REF_COUNT
		clr	cx			; no block in cx
						; (block is in dx)
		call	ObjMessage_obscure_record

	;
	; Finally, send the message through IACP
	;
		mov	cx, di			; cx <- completion msg
		pop	bx			; bx <- msg to send
		mov	dx, TO_PROCESS		; dx <- TravelOption
		mov	ax, IACPS_CLIENT	; ax <- side doing the send
		call	IACPSendMessage

	;
	; That's it, we're done.  Shut down the connection we opened up, so
	; that GeoDex is allowed to exit.  -- Doug 2/93
	;
		clr	cx, dx			; shutting down the client
		call	IACPShutdown

	;
	; Now empty the phone number text object so the user's got a clean
	; slate to copy the number back into.
	;
		mov	dx, cs
		mov	bp, offset emptyString
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	si, offset PhoneNumber
		call	ObjCallInstanceNoLock


done:
		.leave
		ret
freeSearchBlock:
		call	MemFree
		jmp	done		
	
FaxInfoWantsGeoDex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoCheckInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the input fields of the summons contain valid
		data.

CALLED BY:	MSG_FAX_INFO_CHECK_INPUT

PASS:		DS:*SI	= FaxInfo object

RETURN:		Carry	= Clear (OK)
			- or -
		Carry	= Set
		AX	= Handle to block holding error message

DESTROYED:	AX, BX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:
		For now, we just check the PhoneNumber field to make
		sure it contains only valid phone number characters.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/91		Initial version
	don	4/27/91		Use standard error mechanism

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
legalPhoneChars	char	' ()-#,;@0123456789'

FaxInfoCheckInput method dynamic FaxInfoClass, MSG_FAX_INFO_CHECK_INPUT
	uses	cx, dx, bp
	.enter
	assume	ds:FaxUI

	; Allocate an LMem block for the phone number
	;
	clr	al
	mov	cx, PHONE_NUMBER_LENGTH
	call	LMemAlloc			; ax = handle of chunk
	mov_tr	bx, ax
	mov	bp, bx
	mov	bp, ds:[bp]
	mov	dx, ds				; dx:bp = text buffer
	mov	si, offset PhoneNumber
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjCallInstanceNoLock
	jcxz	errorFreeChunk
		
	mov	si, bx
	mov	si, ds:[si]
	segmov	es, cs
	clr	dx
checkLoop:
	lodsb
	cmp	al, '0'
	jb	checkValidPunct
	cmp	al, '9'
	ja	checkValidPunct
	inc	dx		; note another digit
checkValidPunct:
	push	cx
	mov	di, offset legalPhoneChars
	mov	cx, length legalPhoneChars
	repne	scasb
	pop	cx
	loope	checkLoop

	jne	errorFreeChunk
	tst	dx
	jz	errorFreeChunk
	mov_tr	ax, bx		; ax <- text chunk
	call	LMemFree
	clc
done:
	.leave
	ret

errorFreeChunk:
	mov_tr	ax, bx
	call	LMemFree

	; Copy error into block, to be displayed by SpoolPrintControl
	;

	mov	si, ds:[badPhoneNumberMessage]
	ChunkSizePtr	ds, si, ax		; length of message => AX
	push	ax
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc			; allocate block for message
	mov	es, ax
	clr	di
	pop	cx
	ECRepMovsb
	call	MemUnlock
	mov_tr	ax, bx				; memory handle => AX
	stc
	jmp	done				; we're outta here
	assume	ds:dgroup
FaxInfoCheckInput endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoPrintCoverSheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the cover sheet to the spool file, if requested.

CALLED BY:	DR_PRINT_ESC_PREPEND_PAGE

PASS:		ax	= handle of GState to draw to
		bx	= handle of PState
		cx	= handle of duplicated "Main" tree
		dx	= handle of duplicated "Options" tree
		
RETURN:		nothing

DESTROYED:	BX, CX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/02/91		Initial version
	don	5/02/91		Moved into fax driver
	huan	4/29/93		Changed to a printer escape call

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ptrOffsets	word	CoverSheetDatePtr-CoverGStringBase,
			CoverSheetToPtr-CoverGStringBase,
			PhoneNumberPtr-CoverGStringBase,
			CoverSheetCCPtr-CoverGStringBase,
			CoverSheetFromPtr-CoverGStringBase,
			CoverSheetSubjectPtr-CoverGStringBase,
			CoverSheetPagesPtr-CoverGStringBase

objChunks	word	CoverSheetDate,
			CoverSheetTo,
			PhoneNumber,
			CoverSheetCC,
			CoverSheetFrom,
			CoverSheetSubject,
			CoverSheetPages

FaxInfoPrintCoverSheet	proc	far

		assume	ds:FaxUI

		.enter
		mov_tr	di, ax		; dest gstate

	;
	; Dereference the main options UI, and use it.  Let's hope
	; we're running under the same thread!
	;

		mov	bx, cx
		call	ObjLockObjBlock
		mov	ds, ax

	;		
	; Query "CoverSheetList" to see if user wanted a cover sheet.
	; If not, we don't have to do any of this. Selection returned in ax.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset CoverSheetList
		call	ObjCallInstanceNoLock
		
		tst	ax			; identifier of "No" item = 0
	LONG	jz	done

	;
	; Modify the cover sheet gstring to hold the offsets of the text
	; chunks for the text objects in the above tables.
	;
		
		.warn	-private

		push	di			; dest gstate

		mov	di, ds:[CoverGString]
		clr	bp
		mov	cx, length ptrOffsets
coverTextLoop:
		mov	bx, cs:ptrOffsets[bp]
		mov	si, cs:objChunks[bp]
	;
	; Find the text chunk for the object
	;
		mov	si, ds:[si]
		add	si, ds:[si].Gen_offset
		mov	si, ds:[si].GTXI_text

	;
	; Store the current base of the chunk in the gstring opcode
	;
		mov	si, ds:[si]
		tst	{char}ds:[si]
		jnz	storeTextPtr
	;
	; GR_DRAW_TEXT_PTR opcode screws up if null-terminator-only string
	; is given to it (copies no data & gives length of 0, making
	; GR_DRAW_TEXT handler draw the following gstring elements as
	; the string), so give it a blank string instead.
	;
		mov	si, ds:[BlankString]
storeTextPtr:
		mov	ds:[di][bx].ODTP_ptr, si
		
	; Advance to next object
	;
		inc	bp
		inc	bp
		loop	coverTextLoop
afterLoop::
		pop	di			; gstate
		

	;
	; Load the gstring so we can pass the handle to GrDrawGString.
	;
		mov	cl, GST_PTR
		mov	bx, ds
		mov	si, ds:[CoverGString]	; 
		call	GrLoadGString		; si - gstring handle

	;
	; Now draw the string to the passed gstate
	;
		mov	ax, COVER_LEFT_MARGIN
		mov	bx, COVER_TOP_MARGIN	; position on page to
						; play GString
		clr	dx			; play entire string
		call	GrDrawGString

	;
	; Destroy the original gstring handle
	;
		push	di
		clr	di
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
		pop	di
		
	;
	; Finally, set up and draw the message text. This code is taken from
	; the notepad. wheeee.
	;
		
		call	GrSetDefaultTransform
		mov	dx, FAX_MESSAGE_LEFT+COVER_LEFT_MARGIN
		clr	cx
		mov	bx, FAX_MESSAGE_TOP+COVER_TOP_MARGIN
		clr	ax
		call	GrApplyTranslation

	;		
	; Now stuff the text into the empty text object
	; (Allocate text in memory block to prevent objects from shifting)
	;
		clr	dx
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		mov	si, offset CoverSheetMessage
		call	ObjCallInstanceNoLock

		mov	bx, cx
		call	MemLock
		mov_tr	dx, ax
		
		clr	cx, bp
		mov	si, offset PrintTextEdit
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		call	MemFree
	;		
	; Now tell the text object to draw itself
	;
		mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
		call	ObjCallInstanceNoLock

		mov	bp, di
		mov	cl, mask DF_EXPOSED or mask DF_PRINT
		mov	ax, MSG_VIS_DRAW
		call	ObjCallInstanceNoLock

	;		
	; Finally, issue a form-feed if there are any pages in the document.
	;

		mov	bx, ds:[FaxDialogBox]
		add	bx, ds:[bx].FaxInfo_offset
		tst	ds:[bx].FII_numPages		
		jz	done
		mov	al, PEC_FORM_FEED
		call	GrNewPage		; else we want a new page
done:
	;
	; Unlock our object block
	;
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock

		.leave
		ret

		.warn	@private
		assume	ds:dgroup
FaxInfoPrintCoverSheet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxCallSpoolPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a method to the SpoolPrintControl object above me in
		the generic tree

CALLED BY:	INTERNAL
	
PASS:		DS:*SI	= FaxInfoClass object
		AX	= Method to send
		CX	}
		DX	= Data to send with method
		BP	}

RETURN:		AX, CX, DX, BP

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxCallSpoolPrintControl	proc	near
	uses	bx, si, di
	.enter

	; Find the SpoolPrintControlClass object
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
	mov	cx, segment PrintControlClass
	mov	dx, offset PrintControlClass
	call	ObjCallInstanceNoLock		; ^lcx:dx = SPC
EC <	ERROR_NC	UI_FAX_COULD_NOT_FIND_SPOOL_SUMMONS		>

	; Now pass the method on to the SpoolPrintControl object
	;
	mov	bx, cx
	mov	si, dx
	pop	ax, cx, dx, bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
FaxCallSpoolPrintControl	endp

ObjMessage_obscure_record	proc	near
	mov	di, mask MF_RECORD
	GOTO	ObjMessage_obscure
ObjMessage_obscure_record	endp

ObjMessage_obscure_call		proc	near
	mov	di, mask MF_CALL		; MessageFlags => DI
	FALL_THRU	ObjMessage_obscure
ObjMessage_obscure_call		endp

ObjMessage_obscure		proc	near
	call	ObjMessage			; send the message
	ret
ObjMessage_obscure		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoBuildServerList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add children to the ServerList object corresponding to
		the servers in the faxServers key of the [printer] category

CALLED BY:	(INTERNAL) FaxInfoInitializeData
PASS:		ds	= object block
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerCatString	char	'printer', 0
faxServerKeyString	char	'faxServers', 0
FaxInfoBuildServerList method FaxServerListClass, MSG_SPEC_BUILD_BRANCH
		uses	ax, cx, dx, si, es, bp
		.enter
		segmov	es, ds
		mov	bx, si
		segmov	ds, cs, cx
		mov	si, offset printerCatString
		mov	dx, offset faxServerKeyString
		mov	bp, IFCC_INTACT shl offset IFRF_CHAR_CONVERT
		mov	di, cs
		mov	ax, offset FIBSL_callback
		call	InitFileEnumStringSection
		segmov	ds, es
		.leave
		mov	ax, MSG_SPEC_BUILD_BRANCH
		mov	di, offset FaxServerListClass
		GOTO	ObjCallSuperNoLock
FaxInfoBuildServerList endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIBSL_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to add one server to the list of servers.

CALLED BY:	(INTERNAL) FaxInfoBuildServerList via InitFileEnumStringSection
PASS:		ds:si	= string section (null-terminated)
		dx	= section #
		cx	= length of section
		*es:bx	= list object
RETURN:		carry set to stop enumerating
DESTROYED:	ax, cx, dx, di, si, bp all allowed (es fixed up)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FIBSL_callback	proc	far
		uses	ds
		.enter
		push	bx, ds, si, dx
		segmov	ds, es
		segmov	es, <segment GenItemClass>, di
		mov	di, offset GenItemClass
		mov	bx, ds:[LMBH_handle]
		call	ObjInstantiate		; *ds:si <- item
		
	;
	; Set the item's identifier to the string section number.
	; 
		pop	cx
		mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
		call	ObjCallInstanceNoLock
	;
	; Set the item's moniker to the fax server name.
	; 
		pop	cx, dx
		mov	bp, VUM_MANUAL
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		call	ObjCallInstanceNoLock
	;
	; Add the item as the last child of the server list.
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		pop	si			; *ds:si <- list
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
		call	ObjCallInstanceNoLock

		mov	bx, si			; return list in bx
	;
	; Make the item usable. It should update visually in a minute, anyway.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	si, dx		 ; (dx saved by GEN_ADD_CHILD)
		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock

		segmov	es, ds
		clc
		.leave
		ret
FIBSL_callback 	endp

