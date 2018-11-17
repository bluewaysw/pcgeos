COMMENT }-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Window system
FILE:		init

ROUTINES:
	Name		Description
	----		-----------
	WinInitSys	- system initialization routine for windows

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
		5/88		Initial version

DESCRIPTION:
	This module initializes the window system.  See manager.asm for
	documentation.

	$Id: winInit.asm,v 1.1 97/04/05 01:16:23 newdeal Exp $

-------------------------------------------------------------------------------}



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinInitSys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the window system

CALLED BY:	INTERNAL
		StartGEOS

PASS:		ds - kernel variable segment

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		call driver initialization routine;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/25/88	First code placed in here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinInitSys	proc	near	uses	si, di, bp, ds, es
	.enter

	; Display log string
	;
	push	ds
	segmov	ds, cs
	mov	si, offset winLogString
	call	LogWriteInitEntry
	pop	ds

	; Allocate queues for winNotification code
	;
	call	GeodeAllocQueue
	mov	ds:[wPtrEventQueue], bx
	call	GeodeAllocQueue
	mov	ds:[wPtrSendQueue], bx

	; Get geode private data offset to store GeodeWinVars at.
	;
	mov	bx, handle 0
	mov	cx, (size GeodeWinVars)/2
	call	GeodePrivAlloc
	mov	ds:[wGeodeWinVarsOffset], bx

	.leave
	ret
WinInitSys	endp

winLogString	char	"Window Module", 0
