COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pgfsWindow.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/94   	Initial version.

DESCRIPTION:
	This file contains code that requests a window from Card
Services for accessing card memory
	

	$Id: pgfsWindow.asm,v 1.1 97/04/18 11:46:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Resident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSRequestWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request a window from CS, and determine whether we can
		perform 16-bit accesses on the card

CALLED BY:	PGFSIHandleInsertion

PASS:		ax - socket #
		ds - dgroup
		ds:bx - PGFSSocketInfo

RETURN:		carry set if unable to allocate window
		otherwise -
			PGFSSI_window,
			PGFSSI_windowSeg, 
			PSF_WINDOW_ALLOCATED, and
			PSF_16_BIT
		    set correctly 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Request an 8-bit window (if we can), and a 16-bit window.
	Use "rep movsb" from the 8-bit window, and "rep movsw" from
	the 16-bit one and compare the results.
	If they're different, then use the 8-bit window

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RWFlags	record
    RWF_HAVE_8_BIT:1
    RWF_HAVE_16_BIT:1
RWFlags	end

PGFSRequestWindow	proc near

rwArgs		local	CSRequestWindowArgs
rwFlags		local	RWFlags
window8		local	word
windowSeg8	local	sptr
header8		local	GFSPartialHeader
window16	local	word
windowSeg16	local	sptr
header16	local	GFSPartialHeader
		
		.enter
		clr	ss:[rwFlags]
		mov	ss:[rwArgs].CSRWA_socket, ax
		segmov	es, ss

	;
	; First, request an 8-bit window, if possible
	;
		
		mov	ax, mask CSRWA_ENABLED
		call	requestWindow
		jnc	haveWindow8

		cmp	ax, CSRC_BAD_ATTRIBUTE
		je	request16Bit		; => 16-bit only
toFail:
		jmp	fail
haveWindow8:
		ornf	ss:[rwFlags], mask RWF_HAVE_8_BIT
		mov	ss:[windowSeg8], ax
		mov	ds:[bx].PGFSSI_windowSeg, ax
		mov	ss:[window8], dx
		mov	ds:[bx].PGFSSI_window, dx
		
request16Bit:
	;
	; Request a 16-bit window.  If the request fails due to
	; "CSRC_BAD_ATTRIBUTE", then just use the 8-bit window
	;
		
		mov	ax, mask CSRWA_ENABLED or mask CSRWA_16_BIT
		call	requestWindow
		jnc	haveWindow16

		cmp	ax, CSRC_BAD_ATTRIBUTE
		jne	toFail

		test	ss:[rwFlags], mask RWF_HAVE_8_BIT
		jz	toFail

		andnf	ds:[bx].PGFSSI_flags, not mask PSF_16_BIT
		jmp	readHeader

haveWindow16:
		ornf	ss:[rwFlags], mask RWF_HAVE_16_BIT
		mov	ss:[window16], dx
		mov	ss:[windowSeg16], ax
	;
	; If we were able to allocate an 8-bit window, then read
	; through it.  Otherwise, read throught the 16-bit window, but
	; perform 8-bit memory accesses, in case Card Services
	; supports 16-bit windows, but the card doesn't (or something).
	;
	; dx, ax = 16-bit window info
	;
		
		test	ss:[rwFlags], mask RWF_HAVE_8_BIT
		jnz	read8
		mov	ds:[bx].PGFSSI_windowSeg, ax
		mov	ds:[bx].PGFSSI_window, dx
read8:
		andnf	ds:[bx].PGFSSI_flags, not mask PSF_16_BIT
		lea	di, ss:[header8]
		mov	cx, size header8
		clr	ax, dx
		call	GFSDevRead
		jc	fail

	;
	; Read using 16-bit accesses, and compare the two headers
	;
		test	ss:[rwFlags], mask RWF_HAVE_16_BIT
		jz	use8Bit

		mov	ax, ss:[window16]		
		mov	ds:[bx].PGFSSI_window, ax
		mov	ax, ss:[windowSeg16]
		mov	ds:[bx].PGFSSI_windowSeg, ax
		ornf	ds:[bx].PGFSSI_flags, mask PSF_16_BIT
		lea	di, ss:[header16]
		mov	cx, size header16
		clr	ax, dx
		call	GFSDevRead
		jc	fail

		mov	cx, size GFSPartialHeader
		push	ds
		segmov	ds, ss
		lea	si, ss:[header8]
		repe	cmpsb
		pop	ds
		jne	use8Bit
	;
	; Can use 16-bit window, so nuke 8-bit; Everything else already
	; set up for 16-bit accesses.
	; 
		mov	dx, ss:[window8]
		call	PGFSReleaseWindow
		andnf	ss:[rwFlags], not mask RWF_HAVE_8_BIT
readHeader:
	;
	; Since the whole purpose is to look for a GFS, check to make
	; sure we have one now
	;
		lea	di, ss:[header8]
		cmp	{word} es:[di],	'G' or ('F' shl 8)
		jne	fail
		cmp	{word} es:[di][2], 'S' or (':' shl 8)
		jne	fail

		lea	si, ss:[header8].GFSPH_checksum
		call	convertWord
		mov	ds:[bx].PGFSSI_checksum.high, dx
		call	convertWord
		mov	ds:[bx].PGFSSI_checksum.low, dx

		or	ds:[bx].PGFSSI_flags, mask PSF_WINDOW_ALLOCATED
done:
		.leave
		ret
;;--------------------
fail:
		test	ss:[rwFlags], mask RWF_HAVE_8_BIT
		jz	afterRelease8
		mov	dx, ss:[window8]
		call	PGFSReleaseWindow
afterRelease8:
		test	ss:[rwFlags], mask RWF_HAVE_16_BIT
		jz	afterRelease16
		mov	dx, ss:[window16]
		call	PGFSReleaseWindow
afterRelease16:
		stc
		jmp	done

;;--------------------
use8Bit:

	;
	; The byte move and word moves differed, so we must assume
	; that the card only supports 8-bit accesses.  If we allocated
	; an 8-bit window, then use it, and free the 16-bit window.
	; Otherwise use the 16-bit window, but mark it as only
	; supporting 8-bit accesses.
	;
		andnf	ds:[bx].PGFSSI_flags, not mask PSF_16_BIT
		test	ss:[rwFlags], mask RWF_HAVE_8_BIT
		jz	readHeader		; we have a
						; 16-bit window that
						; only allows 8-bit reads.

		mov	ax, ss:[window8]
		mov	ds:[bx].PGFSSI_window, ax
		mov	ax, ss:[windowSeg8]
		mov	ds:[bx].PGFSSI_windowSeg, ax

		mov	dx, ss:[window16]
		call	PGFSReleaseWindow
		andnf	ss:[rwFlags], not mask RWF_HAVE_16_BIT
		jmp	readHeader
		
;;--------------------
requestWindow:
		push	bx
		mov	cx, size CSRequestWindowArgs
		mov	dx, ds:[csHandle]	;client handle passed
		mov	ss:[rwArgs].CSRWA_attributes, ax
		clrdw	ss:[rwArgs].CSRWA_base
		movdw	ss:[rwArgs].CSRWA_size, 16384
		mov	ss:[rwArgs].CSRWA_speed, DS_250NS 
		lea	bx, ss:[rwArgs]
		CallCS	CSF_REQUEST_WINDOW, DONT_LOCK_BIOS
		jc	rwDone
	;
	; shift base address to get segment address then save it
	;

		movdw	bxax, ss:[rwArgs].CSRWA_base
		shrdw	bxax
		shrdw	bxax
		shrdw	bxax
		shrdw	bxax			; ax - address
		clc
rwDone:
		pop	bx
		retn
;;--------------------
;; Convert a word written in ascii hex to its numeric representation
;; PASS:	es:si - bytes to read
;; RETURN:	es:si - points at next byte
;;		dx    - value read
convertWord:
		clr	dx
		mov	cx, 4
cwLoop:
		lodsb	es:
		sub	al, '0'
		cmp	al, 9
		jbe	storeAL
		sub	al, 'A'-'0'-10
		cmp	al, 15
		jbe	storeAL
		sub	al, 'a'-'A'
storeAL:
		shl	dx		
		shl	dx		
		shl	dx		
		shl	dx		
		or	dl, al
		loop	cwLoop
		retn
PGFSRequestWindow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSReleaseWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a window

CALLED BY:	PGFSRequestWindow, PGFSRHandleRemoval, PGFSEExit

PASS:		

RETURN:		nothing 

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSReleaseWindow	proc near
		uses	cx
		.enter
		clr	cx
		CallCS	CSF_RELEASE_WINDOW, DONT_LOCK_BIOS
		.leave
		ret
PGFSReleaseWindow	endp



Resident ends
