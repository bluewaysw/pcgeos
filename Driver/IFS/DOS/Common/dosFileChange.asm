COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		dosFileChange.asm

AUTHOR:		Adam de Boor, Nov 10, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/10/92	Initial revision


DESCRIPTION:
	Support functions for generating file-change notification.
		

	$Id: dosFileChange.asm,v 1.1 97/04/10 11:55:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileChangeCalculateID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the 32-bit ID for a path.

CALLED BY:	(EXTERNAL)
PASS:		ds:si	= path whose ID wants calculating
RETURN:		cxdx	= 32-bit ID
DESTROYED:	si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileChangeCalculateID proc	far
		uses	ax
		.enter
		clr	cx
		mov	dx, 0x31fe	; magic number
		call	DOSFileChangeCalculateIDLow
		.leave
		ret
DOSFileChangeCalculateID endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileChangeCalculateIDLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the 32-bit ID for a path, augmenting an ID
		calculated for the leading components.

CALLED BY:	(EXTERNAL)
PASS:		ds:si	= path whose ID wants calculating
RETURN:		cxdx	= 32-bit ID
DESTROYED:	ax, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileChangeCalculateIDLow proc	far
		uses	bx, di, bp
		.enter
		mov	bx, cx
		mov	cl, 5
		clr	ah
charLoop:
		lodsb
		cmp	al, '\\'	; don't count backslashes, so we avoid
		je	charLoop	;  ickiness augmenting the current dir's
					;  ID during a FileEnum.
		tst	al		; end of string?
		jz	done		; yes
	;
	; Multiply existing value by 33
	; 
		movdw	dibp, bxdx	; save current value for add
		rol	dx, cl		; *32, saving high 5 bits in low ones
		shl	bx, cl		; *32, making room for high 5 bits of
					;  dx
		mov	ch, dl
		andnf	ch, 0x1f	; ch <- high 5 bits of dx
		andnf	dl, not 0x1f	; nuke saved high 5 bits
		or	bl, ch		; shift high 5 bits into bx
		adddw	bxdx, dibp	; *32+1 = *33
	;
	; Add current character into the value.
	; 
		add	dx, ax
		adc	bx, 0
		jmp	charLoop		
done:
	;
	; Return ID in cxdx
	; 
		mov	cx, bx
		.leave
		ret
DOSFileChangeCalculateIDLow endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileChangeGetCurPathID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the ID of the current directory on DOS's default drive.
		This is different from DOSPathGetCurPathID, which returns
		the ID for the thread's current directory, as this can
		be called after mapping a path with leading components
		and obtain the proper result, while the other can't.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		cxdx	= FileID for DOS's current dir.
DESTROYED:	ax, dosPathBuffer
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileChangeGetCurPathID proc	far
		uses	ds, si
		.enter
	;
	; Fetch the DOS dir for the default drive into dosPathBuffer. Don't
	; have to worry that we don't get a leading backslash, as backslashes
	; don't count in the calculation anyway.
	; 
if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeGetCurPath
else	; not SEND_DOCUMENT_FCN_ONLY
		segmov	ds, dgroup, si
		mov	si, offset dosPathBuffer
		clr	dx			; default drive
		mov	ah, MSDOS_GET_CURRENT_DIR
		call	FileInt21
endif	; SEND_DOCUMENT_FCN_ONLY

	;
	; Figure the ID for the thing starting from scratch.
	; 
		call	DOSFileChangeCalculateID
		.leave
		ret
DOSFileChangeGetCurPathID endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileChangeGetCurPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to ask DOS to fill dosPathBuffer with the current path.

CALLED BY:	(INTERNAL) DOSFileChangeGetCurPathID,
			DOSFileChangeCheckIfCurPathLikelyHasDoc
PASS:		nothing
RETURN:		ds:si	= dosPathBuffer
		dosPathBuffer set to DOS current path w/o drive letter or
			leading backslash
		dl	= 0
		CF clear
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/04/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SEND_DOCUMENT_FCN_ONLY

DOSFileChangeGetCurPath	proc	far

	segmov	ds, dgroup, si
	mov	si, offset dosPathBuffer
	clr	dl			; default drive
	mov	ah, MSDOS_GET_CURRENT_DIR
	GOTO	FileInt21

DOSFileChangeGetCurPath	endp

endif	; SEND_DOCUMENT_FCN_ONLY

Resident	ends

PathOps		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileChangeGenerateNotifyWithName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate notification for something that requires a path
		name in the data block

CALLED BY:	(EXTERNAL) DOSAllocOpOpen, DOSAllocOpCreate, DOSPathOpRename,
			   DOSPathOpMove
PASS: 		ax	= FileChangeNotificationType
		[dosPathBuffer] = current directory (DOS)
		[dosFinalComponent] = pointer to file name to include in the
					 notification

		if SEND_DOCUMENT_FCN_ONLY
		si	= disk handle of current dir
		endif
RETURN:		carry clear
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileChangeGenerateNotifyWithName proc far
		uses	cx, dx, ds
		.enter
		call	PathOps_LoadVarSegDS

if SEND_DOCUMENT_FCN_ONLY
		cmp	si, ds:[sysDiskHandle]
		jne	sendNotif

		push	si
		mov	si, offset dosPathBuffer
		call	DOSFileChangeCheckIfPathLikelyHasDoc
		pop	si
		jc	done

sendNotif:
endif	; SEND_DOCUMENT_FCN_ONLY

	;
	; Compute the ID for the containing directory, which is already loaded
	; into dosPathBuffer.
	; 
		push	si
		mov	si, offset dosPathBuffer
		call	DOSFileChangeCalculateID	; cxdx <- dirID
		pop	si
	;
	; Point to the final component on which things operated and generate
	; the notification.
	; 
		lds	bx, ds:[dosFinalComponent]
		call	FSDGenerateNotify
done::
		clc
		.leave
		ret
DOSFileChangeGenerateNotifyWithName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileChangeGenerateNotifyForNativeFFD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a file-change notification for whatever's in
		dosNativeFFD

CALLED BY:	(EXTERNAL) DOSPathOpDeleteDir
PASS:		ax	= FileChangeNotificationType
		ds	= dgroup
RETURN:		carry clear
DESTROYED:	ax, dosPathBuffer
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileChangeGenerateNotifyForNativeFFD proc	far
		uses	cx, dx
		.enter
if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	done		; => no
endif	; SEND_DOCUMENT_FCN_ONLY
if _MSLF
		GetIDFromFindData	ds:[dos7FindData], cx, dx
else
		GetIDFromDTA	ds:[dosNativeFFD], cx, dx
endif
		call	FSDGenerateNotify
done::
		clc
		.leave
		ret
DOSFileChangeGenerateNotifyForNativeFFD endp

if SEND_DOCUMENT_FCN_ONLY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileChangeCheckIfPathLikelyHasDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the passed path is likely to contain documents.

CALLED BY:	(EXTERNAL)
PASS:		ds:si	= path to check
RETURN:		CF clear if path is likely to contain documents, ie. one of
		the following:
			- under SP_DOCUMENT
			- under SP_TOP\DESKTOP
			- under SP_WASTE_BASKET
			- under SP_APPLICATION
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/04/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileChangeCheckIfPathLikelyHasDoc	proc	far
	uses	es
	.enter
	pusha

	segmov	es, dgroup

ifdef	GPC
	; If in Enhanced Mode, any path is likely to have doc.
	tst_clc	es:[enhancedMode]
	jnz	done			; => Enhanced Mode, return CF clear
endif	; GPC

	;
	; Skip any leading backslash in passed path.
	;
	cmp	{char}ds:[si], '\\'
	jne	compare
	inc	si			; skip passed backslash
compare:

	mov	di, offset desktopPath + size char	; skip our backslash
	mov	cx, es:[desktopPathLengthNoBS]
	call	comparePath
	jnc	done			; => yes

	mov	di, offset docPath + size char	; skip our backslash
	mov	cx, es:[docPathLengthNoBS]
	call	comparePath
	jnc	done			; => yes

	mov	di, offset wbPath + size char	; skip our backslash
	mov	cx, es:[wbPathLengthNoBS]
	call	comparePath
	jnc	done			; => yes

	mov	di, offset appPath + size char	; skip our backslash
	mov	cx, es:[appPathLengthNoBS]
	call	comparePath

done:
	popa
	.leave
	ret

comparePath	label	near
	push	si

	;
	; Check if prefix in passed path matches.
	;
	repe	cmpsb
	stc
	jne	doneCompare

	;
	; Check if the last matching component actually ends here.
	;
	tst_clc	{char}ds:[si]
	je	doneCompare
	cmp	{char}ds:[si], '\\'
	je	doneCompare		; => CF clear
	stc				; component doesn't end here, no match

doneCompare:
	pop	si
	retn

DOSFileChangeCheckIfPathLikelyHasDoc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFileChangeCheckIfCurPathLikelyHasDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if current directory is likely to contain documents.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		CF clear if current path is likely to contain documents, ie.
		one of the following:
			- under SP_DOCUMENT
			- under SP_TOP\DESKTOP
			- under SP_WASTE_BASKET
			- under SP_APPLICATION
			- on a non-system disk
DESTROYED:	dosPathBuffer
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/04/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFileChangeCheckIfCurPathLikelyHasDoc	proc	far
	uses	ds
	.enter
	pusha

	call	PathOps_LoadVarSegDS

ifdef	GPC
	; If in Enhanced Mode, any path is likely to have doc.
	tst_clc	ds:[enhancedMode]
	jnz	done			; => Enhanced Mode, return CF clear
endif	; GPC

	;
	; It's likely to contain docs if it's anywhere not on system drive.
	;
	mov	ah, MSDOS_GET_DEFAULT_DRIVE
	call	DOSUtilInt21		; al = 0-based drive #
	cmp	al, ds:[sysDriveNum]
	clc
	jne	done

	call	DOSFileChangeGetCurPath	; ds:si = dosPathBuf with cur path
	call	DOSFileChangeCheckIfPathLikelyHasDoc

done:
	popa
	.leave
	ret
DOSFileChangeCheckIfCurPathLikelyHasDoc	endp

endif	; SEND_DOCUMENT_FCN_ONLY

PathOps	ends
