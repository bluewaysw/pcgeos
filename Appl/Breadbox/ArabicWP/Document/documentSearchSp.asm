COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentSearchSp.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the VisContent related code for WriteDocumentClass

	$Id: documentSearchSp.asm,v 1.1 97/04/04 15:56:21 newdeal Exp $

------------------------------------------------------------------------------@

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentGetObjectForSearchSpell --
		MSG_META_GET_OBJECT_FOR_SEARCH_SPELL for WriteDocumentClass

DESCRIPTION:	Get an object for search spell.  This requires loopoing
		through all the text objects in the document

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx:dx - object that search/spell is currently in
	bp - GetSearchSpellObjectParam

RETURN:
	cx:dx - requested object (or 0 if none)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

Text objects are enumerated in this order:
  1) Each article
  2) Main grobj body
  3) Each master page

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentGetObjectForSearchSpell	method dynamic	WriteDocumentClass,
					MSG_META_GET_OBJECT_FOR_SEARCH_SPELL

	call	LockMapBlockES
ifdef GPC
	push	bp			; save original request
endif

	; Getting the first object is easy.  Just return the first article
	; (which conveniently is our first child)

	cmp	bp, GSSOT_FIRST_OBJECT
	jnz	notFirstObject

	add	bx, ds:[bx].Vis_offset
	movdw	cxdx, ds:[bx].VCI_comp.CP_firstChild
	jmp	done

	; Getting the last object involves going to the last master page
	; and sending it a message to find the last text object on it

notFirstObject:
	cmp	bp, GSSOT_LAST_OBJECT
	jnz	notLastObject

	mov	ax, CA_LAST_ELEMENT
	call	SectionArrayEToP_ES
	jmp	lastMasterPageInSection

notLastObject:

	; Getting the next or previous object is somewhat of a pain.
	; First we have to figure out what type of object we are at

	mov	ax, offset WriteArticleClass
	call	isInClass
	jnc	notArticle

	; The object is an article -- find the child number

treatAsArticle:
	push	bp
	call	callFindChild
	mov_tr	ax, bp
	pop	bp

	cmp	bp, GSSOT_NEXT_OBJECT
	jnz	prevArticle

	; go to the next article or to the grobj body

	inc	ax
	mov_tr	dx, ax
	clr	cx
	call	callFindChild			;cx:dx = optr
	mov	ax, offset WriteArticleClass
	call	isInClass
	LONG jc	done

	; next object is the grobj body -- go to its first object (if any)

	mov	bp, GSSOT_FIRST_OBJECT
	call	getGrObjObject
	LONG jnz done
	jmp	firstMasterPage

prevArticle:
	dec	ax
	LONG js	returnNone
	mov_tr	dx, ax
	clr	cx
	call	callFindChild			;cx:dx = optr
	jmp	done

;---------------------------

	; current object is a grobj text object -- get the body

notArticle:
	push	si, bp
	pushdw	cxdx				;save grobj text object
	push	bp
	movdw	bxsi, cxdx
	mov	ax, MSG_VIS_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;cxdx = body
	pop	bp
	movdw	bxsi, cxdx			;bxsi = body
	popdw	cxdx				;cxdx = grobj text object
	or	bp, mask GSSOP_RELAYED_FLAG
	mov	ax, MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	movdw	axdi, cxdx			;axdi = value returned
	movdw	cxdx, bxsi			;cxdx = grobj body
	pop	si, bp
	tst	ax
	jz	notFound
	movdw	cxdx, axdi
	jmp	done
notFound:

	; the grobj body needs help -- first map NEXT to FIRST and PREV to LAST

	cmp	bp, GSSOT_NEXT_OBJECT
	mov	bp, GSSOT_FIRST_OBJECT
	jz	10$
	mov	bp, GSSOT_LAST_OBJECT
10$:

	; see if it is the main body

	mov	ax, offset WriteMasterPageGrObjBodyClass
	call	isInClass
	jc	masterPage

	; current object is the main grobj body

mainBodyCommon:
	cmp	bp, GSSOT_FIRST_OBJECT
	jz	firstMasterPage

	mov	bp, GSSOT_PREV_OBJECT
	jmp	treatAsArticle

	; goto first master page

firstMasterPage:
	clr	ax
	call	SectionArrayEToP_ES
	mov	ax, es:[di].SAE_masterPages[0]
	jmp	gotMasterPageBlock

;---------------------------

	; current object (cx:dx) is a master page body -- find it in the array

masterPage:
	push	cx, dx, si
	call	MemBlockToVMBlockCX
	segxchg	ds, es				;ds = map block, es = document
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset FindMasterCallback
	call	ChunkArrayEnum			;dx = offset of element
EC <	ERROR_NC MASTER_PAGE_NOT_FOUND					>
	mov	di, dx
	pop	cx, dx, si
	segxchg	ds, es

	; es:di = SectionArrayElement, al = # master pages before, ah = # after

	lea	bx, es:[di].SAE_masterPages
	push	ax
	clr	ah
	shl	ax
	add	bx, ax				;ds:bx points at master page
	pop	ax

	cmp	bp, GSSOT_LAST_OBJECT
	jz	prevMasterPage

	; go to the next master page

	tst	ah
	jz	nextSection
	mov	ax, es:[bx+2]
gotMasterPageBlock:
	call	WriteVMBlockToMemBlock		;ax = mem block of master page
	mov_tr	cx, ax
	mov	dx, offset MasterPageBody
	call	getGrObjObject
	jnz	done
	jmp	masterPage

	; go to first master page in next section

nextSection:
	push	si
	segxchg	ds, es
	mov	si, offset SectionArray
	call	ChunkArrayPtrToElement
	inc	ax
	push	cx
	call	ChunkArrayElementToPtr
	pop	cx
	segxchg	ds, es
	pop	si
	jc	returnNone
	mov	ax, es:[di].SAE_masterPages[0]
	jmp	gotMasterPageBlock

	; go to the previous master page

prevMasterPage:
	tst	al
	jz	prevSection
	mov	ax, es:[bx-2]
	jmp	gotMasterPageBlock

	; go to the previous section

prevSection:
	push	si
	segxchg	ds, es
	mov	si, offset SectionArray
	call	ChunkArrayPtrToElement
	dec	ax
	js	wrapToMainBody
	push	cx
	call	ChunkArrayElementToPtr
	pop	cx
	segxchg	ds, es
	pop	si
lastMasterPageInSection:
	mov	bx, es:[di].SAE_numMasterPages
	dec	bx
	shl	bx
	mov	ax, es:[di][bx].SAE_masterPages[0]
	jmp	gotMasterPageBlock

wrapToMainBody:
	segxchg	ds, es
	pop	si
	mov	ax, es:[MBH_grobjBlock]
	call	WriteVMBlockToMemBlock
	mov_tr	cx, ax
	mov	dx, offset MainBody
	mov	bp, GSSOT_LAST_OBJECT
	call	getGrObjObject
	jnz	done
	jmp	mainBodyCommon

;---------------------------

returnNone:
	clrdw	cxdx
done:
ifdef GPC
	pop	bp			; bp = original command
	call	handleWrap
endif
EC <	call	AssertIsWriteDocument					>
	call	VMUnlockES
	ret

ifdef GPC
handleWrap	label	near
	;
	; check wrap-around: we've wrapped when we get GSSOT_FIRST_OBJECT
	; after getting GSSOT_NEXT_OBJECT and returning 0:0, so when get
	; GSSOT_NEXT_OBJECT and will return 0:0, set flag, when
	; GSSOT_FIRST_OBJECT comes in and flag is set, query user and only
	; return first object is user acknowledges wrap around
	;
	cmp	bp, GSSOT_FIRST_OBJECT
	je	checkWrapped
	cmp	bp, GSSOT_LAST_OBJECT
	je	checkWrapped
	tst	cx
	jnz	noWrap
	cmp	bp, GSSOT_NEXT_OBJECT
	je	markWrap
	cmp	bp, GSSOT_PREV_OBJECT
	jne	noWrap
markWrap:
	mov	ax, TEMP_WRITE_DOCUMENT_NO_SEARCH_WRAP_CHECK
	call	ObjVarFindData
	jc	noWrap
	push	cx
	mov	ax, TEMP_WRITE_DOCUMENT_SEARCH_WRAPPED
	clr	cx
	call	ObjVarAddData
	pop	cx
noWrap:
	retn

checkWrapped:
	mov	ax, TEMP_WRITE_DOCUMENT_SEARCH_WRAPPED
	call	ObjVarDeleteData
	jc	noWrap			; C set if not found
	push	si
	mov	ax, offset SearchReachedEndString
	cmp	bp, GSSOT_FIRST_OBJECT
	je	gotString
	mov	ax, offset SearchReachedBeginningString
gotString:
	call	DisplayQuestion
	cmp	ax, IC_YES
	pop	si
	je	noWrap			; yes, continue search
	clrdw	cxdx			; stop search
	jmp	noWrap
endif

;---

	; ax = offset of class
	; return carry set if cxdx is an article
	; destroy: ax

isInClass:
	push	bx, cx, dx, si, di, bp, ds
	movdw	bxsi, cxdx			;bx:si = object
	mov	cx, segment GeoWriteClassStructures
	mov_tr	dx, ax
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, cx, dx, si, di, bp, ds
	retn

;---

callFindChild:
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompFindChild		;bp = child number
	retn

;---

	; pass cxdx = grobj body, bp = type
	; return cxdx = object or body, Z clear if exists
	; destroy: none

getGrObjObject:
	push	ax, bx, si, di, bp
	or	bp, mask GSSOP_RELAYED_FLAG
	movdw	bxsi, cxdx
	mov	ax, MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst	cx
	jnz	getDone
	movdw	cxdx, bxsi			;return body if no object found
getDone:
	pop	ax, bx, si, di, bp
	retn

WriteDocumentGetObjectForSearchSpell	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindMasterCallback

DESCRIPTION:	Callback routine to find a master page

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	cx - master page VM block

RETURN:
	carry - set if found
	offset of element
	al - number of master pages before
	ah - number of master pages after

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
FindMasterCallback	proc	far
	mov	dx, di
	clr	ax
	mov	ah, ds:[di].SAE_numMasterPages.low
	add	di, offset SAE_masterPages
compareLoop:
	cmp	cx, ds:[di]
	stc
	jz	done
	add	di, size word
	inc	al
	dec	ah
	jnz	compareLoop
	clc
done:
	pushf
	dec	ah
	popf
	ret

FindMasterCallback	endp

ifdef GPC
;
; sorry about this...
;
WriteDocumentClearSearchWrap	method	dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_CLEAR_SEARCH_WRAP_CHECK
	mov	ax, TEMP_WRITE_DOCUMENT_NO_SEARCH_WRAP_CHECK
	clr	cx
	call	ObjVarAddData
	ret
WriteDocumentClearSearchWrap	endm

WriteDocumentSetSearchWrap	method	dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_SET_SEARCH_WRAP_CHECK
	mov	ax, TEMP_WRITE_DOCUMENT_NO_SEARCH_WRAP_CHECK
	call	ObjVarDeleteData
	ret
WriteDocumentSetSearchWrap	endm

GeoWriteClassStructures	segment	resource
 WSpellControlClass
 WSearchReplaceControlClass
GeoWriteClassStructures	ends

WSpellControlStartSpell	method dynamic	WSpellControlClass,
					MSG_SC_CHECK_ENTIRE_DOCUMENT,
					MSG_SC_CHECK_TO_END,
					MSG_SC_CHECK_SELECTION
	;
	; even though the WriteDocument is run by the process thread,
	; synchronization is fine here since the SpellControl will also
	; being sending MSG_SPELL_CHECK to the spell target (run by
	; process thread)
	;
	push	ax, cx, dx, bp, si
	mov	ax, MSG_WRITE_DOCUMENT_CLEAR_SEARCH_WRAP_CHECK
	mov	bx, segment WriteDocumentClass
	mov	si, offset WriteDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_MODEL
	GetResourceHandleNS	WriteDocumentGroup, bx
	mov	si, offset WriteDocumentGroup
	clr	di
	call	ObjMessage
	pop	ax, cx, dx, bp, si
	; resume course
	mov	di, offset WSpellControlClass
	call	ObjCallSuperNoLock
	ret
WSpellControlStartSpell	endm

WSearchReplaceControlStartSearch	method dynamic	WSearchReplaceControlClass,
				MSG_SRC_FIND_NEXT,
				MSG_SRC_FIND_PREV,
				MSG_REPLACE_CURRENT,
				MSG_REPLACE_ALL_OCCURRENCES,
				MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION,
				MSG_SRC_REPLACE_ALL_OCCURRENCES_NO_QUERY,
				MSG_SRC_FIND_FROM_TOP
	;
	; even though the WriteDocument is run by the process thread,
	; synchronization is fine here since the SpellControl will also
	; being sending MSG_SEARCH to the spell target (run by
	; process thread)
	;
	push	ax, cx, dx, bp, si
	mov	ax, MSG_WRITE_DOCUMENT_SET_SEARCH_WRAP_CHECK
	mov	bx, segment WriteDocumentClass
	mov	si, offset WriteDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_MODEL
	GetResourceHandleNS	WriteDocumentGroup, bx
	mov	si, offset WriteDocumentGroup
	clr	di
	call	ObjMessage
	pop	ax, cx, dx, bp, si
	; resume course
	mov	di, offset WSearchReplaceControlClass
	call	ObjCallSuperNoLock
	ret
WSearchReplaceControlStartSearch	endm
endif

DocSTUFF ends
