COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Globalpc 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Parental Control library
FILE:		parentcURLs.asm

AUTHOR:		Edwin Yu, August  9, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/27/99   	Initial revision


DESCRIPTION:
	$Id: $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment
pcRefCount	word	0		; there's synchronization problems
					;	accessing this, need sem
pcFile		word	0		; vm file handle of huge array
varHandle	hptr	0
pcName		TCHAR	'pctrl.vm',0
WWWDynamicListClass
ModifyPrefTextClass
WWWSiteTextClass
idata	ends

PCCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCEnsureOpenData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure our VM file is open 

CALLED BY:	Everyone
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	8/9/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCEnsureOpenData	proc	far	uses bx, dx, ax, cx, di, ds, es, bp
		.enter
	segmov	ds, dgroup
	inc	ds:[pcRefCount]
	mov	bx, ds:[pcFile]
	tst	bx
	jz	openFile
	tst	ds:[varHandle]
	jz	loadArray
	jmp	done

openFile:
	mov	ax, SP_PRIVATE_DATA
	call	FileSetStandardPath

	mov	dx, offset pcName
again:
	mov	ax, (VMO_CREATE shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx
	call	VMOpen
	cmp	ax, VM_CREATE_OK
	je	createNewArray
	cmp	ax, VM_OPEN_OK_BLOCK_LEVEL
	je	loadArray
	cmp	ax, VM_OPEN_INVALID_VM_FILE
;		ERROR_NE	0 ; CANNOT_OPEN_FILE
	call	FileDelete
	jmp	again

createNewArray:
	; now create arrays.
	mov	ax, handle 0
	call	HandleModifyOwner
	mov	ds:[pcFile], bx
					;	tst	ds:[varHandle]
					;	jnz	done
	clr	cx			; set variable sized
	clr	di
	call	HugeArrayCreate		; create the fixed one
	mov	ds:[varHandle], di
	;
	; create a map block
	; bx <- VM file
	mov	ax, PC_MAP_BLOCK		; ax <- ID for map block
	mov	cx, size PCMapBlock		; cx <- Size of map block
	call	VMAlloc				; ax <- VMblock handle

	;
	; Set the map block
	;
	call	VMSetMapBlock			  ; passed ax, bx

	;
	; Lock down the map block
	;
	call	VMLock				  ; ax <- map block segment
						  ; bp <- global block handle
	segmov	es, ax				  ; es <- map block segment
	mov	es:[PCMB_hugeArray], di		  ; store in map block

	call	VMUnlock			  ; ax <- map block segment
	jmp	done

loadArray:
	; bx <- VM file
	mov	ax, handle 0
	call	HandleModifyOwner
	mov	ds:[pcFile], bx
	call	VMGetMapBlock			  ; ax <- map block handle
	;
	; Lock down the map block
	;
	call	VMLock				  ; ax <- map block segment
	segmov	es, ax				  ; es <- map block segment

	;
	; get data structure from map block
	;
	mov	di, es:[PCMB_hugeArray]		  ; 
	mov	ds:[varHandle], di		  ; store in map block

	call	VMUnlock			  ; ax <- map block segment
done:
	;
	; add fixed sites to list
	;
	call	PCAddFixedSites
	.leave
	ret
PCEnsureOpenData	endp

PCAddFixedSites	proc	near
	uses	ax, bx, cx, dx, bp, si, ds
	.enter
	segmov	ds, cs, cx
	mov	si, offset PCCat
	mov	dx, offset PCKey
	mov	bp, 0
	call	InitFileReadString
	jc	exit				; nothing read
	tst	bx
	jz	exit
	call	MemLock
	call	ParseWebSiteList
	call	MemFree
exit:
	.leave
	ret
PCAddFixedSites	endp

PCCat	char	"PCtrl",0
PCKey	char	"FS",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCCloseData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the VM file.

CALLED BY:	Everyone
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	8/9/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCCloseData	proc	far	uses bx, dx, ax, cx, di, ds
	.enter
	segmov	ds, dgroup
	dec	ds:[pcRefCount]
	tst	ds:[pcRefCount]
	jnz	done
	mov	bx, ds:[pcFile]
	tst	bx
	jz	done

	mov	di, ds:[varHandle]
	tst	di
	jz	done

;	call	HugeArrayDestroy
	mov	al, FILE_NO_ERRORS
	call	VMClose

	mov	ds:[varHandle], 0
	mov	ds:[pcFile], 0

done:
	.leave
	ret
PCCloseData	endp

;
;  Pass:  nothing
;  Return: dx:ax
;
PCDataGetCount	proc	far	uses bx, cx, di, ds
	.enter

	segmov	ds, dgroup
	mov	bx, ds:[pcFile]
	tst	bx
	jz	done

	mov	di, ds:[varHandle]
	tst	di
	jz	done

	call	HugeArrayGetCount	; dx.ax - number of elements in array

done:
	.leave
	ret
PCDataGetCount	endp


;
; Pass:	ax - selection item number
; Return: carry set if deleted
;
PCDataDeleteItem	proc	far	uses ax, bx, cx, dx, di, ds
	.enter

	segmov	ds, dgroup
	mov	bx, ds:[pcFile]
	tst	bx
	jz	done		; carry clear

	mov	di, ds:[varHandle]
	tst	di
	jz	done		; carry clear

	clr	dx	; dx:ax - element number to be deleted.
	mov	cx, 1	; cx - one element to be deleted.
	call	HugeArrayDelete
	;
	; make sure fixed sites still in list
	;
	call	PCAddFixedSites

	stc			; indicate deleted

done:
	.leave
	ret
PCDataDeleteItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCStoreURLs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the URLs into the vm file.

CALLED BY:	Everyone
PASS:		ds:di - beginning of the URL string
		ds:si - last char(null or space) of the URL string
RETURN:		carry set if stored
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	8/10/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCStoreURLs	proc	far
	uses	bx, dx, ax, cx, di, es, si, bp
	.enter

	mov	cx, si
	sub	cx, di	; cx - length of the url string
DBCS <	shr	cx, 1						>
	mov	si, di	; ds:si - beginning of the url string

	segmov	es, dgroup
	mov	bx, es:[pcFile]
	tst	bx
	jz	exit		; carry clear
	mov	di, es:[varHandle]
	tst	di
	jz	exit		; carry clear

	; bx - vm file
	; di - huge array handle
	; ds:si - beginning of the url string
	; cx - length
	; dx.ax - position to insert.
	call	HugeArrayBinarySearchNotNullTerm
	cmc
	jnc	exit		; jump if aready set. (carry clear)

	mov	bp, ds		; bp:si - fptr to buffer holding url string
	call	HugeArrayInsert
	stc			; indicate successfully stored
exit:
	.leave
	ret
PCStoreURLs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCFindURL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an URL in the vm file opened by PCEnsureOpenData.

CALLED BY:	Everyone
PASS:		ds:di - beginning of the URL string
		ds:si - last char(null or space) of the URL string
		PCEnsureOpenData must have been called before.
RETURN: 	carry set if found
		dx:ax = position found
		carry clear if not found
		dx:ax = position to insert
		(dx:ax = -1 if append)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	8/12/99		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCFindURL	proc	far
	uses	bx, cx, di, es, si
	.enter

	mov	cx, si
	sub	cx, di	; cx - length of the url string
DBCS <	shr	cx, 1						>
	mov	si, di	; ds:si - beginning of the url string

	segmov	es, dgroup
	mov	bx, es:[pcFile]
	tst	bx
	jz	exit
	mov	di, es:[varHandle]
	tst	di
	clc
	jz	exit

	; bx - vm file
	; di - huge array handle
	; ds:si - beginning of the url string
	; cx - length
	; dx.ax - position to insert.
	call	HugeArrayBinarySearchNotNullTerm
exit:
	.leave
	ret
PCFindURL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCControlBringupWebSiteControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the web site control dialog.

CALLED BY:	
PASS:		^lcx:dx -- the dynamic list requesting the moniker
		bp      -- the position of the item requested
		nothing
		ax, cx, dx, bp -- destroyed

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/28/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WWWListMonikerQuery	method dynamic WWWDynamicListClass,
					MSG_WWW_LIST_MONIKER_QUERY
	.enter

	segmov	es, dgroup
	mov	bx, es:[pcFile]
	tst	bx
	jz	done

	mov	di, es:[varHandle]
	tst	di
	jz	done

	call	HugeArrayGetCount	; dx.ax - number of elements in array
	cmp	bp, ax
	jae	done			; error checking

	mov	ax, bp
	push	ds
	call	HugeArrayLock	; ds:si	- pointer to requested element 
	segmov	es, ds
	pop	ds
	mov	di, si		; es:di
	add	di, dx
	push	es:[di]
	push	di
	mov	{TCHAR}es:[di], 0	; es:[di+length] = null
	mov	cx, es
	mov	dx, si		; cx:dx - pointer to string
	push	cx
	; bp - index
	mov	bx, ds:[LMBH_handle]
	mov	si, offset PermissibleList
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	ds
	pop	di
	pop	ds:[di]
	call	HugeArrayUnlock

done:
	.leave
	ret
WWWListMonikerQuery	endm


WWWListVisOpen	method dynamic WWWDynamicListClass,
					MSG_VIS_OPEN
	uses	es
	.enter

	mov	di, offset WWWDynamicListClass
	call	ObjCallSuperNoLock
	;
	;  Add number of items to the dynamic list.
	;
	segmov	es, dgroup
	mov	bx, es:[pcFile]
	tst	bx
	jz	done

	mov	di, es:[varHandle]
	tst	di
	jz	done

	call	HugeArrayGetCount	; dx.ax - number of elements in array
	mov	dx, ax
	mov	cx, GDLP_FIRST
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	mov	di, offset WWWDynamicListClass
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
WWWListVisOpen	endm

;
;  Make user friendly: enable some triggers when a list item is selected.
;
WWWListEnableTriggers	method dynamic WWWDynamicListClass,
				MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	uses	es
	.enter
	mov	di, offset WWWDynamicListClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock	; ax = selection
	segmov	es, dgroup
	mov	bx, es:[pcFile]
	tst	bx
	jz	enable			; no list, enable
	mov	di, es:[varHandle]
	tst	di
	jz	enable			; no list, enable
	clr	dx			; dx:ax = selection
	push	ds
	call	HugeArrayLock		; ds:si = selection
	call	ScanFixedList
	call	HugeArrayUnlock		; (preserves flags)
	pop	ds
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jc	common			; in fixed list, disable
enable:
	mov	ax, MSG_GEN_SET_ENABLED
common:
	mov	bx, ds:[LMBH_handle]
	mov	si, offset ModifyButton ; bx:si = ModifyButton
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	push	ax
	call	ObjMessage
	pop	ax
	mov	si, offset DeleteButton ; bx:si = ModifyButton
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	.leave
	ret
WWWListEnableTriggers	endm

;
; check if in fixed list
; pass: ds:si = selection
;	dx = selection length
; returns: carry set if found in fixed list
;
ScanFixedList	proc	near
	uses	ds, si, di, ax, bx, cx, dx, bp, es
selectionSeg	local	word	push	ds
selectionOff	local	word	push	si
selectionLen	local	word	push	dx
	.enter
	segmov	ds, cs, cx
	mov	si, offset PCCat
	mov	dx, offset PCKey
	push	bp
	mov	bp, 0
	call	InitFileReadString
	pop	bp
	cmc
	jnc	exit				; nothing read (C clear)
	tst	bx
	jz	exit				; C clear
	call	MemLock
	mov	ds, ax
	clr	si, di		; ds:[si] points to the url addresses
	clr	cx
nextUrl:

	cmp	{TCHAR}ds:[si], C_SPACE
	je	whiteSpace
ifdef DO_DBCS
	cmp	{TCHAR}ds:[si], C_HORIZONTAL_TABULATION
	je	whiteSpace
	cmp	{TCHAR}ds:[si], C_CARRIAGE_RETURN
	je	whiteSpace
	cmp	{TCHAR}ds:[si], C_LINE_FEED
	je	whiteSpace
else
	cmp	{TCHAR}ds:[si], C_TAB
	je	whiteSpace
	cmp	{TCHAR}ds:[si], C_CR
	je	whiteSpace
	cmp	{TCHAR}ds:[si], C_LF
	je	whiteSpace
endif
	cmp	{TCHAR}ds:[si], C_NULL
	je	whiteSpace
	; edwdig was here
	cmp	{TCHAR}ds:[si], ','
	je whiteSpace
	cmp	{TCHAR}ds:[si], ';'
	je whiteSpace
	; end edwdig
	jcxz	newUrl
	jmp	ok

newUrl:
	mov	cx, 1	; turn on a flag that we got a non-white space char
	mov	di, si
	jmp	ok
whiteSpace:
	cmp	cx, 1
	jne	skipWhiteSpace
	;  From ds:[di] to ds:[si] is the new URL
	;  compare to passed selection
	mov	dx, si
	sub	dx, di			; dx = buffer length
DBCS <	shr	dx, 1						>
	push	si, di
	mov	si, di			; ds:si = buffer string
	mov	es, selectionSeg	; es:di = selection string
	mov	di, selectionOff
	mov	cx, selectionLen	; cx = selection length
	call	CmpStringsWithLength
	pop	si, di
	stc				; assume found
	je	noMore			; found, done
notFound:
	mov	cx, 0
skipWhiteSpace:
	mov	di, si
ok:
	tst_clc	{TCHAR}ds:[si]
	jz	noMore		; C clear, not found
	LocalNextChar	dssi
	jmp	nextUrl

noMore:
	pushf
	call	MemFree
	popf
exit:
	.leave
	ret
ScanFixedList	endp

;
;  Make user friendly.  Display the current selection text for modification
;
;
ModifyPrefText	method dynamic ModifyPrefTextClass,
					MSG_VIS_OPEN
	uses	es
	.enter
	mov	di, offset ModifyPrefTextClass
	call	ObjCallSuperNoLock

	;
	;  Delete the current selection
	;
	mov	bx, ds:[LMBH_handle]
	mov	si, offset PermissibleList ; bx:si = PermissbleList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage	; ax - selection
	cmp	ax, -1
	je	none

	mov	cx, bx
	segmov	es, dgroup
	mov	bx, es:[pcFile]
	tst	bx
	jz	none

	mov	di, es:[varHandle]
	tst	di
	jz	none

	clr	dx
	push	cx
	call	HugeArrayLock		; ds:si - string, dx - length

	mov	cx, dx			; cx -length
DBCS <	shr	cx, 1						>
	mov	dx, ds
	mov	bp, si			; dx:bp - text string
	pop	bx
	mov	si, offset PermissionModifyInput ; bx:si = PermissionModifyInput
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage	; ax - selection

	call	HugeArrayUnlock

	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	di, mask MF_CALL
	call	ObjMessage
none:
	.leave
	ret
ModifyPrefText	endm

;
;  User friendly:  Delete the previously entered text.
;
WWWSiteTextOpen	method dynamic WWWSiteTextClass,
					MSG_VIS_OPEN
	.enter
	mov	di, offset WWWSiteTextClass
	call	ObjCallSuperNoLock

	;
	;  Delete the current selection
	;
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	di, offset WWWSiteTextClass
	call	ObjCallInstanceNoLock

	.leave
	ret
WWWSiteTextOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayBinarySearchNotNullTerm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do binary search of huge array.
		Assume element of huge array is not null terminated.

CALLED BY:	global
PASS:		bx = vm file handle
		di = huge array handle
		ds:si = string (not null terminated)
		cx = string length
RETURN: 	carry set if found
		dx:ax = position found
		carry clear if not found
		dx:ax = position to insert
		(dx:ax = -1 if append)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	YK	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayBinarySearchNotNullTerm	proc	near
passedDI	local	word	push	di
passedDS	local	word	push	ds
passedSI	local	word	push 	si
firstPos	local	dword
lastPos		local	dword
middlePos	local	dword

	uses	bx,cx,si,di,bp,es,ds
	.enter

	call	HugeArrayGetCount	; dx:ax <- # of elements
	tstdw	dxax
	LONG	jz	notFoundLastAppend

	movdw	lastPos, dxax
	decdw	lastPos			; set lastPos

	;--------------------------------
	; compare against the 1st element
	;--------------------------------
	clr	dx
	clr	ax
	push	cx			; save string length
	call	HugeArrayLock		; ds:si <- 0th element
					; dx <- length
DBCS <	shr	dx, 1						>
	segmov	es, passedDS
	mov	di, passedSI		; es:di <- dest string


	pop	cx			; restore string length
	call	CmpStringsWithLength

	pushf
	call	HugeArrayUnlock
	popf

	LONG	jz	foundFirst
	LONG	ja	notFoundFirst

	;---------------------------------
	; compare against the last element
	;---------------------------------
	movdw	dxax, lastPos
	mov	di, passedDI
	push	cx
	call	HugeArrayLock		; ds:si <- element
					; dx <- length
DBCS <	shr	dx, 1						>

	mov	di, passedSI		; restore es:di = dest str
	pop	cx
	call	CmpStringsWithLength

	pushf
	call	HugeArrayUnlock
	popf

	LONG	jz	foundLast
	LONG	jb	notFoundLastAppend

	;------------------------------------------
	; start search between firstPos and lastPos
	;------------------------------------------
	clr	ax			; ax = zero register
	clrdw	firstPos, ax

continueSearch:
	movdw	dxax, lastPos
	subdw	dxax, firstPos
	cmpdw	dxax, 1
	jz	notFoundLast

	movdw	dxax, lastPos
	adddw	dxax, firstPos
	shrdw	dxax			; middle <- (first+last)/2
	movdw	middlePos, dxax

	mov	di, passedDI
	push	cx
	call	HugeArrayLock		; ds:si <- middle element
					; dx <- length
DBCS <	shr	dx, 1						>

	mov	di, passedSI		; es:di <- dest str
	pop	cx
	call	CmpStringsWithLength

	pushf
	call	HugeArrayUnlock
	movdw	dxax, middlePos
	popf	

	jz	foundMiddle
	jb 	10$

	movdw	lastPos, dxax
	jmp	continueSearch

10$:	movdw	firstPos, dxax
	jmp	continueSearch

exit:	.leave
	ret

foundFirst:	
	clrdw	dxax
	stc
	jmp	exit

notFoundFirst:
	clrdw	dxax
	clc
	jmp	exit

foundLast:
	movdw	dxax, lastPos
	stc
	jmp	exit

notFoundLast:
	movdw	dxax, lastPos
	clc
	jmp	exit

notFoundLastAppend:
	movdw	dxax, -1
	clc
	jmp	exit

foundMiddle:
	movdw	dxax, middlePos
	stc
	jmp	exit

HugeArrayBinarySearchNotNullTerm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CmpStringsWithLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two strings with different length.

CALLED BY:	HugeArrayBinarySearchNullTerm/NotNullTerm

PASS:		ds:si = source string
		dx    = length of source string
		es:di = destination string
		cx    = length of destination string

RETURN:		flags

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	YK	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CmpStringsWithLength	proc	near
	uses	cx,dx
	.enter

	cmp	dx, cx
	jz	equalLength

	ja	destStrLonger

	;
	; source string is longer
	;
	xchg	dx, cx
	call	LocalCmpStringsNoCase
	jnz	done
	
	cmp	cx, dx		; this is done to set flags properly
	jmp	done

destStrLonger:
	call	LocalCmpStringsNoCase
	jnz	done

	cmp	dx, cx		; this is done to set flags properly
	jmp	done

equalLength:
	call	LocalCmpStringsNoCase

done:	.leave
	ret

CmpStringsWithLength	endp

;
; C stubs
;
SetGeosConvention

	global PARENTALCONTROLENSUREOPENDATA:far
PARENTALCONTROLENSUREOPENDATA	proc	far
		.enter
		call	PCEnsureOpenData
		.leave
		ret
PARENTALCONTROLENSUREOPENDATA	endp

	global PARENTALCONTROLCLOSEDATA:far
PARENTALCONTROLCLOSEDATA	proc	far
		.enter
		call	PCCloseData
		.leave
		ret
PARENTALCONTROLCLOSEDATA	endp

	global PARENTALCONTROLFINDURL:far
PARENTALCONTROLFINDURL	proc	far	url:fptr.char,
					urlEnd:fptr.char,
					position:fptr.dword
		uses	ds, si, di
		.enter
		lds	di, url
		mov	si, urlEnd.offset
		call	PCFindURL
		lds	si, position
		movdw	ds:[si], dxax
		mov	ax, -1			; assume found -- TRUE
		jc	done
		clr	ax			; not found -- FALSE
done:
		.leave
		ret
PARENTALCONTROLFINDURL	endp

	global PARENTALCONTROLSTOREURL:far
PARENTALCONTROLSTOREURL	proc	far	url:fptr.char,
					urlEnd:fptr.char
		uses	ds, si, di
		.enter
		lds	di, url
		mov	si, urlEnd.offset
		call	PCStoreURLs
		mov	ax, -1			; assume stored -- TRUE
		jc	done
		clr	ax			; not stored -- FALSE
done:
		.leave
		ret
PARENTALCONTROLSTOREURL	endp

	global PARENTALCONTROLDELETEURL:far
PARENTALCONTROLDELETEURL	proc	far	url:word
		uses	ds, si, di
		.enter
		mov	ax, url
		call	PCDataDeleteItem
		mov	ax, -1			; assume deleted -- TRUE
		jc	done
		clr	ax			; not deleted -- FALSE
done:
		.leave
		ret
PARENTALCONTROLDELETEURL	endp

SetDefaultConvention

PCCode	ends

