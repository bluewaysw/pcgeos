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
		
	$Id: nullEntry.asm,v 1.1 97/04/18 11:43:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}



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
	cmp	di, DR_VID_INFO
	jne	notVidInfo
	mov	dx, cs			      ; set segment to current code seg
	mov	si, offset dgroup:DriverTable ; get offset
	jmp	exit
notVidInfo:
	cmp	di, DR_VID_GET_EXCLUSIVE
	jne	notGetExcl
	clr	bx
	jmp	exit
notGetExcl:
	cmp	di, DR_VID_END_EXCLUSIVE
	jne	notEndExcl
	clr	si, di, cx, dx
	jmp	exit
notEndExcl:
	cmp	di, DR_VID_GETPIXEL
	jne	notGetPixel
	clr	ax, bx
	jmp	exit
notGetPixel:
	cmp	di, DR_VID_MOVEPTR
	jne	notMovePtr
	clr	al
	jmp	exit
notMovePtr:
	cmp	di, DR_VID_SAVE_UNDER
	je	returnCarrySet

	cmp	di, DR_VID_CHECK_UNDER
	jne	notCheckUnder
	clr	al
	jmp	exit
notCheckUnder:
exit:
	clc
reallyExit:
	ret
returnCarrySet:
	stc
	jmp	reallyExit
DriverStrategy	endp
		public	DriverStrategy
