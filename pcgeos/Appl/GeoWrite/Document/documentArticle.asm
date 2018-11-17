COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentArticle.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the article related code for WriteDocumentClass

	$Id: documentArticle.asm,v 1.1 97/04/04 15:56:15 newdeal Exp $

------------------------------------------------------------------------------@

DocCreate segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateNewArticle

DESCRIPTION:	Create a new article

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - name for new article (null terminated)

RETURN:
	carry - set if error (name already exists)
	ax - article number

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
CreateNewArticle	proc	near	uses bx, cx, dx, si, di, bp, es
	.enter
EC <	call	AssertIsWriteDocument					>

	; Add article to article array

	pushdw	dssi				;save object
	call	LockMapBlockDS
	mov	si, offset ArticleArray

	; check for name already existing

	clr	cx				;null-terminated
	clr	dx
	call	NameArrayFind
	cmp	ax, CA_NULL_ELEMENT
	LONG jnz error

	call	NameArrayAdd			;ax = new token
EC <	ERROR_NC	WRITE_INTERNAL_LOGIC_ERROR			>

	call	ChunkArrayElementToPtr		;ds:di = new element
	segmov	es, ds				;es:di = data
	popdw	dssi

	; Duplicate article block

	mov	bx, handle ArticleTempUI
	call	DuplicateAndAttachObj		;ax = VM block
	mov	es:[di].AAE_articleBlock, ax

	; Initialize text object runs and attribute arrays

	; Make the text object large

	mov	si, offset ArticleText
	mov	ax, MSG_VIS_LARGE_TEXT_CREATE_DATA_STRUCTURES
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; create multiple char attrs and set the element block

	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	mov	cx, mask VTSF_MULTIPLE_CHAR_ATTRS \
				or mask VTSF_MULTIPLE_PARA_ATTRS \
				or mask VTSF_STYLES or mask VTSF_GRAPHICS \
				or mask VTSF_TYPES
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY
	mov	cx, (1 shl 8) or mask VTSF_MULTIPLE_CHAR_ATTRS
	mov	dx, es:MBH_charAttrElements	;dx = VM block
	mov	bp, CHAR_ATTR_NORMAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, (1 shl 8) or mask VTSF_MULTIPLE_PARA_ATTRS
	mov	dx, es:MBH_paraAttrElements	;dx = VM block
	mov	bp, PARA_ATTR_NORMAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, (1 shl 8) or mask VTSF_STYLES
	mov	dx, es:MBH_textStyles		;dx = VM block
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, (1 shl 8) or mask VTSF_GRAPHICS
	mov	dx, es:MBH_graphicElements	;dx = VM block
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; create multiple types and set the element block

	mov	cx, (1 shl 8) or mask VTSF_TYPES
	mov	dx, es:MBH_typeElements		;dx = VM block
	mov	bp, TYPE_ATTR_NORMAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, (1 shl 8) or VTSF_NAMES
	mov	dx, es:MBH_nameElements
	mov	bp, 0	
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bp, es:LMBH_handle
	call	VMDirty
	clc
done:
	call	VMUnlockES

	.leave
	ret

error:
	segmov	es, ds
	popdw	dssi
	stc
	jmp	done

CreateNewArticle	endp

DocCreate ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSendToAllArticles --
		MSG_WRITE_DOCUMENT_SEND_TO_ALL_ARTICLES for WriteDocumentClass

DESCRIPTION:	Send a message to all the articles

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx - message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentSendToAllArticles	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_SEND_TO_ALL_ARTICLES

	call	LockMapBlockES
	mov	di, cx
	call	SendToAllArticlesLow
	call	VMUnlockES

	ret

WriteDocumentSendToAllArticles	endm

DocSTUFF ends

DocPageCreDest segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSendToFirstArticle --
		MSG_WRITE_DOCUMENT_SEND_TO_FIRST_ARTICLE for WriteDocumentClass

DESCRIPTION:	Send a message to the first article

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx - message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentSendToFirstArticle	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_SEND_TO_FIRST_ARTICLE

	call	LockMapBlockES
	mov	di, cx
	call	SendToFirstArticle
	call	VMUnlockES

	ret

WriteDocumentSendToFirstArticle	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToAllArticles

DESCRIPTION:	Send a message to all articles in the document

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - locked map block
	ax - message
	cx, dx, bp - message data
	di - message flags

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
SendToAllArticles	proc	far	uses di
	.enter
EC <	call	AssertIsWriteDocument					>

	call	ObjMessage			;di = message
	call	SendToAllArticlesLow

	.leave
	ret

SendToAllArticles	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToAllArticlesLow

DESCRIPTION:	Send an encapsulated message to all articles in the document
		(and then free the message)

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - locked map block
	di - encapsulated message

RETURN:
	none

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
SendToAllArticlesLow	proc	far	uses ax, bx, cx, dx, si, bp, ds
	.enter

EC <	call	AssertIsWriteDocument					>

	mov	bp, di
	movdw	cxdx, dssi

	segmov	ds, es
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset SendToAllCallback
	call	ChunkArrayEnum

	mov	bx, bp
	call	ObjFreeMessage

	.leave
	ret

SendToAllArticlesLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToAllCallback

DESCRIPTION:	Callback to send a message to all articles

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleArrayElement
	cx:dx - dcoument object
	bp - message

RETURN:
	carry - clear

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
SendToAllCallback	proc	far	uses dx, bp, ds
	.enter

	mov	ax, ds:[di].AAE_articleBlock
	movdw	dssi, cxdx
	call	WriteVMBlockToMemBlock
	mov_tr	cx, ax
	mov	si, offset ArticleText		;cx:si = dest
	mov	bx, bp
	call	MessageSetDestination
	clr	cx
	mov	di, mask MF_RECORD or mask MF_FIXUP_DS		;don't free
	call	MessageDispatch
	mov	cx, ds

	.leave
	ret

SendToAllCallback	endp

DocPageCreDest ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToFirstArticle

DESCRIPTION:	Send an encapsulated message to all articles in the document
		(and then free the message)

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - locked map block
	di - encapsulated message

RETURN:
	none

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
SendToFirstArticle	proc	far	uses ax, bx, cx, dx, si, bp, ds
	.enter

EC <	call	AssertIsWriteDocument					>

	mov	bp, di				;bp = message
	movdw	cxdx, dssi

	segmov	ds, es
	mov	si, offset ArticleArray
	clr	ax
	push	cx
	call	ChunkArrayElementToPtr
	pop	cx
	call	SendToAllCallback

	mov	bx, bp
	call	ObjFreeMessage

	.leave
	ret

SendToFirstArticle	endp

DocSTUFF ends
