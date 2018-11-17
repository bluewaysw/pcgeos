
COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		formatVerify.asm

AUTHOR:		Cheng, 7/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/90		Initial revision

DESCRIPTION:
		
	$Id: formatVerify.asm,v 1.1 97/04/05 01:18:26 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VerifyKeyTracks

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ds - dgroup
		es - workBufSegAddr

RETURN:		carry set on error
		ax - 0 if successful,
		     else one of:
			FMT_ERR_WRITING_BOOT
			FMT_ERR_WRITING_ROOT_DIR
			FMT_ERR_WRITING_FAT

DESTROYED:	bx,cx,dx,bp,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

VerifyKeyTracks	proc	near	uses	ds, es
	.enter

	push	ds
	mov	bx, es
	mov	ds, bx
	pop	es

	mov     bx, FML_DOS
	call    FileGrabSystem

	mov	ah, 0dh				;reset disk system
	int	21h

	clr	dx				;logical sector 0
	mov	al, es:[drive]
	mov	cx, 1				;specify 1 sector

verifyLoop:
	clr	bx
	push	ax,cx,dx
	int	25h
	inc	sp
	inc	sp
	pop	ax,cx,dx
	jc	error

	inc	dx
	cmp	dx, es:[startFilesArea]		;al <- num sectors to verify
	jne	verifyLoop
	clr	ax				;ax <- 0, clear C
	jmp	short done

error:
	mov	ax, FMT_ERR_WRITING_BOOT
	cmp	dx, es:[startFAT]
	jb	doneError

	mov	ax, FMT_ERR_WRITING_FAT
	cmp	dx, es:[startRoot]
	jb	doneError

	mov	ax, FMT_ERR_WRITING_ROOT_DIR

doneError:
	stc
done:
	pushf
	mov     bx, FML_DOS
	call    FileReleaseSystem
	popf

	.leave
	ret
VerifyKeyTracks	endp


if	0	;***************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VerifyInt13

DESCRIPTION:	

CALLED BY:	INTERNAL (Not in use)

PASS:		ah - int 13h operation
		al - number of sectors
		ch - cylinder
		cl - sector
		dh - head
		dl - drive

RETURN:		carry flag

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

VerifyInt13	proc	near	uses	bp
	.enter

	push	ax
	clr	ah			;reset disk system
	int	13h
	pop	ax

	mov	bp, 5

tryLoop:
	push	ax
	int	13h			;perform operation
	pop	ax
	jnc	done

	dec	bp
	jne	tryLoop
	stc

done:
	.leave
	ret
VerifyInt13	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvLogicalToPhysical

DESCRIPTION:	Converts the given logical sector number to its physical
		address.

CALLED BY:	INTERNAL (Not in use)

PASS:		dx - logical sector number
		ds - dgroup

RETURN:		ch - cylinder
		cl - sector
		dh - head

DESTROYED:	dl

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@

ConvLogicalToPhysical	proc	near	uses	ax,bp
	.enter
	;
	; First figure the sector number by dividing the logical sector by
	; the number of sectors per track. This gives us the track number
	; in ax and the sector number in dx. Both of these are 0-origin.
	;
	push	dx
	mov	ax, dx
	clr	dx
	div	ds:[mediaVars.BPB_sectorsPerTrack]
	inc	dl
	mov	cl, dl				;cl <- sector number

	;
	; Now figure the head number from the track number. The tracks are
	; assigned to the heads sequentially, e.g. for a 4-headed drive,
	; track 0 is on head 0, track 1 on head 1, track 2 on head 2, track
	; 3 on head 3, and track 4 is on head 0 again.
	;
	clr	dx
	div	ds:[mediaVars.BPB_numHeads]
	mov	ch, dl				;dh <- head (eventually)

	;
	; Finally we need the cylinder number. For a 4-headed drive,
	; tracks 0-3 make up cylinder 0.
	; 
	mov	ax, ds:[mediaVars.BPB_sectorsPerTrack]
						; Figure sectors per cylinder
	mul	ds:[mediaVars.BPB_numHeads]	; from s.p.t. * tracks per
						; cylinder (number of heads)

	mov	bp, ax				;preserve sectors per cylinder
	pop	ax				;retrieve logical sector
	div	bp				;yields cylinder in ax

	mov	dh, ch				;transfer head to dh now
						; we're done with dx
	mov	ch, al				;return cylinder in ch
	.leave
	ret
ConvLogicalToPhysical	endp

endif		;***************************************************************
