COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Config Library
FILE:		tocUtils.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	TocAllocateNameArray	Allocate a name array in the TOC file.
	TocNameArrayGetElement	Return data about an element, given
				its number.
	TocNameArrayFind	Find a name in the passed name array.
	TocNameArrayAdd		Add an element to a TOC name array.
	TocAllocChunkArray	Create a new chunk array in the DB
				file.
	ConfigEntry		Open the TOC file on entry-- close it
				on exit.
	TocGetFileHandle	Return the TOC file handle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.

DESCRIPTION:
	

	$Id: tocUtils.asm,v 1.1 97/04/04 17:51:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocAllocNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a name array in the TOC file

CALLED BY:	internal

PASS:		bx - element size

RETURN:		ax:di - DBItem of name array

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocAllocNameArray	proc near
	uses	cx,ds,si
	.enter
	mov	cx, size NameArrayHeader
	call	TocAllocDBItem		; *ds:si - new chunk

	push	ax
	clr	ax, cx
	call	NameArrayCreate
	call	TocDBDirty
	call	TocDBUnlock		; that's all for now
	pop	ax			; ax:di - DBItem	

	.leave
	ret
TocAllocNameArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCNAMEARRAYGETELEMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return data about an element, given its number

CALLED BY:	GLOBAL
PARAMETERS:	word (DBGroupAndItem, word, void *)
RETURN:		length of data returned in buffer
SIDE EFFECTS:	buffer is overwritten

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
TOCNAMEARRAYGETELEMENT proc	far	array:DBGroupAndItem,
		       			element:word,
					buffer:fptr
	uses	di
	.enter
	mov	ax, ss:[array].DBGI_group
	mov	di, ss:[array].DBGI_item
	mov	bx, ss:[element]
	movdw	cxdx, ss:[buffer]
	call	TocNameArrayGetElement
	.leave
	ret
TOCNAMEARRAYGETELEMENT		endp
SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocNameArrayGetElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return data about an element, given its number

CALLED BY:	GLOBAL

PASS:		ax:di - name array dbitem
		bx - element #
		cx:dx - buffer in which to stick data
		(must be big enough for name as well)

RETURN:		ax - length of data returned

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocNameArrayGetElement	proc far
	uses	ds, si, es, di
	.enter
	call	TocDBLock
	mov	ax, bx			; element #
	;
	; Get the name and NULL-terminate it
	;
	call	ChunkArrayGetElement

	movdw	esdi, cxdx		; es:di <- element start
	add	di, ax
SBCS <	mov	{char} es:[di], 0					>
DBCS <	mov	{wchar} es:[di], 0					>

	call	TocDBUnlock
	.leave
	ret
TocNameArrayGetElement	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCNAMEARRAYFIND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a name in the passed name array

CALLED BY:	GLOBAL
PARAMETERS:	word (DBGroupAndItem, const char *, void *)
RETURN:		name token (CA_NULL_ELEMENT if not found)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
if DBCS_PCGEOS
TOCNAMEARRAYFIND proc	far	array:DBGroupAndItem,
		 		nameToFind:fptr.wchar,
				buffer:fptr
else
TOCNAMEARRAYFIND proc	far	array:DBGroupAndItem,
		 		nameToFind:fptr.char,
				buffer:fptr
endif
	on_stack	retf
	stc
C_Find_Add_common	label	near
	uses	ds, si, di
	.enter
	on_stack	ds di si bp retf
	mov	ax, ss:[array].DBGI_group
	mov	di, ss:[array].DBGI_item
	lds	si, ss:[nameToFind]
	movdw	cxdx, ss:[buffer]
	jc	doAdd
	call	TocNameArrayFind
done:
	mov_tr	ax, bx
	.leave
	ret
doAdd:
	call	TocNameArrayAdd
	jmp	done
TOCNAMEARRAYFIND endp
SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocNameArrayFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a name in the passed name array

CALLED BY:

PASS:		ax:di - dbptr of NameArray to find name
			if AX = 0, then the map item will be used.
		cx:dx - buffer to stick data into
			cx = 0 to not return data

		ds:si - fptr to name to search for

		THREAD VM FILE OVERRIDE = VM Handle of TOC file

RETURN:		bx - name token
			(bx = CA_NULL_ELEMENT if not found)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocNameArrayFind	proc far
	uses	ax,cx,dx,di,si,bp,ds,es
	.enter

	; lock DBItem ax:di

	push	ds, si		; name to find
	call	TocDBLock
	pop	es, di		; name to find

	mov	ax, dx
	mov	dx, cx
	clr	cx		; null-term
	call	NameArrayFind
	mov	bx, ax		; element #

	; unlock DBItem (name array)

	call	TocDBUnlock
	.leave
	ret

TocNameArrayFind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCNAMEARRAYADD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element to a TOC name array

CALLED BY:	GLOBAL
PARAMETERS:	word (DBGroupAndItem, const char *, const void *)
RETURN:		element number
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TOCNAMEARRAYADD proc	far
	clc
	jmp	C_Find_Add_common
TOCNAMEARRAYADD endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocNameArrayAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element to a TOC name array.

CALLED BY:

PASS:		ax:di - DBItem (nameArray) 
			if AX = 0, then the map item will be used.
		cx:dx - buffer containing data to add
		ds:si - fptr to name to search for

RETURN:		bx	- element #

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	anal register-saving

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocNameArrayAdd	proc far
	uses	ax,cx,dx,di,si,bp,ds,es

	.enter
	push	ds, si			; ds:si - name
	call	TocDBLock		; *ds:si - name array
	pop	es, di			; es:di - name
	mov	ax, dx
	mov	dx, cx			; dx:ax - data to add
	mov	bx, mask NAAF_SET_DATA_ON_REPLACE
	clr	cx			; null-terminated name
	call	NameArrayAdd
	mov_tr	bx, ax			; name token
	call	TocDBDirty
	call	TocDBUnlock

	.leave
	ret
TocNameArrayAdd	endp








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocAllocChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new chunk array in the DB file

CALLED BY:	TocOpenFile

PASS:		bx - element size

RETURN:		ax:di - dbptr of new chunk array

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocAllocChunkArray	proc near
	uses	cx, ds, si
	.enter
	call	TocAllocDBItem
	
	push	ax
	clr	cx, ax
	call	ChunkArrayCreate
	call	TocDBDirty
	call	TocDBUnlock
	pop	ax

	.leave
	ret
TocAllocChunkArray	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the TOC file on entry -- close it on exit

CALLED BY:

PASS:		di - LibraryCallType

RETURN:		carry set if error
		carry clear otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	ConfigEntry:far

ConfigEntry	proc far
	.enter
	cmp	di, LCT_ATTACH
	je	attach
	cmp	di, LCT_DETACH
	clc
	jne	done

	call	TocCloseFile
	clc
	jmp	done

attach:
	call	TocOpenFile		; returns status in carry
done:
	.leave
	ret
ConfigEntry	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocGetFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the TOC file handle

CALLED BY:	PrefTocListBuildArray, etc

PASS:		nothing 

RETURN:		bx - TOC file handle

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocGetFileHandle	proc far
		uses	ds
		.enter
		call	LoadDSDGroup
		mov	bx, ds:[tocFileHandle]

EC <		call	ECVMCheckVMFile				>
		
		.leave
		ret
TocGetFileHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCGETFILEHANDLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C Stub

CALLED BY:	GLOBAL

PASS:		nothing 

RETURN:		file handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/17/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TOCGETFILEHANDLE	proc far
		.enter
		call	TocGetFileHandle
		mov_tr	ax, bx

		.leave
		ret
TOCGETFILEHANDLE	endp

LoadDSDGroup	proc	near	uses	bx
	.enter
	mov	bx, handle dgroup
	call	MemDerefDS
	.leave
	ret
LoadDSDGroup	endp

