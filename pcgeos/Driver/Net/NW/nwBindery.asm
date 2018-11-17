COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nwBindery.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

DESCRIPTION:
	Common code to deal with the NetWare bindery	

	$Id: nwBindery.asm,v 1.1 97/04/18 11:48:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetWareResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Small fixed-code routine to pass off the "object"
		functions. 

CALLED BY:	NetWareStrategy.

PASS:		al - NetObjectFunction to call

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareObject	proc near
	call	NetWareRealObject
	ret
NetWareObject	endp

NetWareResidentCode	ends

NetWareCommonCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareRealObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"Real" object function -- in movable code resource.

CALLED BY:	NetWareObject

PASS:		al - NetObjectFunction to call

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareRealObject	proc far
	clr	ah
	mov_tr	di, ax

EC <	cmp	di, NetPrintFunction	>
EC <	ERROR_AE NW_ERROR_INVALID_DRIVER_FUNCTION			>

	call	cs:[netWareObjectCalls][di]
	.leave
	ret
NetWareRealObject	endp

netWareObjectCalls	nptr	\
	offset	NetWareObjectReadPropertyValue,
	offset NetWareObjectEnumProperties

.assert (size netWareObjectCalls eq NetObjectFunction)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareObjectReadPropertyValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the property of a given object

CALLED BY:	NetWareRealObject, NetWareUserGetFullName

PASS:		ss:bx - NetObjectReadPropertyValueStruct

RETURN:		nothing 

DESTROYED:	es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareObjectReadPropertyValue	proc near

	uses	ds,si,bx,bp,cx,dx

	.enter

	mov	bp, bx		; ss:bp - NetObjectReadPropertyValueStruct

	;
	; Allocate the request and reply buffers
	;

	mov	bx, size NReqBuf_ReadPropertyValue
	mov	cx, size NRepBuf_ReadPropertyValue
	call	NetWareAllocRRBuffers
	mov	ax, ss:[bp].NORPVS_objectType
	mov	es:[si].NREQBUF_RPV_objectType, ax

	;
	; Copy the object name into the request buffer.  Store length
	; in DX
	;
	push	di, si
	mov	bx, si				; es:bx - request buf
	lea	di, es:[si].NREQBUF_RPV_objectName
	lds	si, ss:[bp].NORPVS_objectName
	call	NetWareCopyStringButNotNull	; es:di - next byte in
						; request buf

EC <	cmp	cx, size NetObjectName		>
EC <	ERROR_A	STRING_BUFFER_OVERFLOW		>

	mov	es:[bx].NREQBUF_RPV_objectNameLen, cl

	;
	; store the initial segment number in the next byte -- leave a
	; byte available to store the property length, which we'll
	; fill in after we figure it out.
	;

	mov	{byte} es:[di], NW_BINARY_OBJECT_PROPERTY_INITIAL_SEGMENT
	inc	di
	mov	bx, di		; address of property length
	inc	di

	;
	; Copy in the property name, and store its length
	;

	lds	si, ss:[bp].NORPVS_propertyName
	call	NetWareCopyStringButNotNull	; cx - # chars in prop name

EC <	cmp	cx, size NetPropertyName	>
EC <	ERROR_A	STRING_BUFFER_OVERFLOW		>

	mov	es:[bx], cl

	mov_tr	ax, di			; ax - one byte AFTER last
					; byte written
	pop	di, si			;es:si - request, es:di - reply

	;
	;calculate the size of this request buffer, and place it at
	;the beginning of the buffer

	sub	ax, si
	sub	ax, 2
	mov	es:[si].NREQBUF_RPV_length, ax

	;now call NetWare to get the property's value

callNW::
	mov	ax, NFC_READ_PROPERTY_VALUE
	call	NetWareCallFunctionRR	;call NetWare, passing RR buffer
	jc	done

	;see if there will be another segment of data

EC <	tst	es:[di].NREPBUF_RPV_moreSegments			>
EC <	ERROR_NZ NW_ERROR_BAD_ASSUMPTION_THIS_PROPERTY_HAS_MORE_DATA_SEGMENTS >

	;
	; Copy the value into the caller's buffer
	;

	segmov	ds, es
	lea	si, ds:[di].NREPBUF_RPV_propertyValue
	les	di, ss:[bp].NORPVS_buffer
	mov	cx, ss:[bp].NORPVS_bufferSize
	rep	movsb
	segmov	es, ds

done:
	call	NetWareFreeRRBuffers


	.leave
	ret
NetWareObjectReadPropertyValue	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareGetBinderyObjectID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	High-level function to return 
		the ID of an object, given its name

CALLED BY:	internal (NWPRedirectPort, NetWareUserCheckIfInGroup)

PASS:		ds:si - name of object
		ax - object type

RETURN:		IF ERROR:
			carry set
			al - error code
		ELSE:
			carry clear
			cx:dx - object ID
		

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareGetBinderyObjectID	proc far
	uses	ax,bx,di,si
	.enter

	push	si
	mov	bx, size NReqBuf_GetBinderyObjectID
	mov	cx, size NRepBuf_GetBinderyObjectID
	call	NetWareAllocRRBuffers		; es - rr buffers
	mov	es:[si].NREQBUF_GBOID_objectType, ax
	mov	bx, si				; es:bx - request buf
	pop	si

	;
	; Copy the name into the request buffer, and determine its length
	;

	clr	cx
	push	di
	lea	di, es:[bx].NREQBUF_GBOID_objectName

startLoop:
	lodsb
	stosb
	inc	cx
	tst	al
	jnz	startLoop

	dec	cx
	pop	di			; es:di - reply buf
	mov	si, bx			; es:si - request buf
	mov	es:[si].NREQBUF_GBOID_objectNameLen, cl
	mov	ax, NFC_GET_BINDERY_OBJECT_ID
	call	NetWareCallFunctionRR
	jc	done

	; Move low word of HiLoDWord into DX

	movdw	dxcx, es:[di].NREPBUF_GBOID_objectID
	mov	bx, es:[NRR_handle]
	call	MemFree
	clc
done:
	.leave
	ret
NetWareGetBinderyObjectID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareGetBinderyObjectName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the name of a bindery object, given its ID

CALLED BY:	NWPGetCaptureQueue

PASS:		ds:si - buffer to fill in
		dx:ax - NetWareBinderyObjectID (dx - HIGH word as
		defined by Novell (ie, first word)

RETURN:		if error
			carry set
		else
			carry clear
			buffer filled in


DESTROYED:	ax,bx,cx,dx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareGetBinderyObjectName	proc near
	uses	si,es,di,bp
	.enter

	mov	bp, si			; dest ptr
	
	mov	bx, size NReqBuf_GetBinderyObjectName
	mov	cx, size NRepBuf_GetBinderyObjectName
	call	NetWareAllocRRBuffers
	movdw	es:[si].NREQBUF_GBON_objectID, axdx
	mov	ax, NFC_GET_BINDERY_OBJECT_NAME	
	call	NetWareCallFunctionRR

	jc	freeBuffers

	;
	; Copy the data out
	;

	lea	si, es:[di].NREPBUF_GBON_objectName
	mov	di, bp			
	segxchg	ds, es			; es:di - dest
	call	NetWareCopyNTString
	segxchg	ds, es
	clc

freeBuffers:
	call	NetWareFreeRRBuffers
	.leave
	ret
NetWareGetBinderyObjectName	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareObjectEnumProperties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a list of the properties defined for this object

CALLED BY:	NetWareRealObject

PASS:		ds - segment of NetEnumCallbackData
		cx:dx - NetObjectName
		bx - NetObjectType
	
RETURN:		nothing 

DESTROYED:	es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareObjectEnumProperties	proc near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	;
	; Allocate the request and reply buffers.
	;

	push	bx
	push	cx
	mov	bx, size NReqBuf_ScanProperty
	mov	cx, size NRepBuf_ScanProperty
	call	NetWareAllocRRBuffers
	pop	cx
	pop	es:[si].NREQBUF_SP_objectType

	;
	; Fill in the CallbackData fields
	;

	mov	ds:[NECD_curElement].segment, es
	lea	ax, es:[di].NREPBUF_SP_propertyName
	mov	ds:[NECD_curElement].offset, ax

	;
	; Fill in fields of request buffer
	;
	push	di
	push	ds, si
	mov	ds, cx
	lea	di, es:[si].NREQBUF_SP_objectName
	mov	si, dx
	call	NetWareCopyStringButNotNull
EC <	cmp	cx, size NREQBUF_SP_objectName	>
EC <	ERROR_A	STRING_BUFFER_OVERFLOW			>
	pop	ds, si
	mov	es:[si].NREQBUF_SP_objectNameLen, cl


	;
	; Now, ES:DI is pointing at the sequenceNumber field.  Save
	; the offset in BX so that we can update this field on each
	; iteration. 
	;

	mov	bx, di
	mov	ax, -1
	stosw
	stosw			; NREQBUF_SP_sequenceNumber
	mov	ax, 1
	stosb			; NREQBUF_SP_propertyNameLen

	;
	; 
	;

		CheckHack <size wildcard eq 2>		
		CheckHack <segment wildcard eq @CurSeg>
	mov	ax, {word} cs:[wildcard]
	stosw			; NREQBUF_SP_propertyName

	pop	di

startLoop:

	;
	; Make the next call
	;

	mov	ax, NFC_SCAN_PROPERTY
	call	NetWareCallFunctionRR

	jnc	continue
	cmp	al, 0xFB		; netware return code that
					; signifies valid end of loop,
					; according to the docs...
	je	done
	stc
	jmp	done

continue:
	;
	; Call the callback routine to add our data to the caller's
	; buffer. 
	;

	call	NetEnumCallback

	tst	es:[di].NREPBUF_SP_moreProperties
	jz	done

	;
	; Copy the sequence number from the reply buffer back to the
	; request buffer, and continue
	;

	movdw	es:[bx], es:[di].NREPBUF_SP_sequenceNumber, ax
	jmp	startLoop

done:
	;
	; Free the request / reply buffers
	;

	call	NetWareFreeRRBuffers

	.leave
	ret
NetWareObjectEnumProperties	endp

NetWareCommonCode	ends  
