COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Interface Gadgets
MODULE:		Battery Indicator Gadget
FILE:		uiBatteryIndicator.asm

AUTHOR:		Patrick Buck, Sep 22, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB GadgetsEntry            Initialize stuff for BatteryIndicatorClass.

    INT BICreateBatteryVisMoniker 
				Creates the battery indicator VisMoniker

    INT BIConstructVerticalBatteryGString 
				Construct a gstring for a vertically
				oriented battery indicator.

    INT BIConstructHorizontalBatteryGString 
				Construct a gstring for a horizontally
				oriented battery indicator.

    INT BIConstructLongHorizontalBatteryGString 
				Construct a gstring for the long,
				horizontal battery indicator.

    INT BIGetBatteryIndicatorMetrics 
				Get visible sizes and offsets for the
				various elements in the battery indicator
				moniker.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	9/22/94   	Initial revision


DESCRIPTION:
	Implementation of the BatteryIndicatorClass object
		

	$Id: uiBatteryIndicator.asm,v 1.1 97/04/04 17:59:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetsClassStructures	segment resource
	BatteryIndicatorClass
GadgetsClassStructures	ends

idata	segment
	powerDriverLoaded	BooleanByte	BB_FALSE
idata	ends

udata	segment
	powerStrategy		fptr.far
udata	ends

EntryCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetsEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize stuff for BatteryIndicatorClass.

CALLED BY:	(GLOBAL)
PASS:		di	= LibraryCallType
		ds	= dgroup
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	11/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetsEntry	proc	far
ForceRef	GadgetsEntry
		uses	ax, bx, di, si, ds, es
		.enter
	;
	; We're only interested in initializing a few things for
	; BatteryIndicatorClass, so bail unless this is LCT_ATTACH.
	;
		cmp	di, LCT_ATTACH
		jne	done

	; 
	; Try to load the power driver.
	; 
		mov	ax, GDDT_POWER_MANAGEMENT
		call	GeodeGetDefaultDriver
		tst	ax
		jz	done
		mov	ds:[powerDriverLoaded], BB_TRUE ; object checks this

	;
	; Get its strategy routine.
	;
		mov_tr	bx, ax			; bx <- driver handle
		segmov	es, ds			; es <- dgroup
		call	GeodeInfoDriver		; ds:si <- DriverInfoStruct
		movdw	es:[powerStrategy], ds:[si].DIS_strategy, ax

done:
		clc				; no errors can occur

		.leave
		ret
GadgetsEntry	endp

EntryCode	ends

GadgetsBatteryIndicatorCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BIVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a timer used to update the battery indicator if
		the power driver has been loaded.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= BatteryIndicatorClass object
		ds:di	= BatteryIndicatorClass instance data
		es 	= segment of BatteryIndicatorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BIVisOpen	method dynamic BatteryIndicatorClass, 
					MSG_VIS_OPEN
		.enter

		mov	di, offset BatteryIndicatorClass
		call	ObjCallSuperNoLock

	;
	; See if we can leave mix mode for clearing at MM_CLEAR.
	;
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	UserCallApplication	; ah <- DisplayType

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

		andnf	ah, mask DT_DISP_CLASS
		cmp	ah, DC_GRAY_1 shl (offset DT_DISP_CLASS)
	   	jbe	mixModeSet
		mov	ds:[di].BII_mixModeClear, MM_SET
mixModeSet:

	;
	; Don't set up the timer unless the power driver is available.
	;
		mov	bx, handle dgroup
		call	MemDerefES
		tst	es:[powerDriverLoaded]
		jz	noPower

	;
	; Draw the initial battery level (otherwise the user will perceive
	; some weird jumping around of the battery level).
	;
		mov	ax, MSG_BATTERY_FIND_SET_LIFE
		call	ObjCallInstanceNoLock


	; -----------------------------------------------
	; Setup the timer to update the battery indicator
	; -----------------------------------------------
		mov	dx, MSG_BATTERY_FIND_SET_LIFE
		mov	bx, ds:[LMBH_handle]	; send to us
		mov	al, TIMER_EVENT_CONTINUAL
		clr	cx
		mov	di, BI_TIMER_INTERVAL
		call	TimerStart

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].BII_timerHan, bx
		mov	ds:[di].BII_timerID, ax

done:
		.leave
		ret

	; -------------------------------
	; Draw an empty battery indicator
	; -------------------------------
noPower:		
		clr	cx
		mov	ax, MSG_BATTERY_SET_LIFE
		call	ObjCallInstanceNoLock
		jmp	done

BIVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BIVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the timer used to update the battery indicator.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= BatteryIndicatorClass object
		ds:di	= BatteryIndicatorClass instance data
		ds:bx	= BatteryIndicatorClass object (same as *ds:si)
		es 	= segment of BatteryIndicatorClass
		ax	= message #

RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	10/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BIVisClose	method dynamic BatteryIndicatorClass, 
					MSG_VIS_CLOSE
	.enter

	mov	bx, ds:[di].BII_timerHan
	mov	ax, ds:[di].BII_timerID
	call	TimerStop

	.leave
	mov	ax, MSG_VIS_CLOSE
	mov	di, offset BatteryIndicatorClass
	GOTO	ObjCallSuperNoLock
BIVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BIBatterySetLife
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new value for the battery life.  Redraw battery
   		indicator moniker if the new value differs from the
   		old value.

CALLED BY:	MSG_BATTERY_SET_LIFE
PASS:		*ds:si	= BatteryIndicatorClass object
		ds:di	= BatteryIndicatorClass instance data
		ds:bx	= BatteryIndicatorClass object (same as *ds:si)
		es 	= segment of BatteryIndicatorClass
		ax	= message #

   		cx	= new battery life (0..100 %)

RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	10/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BIBatterySetLife	method dynamic BatteryIndicatorClass, 
					MSG_BATTERY_SET_LIFE
	uses	ax, cx, dx, bp
	.enter
	
   ; Done if nothing has changed
   ; ---------------------------
	cmp	cx, ds:[di].BII_life
	je	done

   ; Set new battery life and create the new moniker
   ; -----------------------------------------------
	mov	ds:[di].BII_life, cx
	call	BICreateBatteryVisMoniker  ; ^lcx:dx = VisMoniker

   ; Set the moniker
   ; ---------------
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	push	cx
	call	ObjCallInstanceNoLock
	pop	bx
	call	MemFree

done:	.leave
	ret
BIBatterySetLife	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BIBatteryFindSetLife
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the power driver to get the current battery life and
   		set ourselves to this value.

CALLED BY:	MSG_BATTERY_FIND_SET_LIFE
PASS:		*ds:si	= BatteryIndicatorClass object
		ds:di	= BatteryIndicatorClass instance data
		ds:bx	= BatteryIndicatorClass object (same as *ds:si)
		es 	= segment of BatteryIndicatorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	10/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BIBatteryFindSetLife	method dynamic BatteryIndicatorClass, 
					MSG_BATTERY_FIND_SET_LIFE
		uses	ax, cx, dx, bp
		.enter

	; ----------------------------------------
	; Find out how much battery life we've got
	; ----------------------------------------
		mov	bx, handle dgroup
		call	MemDerefES   	
		mov	di, DR_POWER_GET_STATUS
		mov	ax, PGST_BATTERY_CHARGE_PERCENT
		call	es:[powerStrategy]	; dxax = life (0..1000)
						; carry set if not supported
	;
	; If the function wasn't supported, just draw empty.
	;
		mov	cx, 0			; don't affect carry
		jc	drawEmpty

	; --------------------------------------------------
	; Set the new battery life (scaled to max batt life)
	; --------------------------------------------------

CheckHack < BI_MAX_BATTERY_LIFE gt 4  >
	;
	;  If 1000/BI_MAX_BATTERY_LIFE is less than 256 (i.e. if
	;  BI_MAX_BATTERY_LIFE is greater than 4) we can change
	;  the divisor to a byte register.  This is also assuming
	;  the power driver doesn't return a battery life greater
	;  than 1000.
	;
	;  WHAT?  Who the heck thought this "optimization" up?
	;  If you change the divisor to a byte, you also change
	;  the result to a byte.  The remainder now gets stuffed
	;  in ah, and so if you pass the whole word off to the
	;  SET_LIFE command you are going to get _BIG_ battery
	;  values.
	;  Sheesh.
	;				-- todd 05/23/95
		mov	bx, 1000 / BI_MAX_BATTERY_LIFE
if 0
		div	bl			; ax = life
		mov_tr	cx, ax
else
		div	bl			; al <- life
						; ah <- un-life
		mov_tr	cl, al			; cx <- life
endif
drawEmpty:		
		mov	ax, MSG_BATTERY_SET_LIFE
		call	ObjCallInstanceNoLock

		.leave
		ret
BIBatteryFindSetLife	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BICreateBatteryVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the battery indicator VisMoniker

CALLED BY:	(INTERNAL) BIBatterySetLife

PASS:		*ds:si = BatteryIndicatorClass object

RETURN:		^lcx:dx	<- VisMoniker
		note:  cx (the gstring block) has to be destroyed after the
			visMoniker has been used.  This is done by calling
			MemFree with the gstring block in bx.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	9/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BICreateBatteryVisMonikerTable	word \
   offset BIConstructVerticalBatteryGString,
   offset BIConstructHorizontalBatteryGString,
   offset BIConstructLongHorizontalBatteryGString

BICreateBatteryVisMoniker	proc	near
	class	BatteryIndicatorClass
	uses	ax,bx,si,di,bp
	.enter

   ; Create an empty GString
   ; 	bx = gstring block
   ;	si = gstring chunk
   ;	di = gstring handle
   ; -----------------------
	mov	bp, si
   	call	CreateGStringForVisualMoniker
	push	bx, si
	mov	si, bp
	
	mov	cx, FID_JSYS
	clr	ax
	mov	dx, 14
	call	GrSetFont
	
   ; Construct the image of the battery indicator
   ; --------------------------------------------
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bp, ds:[di].BII_orientation
	pop	di

   ; returns:
   ; cx = gstring height
   ; dx = gstring width
   ; -------------------
	call	cs:BICreateBatteryVisMonikerTable[bp]

   ; Create the VisMoniker
   ; ---------------------
	pop	bx, si
   	call	CreateVisMonikerFromGString	; ^lcx:dx = VisMoniker
		
	.leave
	ret
BICreateBatteryVisMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BIConstructVerticalBatteryGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct a gstring for a vertically oriented battery
   		indicator.

CALLED BY:	BICreateBatteryVisMoniker

PASS:		*ds:si	= BatteryIndicatorClass object
   		di	= gstring handle

RETURN:		cx	= gstring height
   		dx	= gstring width
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BIConstructVerticalBatteryGString	proc	near
	class	BatteryIndicatorClass
	metrics	local	BatteryIndicatorMetrics
	uses	ax,bx,si,di,bp,ds
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset

   ; Fill the 'metrics' local variable
   ; ---------------------------------
	push	bp
	sub	bp, size BatteryIndicatorMetrics
	mov	cx, ds:[si].BII_orientation
	call	BIGetBatteryIndicatorMetrics
	pop	bp
	
   ; Lock the string resource for the empty & full characters
   ; --------------------------------------------------------
	mov	bx, handle BatteryEmptyFullLetterString
	call	MemLock		; ax <- segment
	mov	ds, ax
	mov	si, ds:[offset BatteryEmptyFullLetterString]

   ; Draw an 'F' (second char of ds:si, ds:si -> "EF")
   ; -----------
	mov	ax, ss:[metrics].BIM_textIndent
	clr	bx
	mov	cx, 1
	inc	si
DBCS <	inc	si							 >
	call	GrDrawText

   ; Draw the tip of the battery
   ; ---------------------------
	mov	ax, BI_BATTERY_WIDTH/2 - 1
	sub	ax, BI_BATTERY_WIDTH/4
	add	ax, ss:[metrics].BIM_batteryIndent
	mov	cx, ax
	add	cx, BI_BATTERY_WIDTH/2
	mov	bx, ss:[metrics].BIM_fontHeight
	add	bx, BI_CHARACTER_SPACING - 1
	mov	dx, bx
	add	dx, BI_BATTERY_TOP_LENGTH
	call	GrFillRect

   ; Draw the empty part of the battery
   ; ----------------------------------
	mov	ax, ss:[metrics].BIM_batteryIndent
	mov	cx, ax
	add	cx, BI_BATTERY_WIDTH
   	dec	cx
	mov	bx, dx
	add	dx, BI_BATTERY_LENGTH
	sub	dx, ss:[metrics].BIM_filledLength
   	call	GrDrawRect

   ; Draw the filled portion of the battery
   ; --------------------------------------
	inc	cx
   	mov	bx, dx
   	add	dx, ss:[metrics].BIM_filledLength
   	call	GrFillRect

   ; Draw an 'E'  (ds:si -> 'F' of "EF")
   ; -----------
   	mov	ax, ss:[metrics].BIM_textIndent
	mov	bx, dx
	add	bx, BI_CHARACTER_SPACING
	mov	cx, 1
   	dec	si
DBCS <	dec	si							 >
   	call	GrDrawText

   ; Unlock string resource
   ; ----------------------
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	clrdw	axbx
	mov	cx, BI_BATTERY_WIDTH
	add	cx, ss:[metrics].BIM_batteryIndent
	inc	cx
	xchg	cx, dx
	
	call	GrEndGString
	.leave
	ret
BIConstructVerticalBatteryGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BIConstructHorizontalBatteryGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct a gstring for a horizontally oriented battery
   		indicator.

CALLED BY:	BICreateBatteryVisMoniker

PASS:		*ds:si	= BatteryIndicatorClass object
   		di	= gstring handle

RETURN:		cx	= gstring height
   		dx	= gstring width

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BIConstructHorizontalBatteryGString	proc	near
	class	BatteryIndicatorClass
	metrics	local	BatteryIndicatorMetrics
	uses	ax,bx,si,di,bp,ds
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset

   ; Fill the 'metrics' local variable
   ; ---------------------------------
	push	bp
	sub	bp, size BatteryIndicatorMetrics
	mov	cx, ds:[si].BII_orientation
	call	BIGetBatteryIndicatorMetrics
	pop	bp
	
   ; Lock the string resource for the empty & full characters
   ; --------------------------------------------------------
	mov	bx, handle BatteryEmptyFullLetterString
	call	MemLock		; ax <- segment
	mov	ds, ax
	mov	si, ds:[offset BatteryEmptyFullLetterString]

   ; Draw an 'E' (ds:si -> "EF")
   ; -----------
	mov	ax, ss:[metrics].BIM_textIndent
	clr	bx
	mov	cx, 1
	call	GrDrawText

   ; Draw the filled portion of the battery
   ; --------------------------------------
	mov	ax, ss:[metrics].BIM_fontWidth
	add	ax, BI_CHARACTER_SPACING
	mov	cx, ax
	add	cx, ss:[metrics].BIM_filledLength
	mov	bx, ss:[metrics].BIM_batteryIndent
	mov	dx, bx
	add	dx, BI_BATTERY_WIDTH
	call	GrFillRect

   ; Draw the empty part of the battery
   ; ----------------------------------
	mov	ax, cx
	add	cx, BI_BATTERY_LENGTH
	sub	cx, ss:[metrics].BIM_filledLength
	dec	dx
	call	GrDrawRect
	
   ; Draw the tip of the battery
   ; ---------------------------
	mov	ax, cx
	add	cx, BI_BATTERY_TOP_LENGTH	
	mov	bx, BI_BATTERY_WIDTH/4
	add	bx, ss:[metrics].BIM_batteryIndent
	mov	dx, bx
	mov	dx, BI_BATTERY_WIDTH - BI_BATTERY_WIDTH/4
	add	dx, ss:[metrics].BIM_batteryIndent
	call	GrFillRect
	
   ; Draw an 'F' (ds:si -> "EF")
   ; -----------
	mov	ax, cx
	add	ax, BI_CHARACTER_SPACING
   	mov	bx, ss:[metrics].BIM_textIndent
	push	cx
   	mov	cx, 1
	inc	si
DBCS <	inc	si							>
   	call	GrDrawText
	pop	cx

   ; Unlock string resource
   ; ----------------------
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	clrdw	axbx
	add	cx, ss:[metrics].BIM_fontWidth
	add	cx, 2
	mov	dx, BI_BATTERY_WIDTH
	add	dx, ss:[metrics].BIM_batteryIndent
	xchg	cx, dx
	
	call	GrEndGString
	.leave
	ret
BIConstructHorizontalBatteryGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BIConstructLongHorizontalBatteryGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct a gstring for the long, horizontal battery
   		indicator.

CALLED BY:	BICreateBatteryVisMoniker

PASS:		*ds:si	= BatteryIndicatorClass object
   		di	= gstring handle

RETURN:		cx	= gstring height
   		dx	= gstring width

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BIConstructLongHorizontalBatteryGString	proc	near
					class	BatteryIndicatorClass
metrics		local	BatteryIndicatorMetrics
clearMixMode	local	MixMode	
		uses	ax, bx, si, di,ds
		.enter

		mov	si, ds:[si]
		add	si, ds:[si].Gen_offset
		mov	al, ds:[si].BII_mixModeClear
		mov	clearMixMode, al
		

   ; Fill the 'metrics' local variable
   ; ---------------------------------
	push	bp
	sub	bp, size BatteryIndicatorMetrics
	mov	cx, ds:[si].BII_orientation
	call	BIGetBatteryIndicatorMetrics
	pop	bp

   ; Lock the string resource for the empty & full characters
   ; --------------------------------------------------------
	mov	bx, handle BatteryEmptyFullLetterString
	call	MemLock		; ax <- segment
	mov	ds, ax
	mov	si, ds:[offset BatteryEmptyFullLetterString]

   ; Draw an 'E' (ds:si -> "EF")
   ; -----------
	mov	bx, ss:[metrics].BIM_textIndent
	add	bx, BI_LONG_BATTERY_MARGIN
	mov	ax, BI_LONG_BATTERY_MARGIN
	mov	cx, 1
	call	GrDrawText

   ; Draw the filled portion of the battery
   ; --------------------------------------
	add	ax, ss:[metrics].BIM_fontWidth
	add	ax, BI_LONG_BATTERY_MARGIN
	push	ax, bx
	mov	cx, ax
	add	cx, ss:[metrics].BIM_filledLength
	mov	bx, ss:[metrics].BIM_batteryIndent
	add	bx, BI_LONG_BATTERY_MARGIN
	mov	dx, bx
	add	dx, BI_LONG_BATTERY_WIDTH
	call	GrFillRect
	pop	ax, bx

   ; Draw an 'F' (ds:si -> "EF");
   ; -----------
	add	ax, BI_TOTAL_LONG_BATTERY_LENGTH + \
   			BI_LONG_BATTERY_MARGIN
	mov	cx, 1
	inc	si
DBCS <	inc	si							>
	call	GrDrawText

   ; Unlock string resource
   ; ----------------------
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	
   ; Draw rectangles
   ; ---------------
	clrdw	axbx
	mov	cx, ss:[metrics].BIM_fontWidth
	add	cx, BI_LONG_BATTERY_MARGIN * 2
	mov	dx, ss:[metrics].BIM_fontHeight
	add	dx, ss:[metrics].BIM_textIndent
	add	dx, BI_LONG_BATTERY_MARGIN * 2
	dec	dx
	call	GrDrawRect

	mov	ax, cx
	add	cx, BI_TOTAL_LONG_BATTERY_LENGTH
	call	GrDrawRect

	mov	ax, cx
	add	cx, ss:[metrics].BIM_fontWidth
	add	cx, BI_LONG_BATTERY_MARGIN * 2
	call	GrDrawRect

   ; Draw segment dividers
   ; ---------------------
   	mov	bx, handle dgroup
   	call	MemDerefES
   	mov	al, clearMixMode
   	call	GrSetMixMode

	mov	ax, ss:[metrics].BIM_fontWidth
	add	ax, BI_LONG_BATTERY_MARGIN * 2
	mov	cx, ax
	mov	bx, ss:[metrics].BIM_batteryIndent
	add	bx, BI_LONG_BATTERY_MARGIN
	mov	dx, bx
	add	dx, BI_LONG_BATTERY_WIDTH
   	mov	si, BI_BATTERY_SEGMENT_COUNT - 1
segDivLoop:
	add	ax, BI_LONG_BATTERY_SEGMENT_LENGTH
	mov	cx, ax
	call	GrDrawLine
	dec	si
	tst	si
	jnz	segDivLoop	

	mov	cx, ss:[metrics].BIM_textIndent
	add	cx, ss:[metrics].BIM_fontHeight
	add	cx, BI_LONG_BATTERY_MARGIN * 2
	mov	dx, ss:[metrics].BIM_fontWidth
	shl	dx, 1
	inc	dx
	add	dx, BI_TOTAL_LONG_BATTERY_LENGTH + \
   			BI_LONG_BATTERY_MARGIN * 4

	.leave
	ret
BIConstructLongHorizontalBatteryGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BIGetBatteryIndicatorMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get visible sizes and offsets for the various elements
   		in the battery indicator moniker.

CALLED BY:	
PASS:		ds:si	= BatteryIndicatorClass object
   		ss:bp	= BatteryIndicatorMetrics structure
   		cx	= BatteryOrientationType

RETURN:		structure filled
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BIGetBatteryIndicatorMetrics	proc	near
	class	BatteryIndicatorClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter

   ; Get the max dimensions of the current font box
   ; ----------------------------------------------
	push	si
	mov	si, GFMI_HEIGHT
	call	GrFontMetrics
	mov	ss:[bp].BIM_fontHeight, dx
	mov	ax, 'E'
	mov	si, GFMI_MAX_WIDTH
	call	GrCharWidth
	mov	ss:[bp].BIM_fontWidth, dx
	pop	si

   ; Set the indentation distances based on the text & battery widths
   ; ----------------------------------------------------------------
	mov	ax, BI_LONG_BATTERY_WIDTH
	mov	bx, ss:[bp].BIM_fontHeight
	cmp	cx, BOT_LONG_HORIZONTAL
	je	compareWidths
	mov	ax, BI_BATTERY_WIDTH
	cmp	cx, BOT_HORIZONTAL
	je	compareWidths
	mov	bx, ss:[bp].BIM_fontWidth

compareWidths:
	cmp	ax, bx
	jl	textWider

	clr	ss:[bp].BIM_batteryIndent
	sub	ax, bx
	shr	ax, 1
	mov	ss:[bp].BIM_textIndent, ax
	jmp	getFilled
	
textWider:
	clr	ss:[bp].BIM_textIndent
	sub	bx, ax
	shr	bx, 1
	mov	ss:[bp].BIM_batteryIndent, bx	
	
   ; Calculate the length of battery that is filled
   ; ----------------------------------------------
getFilled:
	mov	bx, BI_BATTERY_LENGTH
	cmp	cx, BOT_LONG_HORIZONTAL
	jne	getPercentLength
	mov	bx, BI_TOTAL_LONG_BATTERY_LENGTH
getPercentLength:
	clr	dx
	mov	ax, ds:[si].BII_life
	mul	bx
	mov	bx, BI_MAX_BATTERY_LIFE
	div	bx				; ax = life*length/maxLife
	
	mov	bx, BI_BATTERY_SEGMENT_LENGTH
	cmp	cx, BOT_LONG_HORIZONTAL
	jne	getFilledLength
	mov	bx, BI_LONG_BATTERY_SEGMENT_LENGTH
getFilledLength:
	clr	dx
	div	bx
   ;inc	ax				; ax = # of segments to use
	clr	dx
   	mul	bx				; ax = final length
   	mov	ss:[bp].BIM_filledLength, ax

	.leave
	ret
BIGetBatteryIndicatorMetrics	endp

GadgetsBatteryIndicatorCode	ends
