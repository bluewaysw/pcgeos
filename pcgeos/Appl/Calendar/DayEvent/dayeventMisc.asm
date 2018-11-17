COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayEvent
FILE:		dayeventMisc.asm

AUTHOR:		Don Reeves, April 4, 1991

ROUTINES:
	Name			Description
	----			-----------
	MyTextInitialize	Initialization routine for MyTextClass objects
	MyTextVisClose		Clean up a MyText object before visual closing

	DayEventVisClose	Clean up a DayEvent object before closing
	DayEventSetHandles	Psuedo-initialization for a DayEvent object

	PrintEventMadeDirty	PrintEvent object intercepting TEXT_MADE_DIRTY
	PrintEventSetFont&Size	Exactly as advertised for PrintEvent objects
	PrintEventPrintEnable	Routine to allow printing for PRintEvent objs

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/05/89	Initial revision (from dayevent.asm)
	
DESCRIPTION:
	Defines the "DayEvent" miscellaneous procedures
		
	$Id: dayeventMisc.asm,v 1.1 97/04/04 14:47:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                 MyTextInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Performs the initialization on MyText

CALLED BY:      UI (MSG_META_INITIALIZE)

PASS:           AX      = MSG_META_INITIALIZE
                 DS:*SI  = Instance data
                 ES      = DGroup

RETURN:         Nothing

DESTROYED:      TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                 none

REVISION HISTORY:
         Name    Date            Description
         ----    ----            -----------
         Don     1/1/90          Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextInitialize        method  MyTextClass,    MSG_META_INITIALIZE
         .enter

         ; Call superclass to initialize (because I have no master class)
         ;
         mov     di, offset MyTextClass
         call    ObjCallSuperNoLock              ; call my superclass

         ; Initialize some VisText instance data
         ;
         mov     di, ds:[si]                     ; derference the handle
         add     di, ds:[di].Vis_offset          ; access the visual data
         or      ds:[di].VTI_state, mask VTS_TARGETABLE
         movdw   ds:[di].VTI_washColor, es:[eventBGColor], ax
         mov     ds:[di].VTI_lrMargin, EVENT_LR_MARGIN
         mov     ds:[di].VTI_tbMargin, EVENT_TB_MARGIN

         .leave
         ret
MyTextInitialize        endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyTextVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make certain the focus & target exclusives are released
		Also ensure the DayEvent parent is set clean (no update!)

CALLED BY:	UI (MSG_VIS_CLOSE)

PASS:		ES	= DGroup
		DS:*SI	= MyTextClass instance data

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextVisClose	method	MyTextClass,	MSG_VIS_CLOSE
	.enter

	; Tell the DayEvent to not update if dirty
	;
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED	; set myself clean...
	call	ObjCallInstanceNoLock		; send method to myself
	
	; Release the target & focus exclusives, and pass on the VIS_CLOSE
	;
	call	MetaReleaseFocusExclLow		; release focus
	call	MetaReleaseTargetExclLow	; release target
	call	VisReleaseMouse			; release the mouse, too
	mov	ax, MSG_VIS_CLOSE
	mov	di, offset MyTextClass		; ES:DI => this class
	call	ObjCallSuperNoLock		; pass on the MSG_VIS_CLOSE

	.leave
	ret
MyTextVisClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of when the DayEvent disappears

CALLED BY:	UI (MSG_VIS_CLOSE)
	
PASS:		DS:DI	= DayEventClass specific instance data
		DS:*SI	= DayEventClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventVisClose	method	DayEventClass,	MSG_VIS_CLOSE
	.enter

	; If we are selected, make sure we reset the DayPlan
	;
	test	ds:[di].DEI_actFlags, DE_SELECT	; are we selected ?
	jz	finish				; no, so do nothing
	push	si				; save my handle
	mov	ax, MSG_DP_SET_SELECT
	clr	bp				; no new selected event
	mov	si, offset DayPlanObject	; DayPlan OD => DS:SI
	call	ObjCallInstanceNoLock		; send the method
	pop	si				; restore my handle

	; Send the method onto our superclass
finish:
	call	VisReleaseMouse			; release the mouse grab
	mov	ax, MSG_VIS_CLOSE
	mov	di, offset DayEventClass
	call	ObjCallSuperNoLock

	.leave
	ret
DayEventVisClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the two text handles properly

CALLED BY:	CreateDayEventBuffer

PASS:		DS:*SI	= DayEvent instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSetHandles	method	DayEventClass, MSG_DE_SET_HANDLES
	uses	cx, dx, bp
	.enter

	; Some set-up work
	;
	mov	di, ds:[si]			; dereference handle
	mov	ax, ds:[LMBH_handle]		; get the block handle to AX
	mov	bx, di
	add	di, ds:[di].DayEvent_offset	; access my data
	add	bx, ds:[bx].Vis_offset		; access generic data
	or	ds:[bx].VI_attrs, mask VA_FULLY_ENABLED
	mov	ds:[di].DEI_block, ax
	mov	ds:[di].DEI_eventHandle, si

	; Get the first text handle (filter tabs & CR's)
	;
	mov	bx, ds:[bx].VCI_comp.CP_firstChild.chunk
	mov	ds:[di].DEI_timeHandle, bx	; save 1st child
	mov	bx, ds:[bx]			; dereference the 1st handle
	add	bx, ds:[bx].Vis_offset		; access generic data
	mov	ds:[bx].VTI_output.handle, ax
	mov	ds:[bx].VTI_output.chunk, si
	or	ds:[bx].VTI_state, mask VTS_ONE_LINE	; a one line object!
	mov	ds:[bx].VTI_maxLength, MAX_TIME_FIELD_LENGTH
	mov	ds:[bx].VTI_filters, mask VTF_NO_TABS or \
				     VTFC_NO_FILTER shl offset VTF_FILTER_CLASS

	; Get the second text handle (filter tabs)
	;
	mov	bx, ds:[bx].VI_link.chunk
	mov	ds:[di].DEI_textHandle, bx	; save second child
	mov	bx, ds:[bx]			; dereference the 2nd handle
	add	bx, ds:[bx].Vis_offset		; access generic data
	mov	ds:[bx].VTI_output.handle, ax
	mov	ds:[bx].VTI_output.chunk, si
	mov	ds:[bx].VTI_maxLength, MAX_TEXT_FIELD_LENGTH
	mov	ds:[bx].VTI_filters, mask VTF_NO_TABS or \
				     VTFC_NO_FILTER shl offset VTF_FILTER_CLASS
	.leave
	ret
DayEventSetHandles	endp

DayEventCode	ends



PrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEventMadeDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Want to ignore all dirty notifications for this event,
		as the data cannot be altered by printing.

CALLED BY:	GLOBAL (MSG_META_TEXT_USER_MODIFIED)
	
PASS:		DS:DI	= PrintEventClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEventMadeDirty	method	PrintEventClass, MSG_META_TEXT_USER_MODIFIED
	ret
PrintEventMadeDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEventSetFontAndSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the font and pointsize for each of the MyTextObjects

CALLED BY:	GLOBAL (MSG_PE_SET_FONT_AND_SIZE)
	
PASS:		DS:DI	= PrintEventClass specific instance data
		CX	= Font
		DX	= Pointsize
		BP	= PrintEventInfo
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (size VisTextSetFontIDParams) ge (size VisTextSetPointSizeParams)
	FID_AND_SIZE_PARAM_SIZE = (size VisTextSetFontIDParams)
else
	FID_AND_SIZE_PARAM_SIZE = (size VisTextSetPointSizeParams)
endif

PrintEventSetFontAndSize method	PrintEventClass, MSG_PE_SET_FONT_AND_SIZE
	.enter

	; Some set-up work
	;
	mov	ds:[di].PEI_printInfo, bp
	mov	bx, ds:[di].DEI_textHandle
	mov	si, ds:[di].DEI_timeHandle
	sub	sp, FID_AND_SIZE_PARAM_SIZE	; allocate stack frame
	mov	bp, sp				; structure => SS:BP
	push	dx				; save the point size
	clrdw	ss:[bp].VTR_start
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END

	; Set the font for both objects...
	;
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	mov	ss:[bp].VTSFIDP_fontID, cx	; store the FontID enum
	call	ObjCallInstanceNoLock
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	xchg	bx, si				; text object handle => SI
	call	ObjCallInstanceNoLock

	; Set the pointsize for both objects
	;
	pop	ss:[bp].VTSPSP_pointSize.WWF_int
	clr	ss:[bp].VTSPSP_pointSize.WWF_frac
	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	call	ObjCallInstanceNoLock
	mov	si, bx				; time object handle => SI
	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	call	ObjCallInstanceNoLock
		
	; Hack - force the print event's time text object to be multiple lines
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; access the visual data
	and	ds:[di].VTI_state, not (mask VTS_ONE_LINE)
	add	sp, FID_AND_SIZE_PARAM_SIZE	; clean up the stack
	
	.leave
	ret
PrintEventSetFontAndSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEventPrintEnable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get this object ready for printing

CALLED BY:	DayPlanPrintOneEvent (MSG_PE_PRINT_ENABLE)
	
PASS:		DS:DI	= PrintEventClass specific instance data
		DS:BX	= PrintEventClass instance data

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEventPrintEnable	method	PrintEventClass, MSG_PE_PRINT_ENABLE
	uses	cx, dx, bp
	.enter

	; Get everything ready for printing
	;
	add	bx, ds:[bx].Vis_offset		; access my visual data
	mov	ds:[bx].VI_optFlags, 0		; clear these flags
	mov	bx, ds:[di].DEI_textHandle
	mov	si, ds:[di].DEI_timeHandle
	call	PrintEventMakeGeometryValid	; do time object
	mov	si, bx				; chunk handle => SI
	call	PrintEventMakeGeometryValid	; now do text object

	.leave
	ret
PrintEventPrintEnable	endp

PrintEventMakeGeometryValid	proc	near
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Vis_offset		; access the visual data
	mov	ds:[di].VI_optFlags, 0		; clear all of the flags
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID ; method to send
	call	ObjCallInstanceNoLock		; notify the text object
	ret
PrintEventMakeGeometryValid	endp

PrintCode	ends
