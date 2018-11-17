COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS J
MODULE:		JCalendar/Holiday
FILE:		holidaySetting.asm

AUTHOR:		TORU TERAUCHI, JUL 28, 1993

ROUTINES:
	NAME			DESCRIPTION
	----			-----------
  InitCode:
	SetHConstruct		MSG_JC_SHIC_CONSTRUCT handler
	SetHDestruct		MSG_JC_SHIC_DESTRUCT handler
	SetHIntInit		MSG_GEN_INTERACTION_INITIAT handler

  DataLoadSaveCode:
	SetHLoadData		MSG_JC_SHIC_LOADDATA handler
	SetHSaveData		MSG_JC_SHIC_SAVEDATA handler

  UICode:
	SetHReset		MSG_JC_SHIC_RESET handler
	SetHClose		MSG_JC_SHIC_CLOSE handler
	SetHRpeatHApply		MSG_JC_SHIC_RHL_APPLY hander
	SetHGetUsable		MSG_JC_SHIC_GET_USABLE handler

  SetHolidayCode:
	SetHGetHDate		MSG_JC_SHIC_GETHOLIDAYDATE handler
	SetHSetRange		MSG_JC_SHIC_SET_RANGE handler
	SetHReadData		Read data from text file
	SetHWriteData		Write data to text file
	SetHSetResetH		Set / Reset Holiday
	SetHSetYearObjSelect	Set the current selection to the YearObject

  DebugCode:
	SetHDataDump		MSG_JC_SHIC_DATA_DUMP handler

	
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	Tera	6/16/93		Initial revision
	Tera	7/25/93		add SetHWriteData, change SetHSaveData


DESCRIPTION:
	Implements the setting of holiday.
		

	$Id: holidaySetting.asm,v 1.1 97/04/04 14:49:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HolidayCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHConstruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIClass constructer

CALLED BY:	CalendarAttach ( CalendarAppClass )
PASS:		di:di	= SetHolidayInteractionClass specific instance data
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This should be called only once.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHConstruct	method	SetHolidayInteractionClass, MSG_JC_SHIC_CONSTRUCT
	uses	ax, bx, cx, dx, es, ds, di, si
	.enter

	; Allocate the LMem block
	;
	mov	ax, size LMemBlockHeader	; bytes to allocate
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK	; flag
	call	MemAlloc
EC <	ERROR_C	-1				; not enough memory	>

	segmov	es, ds					; save ds -> es
	mov	es:[di].SHIC_holidayMemHandle, bx	; save handle
	push	di					; save di

	; Initialize the heap
	;
	mov	ds, ax				; segment pointer for the heap
	mov	ax, LMEM_TYPE_GENERAL		; a general type of heap
						; bx : handle
	mov	cx, STD_INIT_HANDLES		; number of handles to allocate
	mov	dx, size LMemBlockHeader	; offset at which to begin heap
	mov	si, STD_INIT_HEAP		; allocate amt. of empty heap
	clr	di				; LocalMemoryFlags
	call	LMemInitHeap			; initialize the heap

	; Now create a ChunkArray for National holiday
	;
						; ds : segment ptr for the heap
	mov	bx, size HolidayMonthCell	; element size
	clr	cx				; size for ChunkArrayHeader
	clr	si				; number of alloc ( one )
	clr	al				; ObjChunkFlags no needs ????
	call	ChunkArrayCreate		; create a new array

	pop	di				; restore di
	mov	es:[di].SHIC_NH_ChunkArray, si	; save chunk
	push	di				; save di

	; Now create a ChunkArray for Personal holiday
	;
						; ds : segment ptr for the heap
	mov	bx, size HolidayYearCell	; element size
						; cx:size for ChunkArrayHeader
	clr	si				; number of alloc ( one )
	clr	al				; ObjChunkFlags no needs ????
	call	ChunkArrayCreate		; create a new array

	pop	di				; restore di
	mov	es:[di].SHIC_PH_ChunkArray, si	; save chunk
	push	di				; save di

	; Now create a ChunkArray for Personal weekday
	;
						; ds : segment ptr for the heap
						; bx : element size
						; cx:size for ChunkArrayHeader
	clr	si				; number of alloc ( one )
	clr	al				; ObjChunkFlags no needs ????
	call	ChunkArrayCreate		; create a new array

	pop	di				; restore di
	mov	es:[di].SHIC_PW_ChunkArray, si	; save chunk

	; MemUnLock
	;
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemUnlock
	segmov	ds, es					; restore ds -> es

	; Now load holiday data from file
	;
	call	SetHLoadData

	.leave
	ret
SetHConstruct	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHDestruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIClass destructer

CALLED BY:	CalendarDetach ( CalendarAppClass )
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This should be called only once.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	10/5/93		Add a dialog box.
	Tera	12/23/93	Remove a dialog box for bug fix.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHDestruct	method	SetHolidayInteractionClass, MSG_JC_SHIC_DESTRUCT
;;	uses	ax, bx, cx, dx, si, bp
;;	.enter
;;
;;	; Check flag
;;	;
;;	cmp	ds:[di].SHIC_dataFlag, SH_DF_NOTCHANGED
;;	je	done
;;	cmp	ds:[di].SHIC_dataFlag, SH_DF_CHANGED
;;	mov	bp, offset dataSaveString
;;	je	showDialog
;;	mov	bp, offset undicideddataSaveString	; SH_DF_INDETERMINATE
;;
;;showDialog:
;;	; Now show dialog box
;;	;
;;	push	di					; save di
;;	mov	ax, CustomDialogBoxFlags <
;;		0,					; CDBF_SYSTEM_MODAL
;;		CDT_QUESTION,				; CDBF_DIALOG_TYPE
;;		GIT_AFFIRMATION				; CDBF_INTERACTION_TYPE
;;		,0>
;;	call	JCalendarUserStandardDialog
;;	cmp	ax, IC_NO
;;	pop	di					; restore di
;;	je	done

	; Save holiday data to file
	;
	call	SetHSaveData

;;done:
;;	.leave
	ret
SetHDestruct	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHIntInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIC data init

CALLED BY:	( MSG_GEN_INTERACTION_INITIATE )
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	 7/28/93    	Initial version
	Tera	10/ 6/93	Delete OK Cancel button
	Tera	 1/ 3/93	Setup EventDateArrows

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHIntInit	method	SetHolidayInteractionClass, MSG_GEN_INTERACTION_INITIATE
	uses	di, ax, bx, cx, dx, bp
	.enter

	; Setup RepeatHolidayList
	;
	mov	cx, ds:[di].SHIC_RHoliday		; set data to selected
	clr	dx					; reset indeterminate
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	JCalendarCallRepeatHolidayList		; set repeat holiday

	; Set usable state
	;
	or	ds:[di].SHIC_stateFlag, SH_SF_USABLE	; set usable state

	; Save the current selection from the YearClass object
	;
	CheckHack <YRT_CURRENT eq 0>
	clr	cx				; YRT_CURRENT => CX
	mov	ax, MSG_YEAR_GET_SELECTION
	mov	dx, ss
	sub	sp, size RangeStruct
	mov	bp, sp				; empty RangeStruct => SS:BP
	call	JCalendarCallYearObject		; DX:BP	= RangeStruct (filled)
						; CX	= # of days in range
	mov	ah, ss:[bp].RS_startDay
	mov	ds:[di].SHIC_prevYstartDay, ah
	mov	ah, ss:[bp].RS_startMonth
	mov	ds:[di].SHIC_prevYstartMonth, ah
	mov	ax, ss:[bp].RS_startYear
	mov	ds:[di].SHIC_prevYstartYear, ax
	mov	ah, ss:[bp].RS_endDay
	mov	ds:[di].SHIC_prevYendDay, ah
	mov	ah, ss:[bp].RS_endMonth
	mov	ds:[di].SHIC_prevYendMonth, ah
	mov	ax, ss:[bp].RS_endYear
	mov	ds:[di].SHIC_prevYendYear, ax
	add	sp, size RangeStruct		; clean up the stack

	; Clear the current selection of YearObj
	;
	clr	ax, bx				; start month, date, year
	clr	cx, dx				; end month, date, year
	call	SetHSetYearObjSelect

	; Redraw the calendar
	;
	call	JCalendarRedrawCalendar

	; Set another menu to be not able to use
	;
	push	si				; save si
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	GetResourceHandleNS	QuickMenu, bx
	mov	si, offset QuickMenu
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; disable QuickMenu

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	GetResourceHandleNS	EventDateArrows, bx
	mov	si, offset EventDateArrows
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; disable EventDateArrows
	pop	si				; restore si

	; Call Super
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, offset SetHolidayInteractionClass
	call	ObjCallSuperNoLock

	.leave
	ret
SetHIntInit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHLoadData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIC Load data from holiday file

CALLED BY:	SetHConstruct ( SetHolidayInteractionClass )
		SetHReset ( SetHolidayInteractionClass )
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	12/22/93	bug fix of sand clock icon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHLoadData	method	SetHolidayInteractionClass, MSG_JC_SHIC_LOADDATA
	uses	cx, dx, ax, bx, es, ds, di, si
	.enter

	; Set flag
	;
	mov	ds:[di].SHIC_dataFlag, SH_DF_NOTCHANGED

	mov	dl, VUM_NOW			; set Reset button not enable
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	JCalendarCallHolidayResetTrigger

	; Change directory
	;
	call	GotoHolidayDataDir

	; Get dgroup segment
	;
	segmov	es, ds				; save ds -> es
	GetResourceSegmentNS	dgroup, ds

	; Open data file ( dgroup )
	;
	call	DataFileOpen
	jc	fileOpenError			; can't open file
	tst	ax				; if it creates a new file,
	jnz	next				; then close file.
	call	DataFileClose
	jmp	done

	; Read data from file ( dgroup )
	;
next:
	call	SetHReadData
	pushf					; save flag

	; Close File ( dgroup )
	;
	call	DataFileClose
	popf					; restore flag
	jc	fileReadError

	; Check data array order
	;
	clr	cx					; clear error flag
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock
	mov	ds, ax					; segment pointer

	mov	si, es:[di].SHIC_NH_ChunkArray
	call	CheckHolidayDate			; check National H.
	jnc	next1
	inc	cx					; error
next1:	mov	si, es:[di].SHIC_PH_ChunkArray
	call	CheckHolidayDateYear			; check Personal H.
	jnc	next2
	inc	cx					; error
next2:	mov	si, es:[di].SHIC_PW_ChunkArray
	call	CheckHolidayDateYear			; check Personal W.
	jnc	next3
	inc	cx					; error
next3:							; bx : MemHandle
	call	MemUnlock
	tst	cx
	jnz	dataArrayError
	jmp	done

	; Error
	;
dataArrayError:
	mov	bp, CAL_ERROR_H_DATE_ORDER
	jmp	showDialog
fileOpenError:
	mov	bp, CAL_ERROR_H_FILE_OPEN
	jmp	showDialog
fileReadError:
	mov	bp, CAL_ERROR_H_FILE_READ
showDialog:
	; Now show dialog box
	;
	call	GeodeGetProcessHandle		; get process' handle => bx
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	clr	di				; no MessageFlags
	call	ObjMessage			; display the error dialog box

done:	
	.leave
	ret
SetHLoadData	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHSaveData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIC Save data to holiday file

CALLED BY:	SetHDestruct ( SetHolidayInteractionClass )
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	10/11/93	Change check flag to pass SH_DF_INDETERMINATE
	Tera	12/23/93	remove error dialogbox for bug fix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHSaveData	method	SetHolidayInteractionClass, MSG_JC_SHIC_SAVEDATA
	uses	dx, ax, bx, cx, dx, es, ds, si, di, bp
	.enter

	; Check flag
	;
	cmp	ds:[di].SHIC_dataFlag, SH_DF_NOTCHANGED
	je	done
	mov	ds:[di].SHIC_dataFlag, SH_DF_NOTCHANGED

; JCalendarCallHolidayResetTrigger is already deleted.
;	mov	dl, VUM_NOW			; set Reset button not enable
;	mov	ax, MSG_GEN_SET_NOT_ENABLED
;	call	JCalendarCallHolidayResetTrigger

	segmov	es, ds					; save ds->es

	; Check data array order
	;
	clr	cx					; clear error flag
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock
	mov	ds, ax					; segment pointer

	mov	si, es:[di].SHIC_NH_ChunkArray
	call	CheckHolidayDate			; check National H.
	jnc	next1
	inc	cx					; error
next1:	mov	si, es:[di].SHIC_PH_ChunkArray
	call	CheckHolidayDateYear			; check Personal H.
	jnc	next2
	inc	cx					; error
next2:	mov	si, es:[di].SHIC_PW_ChunkArray
	call	CheckHolidayDateYear			; check Personal W.
	jnc	next3
	inc	cx					; error
next3:							; bx : MemHandle
	call	MemUnlock
	tst	cx
	jnz	dataArrayError

	; Change directory
	;
	call	GotoHolidayDataDir

	; Get dgroup segment
	;
	GetResourceSegmentNS	dgroup, ds

	; Open data file ( dgroup )
	;
	call	DataFileOpen
	jc	fileOpenError				; can't open file

	; Write data to file ( dgroup )
	;
	call	SetHWriteData
	pushf						; save flag

	; Close File ( dgroup )
	;
	call	DataFileClose
	popf						; restore flag
	jc	fileWriteError				; data write error
	jmp	done

	; Error
	;
dataArrayError:
;;	mov	bp, offset sarrayErrorString
;;	jmp	showDialog
fileOpenError:
;;	mov	bp, offset fopenErrorString
;;	jmp	showDialog
fileWriteError:
;;	mov	bp, offset fwriteErrorString
;;showDialog:
;;	; Now show dialog box
;;	;
;;	mov	ax, CustomDialogBoxFlags <
;;		0,					; CDBF_SYSTEM_MODAL
;;		CDT_ERROR,				; CDBF_DIALOG_TYPE
;;		GIT_NOTIFICATION			; CDBF_INTERACTION_TYPE
;;		,0>
;;	call	JCalendarUserStandardDialog

done:
	.leave
	ret
SetHSaveData	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIC Reset holiday data

CALLED BY:	HolidayResetTrigger object
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:		
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Load holiday data form file again.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	10/5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHReset	method	SetHolidayInteractionClass, MSG_JC_SHIC_RESET
	uses	si, es
	.enter

EC<	call	SetHDataDump				; for debug	>

	; Check flag
	;	if flag != not changed then load data
	;
	cmp	ds:[di].SHIC_dataFlag, SH_DF_NOTCHANGED
	je	done

	; Free data memmory
	;
	segmov	es, ds					; save ds -> es
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock
	mov	ds, ax					; segment pointer

	mov	si, es:[di].SHIC_NH_ChunkArray
	call	DeleteAllHolidayDate			; delete National H.
	mov	si, es:[di].SHIC_PH_ChunkArray
	call	DeleteAllHolidayDateYear		; delete Personal H.
	mov	si, es:[di].SHIC_PW_ChunkArray
	call	DeleteAllHolidayDateYear		; delete Personal W.
							; bx : MemHandle
	call	MemUnlock
	segmov	ds, es					; restore es -> ds

	; Load holiday data from file
	;	SHIC_dataFlag <- SH_DF_NOTCHANGED
	;	ResetTrigger  <- MSG_GEN_SET_NOT_ENABLED
	;
	call	SetHLoadData
	
	; Reset RepeatHolidayList
	;
	mov	cx, ds:[di].SHIC_RHoliday		; set data to selected
	clr	dx					; reset indeterminate
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	JCalendarCallRepeatHolidayList		; set repeat holiday

	; Redraw the calendar
	;
	call	JCalendarRedrawCalendar

done:
	.leave
	ret
SetHReset	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIC Close

CALLED BY:	HolidayCloseTrigger object
		OpenLook Close menue
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
		SetHOlClose ( SetHolidayInteractionClass )
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	10/ 6/93    	Initial version
	Tera	 1/ 3/94	Reset EventDateArrows

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHClose	method	SetHolidayInteractionClass, MSG_JC_SHIC_CLOSE
	uses	ax, bx, cx, dx, si, bp
	.enter

	; Reset state
	;
	xor	ds:[di].SHIC_stateFlag, SH_SF_USABLE	; reset usable state

	; Restore the current selection to the YearClass object
	;
	mov	ah, ds:[di].SHIC_prevYstartDay
	mov	al, ds:[di].SHIC_prevYstartMonth
	mov	bx, ds:[di].SHIC_prevYstartYear
	mov	ch, ds:[di].SHIC_prevYendDay
	mov	cl, ds:[di].SHIC_prevYendMonth
	mov	dx, ds:[di].SHIC_prevYendYear
	call	SetHSetYearObjSelect

	; Check flag
	;	if flag == indeterminate then flag = changed
	;
	cmp	ds:[di].SHIC_dataFlag, SH_DF_INDETERMINATE
	jne	done
	mov	ds:[di].SHIC_dataFlag, SH_DF_CHANGED

	; Redraw the calendar
	;
	call	JCalendarRedrawCalendar

done:
	; Reset some menus to be usable
	;
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_ENABLED
	GetResourceHandleNS	QuickMenu, bx
	mov	si, offset QuickMenu
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage				; reset QuickMenu

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_ENABLED
	GetResourceHandleNS	EventDateArrows, bx
	mov	si, offset EventDateArrows
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage				; reset EventDateArrows

	.leave
	ret
SetHClose	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHRpeatHApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIC get apply Msg form RepeatHolidayList

CALLED BY:	RepeatHolidayList object
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Set data flag to indeterminate.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHRpeatHApply	method SetHolidayInteractionClass, MSG_JC_SHIC_RHL_APPLY
	uses	dx, ax
	.enter

	; Set repeat holiday data
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	JCalendarCallRepeatHolidayList;		; ax:repeat holiday
	mov	ds:[di].SHIC_RHoliday, ax

	; Set data flag to indeterminate
	;
	mov	ds:[di].SHIC_dataFlag, SH_DF_INDETERMINATE

	mov	dl, VUM_NOW			; set Reset button enable
	mov	ax, MSG_GEN_SET_ENABLED
	call	JCalendarCallHolidayResetTrigger

	; Redraw the calendar
	;
	call	JCalendarRedrawCalendar

	.leave
	ret
SetHRpeatHApply	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHGetUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get SetHoliday object's usable state

CALLED BY:	MonthSelectDraw ( MonthClass )
		YearCompleteSelection ( YearClass )
		UpdateSelection ( yearYearMouse.asm )
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:		carry set = if usable
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHGetUsable	method SetHolidayInteractionClass, MSG_JC_SHIC_GET_USABLE

	test	ds:[di].SHIC_stateFlag, SH_SF_USABLE
	jnz	usable					; if usable
	clc						; reset carry
	jmp	done

usable:
	stc						; set carry

done:
	ret
SetHGetUsable	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHGetHDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get holiday date

CALLED BY:	SetHSetResetH ( SetHolidayInteractionClass )
		MonthDrawHoliday ( yearMonth.asm )
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
		cx	= number for a year
		dh	= number for a month
		dl	= pos of first day of a month
RETURN:		dx	= holiday date low
		cx	= holiday date hight
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHGetHDate	method SetHolidayInteractionClass, MSG_JC_SHIC_GETHOLIDAYDATE
	uses	ax, bx, ds, si, es, bp
	.enter

	push	cx, dx					; save cx (year), dx

	; Get Repeat holiday data
	;
	mov	ax, ds:[di].SHIC_RHoliday

	; Make Repeat holiday mask
	;	repeat holiday date	low : ax, high : bx
	;
	pop	dx					; restore dx
	mov	cl, 7h
	sub	cl, dl
	ror	al, cl					; RH 7-dl ror

	clr	ah
	clr	cl					; set counter
loop1:
	cmp	cl, dl
	je	pass1					; if cl == dl
	shr	al, 1
	rcl	ah, 1
	jmp	next1
pass1:
	shr	al, 1
	; jmp	next1
next1:
	cmp	cl, 7h
	jae	exitLoop1
	inc	cl
	jmp	loop1
exitLoop1:						; ah : basic mask data

	mov	dl, ah					; basic mask => dl
	mov	al, dl					; basic mask => al
	shl	al, 1					; al : mask 7-1 date
							; basic mask => ah
	ror	ah, 1
	and	ah, 80h
	or	ah, dl					; ah : mask 15-8 date
	mov	bx, ax					;  mask 15-8 => bh
							;  mask  7-1 => bl
	mov	cl, 2h
	shr	bx, cl					; bl : mask 23-16
	mov	cl, 3h					; 3 bit hooey basic mask
	ror	dl, cl
	and	dl, 0c0h
	or	bh, dl					; bh : mask 31-24


	segmov	es, ds					; save ds -> es
	push	ax, bx					; save ax, bx
	; MemLock
	;
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock
	mov	ds, ax					; segment pointer

	; Add National holiday date
	;	RH & NH date	low : ax, high : bx
	;
	mov	bl, dh					; set number of a month
	mov	si, es:[di].SHIC_NH_ChunkArray		; load chunk
	call	GetHolidayDate				; cx:ax  holiday date
	pop	bx					; restore bx
	or	bx, cx					; add high => bx
	pop	cx					; restore ax => cx
	or	ax, cx					; add low => ax

	; Add Personal holiday date
	;	RH & NH & PH date	low : ax, high : bx
	;
	pop	cx					; restore cx (year)
	push	dx, ax, bx				; save dx, ax, bx
	mov	bl, dh					; set number of a month
	mov	dx, cx					; set number of a year
	mov	si, es:[di].SHIC_PH_ChunkArray		; load chunk
	call	GetHolidayDateYear			; cx:ax holiday date
	pop	bx					; restore bx
	or	bx, cx					; add high => bx
	pop	cx					; restore ax => cx
	or	ax, cx					; add low => ax
	pop	cx					; restore dx => cx

	; Sub Personal weekday date
	;	final holiday date	low : dx, high : cx
	;
	push	ax, bx					; save ax, bx
	mov	bl, ch					; set number of a month
							; dx : number of a year
	mov	si, es:[di].SHIC_PW_ChunkArray		; load chunk
	call	GetHolidayDateYear			; cx:ax holiday date
	notdw	cxax
	pop	bx					; restore bx
	and	bx, cx					; sub high => bx
	pop	cx					; restore ax => cx
	and	ax, cx					; sub low => ax
	mov	dx, ax
	mov	cx, bx

	; MemUnLock
	;
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemUnlock

	.leave
	ret
SetHGetHDate	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHSetRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set holiday data

CALLED BY:	YearCompleteSelection ( YearClass )
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHSetRange	method SetHolidayInteractionClass, MSG_JC_SHIC_SET_RANGE
	uses	si, es, bp
	.enter

	; Set data flag to indeterminate
	;
	cmp	ds:[di].SHIC_dataFlag, SH_DF_INDETERMINATE
	je	nextJob

	; Set data flag to indeterminate
	;
	mov	ds:[di].SHIC_dataFlag, SH_DF_INDETERMINATE

	mov	dl, VUM_NOW			; set Reset button enable
	mov	ax, MSG_GEN_SET_ENABLED
	call	JCalendarCallHolidayResetTrigger
nextJob:

	; Let's get the current selection from the Year object
	;
	CheckHack <YRT_CURRENT eq 0>
	clr	cx			; YRT_CURRENT => CX
	mov	ax, MSG_YEAR_GET_SELECTION
	mov	dx, ss
	sub	sp, size RangeStruct
	mov	bp, sp				; empty RangeStruct => SS:BP
	call	JCalendarCallYearObject		; DX:BP	= RangeStruct (filled)
						; CX	= # of days in range

	; Set / Reset personal holiday
	;
	mov	dx, {word} ss:[bp].RS_startDay	; dh = month, dl = date
	mov	bp, ss:[bp].RS_startYear	; bp = year
	clr	bx				; bh = month, bl = days
nextDate:

	; Get number of days in this month
	;
	cmp	bh, dh
	je	sameMonth			; same month
	push	cx				; save cx
						; bp = year, dh = month
	call	CalcDaysInMonth			; ch = days
	mov	bl, ch				; set days buffer
	mov	bh, dh
	pop	cx				; restore cx
sameMonth:

	; Set / Reset holiday
	;
						; dh = month, dl = date
						; bp = year
	call	SetHSetResetH

	; Set next date
	;
	cmp	bl, dl				; check end of month
	jna	endMonth
	inc	dl				; set next date
	jmp	next
endMonth:
	mov	dl, 1				; set next date
	cmp	dh, 12				; check end of year
	jae	endYear
	inc	dh				; set next month
	jmp	next
endYear:
	mov	dh, 1				; set next month
	inc	bp				; set next year

next:	loop	nextDate

	add	sp, size RangeStruct		; clean up the stack
	.leave
	ret
SetHSetRange	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHReadData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read data from text file

CALLED BY:	SetHLoadData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
		es:di	= SetHolidayInteractionClass specific instance data
RETURN:		carry set if read error.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Private function for SetHolidayInteractionClass
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version
	Tera	9/24/93		Error check

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHReadData	proc	near
	class	SetHolidayInteractionClass		; friend to this class
	uses	bx, cx, dx, ax
	.enter

	; Read key code data
	;
	call	ReadKeyCodeData				; bx : key code flag
	cmp	bx, 1h					; cmp 'nation'
	je	nationFlag
	jmp	readError				; readError

mainLoop:
	; Read key code data
	;
	call	ReadKeyCodeData				; bx : key code flag

	; Check the key
	;
	cmp	bx, 0h					; end of file
	je	endOfFile
;	cmp	bx, 1h					; cmp 'nation'
;	je	nationFlag
	cmp	bx, 2h					; cmp 'repeat'
	je	repeatFlag
	cmp	bx, 3h					; cmp 'holiday'
	je	holidayFlag
	cmp	bx, 4h					; cmp 'weekday'
	je	weekdayFlag
	jmp	readError				; readError
;	jmp	mainLoop

	; National Holiday
	;
nationFlag:
	mov	bx, es:[di].SHIC_holidayMemHandle	; set handle
	mov	cx, es:[di].SHIC_NH_ChunkArray		; set chunk
	push	es					; save es
	segmov	es, ds					; set dgroup segment
	push	ds					; save ds
	call	SetMonthDate
	pop	ds					; restore ds
	pop	es					; restore es
	jc	endOfFile				; end of file
	jmp	mainLoop

	; Repeat Holiday
	;
repeatFlag:
	call	ReadWeekData				; bx : week data
	mov	es:[di].SHIC_RHoliday, bx
	jc	endOfFile
	jmp	mainLoop

	; Pearsonal Holiday
	;
holidayFlag:
							; ds : dgroup
	mov	bx, es:[di].SHIC_holidayMemHandle	; set handle
	mov	ax, es:[di].SHIC_PH_ChunkArray		; set chunk
	call	SetYearMonthDate
	jc	endOfFile				; end of file
	jmp	mainLoop

	; Pearsonal Weekday
	;
weekdayFlag:
							; ds : dgroup
	mov	bx, es:[di].SHIC_holidayMemHandle	; set handle
	mov	ax, es:[di].SHIC_PW_ChunkArray		; set chunk
	call	SetYearMonthDate
	jc	endOfFile				; end of file
	jmp	mainLoop

readError:
	stc						; set carry
	jmp	done
endOfFile:
	clc						; reset carry
done:
	.leave
	ret
SetHReadData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHWriteData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data to text file

CALLED BY:	SetHSaveData ( SetHolidayInteractionClass )
PASS:		ds	= dgroup
		es:di	= SetHolidayInteractionClass specific instance data
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Private function for SetHolidayInteractionClass
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHWriteData	proc	near
	class	SetHolidayInteractionClass		; friend to this class
	uses	ax, bx
	.enter

	; Read National holiday
	;
	call	SkipNatinalHoliday
	jc	fileError

	; Write repeat holiday data
	;
	mov	bx, 2
	call	WriteKeyCodeData			; write repeat key word

	mov	bx, es:[di].SHIC_RHoliday
	tst	bx
	jz	next
							; bx:holiday data
	call	WriteWeekData
next:

	; Write personal holiday data
	;
	mov	bx, 3
	call	WriteKeyCodeData			; write repeat key word
							; ds : dgroup
	mov	bx, es:[di].SHIC_holidayMemHandle	; set handle
	mov	ax, es:[di].SHIC_PH_ChunkArray		; set chunk
	call	GetYearMonthDate

	; Write personal weekdaty data
	;
	mov	bx, 4
	call	WriteKeyCodeData			; write repeat key word
							; ds : dgroup
	mov	bx, es:[di].SHIC_holidayMemHandle	; set handle
	mov	ax, es:[di].SHIC_PW_ChunkArray		; set chunk
	call	GetYearMonthDate

	; Erase previous data
	;
	call	ErasePreviousData

	clc						; reset carry
	jmp	done
fileError:
	stc						; set carry
done:
	.leave
	ret
SetHWriteData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHSetResetH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set / Reset Holiday

CALLED BY:	SetHSetRange ( SetHolidayInteractionClass )
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
		dh	= month
		dl	= date
		bp	= year
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Private function for SetHolidayInteractionClass
		
		check holiday
		    if holiday then delete personal holiday
				    check holiday
					if holiday then add weekday
		    else then delete weekday
			      check holiday
				if weekday then add personal holiday


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHSetResetH	proc	near
	class	SetHolidayInteractionClass	; friend to this class
	uses	ax, bx, cx, dx, si, ds, es
	.enter

	segmov	es, ds				; save ds -> es

	; Make date mask
	;
	clr	ch
	mov	cl, dl				; set counter
	movdw	axbx, 1h			; set 1 bit
bitShift:
	shldw	axbx
	loop	bitShift
	push	ax, bx				; save ax, bx ( date mask )

	; Get holiday of a month
	;
	push	dx				; save dx ( month,date )
						; bp = year
						; dh = month
	mov	dl, 1				; first day
	push	ax, bx				; save ax, bx
	CallMod	CalcDayOfWeek			; cl = day of the week
	pop	ax, bx				; restore ax, bx
	mov	dl, cl				; pos of first day of a month
	push	cx				; save cx ( pos of first day )
	mov	cx, bp				; year
						; dh = month
	call	SetHGetHDate			; cx:dx holiday date

	; Check holiday
	;
	and	cx, ax
	and	dx, bx
	tstdw	cxdx				; check holiday
	pop	dx, cx				; restore dx, cx
	push	dx, cx				; save dx, cx
	je	cngWtoH				; change weekday to holiday


	; Change holiday to weekday
	;

	; Delete personal  holiday
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock					; MemLock
	mov	ds, ax					; segment pointer

	mov	bl, dh					; set number of a month
	mov	bh, dl					; set number of a date
	mov	dx, bp					; set number of a year
	mov	si, es:[di].SHIC_PH_ChunkArray		; load chunk
	call	DeleteHolidayDateYear

	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemUnlock

	; Get holiday date
	segmov	ds, es				; restore ds <- es
	pop	dx, cx				; restore dx, cx
	pop	ax, bx				; restore ax, bx
	push	dx				; save dx
	mov	dl, cl				; pos of first day of a month
	mov	cx, bp				; year
						; dh = month
	call	SetHGetHDate			; cx:dx holiday date

	; Check holiday
	and	cx, ax
	and	dx, bx
	tstdw	cxdx				; check holiday
	pop	dx				; restore dx
	je	done

	; Add personal weekday
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock					; MemLock
	mov	ds, ax					; segment pointer

	mov	bl, dh					; set number of a month
	mov	bh, dl					; set number of a date
	mov	dx, bp					; set number of a year
	mov	si, es:[di].SHIC_PW_ChunkArray		; load chunk
	call	SetHolidayDateYear

	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemUnlock
	jmp	done


	; Cheange weekday to holiday
	;
cngWtoH:
	; Delete personal  weekday
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock					; MemLock
	mov	ds, ax					; segment pointer

	mov	bl, dh					; set number of a month
	mov	bh, dl					; set number of a date
	mov	dx, bp					; set number of a year
	mov	si, es:[di].SHIC_PW_ChunkArray		; load chunk
	call	DeleteHolidayDateYear

	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemUnlock

	; Get holiday date
	segmov	ds, es				; restore ds <- es
	pop	dx, cx				; restore dx, cx
	pop	ax, bx				; restore ax, bx
	push	dx				; save dx
	mov	dl, cl				; pos of first day of a month
	mov	cx, bp				; year
						; dh = month
	call	SetHGetHDate			; cx:dx holiday date

	; Check holiday
	and	cx, ax
	and	dx, bx
	tstdw	cxdx				; check holiday
	pop	dx				; restore dx
	jne	done

	; Add personal holiday
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock					; MemLock
	mov	ds, ax					; segment pointer

	mov	bl, dh					; set number of a month
	mov	bh, dl					; set number of a date
	mov	dx, bp					; set number of a year
	mov	si, es:[di].SHIC_PH_ChunkArray		; load chunk
	call	SetHolidayDateYear

	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemUnlock
	; jmp	done


done:
	.leave
	ret
SetHSetResetH	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHSetYearObjSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIC Set the current selection to the YearClass object

CALLED BY:	SetHIntInit ( SetHolidayInteractionClass )
		SetHClose ( SetHolidayInteractionClass )
PASS:		ah	= start day
		al	= start month
		bx	= start year
		ch	= end day
		cl	= end month
		dx	= end year
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/29/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHSetYearObjSelect	proc	near
	class	SetHolidayInteractionClass	; friend to this class
	uses	sp, bp
	.enter

	; Set the current selection to the YearClass object
	;
	sub	sp, size RangeStruct
	mov	bp, sp				; structure => SS:BP
	mov	ss:[bp].RS_startDay, ah
	mov	ss:[bp].RS_startMonth, al
	mov	ss:[bp].RS_startYear, bx
	mov	ss:[bp].RS_endDay, ch
	mov	ss:[bp].RS_endMonth, cl
	mov	ss:[bp].RS_endYear, dx

	mov	ax, MSG_YEAR_SET_SELECTION
	mov	dx, size RangeStruct
	call	JCalendarCallYearObject
	add	sp, size RangeStruct

	.leave
	ret
SetHSetYearObjSelect	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHDataDump
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SHIC holiday data dump for debug

CALLED BY:
PASS:		ds:di	= SetHolidayInteractionClass specific instance data
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetHDataDump	method SetHolidayInteractionClass, MSG_JC_SHIC_DATA_DUMP
	uses	bx, ax, ds, si, es
	.enter

	segmov	es, ds					; save ds -> es

	; MemLock
	;
	mov	bx, es:[di].SHIC_holidayMemHandle	; load handle
	call	MemLock
	mov	ds, ax					; segment pointer

	; Set National holiday chunk arrray
	;
	mov	si, es:[di].SHIC_NH_ChunkArray		; load chunk
	call	DumpHolidayDate

	; Set Personal holiday chunk arrray
	;
	mov	si, es:[di].SHIC_PH_ChunkArray		; load chunk
	call	DumpHolidayDateYear

	; Set Personal weekday chunk arrray
	;
	mov	si, es:[di].SHIC_PW_ChunkArray		; load chunk
	call	DumpHolidayDateYear

	; MemUnLock
	;
							; bx : MemHandle
	call	MemUnlock

	.leave
	ret
SetHDataDump	endm


HolidayCode	ends

