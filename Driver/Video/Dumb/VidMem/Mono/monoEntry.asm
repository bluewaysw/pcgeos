COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver
FILE:		monoEntry.asm

AUTHOR:		Jim DeFrisco, Nov 25, 1991

ROUTINES:
	Name			Description
	----			-----------
	MonoEntry		entry point for mono module
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/25/91	Initial revision


DESCRIPTION:
	This file holds the routine called by DriverStrategy in the main
	module of VidMem
		

	$Id: monoEntry.asm,v 1.1 97/04/18 11:42:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonoEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for mono module

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
MonoEntry	proc	far
		ForceRef MonoEntry
EC <		tst	di				; check for esc code>
EC <		js	funcOK				; >
EC <		tst	cs:[driverJumpTable][di]	; if zero, we're hosed>
EC <		ERROR_Z VIDMEM_BAD_MODULE_CALL				      >
EC <funcOK:								>
		;
		; Setup fs to point at the video driver's group
		; and gs to point to an alias to the code
		;
		push	fs, gs
		segmov	fs, monogroup
		tst	fs:aliasToCode
		jz	getAlias
gotAlias:
		mov	gs, fs:aliasToCode
		
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
		mov	ax, ds:[EB_flags]		; need to store this
		mov	fs:[bm_flags], ax		;  for later
		mov	ax, ds:[EB_color]
		mov	fs:[colorTransfer], ax
		mov	al, ds:[EB_bm].CB_simple.B_type
		mov	cx, ds:[EB_bm].CB_simple.B_width
		cmp	fs:[bm_editedMask], 0		; if edit mask last,
		jne	recalcWidth			;  then recalc things
		cmp	al, fs:[bm_cacheType]		; if not same, recalc
		jne	recalcWidth
		cmp	cx, fs:[bm_cacheWid]
		jne	recalcWidth

		; check the flag that determines if we are drawing to the 
		; mask or to the data, and store the appropriate offset
rejoinEntry:
		pop	ax, cx, ds
		tst	di				; handle escape diff
		js	handleEscape
		call	cs:[driverJumpTable][di]
done:
		VSem	fs, videoSem
exit:
		pop	fs, gs
		ret

		; Create an alias to our code segment so we can
		; do self-modifying code.
getAlias:
		push	bx
		mov	bx, cs
		call	SysAllocCodeAlias
		jc	skipSet
		mov	fs:aliasToCode, bx
skipSet:
		pop	bx
		jc	exit
		jmp	gotAlias

		; call an escape function
handleEscape:
		call	MonoEscape
		jmp	done

		; we want to record in a local variable, the size of a scan
		; line (in bytes).  
recalcWidth:
		clr	fs:[bm_dataOffset]		; assume no mask
		mov	fs:[bm_cacheType], al		; store new cached vals
		mov	fs:[bm_cacheWid], cx
		add	cx, 7				; round up
		shr	cx, 1				; divide by 8
		shr	cx, 1
		shr	cx, 1
		mov	fs:[bm_bpMask], cx		; store scan line wid
		test	al, mask BMT_MASK		; * 2 if mask
		jz	haveWidth
		mov	fs:[bm_dataOffset], cx		; offset to data
		shl	cx, 1
haveWidth:
		mov	fs:[bm_bpScan], cx		; store scan line wid
		clr	fs:[bm_editedMask]		; reset flag
		jmp	rejoinEntry

MonoEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonoEscape
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

MonoEscape	proc	near
		push	di		; save a few regs
		push	cx
		push	ax
		push	es		
		segmov	es, cs, cx	; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset Mono:escCodes ; si -> esc code tab
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
MonoEscape	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonoMaskInfo
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
MonoMaskInfo	proc	far
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
		add	cx, 7				; round up
		shr	cx, 1				; divide by 8
		shr	cx, 1
		shr	cx, 1
		test	al, mask BMT_MASK		; * 2 if mask
		jz	haveWidth
		mov	es:[maskMaskSize], cx		; store scan line wid
		shl	cx, 1
haveWidth:
		mov	es:[maskScanSize], cx		; store scan line wid

		.leave
		ret
MonoMaskInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonoEditMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This entry point is called isntead of MonoEntry when the 
		*mask* of the bitmap is to be edited instead of the picture
		data. 

CALLED BY:	DriverStrategy
PASS:		es	- window
		some variables in dgroup, plus the normal ones for this call
RETURN:		nothing
DESTROYED:	probably everything

PSEUDO CODE/STRATEGY:
		stuff our local variables with the info in dgroup, 
		release the semaphore protecting the dgroup vars,
		do our normal call stuff

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MonoEditMask	proc	far
		push	fs,gs
		segmov	fs, monogroup
		tst	fs:aliasToCode
		jz	getAlias
gotAlias:
		mov	gs, fs:aliasToCode
		push	ax,bx,cx,dx,ds
		mov	ax, dgroup		; gain access to variables
		mov	ds, ax			; ds -> dgroup
		mov	al, ds:[maskType]	; fetch the variables
		mov	bx, ds:[maskWidth]
		mov	cx, ds:[maskScanSize]
		mov	dx, ds:[maskMaskSize]
		VSem	ds, maskInfoSem		; release semaphore
						;  (P'd in XXXMaskInfo call)
		
		; now do the normal work of entering the video driver

		PSem	fs, videoSem		; get our own semaphore
		mov	fs:[bm_cacheType], al	; save vars
		mov	fs:[bm_cacheWid], bx
		mov	fs:[bm_bpScan], cx
		mov	fs:[bm_bpMask], dx	; right side of scan line
		clr	fs:[bm_dataOffset]	; editing mask

		; while we have some regs free, grab the other vars

		mov	ds, es:[W_bmSegment]	; store bitmap segment
		mov	fs:[bm_segment], ds	; for local use
		mov	ax, es:[W_bitmap].segment
		mov	fs:[bm_handle].segment, ax
		mov	ax, es:[W_bitmap].offset
		mov	fs:[bm_handle].offset, ax
		mov	ax, ds:[EB_flags]	; need to store this
		mov	fs:[bm_flags], ax	;  for later
		mov	fs:[bm_editedMask], 0xff ; set flag
		pop	ax,bx,cx,dx,ds
		call	cs:[driverJumpTable][di]
		VSem	fs, videoSem
exit:
		pop	fs,gs
		ret

		; Create an alias to our code segment so we can
		; do self-modifying code.
getAlias:
		push	bx
		mov	bx, cs
		call	SysAllocCodeAlias
		jc	skipSet
		mov	fs:aliasToCode, bx
skipSet:
		pop	bx
		jc	exit
		jmp	gotAlias
MonoEditMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonoCallMod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call into another mono module

CALLED BY:	MonoEntry

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
MonoCallMod	proc	near

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
		mov	ax, fs				; setup new stack
		mov	ss, ax
		mov	sp, offset monogroup:endVidStack
		mov	ss:[TPD_stackBot], offset monogroup:vidStackBot
		mov	ss:[TPD_blockHandle], handle monogroup

		; done with setup.  Load up ax/bx to call ProcCallModule...

		shl	di, 1				; into word table
		mov	ax, cs:[moduleTable][di].offset	; grab offset
		mov	bx, cs:[moduleTable][di].segment
		call	ProcCallFixedOrMovable

		; done with operation, restore stack and exit

		mov	ss, fs:[saveSS]			; restore old stack
		mov	sp, fs:[saveSP]
		ret
MonoCallMod	endp
