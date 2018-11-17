COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Klib/Format
FILE:		Format/formatLow.asm

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial revision

DESCRIPTION:

NOTES:
	multitasking:
		shared vars and bufs
		drive locking
		
	$Id: formatLow.asm,v 1.1 97/04/05 01:18:22 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatTrack

DESCRIPTION:	Formats a disk track regardless of DOS version.

CALLED BY:	INTERNAL ()

PASS:		ds - dgroup
		cx - cylinder
		dx - head

		ds:[ioctlFuncCode]
		ds:[drive]
		ds:[mediaStatus]
		ds:[mediaVars] (BPB_sectorsPerTrack, BPB_sectorSize)

RETURN:		carry clear if successful
		carry set on error
		ds:[errCode] = error code

DESTROYED:	nothing

REGISTER/STACK USAGE:
	ds - idata seg

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

FormatTrack	proc	near
	push	cx, dx
EC<	call	ECCheckDS						>

	call	IsIoctlPresent
	jc	noIoctl

	;-----------------------------------------------------------------------
	;Ioctl present
	;stuff Ioctl Format Track Param Block

	mov	ds:[ioctlFmtTrkParamBlk.FTPB_cylinder], cx
	mov	ds:[ioctlFmtTrkParamBlk.FTPB_head], dx

	mov	cl, ds:[ioctlFuncCode]
	mov	dx, offset ds:[ioctlFmtTrkParamBlk]
	call	Ioctl
	jmp	short done

noIoctl:
	;-----------------------------------------------------------------------
	;Ioctl absent

	;For the convenience of the noIoctl functions, change regs.
	;This is overhead and the price the user pays for running on DOS < 3.2.
	;Want:
	;	ch - cylinder number
	;	cl, bits 7,6 - ms 2 bits of cylinder number
	;	dh - head
	;	dl - drive
	push	ax
	clr	ah
	mov	al, ch		;ah <- ms 2 bits in bits 1,0
	mov	ch, cl		;ch <- cylinder number
	mov	cl, 6
	shl	ax, cl
	mov	cl, al
	or	cx, 1
	mov	dh, dl		;dh <- head
	mov	dl, ds:[biosDrive]
	pop	ax

	test	ds:[mediaStatus], mask DS_MEDIA_REMOVABLE
	je	noIoctlFixed

	call	NoIoctlFormatFloppyTrack
	jmp	short done

noIoctlFixed:
	call	NoIoctlFormatFixedDiskTrack

done:
;;	mov	ax, FMT_DRIVE_NOT_READY
;;	jc	exit
;;	clr	ax
;;	call	CallStatusCallback
        lahf                                    ; save format status
	mov     ch, ah
	call    CallStatusCallback
	jc      exit                            ; aborted, C=1, ax=FMT_ABORTED
	mov     ah, ch                          ; restore format status
	sahf
	mov     ax, 0
	jnc     exit                            ; no error, no abort; ax=0, C=0
	mov     ax, FMT_DRIVE_NOT_READY
						; error, no abort; ax=..., C=1
exit:
	pop	cx, dx
	ret
FormatTrack	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NoIoctlFormatFloppyTrack

DESCRIPTION:	Formats a track on a floppy disk with no recourse to
		the IOCTL functions.

CALLED BY:	INTERNAL (FormatTrack)

PASS:		ds - dgroup
		ch - cylinder number
		cl bits 7,6 - ms 2 bits of cylinder number (should be 0)
		dh - head number
		dl - drive (0 based)

RETURN:		carry clear if successful
		carry set otherwise, err code in ds:[errCode]

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	for num sectors do
	    create address field list
	call int 13h, function 5 (format track)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@


NoIoctlFormatFloppyTrack	proc	near
;EC<	test	cl, 0c0h						>
;EC<	ERROR_NZ	FORMAT_BAD_CYLINDER				>

	push	ax,bx,cx,bp,es

	;-----------------------------------------------------------------------
	;stuff disk base table entry with correct number of sectors
	;some way around this?

	mov	ax, 351eh		;get addr of disk base table
	call	FileInt21		;es:bx <- addr of base table
	mov	al, {byte}ds:[mediaVars.BPB_sectorsPerTrack]
	mov	es:[bx+4], al

	segmov	es, ds, bx
	mov	bx, offset dgroup:[formatTrackBuf]	;es:bx <- buffer

	;-----------------------------------------------------------------------
	;al <- sector size code

	mov	ax, ds:[mediaVars.BPB_sectorSize]
	mov	al, ah				;ax <- sector size / 256
	test	al, 4
	je	codeOK
	dec	al				;al <- 3 if sector size = 1024

codeOK:
	;-----------------------------------------------------------------------
	;loop to initialize address field list

	mov	bp, ds:[mediaVars.BPB_sectorsPerTrack]
	mov	ah, 1

	push	bx
createLoop:
	;-----------------------------------------------------------------------
	;init address field list entry

	mov	es:[bx][AFE_cylinderNum], ch
	mov	es:[bx][AFE_headNum], dh
	mov	es:[bx][AFE_sectorNum], ah
	mov	es:[bx][AFE_sectorSize], al	;store sector size code
	add	bx, size AddrFieldEntry

	inc	ah				;next sector number
	dec	bp				;dec count
	jne	createLoop			;loop while not done
	pop	bx				;make bx point back to buf start

	;-----------------------------------------------------------------------
	;ch - cylinder
	;dh - head
	;dl - drive number
	;es:bx - buffer addr

	mov	ds:[tryCount], BIOS_OP_NUM_TRIES
doFormat:
	;-----------------------------------------------------------------------
	;stuff disk base table entry with correct number of sectors
	;some way around this?

	mov	ah, 5				;BIOS format track
	mov	al, {byte}ds:[mediaVars.BPB_sectorsPerTrack]
	call	FormatInt13
	jc	tryAgain

	mov	ah, 4
	mov	al, {byte}ds:[mediaVars.BPB_sectorsPerTrack]
	mov	cl, 1
	call	FormatInt13
	jc	tryAgain

;	call	NoIoctlVerifyTrack
	jmp	short done

tryAgain:
	mov	ds:[errCode.low], ah

	clr	ah		; reset disk
	call	FormatInt13

	dec	ds:[tryCount]
	jne	doFormat
	stc
done:
	pop	ax,bx,cx,bp,es
	ret
NoIoctlFormatFloppyTrack	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NoIoctlVerifyTrack

DESCRIPTION:	***** NOT CURRENTLY USED *****

CALLED BY:	INTERNAL (NoIoctlFormatFloppyTrack)

PASS:		ds - dgroup
		ch - cylinder number
		cl bits 7,6 - ms 2 bits of cylinder number (should be 0)
		dh - head number
		dl - drive (0 based)
		ds:[mediaBytesPerTrack]
		ds:[trackVerifyBufSegAddr]

RETURN:		carry clear if track verifies OK
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

IF	0	;***************************************************************

NoIoctlVerifyTrack	proc	near
	push	ax,cx,bp,es,di

	;-----------------------------------------------------------------------
	;init track buffer

	push	cx
	mov	es, ds:[trackVerifyBufSegAddr]
	clr	di
	mov	cx, ds:[mediaBytesPerTrack]
	shr	cx, 1				;cx <- num words per track
	mov	bp, cx				;save num words
	mov	ax, TRACK_VERIFY_VALUE
	rep	stosw
	pop	cx

	and	cl, 11000000b			;keep cylinder bits
	or	cl, 1				;specify sector 1
	;-----------------------------------------------------------------------
	;write buffer

	mov	ah, 03				;BIOS write sectors
	mov	al, byte ptr ds:[mediaSectorsPerTrack]
	clr	bx				;es:bx <- track buffer
	call	FormatInt13
	jc	error

	;-----------------------------------------------------------------------
	;read buffer

	mov	ah, 02				;BIOS read sectors
	call	FormatInt13
	jc	error

	;-----------------------------------------------------------------------
	;verify buffer

	clr	di
	mov	ax, TRACK_VERIFY_VALUE
	mov	cx, bp				;retrieve num words per track
	repe	scasw
	tst	cx				;deviation from val?
	clc
	je	done				;done if ok
error:
	stc
done:
	pop	ax,cx,bp,es,di
	ret
NoIoctlVerifyTrack	endp

ENDIF		;***************************************************************


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NoIoctlFormatFixedDiskTrack

DESCRIPTION:	Formats a track on a floppy disk with no recourse to
		the IOCTL functions.

CALLED BY:	INTERNAL (FormatTrack)

PASS:		ds - dgroup
		ch - cylinder number (low 8 bits of cylinder number)
		cl bits 7,6 - ms 2 bits of cylinder number
		dh - head number
		dl - drive (0 based)

RETURN:		carry clear if successful
		carry set otherwise, err code in ds:[errCode]

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	int 13h, function 6 (format track and set bad sector flags)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

NoIoctlFormatFixedDiskTrack	proc	near
	push	ax,dx
	sub	dl, 2		;make fixed drive 0 based
	or	dl, 80h		;set bit 7

	mov	ds:[tryCount], BIOS_OP_NUM_TRIES

doFormat:
	mov	ah, 6		;BIOS format track and set bad sector flags
	mov	al, FORMAT_INTERLEAVE
	call	FormatInt13

	mov	al, ah
	mov	ah, 0
	mov	ds:[errCode], ax
	jnc	done

	dec	ds:[tryCount]
	jne	doFormat
	stc
done:
	pop	ax,dx
	ret
NoIoctlFormatFixedDiskTrack	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CallStatusCallback

DESCRIPTION:	Calls the callback routine if one was supplied.

CALLED BY:	INTERNAL

PASS:		carry from latest disk op
		ds:[callbackRoutine]

RETURN:		carry clear to proceed
		carry set to abort
		ax = error code from latest disk op, or
		     FMT_ABORTED

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

CallStatusCallback	proc	near
;;	jc	exit

	push	cx,dx
	cmp	ds:[callbackRoutine.offset], 0ffffh
	je	done

	mov	cx, ds:[curCylinder]
	mov	dx, ds:[curHead]

	cmp	ds:[callbackInfoFlag], CALLBACK_WITH_PCT_DONE
	jne	doCall

	mov	ax, cx
	mul	ds:[mediaVars.BPB_numHeads]	;dx:ax <- num tracks into the
						;	disk
	mov	dx, 100
	mul	dx
	div	ds:[numTracks]
doCall:
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	mov	ax, ds:[callbackRoutine].offset
	mov	bx, ds:[callbackRoutine].segment
	call	ProcCallFixedOrMovable
	mov	ax, FMT_ABORTED
	jc	done
	clr	ax
done:
	pop	cx,dx
;;exit:
	ret
CallStatusCallback	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ECCheckDS

DESCRIPTION:	Checks to see that ds and es are as expected.

CALLED BY:	INTERNAL ()

PASS:		ds - dgroup

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

IF	ERROR_CHECK
ECCheckDS	proc	near
	push	ax, bx
	mov	ax, dgroup
	mov	bx, ds
	cmp	ax, bx
	ERROR_NZ	FORMAT_BAD_DS
	pop	ax, bx
	ret
ECCheckDS	endp
ENDIF
