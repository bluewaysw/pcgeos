COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Spool/UI
FILE:		uiSpoolSummonsExternal.asm

AUTHOR:		Don Reeves, March 30, 1990
n
ROUTINES:
	Name				Description
	----				-----------
    MSG	SpoolSummonsGetPrintInfo	MSG_SS_GET_PRINT_INFO handler
    MSG	SpoolSummonsGetPaperSizeInfo	MSG_SS_GET_PAPER_SIZE_INFO handler
    MSG	SpoolSummonsGetPrinterOptions	MSG_SS_GET_PRINTER_OPTIONS handler
    MSG	SpoolSummonsSetOutput		MSG_SS_SET_OUTPUT handler
    MSG	SpoolSummonsSetPageRange	MSG_SS_SET_PAGE_RANGE handler
    MSG	SpoolSummonsGetPageRange	MSG_SS_GET_PAGE_RANGE handler
    MSG	SpoolSummonsSetUserPageRange	MSG_SS_SET_USER_PAGE_RANGE handler
    MSG	SpoolSummonsGetUserPageRange	MSG_SS_GET_USER_PAGE_RANGE handler
    MSG	SpoolSummonsGetActualPageRange	MSG_SS_GET_ACTUAL_PAGE_RANGE handler
    MSG	SpoolSummonsSetPrintAttributes	MSG_SS_SET_PRINT_ATTRS handler
    MSG	SpoolSummongGetPrintMode	MSG_SS_GET_PRINT_MODE handler
    MSG	SpoolSummonsSetDefaultPrinter	MSG_SS_SET_DEFAULT_PRINTER handler
    MSG	SpoolsummonsPrintingToFile	MSG_SS_PRINTING_TO_FILE handler
    MSG	SpoolSummonsGetPrinterMargins	MSG_SS_GET_PRINTER_MARGINS handler

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/89		Initial revision
	Don	1/16/92		Update documentation

DESCRIPTION:
	Contains the procedures and method handlers that define that action
	of the SpoolSummons class.
		
	$Id: uiSpoolSummonsExternal.asm,v 1.1 97/04/07 11:10:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsInitializeUILevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the print dialog UI

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_SET_UI_LEVEL)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note that some monikers are changed later, when
		determining which type of print dialog box (print
		or fax) to be displayed in SpoolSummonsSetDriverTYpe()
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsInitializeUILevel	method dynamic	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_INITIALIZE_UI_LEVEL
		.enter

		; If we are in simple UI mode, go change a few things
		;
		test	es:[uiOptions], mask SUIO_SIMPLE
		jz	checkTimeoutRetry	; not simple, so move one

		; Remove the external width & height notifications
		;
		clr	ax, bx
		mov	si, offset PrinterPaperSize
		call	SetUsableOrNotUsableObject

		; Check out the use of Timeout/Retry values
checkTimeoutRetry:
		sub	sp, 2 * (size optr)
		mov	di, sp
		mov	bx, ds:[LMBH_handle]
		clr	cx
		test	es:[uiOptions], mask SUIO_TIMEOUT_RETRY
		jz	checkPrintToFile
		mov	ss:[di].handle, bx
		mov	ss:[di].chunk, offset TimeoutRetryGroup
		add	cx, 4

		; Check out the use of Print-to-File
checkPrintToFile:
		test	es:[uiOptions], mask SUIO_PRINT_TO_FILE
		jz	checkToAddVarData
		push	di
		add	di, cx
		mov	ss:[di].handle, bx
		mov	ss:[di].chunk, offset PrintToOptionsList
		add	cx, 4
		pop	di
checkToAddVarData:
		jcxz	checkPrinterGroup
		call	addUIToChangeBox
	
		; Make the PrinterGroup un-usable if this flag is set.
checkPrinterGroup:
		add	sp, 2 * (size optr)
		test	es:[uiOptions], mask SUIO_NO_PRINTER_GROUP
		jz	done
		clr	ax, bx
		mov	si, offset PrinterGroup
		call	SetUsableOrNotUsableObject
done:
		.leave
		ret

addUIToChangeBox:
		; Create the AddVarDataParams structure & initialize the data
		;
		mov	dx, (size AddVarDataParams)
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].AVDP_data.segment, ss
		mov	ss:[bp].AVDP_data.offset, di
		mov	ss:[bp].AVDP_dataSize, cx
		mov	ss:[bp].AVDP_dataType, ATTR_GEN_CONTROL_APP_UI

		; Tell the object to modify its vardata
		;
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	si, offset PrinterPageSizeControl
		call	ObjCallInstanceNoLock
		add	sp, (size AddVarDataParams)
		retn
SpoolSummonsInitializeUILevel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPrintInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the various and sundry print option information

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_PRINT_INFO)

PASS:		DS:*SI	= SpoolSummons instance data

RETURN: 	CL	= PrinterMode
		CH	= SpoolOptions
		DL	= Number of retries
		DH	= Number of copies
		BP	= Timeout value (seconds)

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetPrintInfo	method	SpoolSummonsClass, \
					MSG_SPOOL_SUMMONS_GET_PRINT_INFO
	.enter

	; Gather all of the information
	;
	mov	ax, MSG_SPOOL_SUMMONS_GET_PRINT_MODE
	call	ObjCallInstanceNoLock		; print mode => CL
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	mov	ch, ds:[di].SSI_spoolOptions
	mov	dl, ds:[di].SSI_retries	
	mov	dh, ds:[di].SSI_numCopies
	mov	bp, ds:[di].SSI_timeout

	.leave
	ret
SpoolSummonsGetPrintInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPaperSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the page size

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_PAPER_SIZE_INFO)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance
		DX:BP	= PageSizeReport buffer

RETURN:		DX:BP	= PageSizeReport filled

DESTROYED:	AX, CX, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetPaperSizeInfo	method dynamic	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_GET_PAPER_SIZE_INFO
	uses	dx, bp
	.enter

	; First get the document size
	;
	push	si
	mov	ax, MSG_PZC_GET_PAGE_SIZE
	mov	si, offset PrinterPageSizeControl
	call	ObjCallInstanceNoLock
	movdw	esdi, dxbp

	; Now get the margins
	;
	pop	si
	mov	ax, MSG_SPOOL_SUMMONS_GET_PRINTER_MARGINS
	call	ObjCallInstanceNoLock
	mov	es:[di].PSR_margins.PCMP_left, ax
	mov	es:[di].PSR_margins.PCMP_top, cx
	mov	es:[di].PSR_margins.PCMP_right, dx
	mov	es:[di].PSR_margins.PCMP_bottom, bp
	
	.leave
	ret
SpoolSummonsGetPaperSizeInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPrinterOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the options displayed by the printer driver

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_PRINTER_OPTIONS)
	
PASS:		*DS:SI	= SpoolSummons object
		DS:DI	= SpoolSummonsInstance
		CX	= JobParameters block handle

RETURN: 	AX	= Zero if no error
			= Non-zero if error

DESTROYED: 	BX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetPrinterOptions	method	dynamic	SpoolSummonsClass, \
				MSG_SPOOL_SUMMONS_GET_PRINTER_OPTIONS
	uses	cx
	.enter

	; Evaluate the UI now, please
	;
	mov	bx, cx				; JobParameters => BX
	call	EvalPrinterUI
	jc	error
	clr	ax
done:
	.leave
	ret

	; Display an error returned by the print driver
error:
	mov	ax, 1				; need to return error
	jcxz	done				; no error to display, so bail
	mov	bx, cx
EC <	call	ECCheckMemHandle		; verify memory handle	>
	call	MemLock				; lock the error block
	mov_tr	dx, ax
	clr	ax				; error message => DX:AX
	mov	cx, PCERR_EXTERNAL		; custom error display
	call	UISpoolErrorBox			; display the error
	call	MemFree				; free the error block display	
	mov	ax, 1				; need to return error
	jmp	done				; we're done
SpoolSummonsGetPrinterOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the total page range to the desired page values CX -> DX

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_SET_PAGE_RANGE)

PASS:		DS:DI	= SpoolSummons instance data
		CX	= First page value
		DX	= Last page value

RETURN:		Nothing

DESTROYED:	AX, BP, SI

PSEUDO CODE/STRATEGY:
		Assumme the page values have already been checked for
		inconsistencies

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetPageRange	method	dynamic	SpoolSummonsClass, \
					MSG_SPOOL_SUMMONS_SET_PAGE_RANGE
	uses	cx, dx
	.enter

	; Store the first and last page values
	;
	mov	ds:[di].SSI_firstPage, cx	; store the first page
	mov	ds:[di].SSI_lastPage, dx	; store the last page

	; Set the maximum values
	;
	mov	si, offset PageFrom
	call	SSSetMaximumValue
	mov	si, offset PageTo
	call	SSSetMaximumValue

	; Set the minimum values
	;
	xchg	cx, dx				; first page => CX
	call	SSSetMinimumValue
	mov	si, offset PageFrom
	call	SSSetMinimumValue

	; Enable or disable the ranges & the selected trigger
	;
	clr	bl				; assume only on page
	cmp	cx, dx				; compare the pages
	je	10$				; if equal, OK
	mov	bl, 1				; assume more than one page
10$:
	mov	bh, 1				; use this a "my value"
	mov	si, offset PageFrom		; enable or disable DS:SI
	call	EnableOrDisableObject
	mov	si, offset PageTo		; enable or disable DS:SI
	call	EnableOrDisableObject
	mov	si, offset SelectedEntry	; enable or disable DS:SI
	call	EnableOrDisableObject

	.leave
	ret
SpoolSummonsSetPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the absolute page range (not the USER page range)

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_PAGE_RANGE)

PASS:		DS:DI	= SpoolSummons instance data

RETURN:		CX	= First page
		DX	= Last page

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetPageRange	method	SpoolSummonsClass, \
					MSG_SPOOL_SUMMONS_GET_PAGE_RANGE
	.enter

	; Get the values
	;
	mov	cx, ds:[di].SSI_firstPage
	mov	dx, ds:[di].SSI_lastPage

	.leave
	ret
SpoolSummonsGetPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetUserPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the user page range (not absolute)

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_SET_USER_PAGE_RANGE)

PASS:		DS:DI	= SpoolSummons instance data
		CX	= First page
		DX	= Last page

RETURN:		Nothing

DESTROYED:	AX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetUserPageRange	method	dynamic	SpoolSummonsClass, \
				MSG_SPOOL_SUMMONS_SET_USER_PAGE_RANGE
	uses	cx, dx
	.enter

	; Store the first and last page values (check range first)
	;
	cmp	cx, ds:[di].SSI_firstPage
	jge	checkLast
	mov	cx, ds:[di].SSI_firstPage
checkLast:
	cmp	dx, ds:[di].SSI_lastPage
	jle	storeValues
	mov	dx, ds:[di].SSI_lastPage
storeValues:
	mov	ds:[di].SSI_firstUserPage, cx	; store the first page
	mov	ds:[di].SSI_lastUserPage, dx	; store the last page

	; Set the first & last user values
	;
	mov	si, offset PageTo
	call	SSSetIntegerValueStatus
	mov	dx, cx
	mov	si, offset PageFrom
	call	SSSetIntegerValueStatus

	.leave
	ret
SpoolSummonsSetUserPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetUserPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current user page range

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_USER_PAGE_RANGE)

PASS:		DS:DI	= SpoolSummons instance data

RETURN:		CX	= First user page
		DX	= Last last page

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetUserPageRange	method	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_GET_USER_PAGE_RANGE

	; Get the user values
	;
	tst	ds:[di].SSI_pageExcl		; all or select
	je	SpoolSummonsGetPageRange	; all - so get entire range
	mov	cx, ds:[di].SSI_firstUserPage
	mov	dx, ds:[di].SSI_lastUserPage
	ret
SpoolSummonsGetUserPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetPrintAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the possible print attributes

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_SET_PRINT_ATTRS)

PASS: 		DS:*SI	= SpoolSummonsClass instance data
		DS:DI	= SpoolSummonsClass specific instance data
		CX	= PrintControlAttrs

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/9/90		Initial version
	Don	8/21/90		Added no form-feed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetPrintAttrs	method	SpoolSummonsClass,
					MSG_SPOOL_SUMMONS_SET_PRINT_ATTRS
	.enter

	; Store the new attributes, then reset the list entries
	;
	mov	ds:[di].SSI_printAttrs, cx	; store the attributes
	and	ds:[di].SSI_spoolOptions, not (mask SO_FORCE_ROT)
	test	cx, mask PCA_FORCE_ROTATION	; do we want rotated output ?
	jz	resetPrintModes
	or	ds:[di].SSI_spoolOptions, mask SO_FORCE_ROT
resetPrintModes:
	mov	cl, ds:[di].SSI_printerAttrs	; printer attributes => CL
	call	InitPrinterModes		; initialize the printer modes
	call	SSSetUIElementsUsableOrNotUsable

	.leave
	ret
SpoolSummonsSetPrintAttrs	endp

SSSetUIElementsUsableOrNotUsable	proc	near
	class	SpoolSummonsClass
	uses	ax, bx, di, si
	.enter

	; A little set-up work
	;
	mov	di, ds:[si]
	add	di, ds:[di].SpoolSummons_offset
	mov	bx, ds:[di].SSI_printAttrs
	and	bx, ds:[di].SSI_driverAttrs

	; Are the printer controls available ??
	;
	mov	ax, mask PCA_NO_PRINTER_CONTROLS
	xor	bx, ax				; flip bit's current state,
						; since meaning of field is
						; opposite of other UI settings
	mov	si, offset PrintUI:PrinterGroup
	call	SetUsableOrNotUsableObject

	; Are the quality controls available ??
	;
	mov	ax, mask PCA_QUALITY_CONTROLS
	mov	si, offset PrintUI:OutputGroup	; object => *DS:SI
	call	SetUsableOrNotUsableObject

	; Are the page controls available ??
	;
	mov	ax, mask PCA_PAGE_CONTROLS
	mov	si, offset PrintUI:PageGroup	; object => *DS:SI
	call	SetUsableOrNotUsableObject

	; Are the copy control available ??
	;
	mov	ax, mask PCA_COPY_CONTROLS
	mov	si, offset PrintUI:CopyGroup	; object => *DS:SI
	call	SetUsableOrNotUsableObject

	; Should the document options even be displayed ??
	;
	and	bx, (mask PCA_QUALITY_CONTROLS or \
		     mask PCA_PAGE_CONTROLS or \
		     mask PCA_COPY_CONTROLS)
	mov	ax, 1
	mov	bx, ax
	jnz	setDocOptionsStatus		; if non-zero, then jump
	clr	bx				; else, flags are 0
setDocOptionsStatus:
	mov	si, offset PrintUI:DocumentGroup ; object => *DS:SI
	call	SetUsableOrNotUsableObject
	
	.leave
	ret
SSSetUIElementsUsableOrNotUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPrintMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current user print mode

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_PRINT_MODE)

PASS:		DS:*SI	= SpoolSummons instance data

RETURN:		CL	= PrinterMode selected

DESTROYED:	AX, BX, CH, DX, BP, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

printModeMap	label	byte
	PrinterMode	PM_GRAPHICS_HI_RES
	PrinterMode	PM_GRAPHICS_MED_RES
	PrinterMode	PM_GRAPHICS_LOW_RES
	byte		0xff
	PrinterMode	PM_TEXT_NLQ
	byte		0xff
	PrinterMode	PM_TEXT_DRAFT
	byte		0xff

SpoolSummonsGetPrintMode	method	SpoolSummonsClass, \
					MSG_SPOOL_SUMMONS_GET_PRINT_MODE
	.enter

	; Get the print output type, and the quality level. If there is
	; no exclusive for the quality level, this means things haven't been
	; initialized yet, so simply return 0 (PM_GRAPHICS_HI_RES)
	;
	mov	si, offset PrintUI:OutputTypeChoices
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjCallInstanceNoLock		; ListEntryState => AL
	mov	bl, al				; move mask => BL
	shl	bl, 1
	shl	bl, 1				; ensure it's in the 4's place
	mov	si, offset PrintUI:OutputQualityChoices
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock		; returns 0, 1, or 2
	cmp	ax, GIGS_NONE			; or -1 if no exclusive!
	jne	continue			; if OK, continue
	clr	al				; else assume nothing
continue:
	or	bl, al				; map mode => BL
	clr	bh
	mov	cl, cs:[printModeMap][bx]	; print mode > CL
EC <	cmp	cl, PrinterMode		; too big		>
EC <	ERROR_A	SPOOL_SUMMONS_GET_PRINT_MODE_INVALID_MODE	>

	.leave
	ret
SpoolSummonsGetPrintMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetDefaultPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the defualt printer, used whenver info is re-loaded

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_SET_DEFAULT_PRINTER)
	
PASS:		DS:DI	= SpoolSummonsClass specific instance data
		CX	= Default printer number

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetDefaultPrinter	method	SpoolSummonsClass, \
				MSG_SPOOL_SUMMONS_SET_DEFAULT_PRINTER
	.enter

	mov	ds:[di].SSI_appDefPrinter, cx	; store the default printer #

	.leave
	ret
SpoolSummonsSetDefaultPrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolsummonsPrintingToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call from PrintControl object as to whether or not we are
		printing to a file

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_PRINTING_TO_FILE)
	
PASS:		DS:DI	= SpoolSummonsClass specific instance data

RETURN:		AX	= 0 if not printing to a file
			= 1 if printing to a file

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolsummonsPrintingToFile	method	SpoolSummonsClass, \
					MSG_SPOOL_SUMMONS_PRINTING_TO_FILE
	uses	cx
	.enter

	mov	al, ds:[di].SSI_flags
	and	al, mask SSF_PRINTING_TO_FILE
	mov	cl, offset SSF_PRINTING_TO_FILE
	shr	al, cl
	cbw

	.leave
	ret
SpoolsummonsPrintingToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetPrinterMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the printer margins for the current printer

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_PRINTER_MARGINS)
	
PASS:		DS:*SI	= SpoolSummonsClass instance data
		DS:DI	= SpoolSummonsClass specific instance data

RETURN:		AX	= Left margin
		CX	= Top margin
		DX	= Right margin
		BP	= Bottom margin
		Carry	= Set if error

DESTROYED:	BX, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetPrinterMargins	method dynamic SpoolSummonsClass, \
				MSG_SPOOL_SUMMONS_GET_PRINTER_MARGINS
	driverStrategy	local	fptr.far
	.enter

	; First load the print driver (should already be loaded)
	;
	call	SSLoadDriver
	jc	exit				; if error, abort
	push	bx				; save driver handle

	; Now go load the options, placing them in the JobParameters structure
	; we're going to allocate at the end of the PState, which is where
	; those funky printer drivers like it.
	;
	mov_tr	bx, ax				; PState handle => BX
	mov	ax, (size PState) + (size JobParameters)	
	mov	ch, mask HAF_LOCK		; lock the thing
	call	MemReAlloc			; resize PState block
	mov	es, ax				; PState/JobParameters => ES
	mov	si, (size PState)		; JobParameters => ES:SI
	mov	ax, bx				; JobParameters handle => AX
	mov	cx, ds:[di].PIS_mainUI.handle
	mov	dx, ds:[di].PIS_optionsUI.handle
	mov	di, DR_PRINT_EVAL_UI
	call	ss:[driverStrategy]		; go load the options
	jnc	getMargins
	jcxz	getMargins
	xchg	bx, cx				; ignore returned error
	call	MemFree				; ...and free its memory
	mov	bx, cx

	; Finally, ask for the printer margins
getMargins:
	mov	di, DR_PRINT_GET_MARGINS
	call	ss:[driverStrategy]		; margins => AX, SI, CX, DX
	call	MemFree				; free PState/JobParameters
	pop	bx				; restore driver handle
	call	SpoolFreeDriver			; free the driver
	clc
exit:
	.leave

	; Return the margins in the correct registers
	;
	mov	bp, dx				; bottom => BP
	mov	dx, cx				; right => DX
	mov	cx, si				; top => CX
if _HACK_20_FAX
	;
	; If this is nike, and we are faxing then the print driver is
	; going to return 0 for the left and right margin.  However,
	; we want a minimum 1/4 inch margin so we are going to hack it
	; in here.
	;
	; We also want a 1/2 inch top margin if we're faxing, and the
	; way to check that is if both left and right margins are 0s.
	; 5/6/95 - ptrinh
	;

	tst	ax
	jnz	notFaxing
	tst	dx
	jnz	notFaxing
	mov	ax, 72/4			; left
	mov	dx, 72/4			; right
	mov	cx, 72/2			; top
notFaxing:

endif	
	
	ret
SpoolSummonsGetPrinterMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsPrependAppendPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow a print driver to prepend or append a page

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_PREPEND_APPEND_PAGE)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance
		CX	= PrintEscCode
		DX	= GString handle to draw to

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsPrependAppendPage	method dynamic	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_PREPEND_APPEND_PAGE
	driverStrategy	local	fptr.far
	.enter

	; First load the print driver (should already be loaded)
	;
	push	cx, dx
	call	SSLoadDriver
	xchg	ax, bx
	pop	si, dx
	jc	exit
	push	ax				; save driver handle

	; Call the printer driver
	;
	mov_tr	ax, dx
	mov	cx, ds:[di].PIS_mainUI.handle
	mov	dx, dS:[di].PIS_optionsUI.handle
	mov	di, si				; PrintEscCode => DI
	call	ss:[driverStrategy]		; margins => AX, SI, CX, DX
	
	; Free the driver
	;
	call	MemFree				; free PState/JobParameters
	pop	bx				; restore driver handle
	call	SpoolFreeDriver			; free the driver
exit:
	.leave
	ret
SpoolSummonsPrependAppendPage	endm

SSLoadDriver	proc	near
	class	SpoolSummonsClass
	driverStrategy	local	fptr.far
	.enter	inherit

	mov	cx, ds:[di].SSI_currentPrinter
	call	AccessPrinterInfoStruct		; PrinterInfoStruct => DS:DI
	mov	dx, cx				; printer # => DX
	call	SpoolLoadDriver			; data => AX, BX, CX, DX
	jc	exit				; if error, abort
	mov	driverStrategy.segment, dx
	mov	driverStrategy.offset, cx
exit:
	.leave
	ret
SSLoadDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsSetDriverType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the driver type to be displayed

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_SET_DRIVER_TYPE)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance
		CL	= PrinterDriverType

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		* Save PrinterDriverType
		* Set the monikers for objects
		* Set status of UI objects that both application and
		  driver have control over
		* Set status of UI objects that only the driver has
		  control over		
		* Reset the state of UI objects (as needed)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 2/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsSetDriverType	method dynamic	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_SET_DRIVER_TYPE
		.enter

		; If we have a new driver type, then mark that the printer
		; list needs to be re-initialized.
		;
		cmp	ds:[di].SSI_driverType, cl
		je	updateMonikers
		mov	ds:[di].SSI_driverType, cl
		or	ds:[di].SSI_flags, mask SSF_RELOAD_PRINTER_LIST or \
					   mask SSF_UPDATE_MONIKERS

		; Update the monikers for various objects
updateMonikers:
		test	ds:[di].SSI_flags, mask SSF_UPDATE_MONIKERS
		jz	done
		andnf	ds:[di].SSI_flags, not (mask SSF_UPDATE_MONIKERS)
		call	CalcUIElementsAvailable
		mov	ds:[di].SSI_driverAttrs, bx
		push	ax			; usable or not usable status
		push	si
		call	CalcMonikersToUse
		clr	bx
monikerLoop:
		push	cx
		mov	si, cs:[objectMonikerList][bx]	; object's OD => *DS:SI
		cmp	si, offset PrintDialogBox
		je	checkSummonsMonikerAdjust
setMoniker:
		mov	cx, cs:[di][bx]		; moniker chunk => CX
		call	SSUseVisMoniker

monikerSetDone:
		pop	cx
		add	bx, 2			; go to next object & moniker
		loop	monikerLoop

		; Set some common UI elements usable or not
		; (those that the application can affect)
		;
		pop	si
		call	SSSetUIElementsUsableOrNotUsable

		; Set the correct help context
		;
		call	SSSetHelpContext

		; Add or remove certain objects that only drivers can affect
		;
		pop	ax			; MSG_GEN_SET_[NOT_]USABLE => AX
		clr	bx
		mov	cx, OBJECT_USABLE_COUNT
objectLoop:
		push	ax, cx
		mov	si, cs:[objectUsableList][bx]
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		pop	ax, cx
		add	bx, 2			; progress to next object
		loop	objectLoop

		; Set the quality selection to something bogus, so that
		; the complete "default quality logic" will be put into play
		;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
;;;		mov	cx, PrintQualityEnum	; bogus quality
		mov	cx, GIGS_NONE		
		clr	dx			; determinate
		mov	si, offset PrintUI:OutputQualityChoices
		call	ObjCallInstanceNoLock
done:
		.leave
		ret

checkSummonsMonikerAdjust:
	;
	; Only adjust the moniker for the summons itself if it's a dialog; if
	; it's part of a larger whole, we want no moniker at all.
	; 
		mov	bp, ds:[si]
		add	bp, ds:[bp].GenInteraction_offset
		cmp	ds:[bp].GII_visibility, GIV_DIALOG
		je	setMoniker
		jmp	monikerSetDone
SpoolSummonsSetDriverType	endm

; The list of objects that are set not usable when faxing,
; but are set to again be usable when printing.

objectUsableList	label	lptr
		lptr	PrinterChangeBox
if	not _NO_MEDIUM_QUALITY	
		lptr	MediumEntry
endif
if	_NO_FAX_DRIVER_CONTROLS
		lptr	PrinterUpperGroup
endif
		lptr	PrinterOptions

OBJECT_USABLE_COUNT	equ	($ - (offset objectUsableList)) / 2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSummonsGetDriverType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the driver type that is currently displayed

CALLED BY:	GLOBAL (MSG_SPOOL_SUMMONS_GET_DRIVER_TYPE)

PASS:		*DS:SI	= SpoolSummonsClass object
		DS:DI	= SpoolSummonsClassInstance

RETURN:		CL	= PrinterDriverType


DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSummonsGetDriverType	method dynamic	SpoolSummonsClass,
				MSG_SPOOL_SUMMONS_GET_DRIVER_TYPE
		.enter

		mov	cl, ds:[di].SSI_driverType

		.leave
		ret
SpoolSummonsGetDriverType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcUIElementsAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate which UI elements should be available for the
		user to muck with

CALLED BY:	SpoolSummonsSetDriverType

PASS:		CL	= PrinterDriverType

RETURN:		BX	= PrintControlAttrs
		AX	= Message to send to objectUsableList

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 3/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcUIElementsAvailable	proc	near
		.enter

		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	bx, not (mask PCA_COPY_CONTROLS)
		cmp	cl, PDT_FACSIMILE
		je	done
		mov	ax, MSG_GEN_SET_USABLE
		mov	bx, -1
done:
		.leave
		ret
CalcUIElementsAvailable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcMonikersToUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate which monikers should be displayed.

CALLED BY:	SpoolSummonsSetDriverType

PASS:		ES	= DGroup
		CL	= PrinterDriverType

RETURN:		DI	= Moniker list
		CX	= # of items in list

DESTROYED:	SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 3/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcMonikersToUse	proc	near
		.enter

		mov	di, offset faxMonikers
		mov	si, offset faxMonikersShort
		cmp	cl, PDT_FACSIMILE
		je	checkSimpleUI
		mov	di, offset printerMonikers
		mov	si, offset printerMonikersShort
checkSimpleUI:
		test	es:[uiOptions], mask SUIO_SIMPLE
		jz	done
		mov	di, si			; if simple, use short monikers
done:
		mov	cx, OBJECT_MONIKER_COUNT
		.leave
		ret
CalcMonikersToUse	endp

objectMonikerList	lptr \
		PrintDialogBox,
		PrinterGroup,
		PrinterUpperGroup,
		OutputQualityChoices,
		HighEntry,
		LowEntry,
		PageControl,
		PrintOKTrigger

OBJECT_MONIKER_COUNT	equ	length objectMonikerList

if	_NO_PRINTER_LIST_MONIKER
PrinterUpperGroupMonikerPrint	= 0
endif

printerMonikers	lptr \
		PrintDialogBoxMonikerPrint,
		PrinterGroupMonikerPrint,
		PrinterUpperGroupMonikerPrint,
		OutputQualityChoicesMonikerPrint,
		HighEntryMonikerPrint,
		LowEntryMonikerPrint,
		PageControlMonikerPrint,
		PrintOKTriggerMonikerPrint

CheckHack	<OBJECT_MONIKER_COUNT eq length printerMonikers>

printerMonikersShort	lptr \
		PrintDialogBoxMonikerPrint,
		PrinterGroupMonikerPrint,
		PrinterUpperGroupMonikerPrint,
		OutputQualityChoicesMonikerShort,
		HighEntryMonikerPrint,
		LowEntryMonikerShort,
		PageControlMonikerShort,
		PrintOKTriggerMonikerPrint

CheckHack	<OBJECT_MONIKER_COUNT eq length printerMonikersShort>

faxMonikers	lptr \
		PrintDialogBoxMonikerFax,
		PrinterGroupMonikerFax,
		PrinterUpperGroupMonikerFax,
		OutputQualityChoicesMonikerFax,
		HighEntryMonikerFax,
		LowEntryMonikerFax,
		PageControlMonikerFax,
		PrintOKTriggerMonikerFax

CheckHack	<OBJECT_MONIKER_COUNT eq length faxMonikers>

faxMonikersShort	lptr \
		PrintDialogBoxMonikerFax,
		PrinterGroupMonikerFax,
		PrinterUpperGroupMonikerFax,
		OutputQualityChoicesMonikerShort,
		HighEntryMonikerFax,
		LowEntryMonikerFax,
		PageControlMonikerShort,
		PrintOKTriggerMonikerFax

CheckHack	<OBJECT_MONIKER_COUNT eq length faxMonikersShort>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSSetHelpContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the help context appropriate for the SpoolSummons

CALLED BY:	SpoolSummonsSetDriverType

PASS:		*DS:SI	= SpoolSummonsClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CONTEXT_STACK_SIZE	equ	32

SSSetHelpContext	proc	near
		class	SpoolSummonsClass
		.enter
	
		; Find the correct context string offset
		;
		mov	di, ds:[si]
		add	di, ds:[di].SpoolSummons_offset
		clr	bx
		cmp	ds:[di].SSI_driverType, PDT_ALL
		je	copyContext
		mov	bl, ds:[di].SSI_driverType
		shl	bx, 1

		; Copy the context string to the stack
copyContext:
		sub	sp, CONTEXT_STACK_SIZE
		segmov	es, ss
		mov	di, sp			; buffer => ES:DI
		mov	ax, di			; remember start of buffer
		push	ds, si
		segmov	ds, cs
		mov	si, cs:[helpContextStrings][bx]
		mov	cx, cs:[helpContextLengths][bx]
		rep	movsb
		pop	ds, si

		; Create the AddVarDataParams structure
		;
		mov	dx, size AddVarDataParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].AVDP_data.segment, ss
		mov	ss:[bp].AVDP_data.offset, ax
		mov	ax, cs:[helpContextLengths][bx]
		mov	ss:[bp].AVDP_dataSize, ax
		mov	ss:[bp].AVDP_dataType, ATTR_GEN_HELP_CONTEXT

		; Tell the object to modify its vardata
		;
		mov	ax, MSG_META_ADD_VAR_DATA
		call	ObjCallInstanceNoLock
		add	sp, (size AddVarDataParams) + CONTEXT_STACK_SIZE

		.leave
		ret
SSSetHelpContext	endp

helpContextStrings	nptr \
	helpContextPrinter,
	helpContextPrinter,
	helpContextFacsimile,
	helpContextPrinter,
	helpContextPrinter

helpContextLengths	word \
	length helpContextPrinter,
	length helpContextPrinter,
	length helpContextFacsimile,
	length helpContextPrinter,
	length helpContextPrinter
			
SBCS <	helpContextPrinter	char	"dbPrint", 0			>
SBCS <	helpContextFacsimile	char	"dbFax", 0			>
DBCS <	helpContextPrinter	wchar	"dbPrint", 0			>
DBCS <	helpContextFacsimile	wchar	"dbFax", 0			>


SpoolSummonsCode	ends
