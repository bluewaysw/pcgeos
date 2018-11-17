COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefPrefNetQList.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

DESCRIPTION:
	

	$Id: prefNetQList.asm,v 1.1 97/04/04 17:50:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBCS <PrintMessage <convert for DBCS>					>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefNetQListSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the queue list so that it contains the
		names and IDs of all print queues on the network.

PASS:		*ds:si	= PrefNetQListClass object
		ds:di	= PrefNetQListClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefNetQListSpecBuild	method	dynamic	PrefNetQListClass, 
					MSG_SPEC_BUILD

	mov	di, offset PrefNetQListClass
	call	ObjCallSuperNoLock

	.enter

	sub	sp, size NetEnumParams
	mov	bp, sp
	mov	ss:[bp].NEP_bufferType, NEBT_CHUNK_ARRAY_VAR_SIZED

	mov	bx, si			; *ds:bx - object chunk
	call	NetPrintEnumPrintQueues	; *ds:si - chunk array

	add	sp, size NetEnumParams
	
	mov	di, ds:[bx]
	add	di, ds:[di].PrefNetQList_offset
	mov	ds:[di].PNQLI_array, si

	call	ChunkArrayGetCount	; cx - count

	;
	; Initialize the dynamic list
	;

	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	si, bx
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefNetQListSpecBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefNetQListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Figure out what the moniker is for this particular
		queue # 

PASS:		*ds:si	= PrefNetQListClass object
		ds:di	= PrefNetQListClass instance data
		es	= dgroup
		bp	= item #

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefNetQListQueryItemMoniker	method	dynamic	PrefNetQListClass, 
				MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER

itemNum		local	word	push	bp
queueName	local	NetWareBinderyObjectNameZ

	.enter

	mov	bx, si			; object chunk

	mov	si, ds:[di].PNQLI_array
	tst	si
	jz	done

	mov	ax, ss:[itemNum]
	call	ChunkArrayElementToPtr	;	ds:di - queue name
	mov	si, di
	segmov	es, ss
	lea	di, ss:[queueName]
	mov	cx, size queueName/2
	rep	movsw

	push	bp
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	cx, ss
	lea	dx, ss:[queueName]
	mov	si, bx			; object chunk
	mov	bp, ss:[itemNum]
	call	ObjCallInstanceNoLock
	pop	bp
	
done:
	.leave
	ret
PrefNetQListQueryItemMoniker	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefNetQListGetQueueID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	return a given queue id

PASS:		*ds:si	= PrefNetQListClass object
		ds:di	= PrefNetQListClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefNetQListGetQueueID	method	dynamic	PrefNetQListClass, 
					MSG_PREF_NET_QLIST_GET_QUEUE_ID
	.enter

if	0

	;
	; Call Net library to get queue ID given name
	;

	mov	si, ds:[di].PNQLI_array
	mov_tr	ax, cx
	call	ChunkArrayElementToPtr
	jc	done
done:
endif

	.leave
	ret
PrefNetQListGetQueueID	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefNetQListGetSelectedQueueID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefNetQListClass object
		ds:di	= PrefNetQListClass instance data
		es	= dgroup

RETURN:		cx:dx - queue id (cx - high word)

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefNetQListGetSelectedQueueID	method	dynamic	PrefNetQListClass, 
				MSG_PREF_NET_QLIST_GET_SELECTED_QUEUE_ID
	uses	bp
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock

	mov_tr	cx, ax

	mov	ax, MSG_PREF_NET_QLIST_GET_QUEUE_ID
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefNetQListGetSelectedQueueID	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefNetQListGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the moniker for the selected item.

PASS:		*ds:si	= PrefNetQListClass object
		ds:di	= PrefNetQListClass instance data
		es	= dgroup
		ss:bp   = GetItemMonikerParams

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefNetQListGetItemMoniker	method	dynamic	PrefNetQListClass, 
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
	uses	cx,dx
	.enter

	mov	bx, di			; instance ptr

	les	di, ss:[bp].GIMP_buffer
	mov	ax, ss:[bp].GIMP_identifier
	mov	cx, ss:[bp].GIMP_bufferSize

	mov	si, ds:[bx].PNQLI_array
	push	di, cx
	call	ChunkArrayElementToPtr	; ds:di - element
	mov	si, di
	pop	di, cx

	rep	movsb

	.leave
	ret
PrefNetQListGetItemMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefNetQListFindItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Find the first string that matches the passed string

PASS:		*ds:si	= PrefNetQListClass object
		ds:di	= PrefNetQListClass instance data
		es	= dgroup
		cx:dx	= asciiZ string to search for
		bp	= nonzero to ignore case

RETURN:		if found
			ax - item #
			carry clear
		else
			ax - last item # + 1
			carry set

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindItemCallbackParams	struct
	FICP_ignoreCase	word
	FICP_string	nptr	; offset of passed string (segment is
				; passed in ES)
	FICP_element	word	; element #

FindItemCallbackParams	ends


PrefNetQListFindItem	method	dynamic	PrefNetQListClass, 
					MSG_PREF_DYNAMIC_LIST_FIND_ITEM
	uses	dx,bp
	.enter

	sub	sp, size FindItemCallbackParams
	mov	bx, sp
	mov	ss:[bx].FICP_ignoreCase, bp
	mov	bp, bx

	mov	ss:[bp].FICP_string, dx
	clr	ss:[bp].FICP_element

	mov	es, cx			; es:dx - string to find

	;
	; Get length of passed string w/o null
	;

	push	di
	mov	di, dx
	clr	al
	mov	cx, -1
	repne	scasb
	not	cx
	dec	cx			; ignore null
	pop	di


	mov	si, ds:[di].PNQLI_array
	mov	bx, cs
	mov	di, offset FindItemCallback

	call	ChunkArrayEnum
	mov	cx, ss:[bp].FICP_element
	lea	sp, ss:[bp][size FindItemCallbackParams]

	cmc	
	mov_tr	ax, cx			; ax <- identifier
	.leave
	ret
PrefNetQListFindItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindItemCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to compare against passed string

CALLED BY:	PrefNetQListFindItem via ChunkArrayEnum

PASS:		ds:di - item to examine
		ss:bp - FindItemCallbackParams
		es - segment of passed string
		cx - length of passed string


RETURN:		carry SET if found
		ax - incremented if not found

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindItemCallback	proc far
	uses	si

	.enter
	mov	di, ss:[bp].FICP_string		; offset of string

	mov	si, di				; ds:si - first string
	mov	di, dx				; es:di - another

	tst	ss:[bp].FICP_ignoreCase
	jnz	ignoreCase
	call	LocalCmpStrings
	jmp	afterCompare
ignoreCase:
	call	LocalCmpStringsNoCase
afterCompare:

	;
	; If found, then done -- set the carry.  Otherwise, increment
	; the current element #
	;

	je	found
	
	inc	ss:[bp].FICP_element
	clc
done:
	.leave
	ret

found:
	stc
	jmp	done

FindItemCallback	endp


