COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Format
FILE:		formatIoctl.asm

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial revision

DESCRIPTION:
		
	$Id: formatIoctl.asm,v 1.1 97/04/05 01:18:20 newdeal Exp $

-------------------------------------------------------------------------------@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetBPB

DESCRIPTION:	Calls the IOCTL function to return the BPB.

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		nothing

RETURN:		ds - dgroup
		ds:[newBPB]

DESTROYED:	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

GetBPB	proc	near

	;-----------------------------------------------------------------------
	;specify:
	;  return default BPB (bit 0 of specialFunctions)

	mov	ds:[newBPB].SDP_common.GDP_specialFuncs,  SpecialFuncs <
		1,	; All sectors same size
		0,	; Set all aspects of the device
		0	; Get the DEFAULT BPB, NOT THE CURRENT ONE.
	>
	mov	dx, offset ds:[newBPB]
	mov	cl, 60h			;get device params in BPB
	call	Ioctl

EC<	jnc	GBPB_10							>
EC<	mov	bx, ax							>
EC<	ERROR	FORMAT_IOCTL_FAILED					>
EC<GBPB_10:								>

	ret
GetBPB	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SaveBPB

DESCRIPTION:	Duplicates the data in the newBPB in saveBPB.

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		ds - dgroup
		ds:[newBPB]

RETURN:		ds:[saveBPB]

DESTROYED:	ax, cx, di, si, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

SaveBPB	proc	near
	segmov	es, ds, ax
	mov	si, offset ds:[newBPB]		;ds:si <- source addr
	mov	di, offset ds:[saveBPB]		;es:di <- dest addr
	mov	cx, size newBPB
	rep	movsb
	ret
SaveBPB	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetBPB

DESCRIPTION:	Set the BPB according to the user's specifications.

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		nothing

RETURN:		BPB set

DESTROYED:	ax, cx, dx, di, si, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@


SetBPB	proc	near
	segmov	es, ds, ax

	;-----------------------------------------------------------------------
	;copy mediaVars over to BPB portion of newBPB

	mov	si, offset dgroup:[mediaVars]			;init source
	mov	di, offset dgroup:[newBPB.SDP_common.GDP_bpb]	;init dest
	mov	cx, size mediaVars
	rep	movsb

if 0		; Already initialized to zero since in udata and no other vars
		; that contain BiosParamBlocks set the reserved fields to
		; anything but 0...
	;-----------------------------------------------------------------------
	;zero initialize reserved portion of BPB

	mov	di, offset dgroup:[newBPB + IDP_bpbReserved]
	clr	al
	mov	cx, size IDP_bpbReserved
	rep	stosb
endif

	;-----------------------------------------------------------------------
	;initialize track layout field

	mov	si, offset newBPB
	call	InitTrackLayout

	;-----------------------------------------------------------------------
	;figure the number of cylinders in the thing. This is the total
	;number of sectors, divided by the number of sectors per track (to
	;get the number of tracks), divided by the number of heads.

	mov	ax, ds:[newBPB].SDP_common.GDP_bpb.BPB_numSectors
	clr	dx			; sectorsPerTrack is a word...
	div	ds:[newBPB].SDP_common.GDP_bpb.BPB_sectorsPerTrack
EC <	tst	dx			; s/b no remainder...		>
EC <	ERROR_NZ	FORMAT_BOGUS_BPB				>
	div	ds:[newBPB].SDP_common.GDP_bpb.BPB_numHeads
	mov	ds:[newBPB].SDP_common.GDP_cylinders, ax

	;-----------------------------------------------------------------------
	;set BPB 

	mov	ds:[newBPB].SDP_common.GDP_specialFuncs, SpecialFuncs <
		1,	; All sectors same size
		0,	; Set all aspects of the device
		1	; Set the CURRENT BPB.
	>

	mov	cl, 40h				;set device params
	mov	dx, offset ds:[newBPB]
	call	Ioctl

EC<	jnc	SBPB_60							>
EC<	mov	ah, 59h				;get extended error info>
EC<	clr	bx							>
EC<	call	FileInt21						>
EC<	ERROR	FORMAT_IOCTL_FAILED					>
EC<SBPB_60:								>

	ret
SetBPB	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	RestoreBPB

DESCRIPTION:	Restores the BPB to the state that it was in before
		LibDiskFormat was invoked.

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		ds - dgroup
		ds:[saveBPB]

RETURN:		nothing

DESTROYED:	cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

RestoreBPB	proc	near
	push	ax

	;-----------------------------------------------------------------------
	;specify:
	;  specify new default BPB (bit 0 of specialFunctions)
	;  normal track layout (bit 2 of specialFunctions)

	mov	si, offset saveBPB
	call	InitTrackLayout
	
	mov	ds:[saveBPB.SDP_common.GDP_specialFuncs], SpecialFuncs <
		1,	; All sectors same size
		0,	; Set all aspects of the device
		1	; Set the CURRENT BPB first.
	>

	mov	cl, 40h				;set device params
	mov	dx, offset ds:[saveBPB]
	call	Ioctl	; destroys nothing

	mov	ds:[saveBPB.SDP_common.GDP_specialFuncs], SpecialFuncs <
		1,	; All sectors same size
		0,	; Set all aspects of the device
		0	; Set the DEFAULT BPB, NOT THE CURRENT ONE. This
			;  tells DOS 4.X to go back to looking at the boot
			;  sector to determine the disk geometry
	>
	call	Ioctl

EC<	jnc	RBPB_done						>
EC<	mov	ah, 59h				;get extended error info>
EC<	clr	bx							>
EC<	call	FileInt21						>
EC<	mov	dx, ax							>
EC<	ERROR	FORMAT_IOCTL_FAILED					>
EC<RBPB_done:								>
	pop	ax
	ret
RestoreBPB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitTrackLayout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the SDP_trackLayout field of a SetDeviceParams
		structure.

CALLED BY:	SetBPB, RestoreBPB
PASS:		ds:si	= SetDeviceParams structure with SDP_common.GDP_bpb
			  properly initialized.
RETURN:		nothing
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitTrackLayout	proc	near
		.enter
		mov	cx, ds:[si].SDP_common.GDP_bpb.BPB_sectorsPerTrack
		mov	ds:[si].SDP_numSectors, cx
		add	si, offset SDP_trackLayout
		mov	ax, 1
sectorLoop:
		mov	ds:[si].TLE_sectorNum, ax
		mov	ds:[si].TLE_sectorSize, MSDOS_STD_SECTOR_SIZE
		add	si, size TrackLayoutEntry
		inc	ax
		loop	sectorLoop
		.leave
		ret
InitTrackLayout	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	IsIoctlPresent

DESCRIPTION:	Boolean function, tells if DOS version we're running under
		has IOCTL function capabilities.

CALLED BY:	INTERNAL (FormatTrack)

PASS:		nothing

RETURN:		carry clear if IOCTL functions present
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

IsIoctlPresent	proc	near
;	stc
;	ret


	push	ax,bx,cx
	mov	ax, 3000h			;get dos version number
	call	FileInt21

	cmp	al, 3				;major version 3?
	jne	exit				;carry set correctly
	cmp	ah, 14h				;minor version 20?
	;carry set correctly
exit:
	pop	ax,bx,cx
	ret
IsIoctlPresent	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	Ioctl

DESCRIPTION:	Performs call to the generic I/O control interrupt for block
		devices in DOS.

CALLED BY:	INTERNAL

PASS:		cl - minor function code for int 21h, func 44h, subfunc 0dh
		ds - dgroup
		ds:dx - addr of parameter block

RETURN:		carry - clear if successful
		ds:[errCode] - error code

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

Ioctl	proc	near
	push	ax,bx,cx

	mov	ax, 440dh
	mov	bl, ds:[drive]
	inc	bl			;specify drive code
	mov	ch, 08h			;specify disk drive
	call	FileInt21

	mov	ds:[errCode], ax
	pop	ax,bx,cx
	ret
Ioctl	endp
