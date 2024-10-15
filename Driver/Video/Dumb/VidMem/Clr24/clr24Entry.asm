COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver
FILE:		clr24Entry.asm

AUTHOR:		Jim DeFrisco, Nov 25, 1991

ROUTINES:
	Name			Description
	----			-----------
	Clr24Entry		entry point for clr24 module
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/25/91	Initial revision


DESCRIPTION:
	This file holds the routine called by DriverStrategy in the main
	module of VidMem
		

	$Id: clr24Entry.asm,v 1.1 97/04/18 11:43:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Clr24Entry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for clr24 module

CALLED BY:	DriverStrategy

PASS:		di		- function number to call

RETURN:		depends on routine called

DESTROYED:	probably everything

PSEUDO CODE/STRATEGY:
		call the routine
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Clr24Entry	proc	far
		ForceRef Clr24Entry
EC <		tst	di				>
EC <		js	funcOK				>
EC <		tst	cs:[driverJumpTable][di]	; if zero, we're hosed>
EC <		ERROR_Z VIDMEM_BAD_MODULE_CALL				      >
EC <funcOK:						>

		PSem	cs, videoSem

		; before we call away, store away some important info about
		; the bitmap header location and the size of a scan line

		push	ax, cx, ds
		mov	ds, es:[W_bmSegment]		; store bitmap segment
		mov	cs:[bm_segment], ds		; for local use
		mov	ax, es:[W_bitmap].segment
		mov	cs:[bm_handle].segment, ax
		mov	ax, es:[W_bitmap].offset
		mov	cs:[bm_handle].offset, ax
		mov	al, ds:[EB_bm].CB_simple.B_type
		mov	cx, ds:[EB_bm].CB_simple.B_width
		cmp	al, cs:[bm_cacheType]		; if not same, recalc
		jne	recalcWidth
		cmp	cx, cs:[bm_cacheWid]
		jne	recalcWidth
rejoinEntry:
		pop	ax, cx, ds
		tst	di
		js	handleEscape
		call	cs:[driverJumpTable][di]
done:
		VSem	cs, videoSem
		ret

		; we want to record in a local variable, the size of a scan
		; line (in bytes).  
recalcWidth:
		clr	cs:[bm_dataOffset]
		mov	cs:[bm_cacheType], al		; store new cached vals
		mov	cs:[bm_cacheWid], cx
		mov	cs:[bm_bpScan], cx		; store this
		shl	cx, 1
		add	cs:[bm_bpScan], cx		; 3* for 3 8-bit planes
		shr	cx, 1				; # of pixels -> cx
		push	cx
		shr	cx				; calc #bytes
		shr	cx				; calc #bytes
		shr	cx				; calc #bytes
		mov	cs:[bm_bpMaskRndDwn], cx	; # bytes, rounded down
		pop	cx
		push	cx
		and	cx, 7				; determine number of
		mov	cs:[bm_nonIntegralPixels], cx	; ..non-integral pixels
		pop	cx
		add	cx, 7				; round up
		shr	cx				; calc #bytes
		shr	cx				; calc #bytes
		shr	cx				; calc #bytes
		mov	cs:[bm_bpMask], cx		;  code
		test	al, mask BMT_MASK		; * 2 if mask
		jz	haveWidth
		mov	cs:[bm_dataOffset], cx
		add	cs:[bm_bpScan], cx
haveWidth:
		jmp	rejoinEntry

		; call an escape function
handleEscape:
		call	Clr24Escape
		jmp	done

Clr24Entry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Clr24Escape
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
	Jim	05/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Clr24Escape	proc	near
		push	di		; save a few regs
		push	cx
		push	ax
		push	es		
		segmov	es, cs, cx	; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset clr24group:escCodes ; si -> esc code tab
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
Clr24Escape	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Clr24MaskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A utility routine that calculates some variables about the
		bitmap and returns

CALLED BY:	DriverStrategy
PASS:		es	- locked window
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		calc values and place them in a shared memory space (in dgroup)
		This routine also P's a semaphore to protect those variables, 
		which is later V'd in the Mono module before the mask is 
		actually edited

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Clr24MaskInfo	proc	far
		uses	ax,bx,cx,dx,ds,es
		.enter

		; load up a pointer to the bitmap

		mov	ds, es:[W_bmSegment]		; store bitmap segment
		mov	ax, dgroup			; gain access to shared
		mov	es, ax				;   es-> dgroup   vars

		; protect the variables in dgroup.  This semaphore will be 
		; V'd later when the bitmap mask is edited in the Mono module.

		PSem	es, maskInfoSem			; provide protection
		mov	al, ds:[EB_bm].CB_simple.B_type
		mov	es:[maskType], al
		mov	cx, ds:[EB_bm].CB_simple.B_width
		mov	es:[maskWidth], cx

		; now calculate what we came here for

		clr	es:[maskMaskSize]
		mov	dx, cx				; store this
		shl	cx, 1
		add	dx, cx				; 3* for 3 8-bit planes
		test	al, mask BMT_MASK		; * 2 if mask
		jz	haveWidth
		shr	cx, 1				; assume not that big
		add	cx, 7				; round up
		shr	cx				; calc #bytes
		shr	cx				; calc #bytes
		shr	cx				; calc #bytes
		mov	es:[maskMaskSize], cx
		add	dx, cx
haveWidth:
		mov	es:[maskScanSize], dx		; store scan line wid
		.leave
		ret
Clr24MaskInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Clr24CallMod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call into another clr24 module

CALLED BY:	Clr24Entry

PASS:		di	- function number

RETURN:		depends on routine

DESTROYED:	probably everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Clr24CallMod	proc	near

		; first, save away ax/bx since they are trashed by CallMod

		mov	cs:[TPD_dataAX], ax		; trashed by CallMod
		mov	cs:[TPD_dataBX], bx

		; next, switch stacks so we still have access to 
		; NOTE: the loading of ss *must* be followed by the loading
		; of sp.

		mov	cs:[saveSS], ss			; save caller's stack
		mov	cs:[saveSP], sp
		mov	bx, ss:[TPD_threadHandle]
		mov	cs:[TPD_threadHandle], bx

;	Copy over TPD_dgroup and TPD_classPointer, because VMDirty is called
;	by the vidmem code, and if a dirty notification needs to be sent to
;	the current thread, it will need to look things up in TPD_classPointer
;	6/18/96 - atw

		mov	bx, ss:[TPD_dgroup]
		mov	cs:[TPD_dgroup], bx
		mov	bx, ss:[TPD_classPointer].segment
		mov	cs:[TPD_classPointer].segment, bx
		mov	bx, ss:[TPD_classPointer].offset
		mov	cs:[TPD_classPointer].offset, bx
		mov	bx, ss:[TPD_processHandle]
		mov	cs:[TPD_processHandle], bx

		mov	bx, {word}ss:[TPD_exclFSIRLocks]
		mov	{word}cs:[TPD_exclFSIRLocks], bx
		mov	ax, cs				; setup new stack
		mov	ss, ax
		mov	sp, offset clr24group:endVidStack
		mov	ss:[TPD_stackBot], offset clr24group:vidStackBot
		mov	ss:[TPD_blockHandle], handle clr24group

		; done with setup.  Load up ax/bx to call ProcCallModule...

		shl	di, 1				; into word table
		mov	ax, cs:[moduleTable][di].offset	; grab offset
		mov	bx, cs:[moduleTable][di].segment
		call	ProcCallFixedOrMovable

		; done with operation, restore stack and exit

		mov	ss, cs:[saveSS]			; restore old stack
		mov	sp, cs:[saveSP]
		ret
Clr24CallMod	endp
