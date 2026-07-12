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
		;
		; Setup fs to point at the video driver's group
		; and gs to point to an alias to the code (for self modifying
		; code or ends up being the VideoCode segment handler)
		;   -- lshields 12/5/2000
		;
		push	fs, gs
		segmov	fs, dgroup
		mov	gs, fs:aliasToCode
		; if no device has been set, just exit, but allow standard
		; extended-driver calls through...

		cmp	di, first VidFunction
		jb	haveDevEnum

		;
		; Don't do anything if not yet initialized
		;

		cmp	fs:[DriverTable].VDI_device, 0xffff
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
		mov	ax, fs:[exclusiveGstate]
		tst	ax
		jz	noExclusive
		cmp	ax, ds:[GS_header].LMBH_handle
		je	noExclusive
		mov	fs:[exclusiveCausedAbort], TRUE
		pop	ax

		push	ds
		segmov	ds, fs				; ds -> vars
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

		FastPSem1	fs, videoSem, DS_P3, DS_P4
		call	fs:[driverJumpTable][di] ; dispatch the function
		FastVSem1	fs, videoSem, DS_V3, DS_V4
exit:
		pop	fs, gs
		ret

		;****************************************************

		; don't need any semaphore,  just call the darn thing
noSemaphoreRequired:
		call	fs:[driverJumpTable][di] ; dispatch the function
		jmp	exit

		; escape code
DS_escape:
		call	VidEscape
		jmp	exit

;----------------------------

		FastPSem2	fs, videoSem, DS_P3, DS_P4
		FastVSem2	fs, videoSem, DS_V3, DS_V4

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
	mov	fs:[exclusiveGstate], bx
	mov	fs:[exclBound].R_left, MAX_COORD
	mov	fs:[exclBound].R_right, MIN_COORD
	mov	fs:[exclBound].R_top, MAX_COORD
	mov	fs:[exclBound].R_bottom, MIN_COORD
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
	cmp	fs:[exclusiveGstate], bx	; is this the exclusive?
	jne	done				; no => do nothing
	mov	fs:[exclusiveGstate], ax	; set exclusive to 0
	xchg	fs:[exclusiveCausedAbort], ax	; fetch abort flag and reset
	tst	ax				; if there was an abort, done
	jz	done
	mov	si, fs:[exclBound].R_left
	mov	di, fs:[exclBound].R_top
	mov	cx, fs:[exclBound].R_right
	mov	dx, fs:[exclBound].R_bottom
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
		mov	bx, fs:[exclusiveGstate]
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
	mov	dx, fs			      ; set segment to current code seg
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
		segmov	es, gs, cx	; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset escCodes ; si -> esc code tab
		;push	ds
		;push	fs
		;segmov	ds, fs, ax
		mov	cx, NUM_ESC_ENTRIES ; init rep count
		repne	scasw		; find the right one
		;pop	fs
		;pop	ds
		pop	es
		pop	ax
		jne	VE_notFound	;  not in table, quit

		; function is supported, call through vector

		pop	cx
		call	gs:[di+((offset escRoutines)-(offset escCodes)-2)]
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

SYNOPSIS:	Prepare to call across stacks

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
VidCallMod	proc	near
		; first, save away ax/bx since they are trashed by us

		mov	fs:[TPD_dataAX], ax
		mov	fs:[TPD_dataBX], bx

		; next, switch stacks so we still have access to dgroup
		; NOTE: the loading of ss *must* be followed by the loading
		; of sp.

		mov	fs:[saveSS], ss			; save caller's stack
		mov	fs:[saveSP], sp
		mov	bx, ss:[TPD_threadHandle]
		mov	fs:[TPD_threadHandle], bx
		mov	bx, {word}ss:[TPD_exclFSIRLocks]
		mov	{word}fs:[TPD_exclFSIRLocks], bx
		mov	bx, dgroup			; setup new stack
		mov	ss, bx
		mov	sp, offset dgroup:endVidStack

		; done with setup.  Push a return address and the calling
		; address and fire away...

		push	di			; save function number
		push	cs			; push return address
		push	offset restoreStack
		push	cs			; push segment of routine
		push	fs:[moduleTable][di]	; push routine offset
		mov	ax, fs:[TPD_dataAX]
		mov	bx, fs:[TPD_dataBX]
		retf				; call routine

		; done with operation.  Clean up and leave.
restoreStack:

		pop	di			; restore function number
		mov	ss, fs:[saveSS]			; restore old stack
		mov	sp, fs:[saveSP]
		ret

VidCallMod	endp
