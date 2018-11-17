COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Timer
FILE:		timerC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: timerC.asm,v 1.1 97/04/05 01:15:28 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TimerStart

C DECLARATION:	extern TimerHandle
		    _far _pascal TimerStart(TimerType timerType,
				MemHandle destHan, ChunkHandle destCh,
				word ticks, Method meth, word interval,
				word _far *id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
TIMERSTART	proc	far	timerType:word, destHan:hptr, destCh:word,
				timerTicks:word, meth:word, interval:word,
				id:fptr.word
				uses si, di, es
	.enter
??START::
	mov	ax, timerType
	mov	bx, destHan
	mov	cx, timerTicks
	mov	dx, meth
	mov	si, destCh
	mov	di, interval
	call	TimerStart

	; store id returned

	tst	id.segment
	jz	done
	les	di, id
	stosw
done:
	mov_tr	ax, bx		; return handle in AX

	.leave
	ret

TIMERSTART	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TimerStop

C DECLARATION:	extern Boolean	/* true if not found */
			_far _pascal TimerStop(TimerHandle th, word id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
TIMERSTOP	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = id

	call	TimerStop

	mov	ax, 0			;assume found
	jnc	done
	dec	ax
done:
	ret

TIMERSTOP	endp

C_Common	ends

;-

C_Local		segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TimerGetDateAndTime

C DECLARATION:	extern void
			_far _pascal TimerGetDateAndTime(TimerDateAndTime
							_far *dateAndTime);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
TIMERGETDATEANDTIME	proc	far
	C_GetOneDWordArg	bx, ax,   cx,dx	;bx = seg, ax = offset

	push	di, es
	mov	es, bx
	mov	di, ax			;es:di = buffer

	call	TimerGetDateAndTime
	call	CSetDateTime

	pop	di, es
	ret

TIMERGETDATEANDTIME	endp

;-
if FULL_EXECUTE_IN_PLACE
CSetDateTime	proc	far
else
CSetDateTime	proc	near
endif
	stosw				;TDAT_year
	clr	ax
	mov	al, bl
	stosw				;TDAT_month
	mov	al, bh
	stosw				;TDAT_day
	mov	al, cl
	stosw				;TDAT_dayOfWeek
	mov	al, ch
	stosw				;TDAT_hours
	mov	al, dl
	stosw				;TDAT_minutes
	mov	al, dh
	stosw				;TDAT_seconds
	ret
CSetDateTime	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TimerSetDateAndTime

C DECLARATION:	extern void
			_far _pascal TimerSetDateAndTime(word flags, const TimerDateAndTime
							_far *dateAndTime);
			Note:The fptr *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
   	PBuck	2/24/95		Fix - get 3 word args and pass flags to asm procedure

------------------------------------------------------------------------------@
TIMERSETDATEANDTIME	proc	far
	C_GetThreeWordArgs	cx, bx, ax, dx
	
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
   	;
EC <		push	cx						>
EC <		push	si						>
EC <		mov	si, ax						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	si						>
EC <		pop	cx						>
endif

	push	si, ds
	mov	ds, bx
	mov	si, ax			;ds:si = buffer

   ; In order to publish this fix, I had to put the guts of
   ; CGetDateTime in here (minus dayOfWeek stuff that's not needed)
   ; PBuck 2/24/95
   ; --------------------------------------------------------------
	lodsw				;TDAT_year
	push	ax
	lodsw				;TDAT_month
	mov	bl, al
	lodsw				;TDAT_day
	mov	bh, al
	lodsw				;TDAT_dayOfWeek (not used)
	lodsw				;TDAT_hours
	mov	ch, al
	lodsw				;TDAT_minutes
	mov	dl, al
	lodsw				;TDAT_seconds
	mov	dh, al
	pop	ax

	pop	si, ds
	call	TimerSetDateAndTime
	ret

TIMERSETDATEANDTIME	endp

;-
if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	segment	resource
CGetDateTime	proc	far
else
CGetDateTime	proc	near
endif
	lodsw				;TDAT_year
	push	ax
	lodsw				;TDAT_month
	mov	bl, al
	lodsw				;TDAT_day
	mov	bh, al
	lodsw				;TDAT_dayOfWeek
	mov	cl, al
	lodsw				;TDAT_hours
	mov	ch, al
	lodsw				;TDAT_minutes
	mov	dl, al
	lodsw				;TDAT_seconds
	mov	dh, al
	pop	ax
	ret
CGetDateTime	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
endif

C_Local		ends

	SetDefaultConvention
