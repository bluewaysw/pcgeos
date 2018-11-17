COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GOES	
MODULE:		DMA driver for DOS - Real Mode
FILE:		dosrealStrategy.asm

AUTHOR:		Todd Stumpf, Oct 13, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/13/92		Initial revision


DESCRIPTION:
	This is the DMA driver for DOS real-mode systems.
	In such a set-up, DMA'ing is easy as all logical addresses
	are physical addresses.  And, as DOS does not appropriate
	the DMA controller for VDS, we can directly manipulate the
	DMA 8237 chip.

	$Id: dosrealStrategy.asm,v 1.1 97/04/18 11:44:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;-----------------------------------------------------------------------------
;		dgroup DATA
;-----------------------------------------------------------------------------
DRIVER_TYPE_DMA	=	DRIVER_TYPE_OUTPUT	; until a DRV_TYPE_DMA

idata	segment

DriverTable	DriverInfoStruct <DOSRDMAStrategy, 0, DRIVER_TYPE_DMA>
ForceRef DriverTable

idata	ends

ResidentCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMAStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine for DOS-Real Mode DMA driver

CALLED BY:	GLOBAL
PASS:		di	-> command to execute
		others <see routine>
		INTERRUPTS_OFF

RETURN:		<see routine>

DESTROYED:	nothing

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		call appropriate routine and return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSRDMAStrategy	proc	far
	.enter
	call	cs:DriverRoutineJumpTable[di]
	.leave
	ret
DOSRDMAStrategy	endp

DriverRoutineJumpTable		nptr	DOSRDMAInit,		; DR_INIT
					DOSRDMADoNothing,	; DR_EXIT
					DOSRDMADoNothing,	; DR_SUSPEND
					DOSRDMADoNothing,	; DR_UNSUPEND
					DOSRDMARequest,		; DR_REQUEST...
					DOSRDMARelease,		; DR_RELEASE...
					DOSRDMADisable,		; DR_DISABLE...
					DOSRDMAEnable,		; DR_ENABLE...
					DOSRDMACheckTC,		; DR_CHECK...
					DOSRDMATransfer,	; DR_START...
					DOSRDMAStop		; DR_STOP_DMA..

;-----------------------------------------------------------------------------
;
;		Standard Driver Routines
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMAInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with driver initialization

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		sets runningOnAt flag

PSEUDO CODE/STRATEGY:
		get system set up
		if 2 int controllers, assume 2 dma controllers.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/17/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMAInit	proc	near
	uses	ax, dx, ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax

	call	SysGetConfig		; trashes dx, al <- SysConfigFlags
	and	al, mask SCF_2ND_IC		; al <- are there 2 dma chips?
	mov	ds:[runningOnAt], al		; save settings

	;
	;  Set usage maps for non-existant channels
	mov	ds:[channelUsage], 010h		; assume on AT.  no channel 4.
	tst	al

	jnz	done
	mov	ds:[channelUsage], 0f0h		; actually PC.  no channel 4-7.
done:
	.leave
	ret
DOSRDMAInit	endp

ResidentCode		ends

