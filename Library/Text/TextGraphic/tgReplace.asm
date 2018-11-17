COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextGraphic
FILE:		tgReplace.asm

METHODS:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	...

	$Id: tgReplace.asm,v 1.1 97/04/07 11:19:40 newdeal Exp $

------------------------------------------------------------------------------@

TextGraphic segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextReplaceWithGraphic --
		MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC for VisTextClass

DESCRIPTION:	Replace the current selection with a graphic

PASS:
	*ds:si - instance data (VisTextInstance)

	dx - size ReplaceWithGraphicParams
	ss:bp - ReplaceWithGraphicParams

RETURN:
	carry set if error. (maxLength would be exceeded by adding graphic).

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	SH	5/94		XIP'ed
------------------------------------------------------------------------------@

VisTextReplaceWithGraphic	proc	far ; MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	class	VisTextClass

	; If the graphic is coming from a VM file, make sure this text
	; object resides in a VM file as well.
	;
	tst	ss:[bp].RWGP_sourceFile
	jz	afterVMCheck

	; T_GetVMFile will return the process handle if this is a
	; non-VM text object, so bail if that happens.

	call	T_GetVMFile
	mov_tr	ax, bx

	call	GeodeGetProcessHandle
	cmp	ax, bx
	jne	afterVMCheck
	ret				; <- EXIT

afterVMCheck:

	; suspend the text object

	call	TextSuspend

	; insert the C_GRAPHIC character

	mov	ax, offset ReplacementString
	call	TU_StartChainIfUndoable

	push	bp
	movdw	dxax, ss:[bp].RWGP_range.VTR_start
	movdw	cxbx, ss:[bp].RWGP_range.VTR_end
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp
	movdw	ss:[bp].VTRP_range.VTR_start, dxax
	movdw	ss:[bp].VTRP_range.VTR_end, cxbx
	movdw	ss:[bp].VTRP_insCount, 1
	mov	ss:[bp].VTRP_flags, 0
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
NOFXIP<	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.\
				TRP_pointer.segment, cs			>
FXIP <	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.\
				TRP_pointer.segment, segment dummyChar 	>
	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.\
				TRP_pointer.offset, offset dummyChar 	
	call	QuickMoveSpecial
	jc	error

	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp
	jc	error	;Exit, if we couldn't add the graphic

	; change the dummy character that we inserted to a C_GRAPHIC

	movdw	dxax, ss:[bp].VTRP_range.VTR_start
	incdw	dxax
	movdw	ss:[bp].VTRP_range.VTR_end, dxax
	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.\
					TRP_pointer.offset, offset graphicChar
	call	TS_ReplaceRange

	movdw	dxax, ss:[bp].VTRP_range.VTR_start

	add	sp, size VisTextReplaceParameters
	pop	bp

	; add the element and the run

	push	bp
	mov	bx, ss:[bp].RWGP_sourceFile
	lea	bp, ss:[bp].RWGP_graphic
	call	TA_AddGraphicAndRun

	; nuke any cached information

	mov	ax, TEMP_VIS_TEXT_CACHED_RUN_INFO
	call	ObjVarDeleteData
	clc			;Replace succeeded...
exit:

	pushf
	; un-suspend the object

	call	TU_EndChainIfUndoable

	call	TextUnsuspend
	popf

	pop	bp

	ret
error:
	add	sp, size VisTextReplaceParameters
	stc			;Return carry set to denote error
	jmp	exit
	

VisTextReplaceWithGraphic	endp

;
; On XIP systems, put these characters in a fixed resource, to save us lots
; of headaches...
;
FXIP <TextFixed	segment resource					>
SBCS <dummyChar	char	"x"						>
DBCS <dummyChar	wchar	"x"						>

SBCS <graphicChar	char	C_GRAPHIC				>
DBCS <graphicChar	wchar	C_GRAPHIC				>
FXIP <TextFixed	ends					>


COMMENT @----------------------------------------------------------------------

FUNCTION:	TG_CopyGraphic

DESCRIPTION:	Copy a graphic to a VM file

PASS:
	bx - destination file
	dx - source vm file
	ss:bp - VisTextGraphic

RETURN:
	ss:bp - VisTextGraphic

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
TG_CopyGraphic	proc	far	uses	ax, bx, cx, dx, si, di, es
	.enter

	; get the dest file

	xchg	bx, dx				;bx = source, dx = dest
	tst	bx
	jnz	gotSource
	mov	bx, dx				;source = dest
gotSource:

	mov	ax, ss:[bp].VTG_vmChain.high
	tst	ax
	jz	done
	push	bp
	mov	bp, ss:[bp].VTG_vmChain.low
	clr	cx				;preserve VM id's
	call	VMCopyVMChain			;axbp = chain
	mov	cx, bp				;axcx = chain
	pop	bp

	; don't copy lmem chunk

	movdw	ss:[bp].VTG_vmChain, axcx

done:
	.leave
	ret

TG_CopyGraphic	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TG_CompareGraphics

DESCRIPTION:	Compare two VisTextGraphic structures

CALLED BY:	INTERNAL

PASS:
	ds:si - element in array
	es:di - element to compare against
	ss:ax - file for es:di element, file for ds:si element

RETURN:
	carry - set if equal

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
TG_CompareGraphics	proc	far	uses	si, di, bp, ds, es
	.enter

if ERROR_CHECK
	;
	; Validate that the element is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, es							>
FXIP<	mov	si, di							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	mov_tr	bp, ax
	mov	dx, ss:[bp]			;dx = source file
	mov	bx, ss:[bp+2]			;bx = dest file

	; compare everything but the data...

	push	si, di
	mov	cx, (size VisTextGraphic) - (offset VTG_size)
	add	si, offset VTG_size
	add	di, offset VTG_size
	repe	cmpsb
	pop	si, di
	jnz	different

	; compare vm data

	mov	ax, ds:[si].VTG_vmChain.high
	mov	cx, es:[di].VTG_vmChain.high
	jcxz	esdiIsLMem
	tst	ax
	jz	different

	; get the dest file

	tst	dx
	jnz	gotESDIfile
	mov	dx, bx
gotESDIfile:

	; bx = dssi file, dx = esdi file

	mov	bp, ds:[si].VTG_vmChain.low
	mov	di, es:[di].VTG_vmChain.low
	call	VMCompareVMChains
	jmp	done

esdiIsLMem:
	tst	ax
	jnz	different

	mov	si, ds:[si].VTG_vmChain.low
	mov	di, es:[di].VTG_vmChain.low
	tst	di
	jz	esdiInNone
	tst	si
	jz	different

	mov	si, ds:[si] 
	mov	di, ds:[di]

;	Crash if either chunk is empty. If they *can* be empty, then the
;	code should change to check for this case.

EC <	cmp	si, -1							>
EC <	ERROR_Z -1							>
EC <	cmp	di, -1							>
EC <	ERROR_Z -1							>

	mov	cx, ds:[si].LMC_size
	cmp	cx, ds:[di].LMC_size
	jnz	different

	segmov	es, ds
	dec	cx
	dec	cx
	shr	cx, 1
	jnc	20$
	cmpsb
	jne	different
20$:	
	repe	cmpsw
	stc
	je	done
different:
	clc
done:

	.leave
	ret

esdiInNone:
	tst	si
	jnz	different
	stc
	jmp	done

TG_CompareGraphics	endp

TextGraphic ends
