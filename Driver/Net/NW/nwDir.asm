COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Novell NetWare Driver
FILE:		nwDir.asm

AUTHOR:		Chung Liu, Dec 29, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/29/92   	Initial revision


DESCRIPTION:
	Code for directory related netware stuff.
		

	$Id: nwDir.asm,v 1.1 97/04/18 11:48:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareGetVolumeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the volume name given the volume number.
		Volume name will be null-terminated.

CALLED BY:	Net Library
PASS:		ds:si 	- buffer of size >= NETWARE_VOLUME_NAME_SIZE+1
		dl	- volume number (0 to 31)
RETURN:		al	- NetWareReturnCode (0 = successful)
		carry set on error
DESTROYED:	?
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	* May want to change to add length of name as a return value
	and not null-terminate.  Need to investigate API for other
	network drivers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/29/92    	Initial version
	dloft	1/1/93		Changed to null-terminate vol. name.
	dloft	2/13/93		Fixed to handle errors from NetWareCallFunctionRR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode 	segment resource
NetWareGetVolumeName	proc	near
	call NetWareGetVolumeNameInternal
	ret
NetWareGetVolumeName	endp
NetWareResidentCode 	ends

NetWareCommonCode 	segment resource
NetWareGetVolumeNameInternal	proc	far
	uses	bx, cx, dx, ds, si, bp, es, di
	.enter
EC <	mov	ax, ds					>
EC <	call	ECCheckSegment				>

	push	ds, si				;buffer from caller

	mov	bx, size NReqBuf_GetVolumeName
	mov	cx, size NRepBuf_GetVolumeName
	call	NetWareAllocRRBuffers
	push	es, di				;reply buffer

	mov	{byte} es:[si].NREQBUF_GVN_volumeNumber, dl
	mov	ax, NFC_GET_VOLUME_NAME
	call	NetWareCallFunctionRR
	jc	handleError

	;
	; copy from reply buffer to buffer passed by user
	;
	pop	ds, si				;reply buffer
	add	si, NREPBUF_GVN_name
	clr	cx
	mov	cl, es:[di].NREPBUF_GVN_nameLength
	pop	es, di				;volume name buffer
	rep	movsb

	mov	{byte} es:[di], 0		; null-terminate
	; 
	; free buffers allocated by NetWareAllocRRBuffers
	;
	segmov	es, ds
	mov	al, 0
done:
	call	NetWareFreeRRBuffers
	.leave
	ret

handleError:
	pop	ds, si
	pop	ds, di				; es = reply buffer

	stc
	jmp	done

NetWareGetVolumeNameInternal	endp
NetWareCommonCode 	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareGetDriveCurrentPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current directory (full path) for a given
		drive.

CALLED BY:	Net Library

PASS:		ds:si 	- buffer of size >= DOS_STD_PATH_LENGTH
		dl	- drive letter

RETURN:		al	- NetWareReturnCode (0 = successful)

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	4/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetWareResidentCode 	segment resource

NetWareGetDriveCurrentPath	proc	near
	call	NetWareGetDriveCurrentPathInternal
	ret
NetWareGetDriveCurrentPath	endp
NetWareResidentCode 	ends

NetWareCommonCode 	segment resource

NetWareGetDriveCurrentPathInternal	proc	far
pathBuffer	local	fptr
	uses	bx,cx,dx,ds,si,es,di
	.enter

EC <	mov	ax, ds					>
EC <	call	ECCheckSegment				>

	movdw	pathBuffer, dssi

	sub	dl, 'A'
	clr	dh
	mov	ax, NFC_GET_DIRECTORY_HANDLE
	call	NetWareCallFunction
	tst	al
	jz	error				;invalid drive

	; al = dirHandle

	mov	bx, size NReqBuf_GetDirectoryPath
	mov	cx, size NRepBuf_GetDirectoryPath
	call	NetWareAllocRRBuffers		;returns ^hbx = block (locked)
	push	bx

	;es:si = request buffer, es:di = reply buffer

	mov	es:[si].NREQBUF_GDP_subFunc, 1
	mov	es:[si].NREQBUF_GDP_dirHandle, al
	
	segmov	ds, es
	mov	ax, NFC_GET_DIRECTORY_PATH
	call	NetWareCallFunction
	tst	al
	jnz	error

	;es:di = reply buffer 
	clr	cx
	mov	cl, es:[di].NREPBUF_GDP_pathLength
	segmov	ds, es
	mov	si, di				;now ds:si = reply buffer
	add	si, NREPBUF_GDP_path		;now ds:si = NREPBUF_GDP_path

	;copy the string from the reply buffer to the user-provided buffer
	les	di, pathBuffer
	rep	movsb
	
	;null-terminate the user-provided buffer
	clr	al
	stosb

	pop	bx
	call	MemFree

exit:
	.leave
	ret

error:
	jmp	exit

NetWareGetDriveCurrentPathInternal	endp

NetWareCommonCode 	ends

