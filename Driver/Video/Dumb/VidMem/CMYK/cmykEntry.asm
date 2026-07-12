COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver
FILE:		cmykEntry.asm

AUTHOR:		Jim DeFrisco, Nov 25, 1991

ROUTINES:
	Name			Description
	----			-----------
    INT CMYKEntry		Entry point for cmyk module
    INT CMYKMaskInfo		A utility routine that calculates some
				variables about the bitmap and returns
    INT CMYKCallMod		Call into another cmyk module

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/25/91	Initial revision


DESCRIPTION:
	This file holds the routine called by DriverStrategy in the main
	module of VidMem
		

	$Id: cmykEntry.asm,v 1.1 97/04/18 11:43:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for cmyk module

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
CMYKEntry	proc	far
		ForceRef CMYKEntry
EC <		tst	di				>
EC <		js	funcOK				>
EC <		tst	cs:[driverJumpTable][di]	; if zero, we're hosed>
EC <		ERROR_Z VIDMEM_BAD_MODULE_CALL				      >
EC <funcOK:						>

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
		mov	ax, ds:[EB_flags]
		mov	fs:[bm_flags], ax
		mov	ax, ds:[EB_color]
		mov	fs:[colorTransfer], ax
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
		mov	fs:[bm_cacheType], al		; store new cached vals
		mov	fs:[bm_cacheWid], cx
		add	cx, 7				; round up
		shr	cx, 1				; divide by 8
		shr	cx, 1
		shr	cx, 1
		mov	fs:[bm_bpMask], cx		; store for char code
		test	al, mask BMT_MASK		; * 2 if mask
		mov	ax, 0				; DON'T USE CLR
		jz	haveWidth
		mov	ax, cx
haveWidth:
		shl	cx, 1				; 4 planes 
		shl	cx, 1
		add	cx, ax				; add in mask size
		mov	fs:[bm_bpScan], cx		; store scan line wid
		jmp	rejoinEntry


		; call an escape function
handleEscape:
		call	CMYKEscape
		jmp	done

CMYKEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKEscape
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

CMYKEscape	proc	near
		push	di		; save a few regs
		push	cx
		push	ax
		push	es		
		segmov	es, cs, cx	; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset cmykcode:escCodes ; si -> esc code tab
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
CMYKEscape	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKMaskInfo
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
CMYKMaskInfo	proc	far
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
		mov	dx, cx
		clr	cx
		add	dx, 7				; round up
		shr	dx, 1				; divide by 8
		shr	dx, 1
		shr	dx, 1
		test	al, mask BMT_MASK		; * 2 if mask
		jz	haveWidth
		mov	cx, dx
		mov	es:[maskMaskSize], dx
haveWidth:
		shl	dx, 1				; 4 planes 
		shl	dx, 1
		add	dx, cx				; add in mask size
		mov	es:[maskScanSize], dx		; store scan line wid

		.leave
		ret
CMYKMaskInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKCallMod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call into another cmyk module

CALLED BY:	CMYKEntry

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
CMYKCallMod	proc	near

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
		mov	sp, offset cmykgroup:endVidStack
		mov	ss:[TPD_stackBot], offset cmykgroup:vidStackBot
		mov	ss:[TPD_blockHandle], handle cmykgroup

		; done with setup.  Load up ax/bx to call ProcCallModule...

		shl	di, 1				; into word table
		mov	ax, cs:[moduleTable][di].offset	; grab offset
		mov	bx, cs:[moduleTable][di].segment
		call	ProcCallFixedOrMovable

		; done with operation, restore stack and exit

		mov	ss, fs:[saveSS]			; restore old stack
		mov	sp, fs:[saveSP]
		ret
CMYKCallMod	endp




