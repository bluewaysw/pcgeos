COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipTrans.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetGetStyle

	$Id: manipTrans.asm,v 1.1 97/04/07 11:15:31 newdeal Exp $

------------------------------------------------------------------------------@

ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetCopyElement

DESCRIPTION:	Copy an element from an attribute array in document space to
		an attribute array in transfer space, copying underlying
		style information as needed

CALLED BY:	GLOBAL

PASS:
	ss:bp - StyleSheetParams
	ax - element # to copy (in document space)
	bx - offset of attribute array to work on
	cx - non-zero to copy from transfer space
	dx - CA_NULL_ELEMENT to copy style or attribute token to base
	     destination on
	di - optimization block handle (or 0 to allocate one)
	
RETURN:
	bx - element # in destination (in transfer space)
	di - optimization block

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetCopyElement	proc	far
STYLE_COPY_LOCALS
transParam	local	word

	; if no style array was passed then bail out

	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jnz	1$
	ret
1$:

	.enter

	ENTER_FULL_EC

	clr	substituteFlag

	push	di
	call	EnterStyleSheet
	pop	optBlock
	mov	transParam, dx

	; set flags

	mov	dx, 0x0100			;assume TO
	jcxz	10$
	mov	dx, 0x0001			;FROM
10$:
	mov	fromTransfer, dl
	mov	changeDestStyles, dh

	push	ax, bx				;save element & offset

	call	LockSpecificAttrArray

	call	Load_dssi_sourceAttr
	call	ChunkArrayElementToPtr		;ds:di = element, cx = size
	mov	ax, ds:[di].SSEH_style

	; if copying relative to another destination element then get the
	; base style from there

	cmp	transParam, CA_NULL_ELEMENT
	jz	useStyle

	call	Load_dssi_sourceStyle
	call	ChunkArrayElementToPtr		;ds:di = element, cx = size
	add	di, attrCounter2
	mov	ax, ds:[di].SEH_attrTokens	;ax = attr in destination space
	mov	styleToChange, ax

	mov	ax, transParam
	call	Load_dssi_destAttr
	call	ChunkArrayElementToPtr		;ds:di = element, cx = size
	mov	ax, ds:[di].SSEH_style
	call	UnlockSpecificAttrArray
	mov	dx, 1
	jmp	common

useStyle:
	call	UnlockSpecificAttrArray
	mov	styleToChange, ax
	call	CopyStyle			;ax = style (in dest)
	clr	dx

common:
	mov	destStyle, ax
	mov	destCopyFromStyle, ax
	pop	ax, bx

	call	LockSpecificAttrArray

	push	bx, dx
	mov	bx, attrCounter2
	add	bx, OPT_ATTR_ARRAY_CHUNK
	mov	dx, transParam
	call	LookupOpt
	pop	bx, dx
	jnc	noOpt

	; the optimization worked -- we know what the new token is, now we
	; have to add a reference for it

	call	Load_dssi_destAttr
	call	ElementArrayAddReference
	jmp	afterCopyElement

noOpt:
	push	ax
	call	CopyElement			;ax = element (in dest)
	pop	cx
	mov	dx, transParam
	mov	bx, attrCounter2
	add	bx, OPT_ATTR_ARRAY_CHUNK
	call	AddOpt
afterCopyElement:
	push	ax

	call	UnlockSpecificAttrArray

	call	LeaveStyleSheet

	pop	bx				;bx = element to return
	mov	di, optBlock

	LEAVE_FULL_EC

	.leave
	ret

StyleSheetCopyElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetImportStyles

DESCRIPTION:	Import styles from an outside source.

CALLED BY:	GLOBAL

PASS:
	cx - non-zero to change destination styles when there are duplicates
	ss:bp - StyleSheetParams
	
RETURN:
	ax - non-zero if recalculation is necessary

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetImportStyles	proc	far
STYLE_COPY_LOCALS

	; if no style array was passed then bail out

	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jnz	1$
	ret
1$:

	.enter

	ENTER_FULL_EC

	call	EnterStyleSheet
	clr	optBlock
	mov	substituteFlag, 1

	mov	fromTransfer, 1
	jcxz	10$
	inc	cl
10$:
	mov	changeDestStyles, cl

	call	Load_dssi_sourceStyle
	mov	bx, cs
	mov	di, offset ImportStyleCallback
	call	ChunkArrayEnum

	mov	bx, optBlock
	tst	bx
	jz	20$
	call	MemFree
20$:

	call	StyleSheetIncNotifyCounter	;mark styles changed
	call	LeaveStyleSheet

	mov	ax, recalcFlag

	LEAVE_FULL_EC

	.leave
	ret

StyleSheetImportStyles	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ImportStyleCallback

DESCRIPTION:	Callback to import a style

CALLED BY:	StyleSheetImportStyles (via ChunkArrayEnum)

PASS:
	*ds:si - array
	ds:di - element
	ss:bp - inherited variables

RETURN:
	carry clear (continue enumeration)

DESTROYED:
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/14/92		Initial version

------------------------------------------------------------------------------@
ImportStyleCallback	proc	far
STYLE_COPY_LOCALS
	.enter inherit far

	; skip free elements

	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	LONG jz	done

	push	ds
	call	ChunkArrayPtrToElement		;ax = style (in source)
	call	CopyStyle			;ax = style (in dest)
	pop	ds

done:
	clc
	.leave
	ret

ImportStyleCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetOpenFileForImport

DESCRIPTION:	Open a file for importing a style sheet

CALLED BY:	GLOBAL

PASS:
	ss:bp - SSCLoadStyleSheetParams

RETURN:
	carry - set if error
	bx - file handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/22/92		Initial version

------------------------------------------------------------------------------@
StyleSheetOpenFileForImport	proc	far	uses ax, cx, dx, si, di, ds
	mov	bx, bp				;ss:bx = params
SBCS <buffer	local	PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE dup (char)>
DBCS <buffer	local	PATH_BUFFER_SIZE/2+FILE_LONGNAME_BUFFER_SIZE/2 dup (wchar)>
	.enter

	call	FilePushDir

	mov	si, ss:[bx].SSCLSSP_fileSelector.chunk
	mov	bx, ss:[bx].SSCLSSP_fileSelector.handle	;bx:si = file selector
	push	bx

	push	bp
	mov	dx, ss
	lea	bp, buffer
	mov	cx, size buffer
	mov	ax, MSG_GEN_PATH_GET
	mov	di, mask MF_CALL
	call	ObjMessage			;cx = disk handle
	mov	bx, cx
	pop	bp

	segmov	ds, ss
	lea	dx, buffer
	call	FileSetCurrentPath
	pop	bx
	jc	done

	mov	cx, ss
	lea	dx, buffer
	push	bp
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	segmov	ds, ss
	lea	dx, buffer
	mov	ax, (VMO_OPEN shl 8) or mask VMAF_FORCE_READ_ONLY
	call	VMOpen

done:
	call	FilePopDir
	.leave
	ret

StyleSheetOpenFileForImport	endp

ManipCode	ends
