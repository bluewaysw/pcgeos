COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 5/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial revision

DESCRIPTION:
		
	$Id: diskcopyIoctl.asm,v 1.1 97/04/05 01:18:12 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskcopyInitMediaVars

DESCRIPTION:	Initialize variables relating to the medium that we're going
		to work on.

CALLED BY:	INTERNAL (DiskcopyDoInit)

PASS:		ds - dgroup
		al - PC/GEOS media descriptor

RETURN:		media vars

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@


DiskcopyInitMediaVars	proc	near
	push	ax,cx,di,si

	push	ax
	mov	al, ds:[sourceDrive]
	call	DriveGetStatus
	mov	ds:[mediaStatus], ah
	test	ah, mask DS_MEDIA_REMOVABLE
	pop	ax
	jnz	floppy

	;-----------------------------------------------------------------------
	;dealing with fixed disk...
	;
	;if IOCTL is present then
	;    get params
	;    copy BPB over to media vars
	;else
	;    get boot sector
	;    copy BPB over to media vars
	;
	;get partition entry

	mov	ds:[ioctlFuncCode], 62h		;verify track
	jmp	short done

floppy:
	;-----------------------------------------------------------------------
	;dealing with floppy disk...

	push	ds,es
	clr	ah
	dec	ax				;make ax 0 based
	mov	cx, size BiosParamBlock		;cx <- block size
	mul	cx				;ax <- 0 based offset
	add	ax, offset cs:[BPB_160K]	;ax <- offset to BPB for media
	mov	si, ax
	mov	di, offset dgroup:[mediaVars]
	push	cs
	push	ds
	pop	es			; es <- ds
	pop	ds			; ds <- cs
	rep	movsb
	pop	ds,es

	clr	ax
;	mov	ds:[curCylinder], ax
;	mov	ds:[curHead], ax
;	mov	ds:[curSector], 1

	mov	ds:[ioctlFuncCode], 42h		;format and verify track

done:
	pop	ax,cx,di,si
	ret
DiskcopyInitMediaVars	endp


	CheckHack <MEDIA_160K eq 1>
BPB_160K	BiosParamBlock <
	512,		;sectorSize
	1,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	64,		;numRootDirEntries
	320,		;numSectors
	DOS_MEDIA_160K,	;mediaDescriptor

	1,		;sectorsPerFAT
	8,		;sectorsPerTrack
	1,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_180K eq 2>
BPB_180K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	64,		;numRootDirEntries, 4 sectors
	360,		;numSectors
	DOS_MEDIA_180K,	;mediaDescriptor
	1,		;sectorsPerFAT
	9,		;sectorsPerTrack
	1,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_320K eq 3>
BPB_320K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	112,		;numRootDirEntries
	640,		;numSectors
	DOS_MEDIA_320K,	;mediaDescriptor
	1,		;sectorsPerFAT
	8,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_360K eq 4>
BPB_360K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	112,		;numRootDirEntries, 7 sectors
	720,		;numSectors
	DOS_MEDIA_360K,	;mediaDescriptor
	2,		;sectorsPerFAT
	9,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_720K eq 5>
BPB_720K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	112,		;numRootDirEntries, 7 sectors
	1440,		;numSectors
	DOS_MEDIA_720K,	;mediaDescriptor
	3,		;sectorsPerFAT
	9,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_1M2 eq 6>
BPB_1M2		BiosParamBlock <
	512,		;sectorSize
	1,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	224,		;numRootDirEntries, 14 sectors
	2400,		;numSectors
	DOS_MEDIA_1M2,	;mediaDescriptor
	7,		;sectorsPerFAT
	15,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_1M44 eq 7>
BPB_1M44	BiosParamBlock <
	512,		;sectorSize
	1,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	224,		;numRootDirEntries, 14 sectors
	2880,		;numSectors
	DOS_MEDIA_1M44,	;mediaDescriptor
	9,		;sectorsPerFAT
	18,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
IF	0
	CheckHack <MEDIA_FIXED_DISK eq 8>
BPB_fixed	BiosParamBlock <
	512,		;sectorSize
	0,		;clusterSize, 4 or 8
	1,		;numReservedSectors
	2,		;numFATs
	0,		;numRootDirEntries, 200 or 512
	0,		;numSectors
	DOS_MEDIA_FIXED_DISK,	;mediaDescriptor
	0,		;sectorsPerFAT
	17,		;sectorsPerTrack
	0,		;numHeads, 4, 5 or 7
	0		;numHiddenSectors
>
ENDIF


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetBPB

DESCRIPTION:	Calls the IOCTL function to return the BPB.

CALLED BY:	INTERNAL ()

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

	mov	byte ptr ds:[newBPB.SDP_common.GDP_specialFuncs], 0
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

CALLED BY:	INTERNAL ()

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

CALLED BY:	INTERNAL ()

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

	mov	cx, ds:[mediaVars.BPB_sectorsPerTrack]
	mov	ds:[newBPB.SDP_numSectors], cx
	mov	si, offset ds:[newBPB.SDP_trackLayout]
	mov	ax, 1
SBPB_loop:
	mov	ds:[si].TLE_sectorNum, ax
	mov	ds:[si].TLE_sectorSize, MSDOS_STD_SECTOR_SIZE	;sector size
	add	si, size TrackLayoutEntry
	inc	ax
	loop	SBPB_loop

	;-----------------------------------------------------------------------
	;set BPB (specialFuncs == 5 => set current BPB, using standard layout

	mov	ds:[newBPB.SDP_common.GDP_specialFuncs], 5
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

DESCRIPTION:	Restores the BPB to the state that it was in before.
		

CALLED BY:	INTERNAL ()

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
	;  (was originally 5, why???)
	;  specify new default BPB (bit 0 of specialFunctions)
	;  normal track layout (bit 2 of specialFunctions)

	mov	ds:[saveBPB.SDP_common.GDP_specialFuncs], 5
	mov	cl, 40h				;set device params
	mov	dx, offset ds:[saveBPB]
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


COMMENT @-----------------------------------------------------------------------

FUNCTION:	IsIoctlPresent

DESCRIPTION:	Boolean function, tells if DOS version we're running under
		has IOCTL function capabilities.

CALLED BY:	INTERNAL ()

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
	;for testing
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
	mov	bl, ds:[sourceDrive]
	inc	bl			;specify drive code
	mov	ch, 08h			;specify disk drive
	call	FileInt21

	pop	ax,bx,cx
	ret
Ioctl	endp
