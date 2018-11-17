COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netwareSpecific.asm

AUTHOR:		Chung Liu, Oct 14, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/14/92		Initial revision


DESCRIPTION:
	Netware specific driver routines (DR_NETWARE_*)
		

	$Id: netwareSpecific.asm,v 1.1 97/04/10 11:55:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident 	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWMapDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Permanently assign a workstation drive to a directory on
		the current file server.

CALLED BY:	DR_NETWARE_MAP_DISK
PASS:		es:ax	= asciiz directory path (full or partial) on the
			  file server.
		cx:dx	= asciiz drive name.			  
		bl	= ascii drive letter.
RETURN:		al	= completion code
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWMapDrive	proc	far
dirPath 	local	fptr	push es, ax
driveName	local	fptr	push cx, dx	
reqBuf		local	fptr
repBuf		local	fptr
	uses	ds,si,es,di,bx,cx,dx
	.enter
	
	call	LoadVarSegDS
	mov	si, offset nwMapDriveRequestBuffer
	mov	di, offset nwMapDriveReplyBuffer
	
	movdw	reqBuf, dssi
	movdw	repBuf, dsdi

	;
	; stuff directory path in the request buffer, while
	; counting the length
	;
	les	di, reqBuf
	add	di, offset NREQBUF_APDH_path
	lds	si, dirPath
	
	clr 	cx	;initial length = 0;
	
copyPath:
	lodsb
	tst	al	;test for end of string
	jz	copyDone
	stosb
	inc	cx
	cmp	cx, 255
	jb	copyPath	;max 255 chars

	mov	al, NRC_INVALID_PATH
	jmp	error

copyDone:
	;
	; stuff other request buffer data
	;
	lds	si, reqBuf	
	mov	ds:[si].NREQBUF_APDH_subfunc, 
			low NFC_ALLOC_PERMANENT_DIRECTORY_HANDLE
	mov	ds:[si].NREQBUF_APDH_dirHandle, 0
	mov	ds:[si].NREQBUF_APDH_driveLetter, bl
	mov	ds:[si].NREQBUF_APDH_pathLength, cl
	add	cx, offset NREQBUF_APDH_path - size NREQBUF_APDH_length
	mov	ds:[si].NREQBUF_APDH_length, cx

	;
	; call netware
	;
	les	di, repBuf
	mov	ax, NFC_ALLOC_PERMANENT_DIRECTORY_HANDLE
	call 	FileInt21
	
	;al = return code from NetWare
	tst	al
	jnz	error

	;
	; call FSDInitDrive to tell the rest of the system 
	; that we just added a new drive.
	;
	mov	ah, MEDIA_FIXED_DISK
	mov	al, bl
	sub	al, 'A'			; drive number instead of letter
 	clr     bx                      ; no private data
	mov     cx, DriveExtendedStatus <
                                0,              ; drive may be available over
                                                ;  net
                                0,              ; drive not read-only
                                0,              ; drive cannot be formatted
                                0,              ; drive not an alias
                                0,              ; drive not busy
                                <
                                    1,          ; drive is present
                                    0,          ; assume not removable
                                    1,          ; assume is network
                                    DRIVE_FIXED ; assume fixed
                                >
                        >
	call	LoadVarSegDS
	mov	dx, ds:[fsdOffset]		;FSDriver offset
	lds	si, driveName

	call	FSDInitDrive	

	clr	ax			; (clears carry)
exit:	
	.leave
	ret
error:
	stc
	jmp	exit	
NWMapDrive	endp

		
Resident	ends		
