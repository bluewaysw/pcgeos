COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netEnum.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

DESCRIPTION:
	

	$Id: netEnum.asm,v 1.1 97/04/05 01:25:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetCommonCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate over a variety of network resources

CALLED BY:	GLOBAL

PASS:		ss:bp - NetEnumParams
		ds - segment of lmem block in which to place chunk
		array, (if chunk array allocation requested)
		di - NetDriverFunction to call 
		al - subfunction (if necessary)


RETURN:		if error:
			carry set
			ax - NetError
		else
			if chunk array requested:
				*ds:si -chunk array

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetEnum	proc far
	uses	ax,bx,cx,dx,es,bp,di
	.enter

	push	bx, cx, dx

	mov_tr	dl, al		; subfunction code

	;
	; Allocate a block of memory for the callback routine to use
	;

	mov	ax, size NetEnumCallbackData
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jnc	memOK

	mov	ax, NET_ERROR_INSUFFICIENT_MEMORY
	jmp	donePop

memOK:
	mov	es, ax
	mov	es:[NECD_handle], bx
	mov	es:[NECD_netDriverFunction], di
	mov	es:[NECD_netDriverSubFunc], dl

	;
	; Copy the NetEnumParams into this block
	;
	push	ds
	segmov	ds, ss
	mov	si, bp			; ds:si - NetEnumParams
	mov	di, offset NECD_params
	mov	cx, size NetEnumParams/2
		CheckHack <(size NetEnumParams and 1) eq 0>
	rep	movsw
	pop	ds

	;
	; See what type the user called us with.  (XXX: Only
	; NEBT_CHUNK_ARRAY_VAR_SIZED is supported at the moment)
	;

	cmp	es:[NECD_params].NEP_bufferType, NEBT_CHUNK_ARRAY_VAR_SIZED
	ERROR_NE	NL_ERROR_ILLEGAL_BUFFER_TYPE

	clr	ax, bx, cx, si
	call	ChunkArrayCreate
	movdw	es:[NECD_buffer], dssi


	;
	; All called functions expect NetEnumCallbackData in DS
	;

	segmov	ds, es

	;
	; Now, call each driver with the requested function, until it
	; returns us an error
	;

	mov	di, ds:[NECD_netDriverFunction]
	mov	al, ds:[NECD_netDriverSubFunc]

	pop	bx, cx, dx
	call	NetForeachDriver		

	;
	; Clean up
	;
	call	NetEnumEnd
done:
	.leave
	ret

donePop:
	pop	bx, cx, dx
	jmp	done

NetEnum		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to process a list of strings

CALLED BY:	various netware drivers

PASS:		ds - segment of NetEnumCallbackData
			ds:NECD_curElement points to another element
			to add.

RETURN:		carry set if error (meory full, etc) 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	
	Add NECD_curElement to the buffer pointed to by NECD_buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
callbackTable	nptr.near	\
	NetEnumError,
	NetEnumError,
	NetEnumChunkArrayVarSized

.assert (size callbackTable eq NetEnumBufferType)

NetEnumCallback	proc far
	uses	di,si,es,ds,ax,bx,cx,dx,bp
	.enter

EC <	call	ECCheckNetEnumCallbackData	>

	;
	; XXX: We may want to call appropriate filtering routines
	; before adding the data.
	;


	;
	; Add the data
	;

	mov	bx, ds:[NECD_params].NEP_bufferType
	call	cs:[callbackTable][bx]

	.leave
	ret
NetEnumCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetEnumChunkArrayVarSized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element to a variable-sized chunk array

CALLED BY:	NetEnumCallback

PASS:		ds - NetEnumCallbackData

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,es,ds 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine deals with 3 different segments, so watch out!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetEnumChunkArrayVarSized	proc near
	.enter

	;
	; get length of source string, including NULL
	;

	les	di, ds:[NECD_curElement]
	clr	al
	mov	cx, -1
	repne	scasb
	not	cx

	;
	; Add another chunk array element. Fixup the far pointer after
	; adding. 
	;

	mov	ax, cx			; element size (no mov_tr)
	segmov	es, ds
	lds	si, es:[NECD_buffer]
	call	ChunkArrayAppend		; ds:di - new element
	mov	es:[NECD_buffer].segment, ds	

	;
	; Copy the data in from the far pointer stored in the
	; NetEnumCallbackData. 
	;
	push	ds			; segment of chunk array
	lds	si, es:[NECD_curElement]	; source data
	pop	es
	rep	movsb

	.leave
	ret
NetEnumChunkArrayVarSized	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetEnumEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up the enumeration -- free the NetEnum block,
		etc. 

CALLED BY:	various network drivers

PASS:		ds - segment of NetEnumCallbackData to be freed

RETURN:		IF CHUNK ARRAY requested:
			*ds:si - chunk array
		ELSE:
			bx - handle of created memory buffer

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Caller should get any data out of this block before calling
	this procedure

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetEnumEnd	proc far
	uses	bx
	.enter
EC <	call	ECCheckNetEnumCallbackData	>

	;
	; For now, only support chunk arrays:
	;

	mov	bx, ds:[NECD_handle]
	lds	si, ds:[NECD_buffer]

	call	MemFree

	.leave
	ret
NetEnumEnd	endp


if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckNetEnumCallbackData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that DS points to a NetEnumCallbackData
		segment. 

CALLED BY:	NetEnumCallback, NetEnumEnd

PASS:		ds - segment of NetEnumCallbackData

RETURN:		nothing 

DESTROYED:	nothing, flags preserved 

PSEUDO CODE/STRATEGY:
	- Make sure DS:0 is a self-referencing handle
	- Make sure ds:NECD_params.NEP_bufferType is a valid type	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckNetEnumCallbackData	proc near
	uses	ax,bx

	.enter

	pushf
	mov	bx, ds:[NECD_handle]
	mov	ax, MGIT_ADDRESS
	call	MemGetInfo
	mov	bx, ds
	cmp	ax, bx
	ERROR_NE	NL_ERROR_DRIVER_TRASHED_DS

	cmp	ds:[NECD_params].NEP_bufferType, NetEnumBufferType
	ERROR_AE 	NL_ERROR_ILLEGAL_BUFFER_TYPE

	popf

	.leave
	ret
ECCheckNetEnumCallbackData	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetEnumError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Crash

CALLED BY:	NetEnumCallback

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetEnumError	proc near
EC <	ERROR	NL_ERROR	>
NEC <	ret			>
NetEnumError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetForeachDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call each driver 

CALLED BY:	INTERNAL

PASS:		di - function to call
		al - subfunction

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetForeachDriver	proc near
	.enter
	call	NetCallDriver
	.leave
	ret
NetForeachDriver	endp



NetCommonCode	ends
