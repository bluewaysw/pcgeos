COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskmaxDriver.asm

AUTHOR:		Adam de Boor, Oct  4, 1991

ROUTINES:
	Name			Description
	----			-----------
	TaskDRInit		verify switcher is present and initialize it
	TaskDRExit		close down our control of the switcher
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/4/91		Initial revision


DESCRIPTION:
	Switcher-specific driver routines.
		

	$Id: taskmaxDriver.asm,v 1.1 97/04/18 11:58:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource
;
; The code for the int 26h interceptor, as it exists in the first version
; of DR DOS 6.0. This beast refuses to let us write the boot sector
; for any drive above B if there's more than one task active. This causes
; us to think all removable drives above B are write-protected, which sucks.
; To get around this, we determine if the interceptor looks the way we
; think it should (the bytes are in two tables, below, to allow the address
; of the number-of-active-tasks flag to be whatever it needs to be; Part2
; takes up two bytes after Part1 leaves off, with the offset of the original
; int 26h vector being the two bytes after Part2), and if so, replace int 26h
; with the previous contents of the int 26h vector, as extracted from TaskMax.
; 
int26Part1	byte	0x3c, 0x02,	; cmp al, 2
			0x72, 0x08,	; jb $+10
			0x2e, 0x83, 0x3e; cmp cs:[xxxx],

int26Part2	byte	0x01,		; 1
			0x75, 0x05,	; jne $+7
			0x2e, 0xff, 0x2e; jmp {fptr.far}cs:[xxxx]



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing initialization routine. All the real work is done
		during DRE_TEST_DEVICE and DRE_SET_DEVICE now.

CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		carry clear
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrInit	proc	near
		.enter
		clc
		.leave
		ret
TaskDrInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the switcher we're supposed to drive is loaded

CALLED BY:	TaskStrategy
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		ax	= DevicePresent
		carry set if DP_INVALID_DEVICE, clear otherwise
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrTestDevice proc	near
		uses	bx, cx, dx, ds
		.enter
		segmov	ds, dgroup, ax
	;
	; Make sure we're running under a DR-DOS version that supports
	; int 2fh.
	; 
		mov	ah, MSDOS_GET_VERSION
		call	FileInt21
		cmp	al, 3
		jb	error
		
		mov	ax, DRDOS_GET_VERSION
		call	FileInt21
		jc	error
	;
	; See if the switcher is loaded.
	; 
		mov	ax, TMAPI_CHECK_INSTALL
		call	TMInt2f
		tst	al
		jz	error
		
	;
	; Register as the task manager, if possible.
	; 
		mov	ax, TMAPI_SET_TASK_MGR
		mov	dl, 1
		call	TMInt2f
		tst	dl		; no manager before us?
		jnz	error		; sigh. there was, so we can't do
					;  spit
	;
	; We were able to register, so now unregister, as this is supposed to
	; be non-intrusive...
	; 
		mov	ax, TMAPI_SET_TASK_MGR
		call	TMInt2f

		mov	ds:[taskProcessStartupOK], TRUE
		mov	ax, DP_PRESENT
done:
	;
	; Let our process thread go, now that taskProcessStartupOK is set
	; properly.
	; 
		VSem	ds, taskProcessStartupSem
		clc
		.leave
		ret
error:
		mov	ax, DP_NOT_PRESENT
		jmp	done
TaskDrTestDevice endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Now put our hooks into TaskMax

CALLED BY:	DRE_SET_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrSetDevice proc	near
		uses	ax, bx, cx, dx, es, ds, si
		.enter
	;
	; Register as the task manager.
	; 
		mov	ax, TMAPI_SET_TASK_MGR
		mov	dl, 1
		call	TMInt2f
	;
	; Rename our task to something obvious.
	; 
EC <		push	es						>
		mov	ax, TMAPI_FIND_TASKS
		call	TMInt2f		; bx <- our task index
		mov	dl, es:[si][bx]	; dx <- our task ID
EC <		pop	es						>
		clr	dh
		mov	bx, handle TaskStrings
		call	MemLock
		mov	ds, ax
		assume	ds:TaskStrings
		mov	si, ds:[systemName]	; ds:si <- name
		mov	ax, TMAPI_NAME_TASK
		call	TMInt2f
EC <		segmov	es, ds			; avoid ec +segment 	>
		mov	bx, handle TaskStrings
		call	MemUnlock
		assume	ds:nothing

		call	TMDRHackInt26
	;
	; Mark DRE_SET_DEVICE as having been called, so DR_EXIT knows what
	; to do.
	; 
		segmov	ds, dgroup, ax
		mov	ds:[deviceSet], TRUE
		.leave
		ret
TaskDrSetDevice endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMDRHackInt26
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grossness to get around TaskMax refusing to allow us to
		write the boot sector of any drive above B, even though
		there could well be floppies/removable drives there.

CALLED BY:	TaskDrSetDevice
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMDRHackInt26	proc	near
EC <		uses	es		; avoid ec +segment deaths	>
		.enter
	;
	; See if int 26h is still obnoxious.
	; 
		clr	ax
		mov	es, ax
		les	di, es:[26h*4]		; es:di <- current int 26h
						;  handler
		segmov	ds, dgroup, ax
		mov	ds:[old26].segment, es	; save for restore on exit
		mov	ds:[old26].offset, di

	    ; see if first part matches
		segmov	ds, cs
		assume	ds:@CurSeg
		mov	si, offset int26Part1
		mov	cx, length int26Part1
		repe	cmpsb
		jne	int26OK
	    ; skip over number-of-running-tasks offset (1 word)
		inc	di
		inc	di
	    ; see if second part matches
	CheckHack <offset int26Part1+length int26Part1 eq offset int26Part2>
		mov	cx, length int26Part2
		repe	cmpsb
		jne	int26OK
	;
	; Interceptor looks to be obnoxious, so fetch the original int 26h
	; vector from the variable in taskmax-space into di:cx
	; 
		mov	di, es:[di]
		mov	cx, es:[di].offset
		mov	di, es:[di].segment
	;
	; Stuff it into the int 26h vector again.
	; 
		clr	ax
		mov	es, ax
		INT_OFF
		mov	es:[26h*4].offset, cx
		mov	es:[26h*4].segment, di
		INT_ON
int26OK:
		assume	ds:dgroup
		.leave
		ret
TMDRHackInt26	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDrExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves.

CALLED BY:	TaskStrategy
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDrExit	proc	near
		.enter
EC <		push	es						>
		segmov	es, dgroup, ax
		tst	es:[deviceSet]
		jz	done
	;
	; Remove ourselves as the task manager.
	; 
		mov	ax, TMAPI_SET_TASK_MGR
		mov	dl, 0
		call	TMInt2f
	;
	; Allow our task name to be adjusted dynamically again, now we're
	; history, by setting it to all null bytes.
	; 
		mov	ax, TMAPI_FIND_TASKS
		call	TMInt2f			; bx <- our task index
		mov	dl, es:[si][bx]
		clr	dh			; dx <- our task ID
		mov	si, offset nullName
		segmov	ds, cs			; ds:si <- null name
		mov	ax, TMAPI_NAME_TASK
		call	TMInt2f
   		
	;
	; Restore TaskMax's int 26h vector.
	; 
		clr	ax
		mov	es, ax
		segmov	ds, dgroup, ax
		mov	ax, ds:[old26].offset
		mov	dx, ds:[old26].segment
		INT_OFF
		mov	es:[26h*4].offset, ax
		mov	es:[26h*4].segment, dx
		INT_ON
done:
EC <		pop	es						>
		clc
		.leave
		ret

nullName	char	TM_TASK_NAME_LENGTH dup(0)
TaskDrExit	endp

Resident	ends
