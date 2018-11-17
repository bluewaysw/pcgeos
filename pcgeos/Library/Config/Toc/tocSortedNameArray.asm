COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tocSortedNameArray.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	TocAllocSortedNameArray	Allocate a sorted name array.  This is
				a huge array.
	TocSortedNameArrayFind	Find a name in a sorted name array.
	TocSortedNameArrayAdd	Add an element to the name array,
				inserting it in the proper order.
	AddItemLow		Common procedure to add an item into
				the name array.
	TocSortedNameArrayGetDataSize	Return the SNA_dataSize field
				of the SortedNameArray.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/17/92   	Initial version.

DESCRIPTION:
	

	$Id: tocSortedNameArray.asm,v 1.1 97/04/04 17:51:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocAllocSortedNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a sorted name array.  This is a huge array.

CALLED BY:	TocCreateCategory

PASS:		bx - size of the fixed-element portion.  Array
		elements are assumed to be variable-sized, with a
		fixed-size part at the beginning, followed by the
		name.  The size of the fixed portion is stored in the
		header. 

RETURN:		ax - 0
		di - SortedNameArray handle (huge array)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocAllocSortedNameArray	proc near
		uses	bx,cx,ds,bp
		.enter
		push	bx		; element size

	; Get the TOC file handle.

		call	TocGetFileHandle
		
	; Create a huge array in the file.

		clr	cx		; Variable-sized elements.
		mov	di, size SortedNameArray	; Header.
		call	HugeArrayCreate

	; Lock the directory block to store the data size there.

		mov	ax, di		; no mov_tr!
		call	VMLock
		mov	ds, ax
	
	; Need to preserve BX anyway, so might as well pop it and
	; move, rather than pop directly into memory.
		
		pop	bx
		mov	ds:[SNA_dataSize], bx
		call	VMUnlock

		clr	ax		; signal that it's not a dbptr
					; by returning 0 in AX

		.leave
		ret
TocAllocSortedNameArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocSortedNameArrayFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a name in a sorted name array

CALLED BY:	GLOBAL

PASS:		di - VM handle of SortedNameArray
		ds:si - name to find
		cx:dx - buffer for data (cx = null to not store data)
		bl - SortedNameArrayFindFlags

RETURN:		IF FOUND:
			carry set
			ax - element #
		ELSE:
			carry clear
			ax - element # where element would appear if
			it were in the list.

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortedNameArrayFindVars	struct
SortedNameArrayFindVars	ends

TocSortedNameArrayFind	proc far
		
		uses	bx,cx,dx,ds,es,si,di

array		local	word		push	di
buffer		local	fptr		push	cx, dx
SBCS <nameToFind	local	nptr.char	push	si		>
DBCS <nameToFind	local	nptr.wchar	push	si		>
lowerBound	local	word
upperBound	local	word
dataSize	local	word
flags		local	SortedNameArrayFindFlags
strLen		local	word
		
		.enter
		
	
		mov	ss:[flags], bl

	;		
	; get the string length not including NULL
	;
		segmov	es, ds
		mov	di, si
		call	LocalStringLength
		mov	ss:[strLen], cx

	;
	; get data element size from header.  Routine also returns
	; file handle for our convenience.
	;
		
		mov	di, ss:[array]
		call	TocSortedNameArrayGetDataSize
		mov	ss:[dataSize], cx
		
		clr	ss:[lowerBound]

		mov	di, ss:[array]
		call	HugeArrayGetCount
		tst	ax
		jnz	continue

	;
	; If no elements, just return BX zero
	;
		
		clr	bx
		jmp	notFound
continue:
		dec	ax
		mov	ss:[upperBound], ax
		
	; start at count/2
		
		shr	ax

startLoop:
	; bx - file handle
	; ax - current element
	; es - segment of name to find (offset in local frame)
		
		mov	di, ss:[array]
		clr	dx			; high word always zero

		push	ax
		call	HugeArrayLock
EC <		tst	ax						>
EC <		ERROR_Z	SORTED_NAME_ARRAY_ELEMENT_NOT_FOUND		>
		pop	ax
		
		mov	cx, dx			; element size
		add	si, ss:[dataSize]
		sub	cx, ss:[dataSize]
DBCS <		shr	cx, 1			; # bytes -> # chars	>
DBCS <		ERROR_C	DBCS_ERROR					>
		mov	di, ss:[nameToFind]

	;
	; Compare the two strings -- the array element at ds:si, and
	; the passed string at es:di
	;
		
		test	ss:[flags], mask SNAFF_IGNORE_CASE
		jnz	ignoreCase
		call	LocalCmpStrings
		jmp	afterCompare
		
ignoreCase:
		call	LocalCmpStringsNoCase
		
afterCompare:
		jne	compareDone
		
	;	
	; If equal, compare string lengths
	;
		
		cmp	cx, ss:[strLen]
compareDone:
		
		je	found			; ds:di - current element

		call	HugeArrayUnlock
		jg	lookBefore		; current element > passed
	;
	; It's AFTER the current element.  Always increment current
	; element and lower bound.
	;
		
		inc	ax
		cmp	ax, ss:[upperBound]
		ja	notFound
		
		mov	ss:[lowerBound], ax
		add	ax, ss:[upperBound]
		shr	ax
		jmp	startLoop
		
lookBefore:
	;
	; Move the upper bound to one less than the current element.
	; If upper bound is less than lower bound, then the thing
	; ain't there.  AX points to the element to insert BEFORE
	;
		
		mov	cx, ax		; current element (preserve AX)
		jcxz	notFound

		dec	cx
		mov	ss:[upperBound], cx
		
		cmp	cx, ss:[lowerBound]
		jb	notFound

	;
	; Make current element (lower+upper)/2
	;
		mov_tr	ax, cx				; upper bound
		add	ax, ss:[lowerBound]
		shr	ax
		jmp	startLoop
		
found:

		
	;		
	; Copy the data into the buffer.  SI had been added to
	; ss:[dataSize] previously, so subtract it off here.  If the
	; passed buffer segment was zero, then skip this.
	;
		
		mov	cx, ss:[buffer].segment
		jcxz	afterCopy

		sub	si, ss:[dataSize]
		mov	es, cx
		mov	di, ss:[buffer].offset
		mov	cx, ss:[dataSize]
		rep	movsb
		
afterCopy:
		call	HugeArrayUnlock
		stc
		jmp	done
		
notFound:
		clc
done:
		.leave
		ret
TocSortedNameArrayFind	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocSortedNameArrayAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element to the name array, inserting it in the
		proper order.

CALLED BY:	GLOBAL

PASS:		di - VM handle of name array
		ds:si - name
		cx:dx - data to add, pass CX=0 if no data
		bx - NameArrayAddFlags

RETURN:		ax - new element number

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocSortedNameArrayAdd	proc far
		uses	ds,es,si,di,bx,cx,dx
		.enter

		ECCheckFlags	bx, NameArrayAddFlags

	;
	; First, see if the thing's already there, and if not, where
	; to insert it.
	;
		
		push	bx, cx
		clr	bx, cx
		call	TocSortedNameArrayFind
		pop	bx, cx
		
	;
	; Carry set if name is already in the array.  If so, see if the
	; caller wants to overwrite the data portion
	;
		
		jnc	addNew
		test	bx, mask NAAF_SET_DATA_ON_REPLACE
		jz	done
		
		jcxz	done			; no data
		
	;
	; cx:dx - data to write
	;
		mov	es, cx
		call	TocSortedNameArrayGetDataSize	; cx - data size
							; bx - file handle

		push	dx			; data offset
		
		push	ax
		clr	dx
		call	HugeArrayLock		; ds:si - element
EC <		tst	ax					>
EC <		ERROR_Z ELEMENT_NUMBER_OUT_OF_BOUNDS		>
		pop	ax
		
		segxchg	ds, es
		mov	di, si
		pop	si				; data offset
		rep	movsb

		segmov	ds, es				; huge array block
		call	HugeArrayUnlock
		jmp	done
		
addNew:
		call	AddItemLow
		
done:

		.leave
		ret
TocSortedNameArrayAdd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocSortedNameArrayGetDataSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the SNA_dataSize field of the SortedNameArray

CALLED BY:	TocSortedNameArrayFind, TocSortedNameArrayAdd

PASS:		di - VM handle of SortedNameArray

RETURN:		bx - TOC file handle (this is a side effect, but it's
		useful...

		cx - data size

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocSortedNameArrayGetDataSize	proc near
		uses	ds,ax,bp
		.enter
		call	TocGetFileHandle

		mov	ax, di		; no mov_tr!
EC < 		call	ECVMCheckVMBlockHandle			>
		call	VMLock
		mov	ds, ax
		mov	cx, ds:[SNA_dataSize]
		call	VMUnlock
		.leave
		ret
TocSortedNameArrayGetDataSize	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddItemLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common procedure to add an item into the name array

CALLED BY:	TocSortedNameArrayAdd

PASS:		
		ds:si - name
		cx:dx - data to add
		di - VM handle of array
		ax - element # to insert before

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddItemLow	proc near
		uses	ax,bx,cx,dx,si,es

array		local	word	push	di
elementNumber	local	word	push	ax
sourceName	local	fptr	push	ds, si
sourceData	local	fptr	push	cx, dx
totalSize	local	word
stringLength	local	word
		
		.enter
		
		
	;
	; string length
	;
		segmov	es, ds
		mov	di, si
		call	LocalStringLength	; cx - string size
		mov	ss:[stringLength], cx

		mov_tr	ax, cx			; string size
DBCS <		shl	ax, 1			; # chars -> # bytes	>

		mov	di, ss:[array]
		call	TocSortedNameArrayGetDataSize	; cx - data size
							; bx - file handle

		add	ax, cx			; ax - total size
		mov	ss:[totalSize], ax
		
	;
	; Copy the data and name to a temporary buffer, so that we can
	; stick it all in at once
	;
		sub	sp, ax
		mov	di, sp
		segmov	es, ss			; es:di - dest
		
		tst	ss:[sourceData].segment
		jz	noData

		lds	si, ss:[sourceData]
		rep	movsb
		jmp	afterData
noData:
		add	di, cx
afterData:
		lds	si, ss:[sourceName]
		mov	cx, ss:[stringLength]
		LocalCopyNString

		mov	di, ss:[array]
		call	HugeArrayGetCount	; ax - # elements

	;
	; Decide whether to insert or append (if element number is
	; greater than or equal to number of elements, then append)
	;
		mov	si, sp
		mov	cx, ss:[totalSize]
		clr	dx
		cmp	ss:[elementNumber], ax
		jb	insert
	;
	; Append
	;
		push	bp
		mov	bp, ss
		call	HugeArrayAppend
		pop	bp
		jmp	done

insert:
		mov	ax, ss:[elementNumber]
		push	bp
		mov	bp, ss
		call	HugeArrayInsert
		pop	bp
done:
		add	sp, cx
		
		
		.leave
		ret
AddItemLow	endp

;-----------------------------------------------------------------------------
;		C STUBS		
;-----------------------------------------------------------------------------
 



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCSORTEDNAMEARRAYADD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a name to the array

CALLED BY:	GLOBAL
PARAMETERS:	word (word arr, const char *nameToAdd,
		      NameArrayAddFlags flags, const void *data);
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
if DBCS_PCGEOS
TOCSORTEDNAMEARRAYADD proc	far	array:word, nameToAdd:fptr.wchar,
			   		flags:word, data:fptr
else
TOCSORTEDNAMEARRAYADD proc	far	array:word, nameToAdd:fptr.char,
			   		flags:word, data:fptr
endif
	uses	es, di, ds, si
	.enter
	mov	di, ss:[array]
	movdw	cxdx, ss:[data]
	mov	bx, ss:[flags]
	lds	si, ss:[nameToAdd]
	call	TocSortedNameArrayAdd
	.leave
	ret
TOCSORTEDNAMEARRAYADD		endp
SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCSORTEDNAMEARRAYFIND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a named element in a sorted array

CALLED BY:	GLOBAL
PARAMETERS:	Boolean (optr arr, const char *nameToFind,
			 SortedNameArrayFindFlags flags,
			 void *buffer, word *elementNum);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
if DBCS_PCGEOS
TOCSORTEDNAMEARRAYFIND proc	far	array:word, nameToFind:fptr.wchar,
		    			flags:word, buffer:fptr,
					elementNum:fptr.word
else
TOCSORTEDNAMEARRAYFIND proc	far	array:word, nameToFind:fptr.char,
		    			flags:word, buffer:fptr,
					elementNum:fptr.word
endif
	uses	ds, si, es, di
	.enter
	mov	di, ss:[array]
	lds	si, ss:[nameToFind]
	movdw	cxdx, ss:[buffer]
	mov	bx, ss:[flags]
	call	TocSortedNameArrayFind
	les	di, ss:[elementNum]
	stosw

	mov	ax, 0		; assume not found
	jnc	done
	dec	ax		; it's there.
done:
	.leave
	ret
TOCSORTEDNAMEARRAYFIND		endp
SetDefaultConvention
