COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS	
MODULE:		Irlmp
FILE:		irdbGetValueInternal.asm

AUTHOR:		Andy Chiu, Feb 11, 1996

ROUTINES:
	Name			Description
	----			-----------
	IIGVBCLookForAttribute
	IIGVBCLookForAttributeCallback

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/11/96   	Initial revision


DESCRIPTION:
	Routines to handle the internals of a GetValueByClass request
		

	$Id: irdbGetValueInternal.asm,v 1.1 97/04/05 01:08:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrdbCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIGVBCLookForAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the specified attribute and write
		it into our HugeLMem

CALLED BY:	IrdbGetValueByClass
PASS:		ds:si	= IrdbObjectArrayElement that we're searching
		
RETURN:		writes data using the local variables it inherits.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIGVBCLookForAttribute	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter inherit IrdbGetValueByClass

	;
	; Look for the for the attributes in the attribute array.
	;
		movdw	ss:objArrayElement, dssi
		mov	ax, ds:[si].IOAE_attrsBlockHandle
		mov	dx, ds:[si].IOAE_objectID
		mov	si, ds:[si].IOAE_attrsChunkHandle
	;
	; Lock the attributes block down
	;
		push	bp			; save for locals
		mov	bx, ss:fileHandle
		call	VMLock			; ax <- segment
		pop	bp			; restore for locals
		mov_tr	ds, ax			; *ds:si <- attrs array
	;
	; Look through the possible attrs to see if we have a match
	;
		Assert	ChunkArray	dssi
		mov	bx, SEGMENT_CS
		mov	di, offset IIGVBCLookForAttributeCallback
		call	ChunkArrayEnum
	;
	; If we didn't find an element.  Let's get out of here.
	;
	LONG	jnc	unlockBlock

		mov_tr	di, ax		; ds:di <- attr element
	;
	; The strings are the same.  Now we have to write the attribute
	; value and object id. 
	;
		mov	cx, size word

		pushdw	dssi
		
		lds	si, ss:objArrayElement
		mov	bx, ds:[si].IOAE_objectID
		xchg	bl, bh
		mov	ds:[si].IOAE_objectID, bx
		movdw	dxax, dssi
		call	sendData

		xchg	bl, bh
		mov	ds:[si].IOAE_objectID, bx

		popdw	dssi
	;
	; Up the count of the number of objects that we found with
	; the matching classname and attribute.
	;
		inc	ss:foundCount
	;
	; Write the type of the attribute found.
	;
		mov	cx, size byte
		mov	dx, ds
		lea	ax, ds:[di].IAAE_attrType
		call	sendData

	;
	; Now depending on the type of attribute, write the data to the
	; stream.
	;
		mov	cl, ds:[di].IAAE_attrType

		cmp	cl, IIVT_OCTET_SEQUENCE		
		jz	writeSequence

		cmp	cl, IIVT_USER_STRING		
		jz	writeUserString

		cmp	cl, IIVT_INTEGER
		jnz	unlockBlock

writeInteger::
		mov	cx, size dword
		lea	ax, ds:[di].IAAE_attrData.AD_integer
		call	sendData

		jmp	unlockBlock
		
writeSequence:
	;
	; Get how many bytes to copy.  Switch it into network order.
	; Write it to the stream.  Fixup our data back to little endian
	;
		mov	bx, ds:[di].IAAE_attrData.AD_octetSequence.OSD_size
		xchg	bl, bh
		mov	ds:[di].IAAE_attrData.AD_octetSequence.OSD_size, bx
		lea	ax, ds:[di].IAAE_attrData.AD_octetSequence.OSD_size
		mov	cx, size word
		call	sendData

		xchg	bl, bh
		mov	ds:[di].IAAE_attrData.AD_octetSequence.OSD_size, bx
	;
	; Get DX:AX to point to the attribute data sequence
	;
		mov	cx, bx			; number of bytes to write
		mov	bx, ds:[di].IAAE_attrData.AD_octetSequence.OSD_data
		mov	ax, ds:[bx]		; deref data
	;
	; Copy the data to the packet.
	;
		call	sendData
		jmp	unlockBlock

		
writeUserString:
	;
	; First write the char set, and then write the data.
	;
		mov	cx, size byte
		lea	ax, ds:[di].IAAE_attrData.AD_userString.USD_charSet
		call	sendData

		lea	ax, ds:[di].IAAE_attrData.AD_userString.USD_size
		call	sendData
		
		clr	cx
		mov	cl, ds:[di].IAAE_attrData.AD_userString.USD_size
		mov	bx, ds:[di].IAAE_attrData.AD_userString.USD_data
		mov	ax, ds:[bx]		; deref data
		call	sendData
		jmp	unlockBlock
	;
	; Unlock the attrs array block
	; 
unlockBlock:
		mov	bp, ds:[LMBH_handle]
		call	VMUnlock


		.leave
		ret

sendData:
		push	ds, si, ax, bp
		lds	si, ss:serverFsm
		mov_tr	bp, ax
		mov	ax, MSG_ISF_SEND_DATA
		call	ObjCallInstanceNoLock
		pop	ds, si, ax, bp
		ret

IIGVBCLookForAttribute	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIGVBCLookForAttributeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go throught the attribute array and look for
		the attribute that matches the one we're looking for

CALLED BY:	IIGVBCLookForAttribute via ChunkArrayEnum
PASS:		*ds:si	= IrdbAttrArray
		ds:di	= IrdbAttrArrayEntry
RETURN:		carry set when element found
		ds:ax	= element found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIGVBCLookForAttributeCallback	proc	far
		uses	cx,si,di
		.enter	inherit	IIGVBCLookForAttribute

	;
	; First check to see if the string sizes match.  If they don't
	; they can't be the same.
	;
		clr	cx
		mov	cl, ds:[di].IAAE_attrNameSize
		cmp	cl, ss:attrSize
		jnz	noMatch
	;
	; Well the string sizes match, so check to see if they
	; if they are the same
	;
		mov	ax, di			; ds:ax <- attr element
		mov	si, ds:[di].IAAE_attrName
		mov	si, ds:[si]		; ds:si <- attr name

		les	di, ss:attrString	; es:di <- passed attr
		
		repe	cmpsb
		jnz	noMatch

		stc
		jmp	done
		
noMatch:
		clc
done:		
		.leave
		ret
IIGVBCLookForAttributeCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IIGVBCLookForClassCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		cxdxbpes
		es:dx	= class name to look for
		cx	= size of class name
		bp	= for local variables
		ds:di	= Object Array Element
RETURN:		
DESTROYED:	ax, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IIGVBCLookForClassCallback	proc	far
		.enter inherit IrdbGetValueByClass
	;
	; See if the string size matches
	;
		cmp	cl, ds:[di].IOAE_classNameSize
		jnz	exit

	;
	; Compare the strings to see if they're the same
	;
		push	di
		lea	si, [di].IOAE_className	; ds:si <- class name

		mov	di, dx			; es:di <- string to match
	;
	; Do the comparison.  If we don't find it, then go to the next one.
	; This uses sbcs strings in both the dbcs and sbcs version.
	;	
		SBCompareStrings	
		pop	si			; ds:si <- obj array element
		jnz	exit

	;
	; Found a class name that matches.  Find out to see if it has the
	; attribute we want.
	;
		inc	ss:classMatchCount
		call	IIGVBCLookForAttribute
		
exit:
		clc
		.leave
		ret
IIGVBCLookForClassCallback	endp


IrdbCode	ends






