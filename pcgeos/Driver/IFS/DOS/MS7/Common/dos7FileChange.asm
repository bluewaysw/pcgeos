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
		

	$Id: dos7FileChange.asm,v 1.1 97/04/10 11:55:30 newdeal Exp $

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

if _MS7
	;
	; Since dos7 maintains the case when the current dir is set, and
	; different parts of the system use all upper of mixed case, we
	; must convert to upper here so we can depend on the results.
	;
		cmp	al, 'a'
		jb	onWithIt

		cmp	al, 'z'
		ja	onWithIt

		sub	al, 'a' - 'A'
onWithIt:
endif
		

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
		segmov	ds, dgroup, si
		mov	si, offset dosPathBuffer
		clr	dx			; default drive
if _MS7
		mov	ax, MSDOS7F_GET_CURRENT_DIR
else
		mov	ah, MSDOS_GET_CURRENT_DIR
endif
		call	FileInt21
	;
	; Figure the ID for the thing starting from scratch.
	; 
		call	DOSFileChangeCalculateID
		.leave
		ret
DOSFileChangeGetCurPathID endp

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
		si	= disk handle
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
if _MS7
		push	si
		mov	si, offset dos7FindData
		clr	cx, dx
		call	DOS7GetIDFromFD
		pop 	si
else:	
		GetIDFromDTA	ds:[dosNativeFFD], cx, dx
endif
		call	FSDGenerateNotify
		clc
		.leave
		ret
DOSFileChangeGenerateNotifyForNativeFFD endp


PathOps	ends
