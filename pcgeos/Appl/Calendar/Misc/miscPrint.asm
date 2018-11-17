COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Misc - Printing Mechanisms
FILE:		miscPrint.asm

AUTHOR:		Don Reeves, February 25, 1990

ROUTINES:
	Name			Description
	----			-----------
    GLB	MyPrintSetOutputType	MSG_MY_PRINT_SET_OUTPUT_TYPE handler
    GLB	MyPrintSetIncludeEvents	MSG_MY_PRINT_SET_INCLUDE_EVENTS handler
    GLB	MyPrintGetPrintInfo	MSG_MY_PRINT_GET_INFO handler

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial revision

DESCRIPTION:
	Contains all the code dealing with print UI.
		
	$Id: miscPrint.asm,v 1.1 97/04/04 14:48:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment
	MyPrintClass
idata		ends


PrintCode 	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyPrintUpdateDisplayData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the data displayed in the print options DB

CALLED BY:	GLOBAL (MSG_MY_PRINT_UPDATE_DISPLAY_DATA)

PASS:		*DS:SI	= MyPrintClass object
		DS:DI	= MyPrintClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyPrintUpdateDisplayData	method dynamic	MyPrintClass,
					MSG_MY_PRINT_UPDATE_DISPLAY_DATA
		.enter

		; If we've already initialized the year/month, don't
		; do it again. Actually, I don't see a good reason for
		; doing this, and there is a good reason not to do
		; this - so that whenever we print the current month
		; and year will be displayed. So, I've commented it out.
		;   -Don 4/29/00
		;
;;; 		test	ds:[di].MPI_attrs, mask MPA_INITIALIZED
;;; 		jnz	eventTitle
;;; 		or	ds:[di].MPI_attrs, mask MPA_INITIALIZED

		; Get the current month & day. We previously
		; would retrieve the selection range and use
		; the start month/year, but it seems that we can
		; do better and show the contents of the YearView. 
		;
		mov	ax, MSG_YEAR_GET_MONTH_AND_YEAR
		GetResourceHandleNS	YearObject, bx
		mov	si, offset YearObject
		call	ObjMessage_print_call

		; Update the month & day spinners
		;
		push	dx
		mov	cl, ch
		clr	ch
		mov	si, offset DataMonth
		call	PrintSetRangeValue
		pop	cx
		mov	si, offset DataYear
		call	PrintSetRangeValue

		; Update the event text
eventTitle::	
		mov	ax, MSG_DP_SET_TITLE
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset DataEvents
		call	ObjMessage_print_send

		.leave
		ret
MyPrintUpdateDisplayData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyPrintSetOutputType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the type of print output the user desires.

CALLED BY:	UI (MSG_MY_PRINT_SET_OUTPUT_TYPE)

PASS:		ES	= DGroup
		DS:DI	= MyPrintClass specific instance data
		CL	= MyPrintOutputType

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Sets things enabled/disabled as necessary
		Set the output of printing correctly

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/26/90		Initial version
	Don	5/11/90		Removed delayed stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyPrintSetOutputType	method	dynamic	MyPrintClass, 
					MSG_MY_PRINT_SET_OUTPUT_TYPE
		.enter

		; Store the new output type
		;
		and	ds:[di].MPI_attrs, not (mask MPA_OUTPUT_TYPE)
		or	ds:[di].MPI_attrs, cl	; set the new output type
		mov	bl, cl			; MyPrintOutputType => BL

		; Enable or disable the Include Events checkbox
		;
		mov	ax, MSG_GEN_SET_ENABLED
		cmp	bl, MPOT_GR_MONTH
		je	setStatus
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setStatus:
		mov	si, offset IncludeEventsEntry
		call	ObjCallInstanceNoLock_VUM

		; Now determine which data controls are displayed
		;
		mov	ax, MSG_GEN_SET_USABLE
		mov	bp, MSG_GEN_SET_NOT_USABLE
		cmp	bl, MPOT_EVENTS
		je	setDataEvents
		xchg	ax, bp
setDataEvents:
		push	bp
		mov	si, offset DataEvents
		call	ObjCallInstanceNoLock_VUM
		pop	ax
		mov	si, offset DataMonthYear
		call	ObjCallInstanceNoLock_VUM
		
		mov	ax, MSG_GEN_SET_USABLE
		cmp	bl, MPOT_GR_MONTH
		je	setDataMonth
		mov	ax, MSG_GEN_SET_NOT_USABLE
setDataMonth:
		mov	si, offset DataMonth
		call	ObjCallInstanceNoLock_VUM

		.leave
		ret
MyPrintSetOutputType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyPrintSetIncludeEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the collate mode on/off

CALLED BY:	UI (MSG_MY_PRINT_SET_INCLUDE_EVENTS)

PASS:		DS:DI	= MyPrintClass specific instance data
		CL	= mask MPA_INCLUDE_EVENTS or 0
		
RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/25/90		Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyPrintSetIncludeEvents	method	dynamic	MyPrintClass,
				MSG_MY_PRINT_SET_INCLUDE_EVENTS

		; Set or clear the flag
		;
		and	ds:[di].MPI_attrs, not (mask MPA_INCLUDE_EVENTS)
		or	ds:[di].MPI_attrs, cl
		ret
MyPrintSetIncludeEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyPrintStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start printing, please

CALLED BY:	GLOBAL (MSG_PRINT_START_PRINTING)

PASS:		*DS:SI	= MyPrintClass object
		DS:DI	= MyPrintClassInstance
		CX:DX	= OD of PrintControl object
		BP	= GState to print to

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		We want, if at all possible, for the document to fit.
		So try doing things with the margins oriented in
		either direction.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyPrintStartPrinting	method dynamic	MyPrintClass, MSG_PRINT_START_PRINTING
		.enter

		; Set the number of pages to 1 (the default)
		;
		push	cx, dx, bp		; save message data
		push	si			; save my chunk handle
		mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
		movdw	bxsi, cxdx		
		mov	cx, 1
		mov	dx, cx
		call	ObjMessage_print_send

		; First set the document size
		;
		sub	sp, size PageSizeReport
		mov	bp, sp			
		push	bx, si			; save OD of PrintControl
		mov	dx, ss			; PageSizeReport => DX:BP
		mov	ax, MSG_PZC_GET_PAGE_SIZE
		GetResourceHandleNS	CalendarPageSetup, bx
		mov	si, offset CalendarPageSetup
		call	ObjMessage_print_call
		mov	ax, ss:[bp].PSR_width.low
		mov	es:[printWidth], ax
		mov	ax, ss:[bp].PSR_height.low
		mov	es:[printHeight], ax

		; Get the printer's margins
		;
		mov	ax, MSG_PRINT_CONTROL_GET_PRINTER_MARGINS
		pop	bx, si			; PrintControl OD => BX:SI
		mov	dx, FALSE		; no reason to set the margins
		call	ObjMessage_print_call	; margins => AX, CX, DX, BP
		mov	di, bp
		mov	bp, sp
		mov	ss:[bp].PSR_margins.PCMP_left, cx
		mov	ss:[bp].PSR_margins.PCMP_top, ax
		mov	ss:[bp].PSR_margins.PCMP_right, di
		mov	ss:[bp].PSR_margins.PCMP_bottom, dx

		; Set the document info, and see if it will fit. If it
		; doesn't then assume the other way.
		;
		push	ax, cx, dx, di
		call	MyPrintSetSizeCheckFit
		tst	ax
		pop	ax, cx, dx, di
		jnz	thingsFitWell
		mov	ss:[bp].PSR_margins.PCMP_left, ax
		mov	ss:[bp].PSR_margins.PCMP_top, cx
		mov	ss:[bp].PSR_margins.PCMP_right, dx
		mov	ss:[bp].PSR_margins.PCMP_bottom, di
		call	MyPrintSetSizeCheckFit

		; Now store the printable area & top/left margins
thingsFitWell:
		mov	ax, ss:[bp].PSR_margins.PCMP_left
		mov	cx, ss:[bp].PSR_margins.PCMP_top
		mov	dx, ss:[bp].PSR_margins.PCMP_right
		mov	bp, ss:[bp].PSR_margins.PCMP_bottom
		add	sp, size PageSizeReport
		mov	es:[printMarginLeft], ax
		mov	es:[printMarginTop], cx
		add	ax, dx			; horizontal margins => AX
		add	bp, cx			; vertical margins => BP
		sub	es:[printWidth], ax
		sub	es:[printHeight], bp
		dec	es:[printHeight]	; month can be one pixel too
						; long, so add in margin here

		; Finally, send the print message off to the proper object
		;
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].MyPrint_offset
		GetResourceHandleNS	YearObject, bx
		mov	si, offset YearObject
		test	ds:[di].MPI_attrs, MPOT_EVENTS
		jz	startPrinting
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
startPrinting:
		mov	ax, MSG_PRINT_START_PRINTING
		pop	cx, dx, bp
		call	ObjMessage_print_send

		.leave
		ret
MyPrintStartPrinting	endm

MyPrintSetSizeCheckFit	proc	near
		uses	bp
		.enter

		; First set the size
		;
		mov	dx, ss
		mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE_INFO
		call	ObjMessage_print_call

		; Now see if things fit
		;
		mov	ax, MSG_PRINT_CONTROL_CHECK_IF_DOC_WILL_FIT
		clr	cx			; don't display warning
		call	ObjMessage_print_call

		.leave
		ret
MyPrintSetSizeCheckFit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyPrintGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns all of the current print data

CALLED BY:	GLOBAL (MSG_MY_PRINT_GET_INFO)

PASS:		DS:DI	= MyPrintClass specific instance data
		
RETURN:		CX	= FontID to use for printing
		DL	= MyPrintAttrs
		DH	= Month
		BP	= Year

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyPrintGetInfo	method	dynamic	MyPrintClass, 	MSG_MY_PRINT_GET_INFO
		.enter

		; Return the crucial information
		;
		mov	bl, ds:[di].MPI_attrs
		mov	di, ds:[di].MPI_fontID
		call	GetOverrideFontID

		; Grab the month & the year
		;
		mov	si, offset DataYear
		call	PrintGetRangeValue
		push	dx			; save the year
		mov	si, offset DataMonth
		call	PrintGetRangeValue
		mov	dh, dl			; month => DH
		mov	dl, bl			; MyPrintAttrs => DL
		mov	cx, di			; FontID => CX
		pop	bp			; year => BP

		.leave
		ret
MyPrintGetInfo	endp

GetOverrideFontID	proc	near
		uses	ax, cx, dx, si, ds
		.enter

		; Look in the .INI file for a font override
		;
		segmov	ds, cs, cx
		mov	si, offset fontIDOverrideCategory
		mov	dx, offset fontIDOverrideKey
		mov_tr	ax, di			; default => AX
		call	InitFileReadInteger
		mov_tr	di, ax			; new fontID (maybe) => DI

		.leave
		ret
GetOverrideFontID	endp

fontIDOverrideCategory	char	"GeoPlanner", 0
fontIDOverrideKey	char	"printFontID", 0

PrintSetRangeValue	proc	near
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		clr	bp			; determinate
		GOTO	ObjCallInstanceNoLock_print
PrintSetRangeValue	endp

PrintGetRangeValue	proc	near
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		GOTO	ObjCallInstanceNoLock_print
PrintGetRangeValue	endp

ObjCallInstanceNoLock_VUM	proc	near
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		FALL_THRU	ObjCallInstanceNoLock_print
ObjCallInstanceNoLock_VUM	endp

ObjCallInstanceNoLock_print	proc	near
		call	ObjCallInstanceNoLock
		ret
ObjCallInstanceNoLock_print	endp

ObjMessage_print_send	proc	near
		mov	di, mask MF_FIXUP_DS
		GOTO	ObjMessage_print
ObjMessage_print_send	endp

ObjMessage_print_call	proc	near
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
		FALL_THRU	ObjMessage_print
ObjMessage_print_call	endp

ObjMessage_print	proc	near
		call	ObjMessage
		ret
ObjMessage_print	endp

PrintCode ends
