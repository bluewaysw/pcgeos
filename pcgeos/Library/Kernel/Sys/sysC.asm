COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Sys
FILE:		sysC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the geode routines

	$Id: sysC.asm,v 1.1 97/04/05 01:14:56 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	UtilHex32ToAscii

C DECLARATION:	extern word
		    _far _pascal UtilHex32ToAscii(char _far *buffer,
						dword value, word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
UTILHEX32TOASCII	proc	far	buffer:fptr.char, value:dword,
					flags:word
				uses di, es
	.enter

	les	di, buffer
	mov	cx, flags
	mov	dx, value.high
	mov	ax, value.low
	call	UtilHex32ToAscii
	mov	ax, cx				; length of string => AX

	.leave
	ret

UTILHEX32TOASCII	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	UtilAsciiToHex32

C DECLARATION:	extern Boolean		/* TRUE if string is a valid number */
		    _far _pascal UtilAsciiToHex32T(char _far *string
						dword *value);
			Note: "stirng" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/92		Initial version

------------------------------------------------------------------------------@
UTILASCIITOHEX32	proc	far	string:fptr.char, value:fptr.dword
	uses	si, ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, string					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	lds	si, string
	call	UtilAsciiToHex32		; value => DX:AX
	lds	si, value
	movdw	ds:[si], dxax			; store the dword
	mov	ax, 0				; assume valid number
	jnc	done
	dec	ax				; else invalid number
done:
	.leave
	ret
UTILASCIITOHEX32	endp

C_Common	ends

;-

C_System	segment resource

if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysGetDosEnvironment

C DECLARATION:	extern Boolean		/* true if error (not found) */
		    _far _pascal SysGetDosEnvironment(const char _far *variable,
					char _far *buffer, word bufSize);
			Note: "variable" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSGETDOSENVIRONMENT	proc	far	variable:fptr.far, buffer:fptr.far,
					bufSize:word
				uses si, di, ds, es
	.enter

	lds	si, variable
	les	di, buffer
	mov	cx, bufSize
	call	SysGetDosEnvironment

	mov	ax, 0			;assume found
	jnc	done
	dec	ax
done:

	.leave
	ret

SYSGETDOSENVIRONMENT	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysNotify

C DECLARATION:	extern word
		    _far _pascal SysNotify(word flags,
				const char _far *string1, const char *string2);
			Note:The fptrs *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSNOTIFY	proc	far	flags:word, string1:fptr.char,
				string2:fptr.char
							uses si, di, ds
	.enter

EC <	mov	ax, string1.segment					>
EC <	tstdw	string2							>
EC <	jz	strok							>
EC <	cmp	ax, string2.segment					>
EC <	ERROR_NZ	SYSNOTIFY_STRINGS_MUST_BE_IN_SAME_SEGMENT	>
EC <strok:								>

	lds	si, string1
	mov	di, string2.offset
	mov	ax, flags
	call	SysNotify

	.leave
	ret

SYSNOTIFY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysRegisterScreen

C DECLARATION:	extern void
			_far _pascal SysRegisterScreen(GeodeHandle driver,
							WindowHandle root);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSREGISTERSCREEN	proc	far
	C_GetTwoWordArgs	dx, cx,   ax,bx	;dx = video dr, cx = root

	call	SysRegisterScreen
	ret

SYSREGISTERSCREEN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysShutdown

C DECLARATION:	extern Boolean
			_cdecl SysShutdown(SysShutdownType type, ...);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
.model	medium, C

_SysShutdown	proc	far	shutdownType:SysShutdownType,
				args:byte
	uses	ds, si, di
	.enter
	;
	; Fetch the shutdown type, as that's constant, and use that to get
	; to the code to fetch the rest of the args into their appropriate
	; registers.
	; 
	mov	ax, ss:[shutdownType]

EC <	cmp	ax,SysShutdownType					>
EC <	ERROR_AE	BAD_SHUTDOWN_TYPE				>

	mov	si, ax
	shl	si
	jmp	cs:[SYSSHUTDOWNHandlers][si]
SYSSHUTDOWNHandlers	nptr.near	cleanOrSuspend, ; SST_CLEAN
					doShutdown,	; SST_CLEAN_FORCED
					reason,		; SST_DIRTY
					doShutdown,	; SST_PANIC
					doShutdown,	; SST_REBOOT
					doShutdown,	; SST_RESTART
					reason,		; SST_FINAL
					cleanOrSuspend,	; SST_SUSPEND
					doShutdown,	; SST_CONFIRM_START
					confirmEnd,	; SST_CONFIRM_END
					cleanOrSuspend	; SST_CLEAN_REBOOT
cleanOrSuspend:
	;
	; SysShutdown(SST_CLEAN, optr ackOD, Message ackMsg);
	; 
	mov	cx, ({optr}ss:[args]).handle
	mov	dx, ({optr}ss:[args]).chunk
	mov	bp, {word}ss:[args+size optr]	; can do this b/c there are
						;  no local vars and Esp
						;  optimizes out need of BP
						;  in .leave for this case
	jmp	doShutdown

reason:
	;
	; SysShutdown(SST_DIRTY or SST_FINAL, const char *reason);
	; 
	lds	si, {fptr.char}ss:[args]
	jmp	doShutdown

confirmEnd:
	;
	; SysShutdown(SST_CONFIRM_END, Boolean allowShutdown);
	; 
	mov	cx, {word}ss:[args]
doShutdown:
	call	SysShutdown

	;
	; Return non-zero if carry set.
	; 
	mov	ax, 0
	jnc	done
	dec	ax
done:
	.leave
	ret
_SysShutdown	endp

	SetGeosConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysSetExitFlags

C DECLARATION:	extern word
			_far _pascal SysSetExitFlags(word bitsToSet,
							word bitsToClear);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSSETEXITFLAGS	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = set, ax = clear

	mov	bh, al			;bh = bits to clear
	call	SysSetExitFlags
	mov_trash	ax, bx		;return new exit flags
	clr	ah
	ret

SYSSETEXITFLAGS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysGetECLevel

C DECLARATION:	extern word
			_far _pascal SysGetECLevel(MemHandle _far
							*checksumBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSGETECLEVEL	proc	far
	C_GetOneDWordArg	cx, dx,   ax,bx	;cx = seg, dx = off

	call	SysGetECLevel

	tst	cx
	jz	done
	push	si, ds
	mov	ds, cx
	mov	si, dx
	mov	ds:[si], bx
	pop	si, ds
done:
	ret

SYSGETECLEVEL	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysSetECLevel

C DECLARATION:	extern void
			_far _pascal SysSetECLevel(word flags,
						MemHandle checksumBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSSETECLEVEL	proc	far
	C_GetTwoWordArgs	ax, bx,   cx,dx	;ax = flags, bx = han

	GOTO	SysSetECLevel

SYSSETECLEVEL	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysStatistics

C DECLARATION:	extern void
			_far _pascal SysStatistics(SysStats _far *stats);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSSTATISTICS	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = seg, ax = off

	push	di, es
	mov	es, bx
	mov	di, ax
	call	SysStatistics
	pop	di, es
	ret

SYSSTATISTICS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysGetInfo

C DECLARATION:	extern dword
			_far _pascal SysGetInfo(SysGetInfoType info);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSGETINFO	proc	far
	C_GetOneWordArg	ax,   bx,cx	;bx = info

	call	SysGetInfo
	ret

SYSGETINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysSetInkWidthAndHeight

C DECLARATION:	extern void
			_far _pascal SysSetInkWidthAndHeight(thickness word);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/3		Initial version

------------------------------------------------------------------------------@
SYSSETINKWIDTHANDHEIGHT	proc	far
	C_GetOneWordArg	ax,	bx, cx
	call	SysSetInkWidthAndHeight

	ret
SYSSETINKWIDTHANDHEIGHT	endp

C_System	ends

	SetDefaultConvention












