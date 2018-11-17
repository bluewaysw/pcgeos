COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video drivers
FILE:		vidcomEntry.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	DriverStrategy		entry point to driver
	VidStartExclusive	Enter into exclusive use
	VidEndExclusive		Finished with exclusive use
	VidInfo			Return address of info block
	VidEscape		Generalized escape function

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	5/88	initial verison

DESCRIPTION:
	This file contains the entry point routine for the video drivers,
	the driver jump table and local driver variables
		
	$Id: vidcomEntry.asm,v 1.1 97/04/18 11:41:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

NT <include Internal/winnt.def>

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriverStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all video display driver calls

CALLED BY:	KERNEL

PASS:		[di] - offset into driver function table

RETURN:		see individual routines

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		call function thru the jump table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88...	Initial version of strategy routine
	Jim	10/88		Modified for video drivers
	Jim	5/89		Modified to add escape capability

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

DriverStrategy	proc	far

		; if no device has been set, just exit, but allow standard
		; extended-driver calls through...

		cmp	di, first VidFunction
		jb	haveDevEnum

		;
		; Don't do anything if not yet initialized
		;

		cmp	cs:[DriverTable].VDI_device, 0xffff
		je	exit

haveDevEnum:
		cmp	di, DR_VID_LAST_NON_SEMAPHORE
		jbe	noSemaphoreRequired	; branch seldom taken...

		; check if we need to obey the exclusive flag...

		cmp	di,DR_VID_LAST_NON_EXCLUSIVE
		jbe	callFunctionWithSemaphore	;  no, continue

		cmp	di, DR_VID_LAST_FUNCTION	; escape code?
		ja	callFunctionWithSemaphore	; yes, no excl
	;
	; If the exclusive flag is our life, first see if any exclusive
	; has been set (exclusiveGstate is non-zero). Only if it is do we
	; compare it against ds:[LMBH_handle]. (don't use cx here, though
	; a jcxz is tempting, as we can recover ax and interrupts easily
	; and do a jnz in both cases to deal with either there being no
	; exclusive or the gstate being the one with the exclusive).
	; 
		push	ax
		INT_OFF
		mov	ax, cs:[exclusiveGstate]
		tst	ax
		jz	noExclusive
		cmp	ax, ds:[GS_header].LMBH_handle
		je	noExclusive
		mov	cs:[exclusiveCausedAbort], TRUE
		pop	ax

		push	ds
		segmov	ds, cs				; ds -> vars
		call	VidExclBounds			; in Exclusive module
		pop	ds
		INT_ON
		cmp	di, DR_VID_PUTSTRING
		jne	exit
	    ;
	    ; XXX: Gross hack for DR_VID_PUTSTRING, being the only output
	    ; operation that returns something.
	    ; 
		mov	bp, cx		; must return font segment in bp
		jmp	exit

noExclusive:
		INT_ON
		pop	ax

callFunctionWithSemaphore:

		; check for VID_ESCAPE codes

		or	di, di			; is it an escape ?
		js	DS_escape		;  yes, do escape function

		FastPSem1	cs, videoSem, DS_P3, DS_P4
		call	cs:[driverJumpTable][di] ; dispatch the function
		FastVSem1	cs, videoSem, DS_V3, DS_V4
exit:
		ret

		;****************************************************

		; don't need any semaphore,  just call the darn thing
noSemaphoreRequired:
		call	cs:[driverJumpTable][di] ; dispatch the function
		ret

		; escape code
DS_escape:
		call	VidEscape
		ret

;----------------------------

		FastPSem2	cs, videoSem, DS_P3, DS_P4
		FastVSem2	cs, videoSem, DS_V3, DS_V4

DriverStrategy	endp
		public	DriverStrategy

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidStartExclusive

DESCRIPTION:	Start exclusive access to the driver

CALLED BY:	INTERNAL
		DriverStrategy

PASS:
	bx - graphics state handle

RETURN:
	nothing

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

VidStartExclusive	proc	near
	INT_OFF		; ensure atomic update of bounds... -- ardeb 4/27/93
	mov	cs:[exclusiveGstate], bx
	mov	cs:[exclBound].R_left, MAX_COORD
	mov	cs:[exclBound].R_right, MIN_COORD
	mov	cs:[exclBound].R_top, MAX_COORD
	mov	cs:[exclBound].R_bottom, MIN_COORD
	INT_ON
	ret
VidStartExclusive	endp
	public	VidStartExclusive

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidEndExclusive

DESCRIPTION:	End exclusive access to the driver

CALLED BY:	INTERNAL
		DriverStrategy

PASS:		bx	= gstate that supposedly had the exclusive

RETURN:		ax	= non-zero if some output operation was aborted
			  during that gstate's tenure as the exclusive
		si,di,cx,dx - bounds of rectangle to invalidate, if ax != 0
DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

VidEndExclusive	proc	near
	INT_OFF
	clr	ax				; assume wasn't exclusive =>
						;  couldn't have caused an
						;  abort
	cmp	cs:[exclusiveGstate], bx	; is this the exclusive?
	jne	done				; no => do nothing
	mov	cs:[exclusiveGstate], ax	; set exclusive to 0
	xchg	cs:[exclusiveCausedAbort], ax	; fetch abort flag and reset
	tst	ax				; if there was an abort, done
	jz	done
	mov	si, cs:[exclBound].R_left
	mov	di, cs:[exclBound].R_top
	mov	cx, cs:[exclBound].R_right
	mov	dx, cs:[exclBound].R_bottom
done:
	INT_ON
	ret
VidEndExclusive	endp
	public	VidEndExclusive


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidGetExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the handle of the GState with the current exclusive

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		bx	- GState handle for GState with exclusive, or
			  zero if nothing has exclusive access
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidGetExclusive		proc	near
		.enter
		mov	bx, cs:[exclusiveGstate]
		.leave
		ret
VidGetExclusive		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a pointer to the driver info block

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		dx:si	- pointer to DriverInfo block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just stuff the table address;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The memory driver may want to do something special, since 
		it may keep a separate table for each user;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	05/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	VidInfo
VidInfo	proc	near
	mov	dx, cs			      ; set segment to current code seg
	mov	si, offset dgroup:DriverTable ; get offset
	ret
VidInfo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute some escape function

CALLED BY:	GLOBAL

PASS:		di	- escape code (ORed with 8000h)

RETURN:		di	- set to 0 if escape not supported
			- return unchanged if handled

DESTROYED:	see individual functions

PSEUDO CODE/STRATEGY:
		scan through the table, find the code, call the handler.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	05/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	VidEscape
VidEscape	proc	near
		push	di		; save a few regs
		push	cx
		push	ax
		push	es		
		segmov	es, cs, cx	; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset dgroup:escCodes ; si -> esc code tab
		mov	cx, NUM_ESC_ENTRIES ; init rep count
		repne	scasw		; find the right one
		pop	es
		pop	ax
		jne	VE_notFound	;  not in table, quit

		; function is supported, call through vector

		pop	cx
		call	cs:[di+((offset escRoutines)-(offset escCodes)-2)]
		pop	di
		ret

		; function not supported, return di==0
VE_notFound:
		pop	cx		; restore stack
		pop	di
		clr	di		; set return value
		ret
VidEscape	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidCallMod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to call into another module

CALLED BY:	INTERNAL
		DriverStrategy

PASS:		di	- function number

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		switch stacks, save necc variables, call into other module.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		; dash fill module also needs polygon code
dashfillLocks:
		push	ax
		mov	bx, vseg VideoPolygon
		call	MemLockFixedOrMovable
EC <		ERROR_C	LOCK_RETURNED_ERROR	;can't happen :) >
		pop	ax
		jmp	modsLocked

		; calling VidPutLine.  Need to lock both the bitmap and
		; line modules as well
putlineLocks:
		push	ax			; save Putline segment
		mov	bx, vseg VideoBitmap
		call	MemLockFixedOrMovable	; lock the block
EC <		ERROR_C	LOCK_RETURNED_ERROR	;can't happen :) >

		mov	bx, vseg VideoLine
		call	MemLockFixedOrMovable
EC <		ERROR_C	LOCK_RETURNED_ERROR	;can't happen :) >
		pop	ax
		jmp	modsLocked

		; need to lock more modules, maybe.
lockAdditional	label	near
		je	putlineLocks		
		cmp	di, DR_VID_DASH_FILL*2
		je	dashfillLocks
		cmp	di, DR_VID_POLYGON*2
		jne	modsLocked

		; polygon code needs line module

		push	ax
		mov	bx, vseg VideoLine
		call	MemLockFixedOrMovable
EC <		ERROR_C	LOCK_RETURNED_ERROR	;can't happen :) >
		pop	ax
		jmp	modsLocked

VidCallMod	proc	near

		; give up the videoSem, while we try and lock the block. 
		; This will allow SysNotify to work if we happen to fault
		; while loading in the module we are calling.

		VSem	cs, videoSem

		; before we switch stacks or write to any ThreadPrivateData
		; or any dgroup variables we need to have the videoSem.  So
		; locking the block is the first order of business.  Lock
		; the main one, then check for the case where two (or three)
		; modules need to be locked (yuck).
		;	
		; The functions that need extra modules locked are:
		;	PutLine		- also needs Bitmap, Line
		;	DashFill	- also needs Polygon
		;	Polygon		- also needs Line

		push	ax
		push	bx				; save regs we trash
		shl	di, 1				; function# * 2
		mov	bx, cs:[moduleTable][di].segment ; load virtual seg
		call	MemLockFixedOrMovable
EC <		ERROR_C	LOCK_RETURNED_ERROR	;can't happen :) >
		cmp	di, DR_VID_PUTLINE*2		; check for extra...
		jae	lockAdditional

		; now that the modules are safely locked, re-P the semaphore
		; and continue.
modsLocked	label	near
		PSem	cs, videoSem

		; restore the original values of ax,bx where we will be able
		; to use them later.

		pop	cs:[TPD_dataBX]
		pop	cs:[TPD_dataAX]			; trashed by CallMod

		; next, switch stacks so we still have access to dgroup
		; NOTE: the loading of ss *must* be followed by the loading
		; of sp.

		mov	cs:[saveSS], ss			; save caller's stack
		mov	cs:[saveSP], sp
		mov	bx, ss:[TPD_threadHandle]
		mov	cs:[TPD_threadHandle], bx
		mov	bx, {word}ss:[TPD_exclFSIRLocks]
		mov	{word}cs:[TPD_exclFSIRLocks], bx
		mov	bx, dgroup			; setup new stack
		mov	ss, bx
		mov	sp, offset dgroup:endVidStack

		; done with setup.  ax holds the segment of the routine to
		; call.  Push a return address and the calling address and 
		; fire away...

		push	di			; save function number
		push	cs			; push return address
		mov	bx, offset restoreStack
		push	bx
		push	ax			; push segment of routine
		push	cs:[moduleTable][di].offset ; push routine offset
		mov	ax, cs:[TPD_dataAX]
		mov	bx, cs:[TPD_dataBX]
		retf				; call routine

		; done with operation.  unlock modules.
restoreStack:

		pop	di			; restore function number
		mov	bx, cs:[moduleTable][di].segment
		call	MemUnlockFixedOrMovable	; unlock module we called
		cmp	di, DR_VID_PUTLINE*2		; check for extra...
		jae	unlockAdditional
modsUnlocked:
		mov	ss, cs:[saveSS]			; restore old stack
		mov	sp, cs:[saveSP]
		ret

		; need the same type of code to unlock the extra mods.
unlockAdditional:
		je	putlineUnlocks		
		cmp	di, DR_VID_DASH_FILL*2
		je	dashfillUnlocks
		cmp	di, DR_VID_POLYGON*2
		jne	modsUnlocked

		; polygon code needs line module
polygonUnlocks:
		mov	bx, vseg VideoLine
		call	MemUnlockFixedOrMovable
		jmp	modsUnlocked
dashfillUnlocks:
		mov	bx, vseg VideoPolygon
		call	MemUnlockFixedOrMovable
		jmp	modsUnlocked
putlineUnlocks:
		mov	bx, vseg VideoBitmap
		call	MemUnlockFixedOrMovable
		jmp	polygonUnlocks
VidCallMod	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidCallModNoSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as VidCallMod, but videoSem not down

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		di	- VidFunction
RETURN:		depends on routine called
DESTROYED:	depends on routine called

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidCallModNoSem		proc	near
		; first, save away ax/bx since they are trashed by CallMod

		mov	cs:[TPD_dataAX], ax		; trashed by CallMod
		mov	cs:[TPD_dataBX], bx

		; next, switch stacks so we still have access to dgroup
		; NOTE: the loading of ss *must* be followed by the loading
		; of sp.

		mov	cs:[saveSS], ss			; save caller's stack
		mov	cs:[saveSP], sp
		mov	bx, ss:[TPD_threadHandle]
		mov	cs:[TPD_threadHandle], bx
		mov	bx, {word}ss:[TPD_exclFSIRLocks]
		mov	{word}cs:[TPD_exclFSIRLocks], bx
NT <		mov	bx, ss:[TPD_curPath]				>
NT <		mov	cs:[TPD_curPath], bx				>
		mov	ax, dgroup			; setup new stack
		mov	ss, ax
		mov	sp, offset dgroup:endVidStack

		; done with setup.  Load up ax/bx to call ProcCallModule...

		shl	di, 1				; into word table
		mov	ax, cs:[moduleTable][di].offset	; grab offset
		mov	bx, cs:[moduleTable][di].segment
		call	ProcCallFixedOrMovable

		; done with operation, restore stack and exit

		mov	ss, cs:[saveSS]			; restore old stack
		mov	sp, cs:[saveSP]
		ret
VidCallModNoSem		endp
