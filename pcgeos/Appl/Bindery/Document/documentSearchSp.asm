COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentSearchSp.asm

ROUTINES:
	Name				Description
	----				-----------
    INT FindMasterCallback	Callback routine to find a master page

METHODS:
	Name			Description
	----			-----------
    StudioDocumentGetObjectForSearchSpell  
				Get an object for search spell.	 This
				requires loopoing through all the text
				objects in the document

				MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the VisContent related code for StudioDocumentClass

	$Id: documentSearchSp.asm,v 1.1 97/04/04 14:39:06 newdeal Exp $

------------------------------------------------------------------------------@

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentGetObjectForSearchSpell --
		MSG_META_GET_OBJECT_FOR_SEARCH_SPELL for StudioDocumentClass

DESCRIPTION:	Get an object for search spell.  This requires loopoing
		through all the text objects in the document

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentGetObjectForSearchSpell	method dynamic	StudioDocumentClass,
					MSG_META_GET_OBJECT_FOR_SEARCH_SPELL

	call	LockMapBlockES

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

	mov	ax, offset StudioArticleClass
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
	mov	ax, offset StudioArticleClass
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
	mov	di, mask MF_CALL
	call	ObjMessage			;cxdx = body
	pop	bp
	movdw	bxsi, cxdx			;bxsi = body
	popdw	cxdx				;cxdx = grobj text object
	or	bp, mask GSSOP_RELAYED_FLAG
	mov	ax, MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
	mov	di, mask MF_CALL
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

	mov	ax, offset StudioMasterPageGrObjBodyClass
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
	call	StudioVMBlockToMemBlock		;ax = mem block of master page
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
	call	StudioVMBlockToMemBlock
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
EC <	call	AssertIsStudioDocument					>
	call	VMUnlockES
	ret

;---

	; ax = offset of class
	; return carry set if cxdx is an article
	; destroy: ax

isInClass:
	push	bx, cx, dx, si, di, bp, ds
	movdw	bxsi, cxdx			;bx:si = object
	call	StudioGetDGroupDS
	mov	cx, ds
	mov_tr	dx, ax
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL
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
	mov	di, mask MF_CALL
	call	ObjMessage
	tst	cx
	jnz	getDone
	movdw	cxdx, bxsi			;return body if no object found
getDone:
	pop	ax, bx, si, di, bp
	retn

StudioDocumentGetObjectForSearchSpell	endm

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

DocSTUFF ends
