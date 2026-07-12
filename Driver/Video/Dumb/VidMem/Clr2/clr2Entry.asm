COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2Entry.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	This file holds the routine called by DriverStrategy in the main
	module of VidMem

	$Id: clr2Entry.asm,v 1.1 97/04/18 11:43:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Clr2Entry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for clr2 module

CALLED BY:	DriverStrategy

PASS:		di	= function number to call

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
Clr2Entry	proc	far
		ForceRef	Clr2Entry

EC <		tst	di				; check for escape    >
EC <		js	funcOK				; 		      >
EC <		tst	cs:[driverJumpTable][di]	; if zero, we're hosed>
EC <		ERROR_Z VIDMEM_BAD_MODULE_CALL				      >
EC <funcOK:								      >

		PSem	fs, videoSem

		; before we call away, store away some important info about
		; the bitmap header location and the size of a scan line

		push	ax, cx, ds
		mov	ds, es:[W_bmSegment]		; store bitmap segment
		mov	fs:[bm_segment], ds		; for local use
		mov	ax, es:[W_bitmap].segment
		mov	fs:[bm_handle].segment, ax
		mov	ax, es:[W_bitmap].offset
		mov	fs:[bm_handle].offset, ax
		mov	al, ds:[EB_bm].CB_simple.B_type
		mov	cx, ds:[EB_bm].CB_simple.B_width
		cmp	al, fs:[bm_cacheType]		; if not same, recalc
		jne	recalcWidth
		cmp	cx, fs:[bm_cacheWid]
		jne	recalcWidth
rejoinEntry:
		pop	ax, cx, ds
		tst	di
		js	handleEscape
		call	cs:[driverJumpTable][di]
done:
		VSem	fs, videoSem
		ret

		; we want to record in a local variable, the size of a scan
		; line (in bytes).  
recalcWidth:
		clr	fs:[bm_dataOffset]
		mov	fs:[bm_cacheType], al		; store new cached vals
		mov	fs:[bm_cacheWid], cx
		inc	cx				; round up
		shr	cx, 1				; divide by 2
		mov	fs:[bm_bpScan], cx		; store this
		mov	cx, fs:[bm_cacheWid]		; need to calc mask
		add	cx, 7				; round up
		shr	cx, 1				; calc #bytes
		shr	cx, 1
		shr	cx, 1
		mov	fs:[bm_bpMask], cx		; save for char code
		test	al, mask BMT_MASK		; * 2 if mask
		jz	haveWidth
		mov	fs:[bm_dataOffset], cx		; where to start
		add	fs:[bm_bpScan], cx
haveWidth:
		jmp	rejoinEntry

		; call an escape function
handleEscape:
		call	Clr2Escape
		jmp	done

Clr2Entry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Clr2Escape
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
Clr2Escape	proc	near
		push	di		; save a few regs
		push	cx
		push	ax
		push	es		
		segmov	es, cs, cx	; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset clr2group:escCodes ; si -> esc code tab
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
Clr2Escape	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Clr2MaskInfo
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
Clr2MaskInfo	proc	far
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
		inc	dx				; round up
		shr	dx, 1				; divide by 2
		test	al, mask BMT_MASK		; * 2 if mask
		jz	haveWidth
		add	cx, 7				; round up
		shr	cx, 1				; calc #bytes
		shr	cx, 1
		shr	cx, 1
		mov	es:[maskMaskSize], cx		; where to start
		add	dx, cx
haveWidth:
		mov	es:[maskScanSize], dx		; store scan line wid

		.leave
		ret
Clr2MaskInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Clr2CallMod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call into another clr2 module

CALLED BY:	Clr2Entry

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
Clr2CallMod	proc	near

		; first, save away ax/bx since they are trashed by CallMod

		mov	fs:[TPD_dataAX], ax		; trashed by CallMod
		mov	fs:[TPD_dataBX], bx

		; next, switch stacks so we still have access to 
		; NOTE: the loading of ss *must* be followed by the loading
		; of sp.

		mov	fs:[saveSS], ss			; save caller's stack
		mov	fs:[saveSP], sp
		mov	bx, ss:[TPD_threadHandle]
		mov	fs:[TPD_threadHandle], bx

;	Copy over TPD_dgroup and TPD_classPointer, because VMDirty is called
;	by the vidmem code, and if a dirty notification needs to be sent to
;	the current thread, it will need to look things up in TPD_classPointer
;	6/18/96 - atw

		mov	bx, ss:[TPD_dgroup]
		mov	fs:[TPD_dgroup], bx
		mov	bx, ss:[TPD_classPointer].segment
		mov	fs:[TPD_classPointer].segment, bx
		mov	bx, ss:[TPD_classPointer].offset
		mov	fs:[TPD_classPointer].offset, bx
		mov	bx, ss:[TPD_processHandle]
		mov	fs:[TPD_processHandle], bx

		mov	bx, {word}ss:[TPD_exclFSIRLocks]
		mov	{word}fs:[TPD_exclFSIRLocks], bx
		mov	ax, cs				; setup new stack
		mov	ss, ax
		mov	sp, offset clr2group:endVidStack
		mov	ss:[TPD_stackBot], offset clr2group:vidStackBot
		mov	ss:[TPD_blockHandle], handle clr2group

		; done with setup.  Load up ax/bx to call ProcCallModule...

		shl	di, 1				; into word table
		mov	ax, cs:[moduleTable][di].offset	; grab offset
		mov	bx, cs:[moduleTable][di].segment
		call	ProcCallFixedOrMovable

		; done with operation, restore stack and exit

		mov	ss, fs:[saveSS]			; restore old stack
		mov	sp, fs:[saveSP]
		ret
Clr2CallMod	endp
