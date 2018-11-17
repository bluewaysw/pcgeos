COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextTransfer
FILE:		ttReplace.asm

AUTHOR:		Tony Requist, 3/12/90

METHODS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/12/89		Initial revision

DESCRIPTION:
	Transfer item paste stuff

	$Id: ttReplace.asm,v 1.1 97/04/07 11:19:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextTransfer segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextReplaceWithTransferFormat --
			MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
						for VisTextClass

DESCRIPTION:	Replace the given range with a text transfer item.  The range
		passed is the range to replace.  (0, 0) can be passed to insert
		and the beginning.  (TEXT_ADDRESS_PAST_END,
		TEXT_ADDRESS_PAST_END) can be passed to append at the end.

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

	dx - size CommonTransferParams (if called remotely)
	bp - CommonTransferParams

RETURN:
	carry - set if replacement would exceed max length

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@

VisTextReplaceWithTransferFormat	proc	far	uses bp
			; MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	class	VisTextClass
	.enter


	clr	bx				;no context
	call	TA_GetTextRange

	; lock the header block

	push	bp
	mov	ax, ss:[bp].CTP_vmBlock
	mov	bx, ss:[bp].CTP_vmFile
	call	VMLock				;ax = segment, bp = handle
	mov	es, ax				;es <- seg addr of transfer.
	mov	cx, bp				;cx = tt header handle
	pop	bp

	push	cx				;save tt header handle

	; We have to take care of a slight problem here.  The various run
	; arrays contain the VM block handle of the corresponding elements
	; in their huge array header.  Unfortunately this VM block handle
	; could be wrong, since VMCopyVMChain could have been used to copy
	; the transfer item.  We need to go into each run array and fix
	; the element block if needed.

	mov	di, es:[TTBH_charAttrRuns].high
	mov	cx, es:[TTBH_charAttrElements].high
	call	fixElementVMBlock
	mov	di, es:[TTBH_paraAttrRuns].high
	mov	cx, es:[TTBH_paraAttrElements].high
	call	fixElementVMBlock
	mov	di, es:[TTBH_typeRuns].high
	mov	cx, es:[TTBH_typeElements].high
	call	fixElementVMBlock
	mov	di, es:[TTBH_graphicRuns].high
	mov	cx, es:[TTBH_graphicElements].high
	call	fixElementVMBlock

	; The problem, sad to say, is worse than that described above.  The
	; graphics element array also contains references to VM blocks that
	; are likely out of date.  We must fix them up also

	mov	ax, es:[TTBH_graphicElements].high
	mov	di, size TextTransferBlockHeader
	call	TT_RelocateGraphics

	; set up VisTextReplaceParameters

	push	bp
	mov	di, bp
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp
	movdw	ss:[bp].VTRP_range.VTR_start, ss:[di].VTR_start, ax
	movdw	ss:[bp].VTRP_range.VTR_end, ss:[di].VTR_end, ax
	mov	ss:[bp].VTRP_flags, mask VTRF_FILTER or \
				    mask VTRF_USER_MODIFICATION
	push	di
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_HUGE_ARRAY
	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_hugeArray.TRHA_file, bx
	mov	di, es:TTBH_text.high
	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_hugeArray.TRHA_array, di

	; get the size of the text (bx = file of transfer item)

	call	HugeArrayGetCount			;dx.ax = count
	tstdw	dxax
	jz	noText

	decdw	dxax					;don't count NULL
	movdw	ss:[bp].VTRP_insCount, dxax
	pop	di
	adddw	dxax, ss:[di].VTR_start
	movdw	ss:[di].VTR_end, dxax

	; copy in the text

	;
	; Make sure that the user isn't trying to nuke a section break.
	;
	call	TR_CheckCrossSectionChange	; Illegal to nuke section-break
	jc	illegal				; Branch if nuking a break

	; Need to make sure that this replacement won't overflow the 'maxSize'
	; of the text object.  Also make sure that none of the characters to
	; paste violate the filter

	call	TS_CheckLegalChange
	jc	notTooMany

illegal:
	mov	ax, ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR
	call	ObjVarFindData
	jc	noBeep
if PASTE_ERROR_BOXES
	call	displayPasteError
else
	mov	ax, SST_ERROR
	call	UserStandardSound
endif
noBeep:
	add	sp, size VisTextReplaceParameters
	pop	bp
	stc
	jmp	afterReplace

noText:
	; The transfer item was empty.  Fix up the stack and exit.
	;
	pop	di
	jmp	illegal

notTooMany:
	call	TextSuspend

	; We have decided that the replace can happen, call the quick-move
	; handler and let it do any extra work that might need doing.

	call	QuickMoveSpecial
	jc	restoreStackAndCheckError

	clr	dx				;optimization block

	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock

restoreStackAndCheckError:
	lahf					;ah <- error flag (carry)
	add	sp, size VisTextReplaceParameters
	pop	bp
	sahf					;carry set if error replacing
	
	jnc	noError
	;
	; Error returned from trying to replace text, so beep at the
	; user. IP 8/30/94
	;
	mov	ax, ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR
	call	ObjVarFindData
	jc	noBeep2
if PASTE_ERROR_BOXES
	call	displayPasteError
else
	mov	ax, SST_ERROR
	call	UserStandardSound
endif
noBeep2:
	stc
	jmp	unsuspendAndQuit

noError:
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	al, ds:[bx].VTI_storageFlags

	test	al, mask VTSF_MULTIPLE_CHAR_ATTRS
	jz	noCharAttr
	mov	cx, es:TTBH_charAttrRuns.high
	mov	bx, offset VTI_charAttrRuns
	call	callCopyRun
noCharAttr:

	test	al, mask VTSF_MULTIPLE_PARA_ATTRS
	jz	noParaAttr
	mov	cx, es:TTBH_paraAttrRuns.high
	mov	bx, offset VTI_paraAttrRuns
	call	callCopyRun
noParaAttr:

	test	al, mask VTSF_TYPES
	jz	noTypes
	mov	cx, es:TTBH_typeRuns.high
	mov	bx, OFFSET_FOR_TYPE_RUNS
	call	callCopyRun
noTypes:

	test	al, mask VTSF_GRAPHICS
	jz	noGraphics
	mov	cx, es:TTBH_graphicRuns.high
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	call	callCopyRun
noGraphics:

if 0
	test	al, mask VTSF_MULTIPLE_CHAR_ATTRS
	jz	noCharAttr
	mov	cx, es:TTBH_regions.high
	mov	bx, offset VTI_charAttrRuns
	call	callCopyRun
noCharAttr:
endif

	mov	bx, dx
	tst	bx
	jz	noOptBlock
	call	MemFree
noOptBlock:

	; nuke any cached information

	mov	ax, TEMP_VIS_TEXT_CACHED_RUN_INFO
	call	ObjVarDeleteData

unsuspendAndQuit:

	;
	; unlock before sending notification as that could cause
	; another thread to try to lock the VM block.  This avoid
	; a deadlock situation - brianc 12/16/93
	;
	pop	bp
	call	VMUnlock

	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS or mask VTNF_NAME
	call	TA_SendNotification

	call	TextUnsuspend

	clc
	jmp	exit

afterReplace:

	pop	bp
	call	VMUnlock
exit:


	.leave
	ret

;---

	; di = runs, cx = elements, bx = file

fixElementVMBlock:
	push	ds
	tst	di
	jz	fixDone
	call	HugeArrayLockDir
	mov	ds, ax
	cmp	cx, ds:[TLRAH_elementVMBlock]
	jz	fixUnlock
	mov	ds:[TLRAH_elementVMBlock], cx
	call	HugeArrayDirty
fixUnlock:
	call	HugeArrayUnlockDir
fixDone:
	pop	ds
	retn


;---

callCopyRun:
	jcxz	noCopy
	push	ax, di
	push	bx
	mov	bx, ss:[di].CTP_vmFile
	mov	ax, ss:[di].CTP_vmBlock
	call	VMVMBlockToMemBlock
	mov_tr	di, ax
	mov_tr	ax, bx
	pop	bx
	call	TA_CopyRunFromTransfer
	pop	ax, di
noCopy:
	retn

;---

if PASTE_ERROR_BOXES
ErrorStrings	segment lmem LMEM_TYPE_GENERAL

LocalDefString	PasteErrorString <'Unable to insert text.  There may be too many characters or characters that are not supported.',0>		
ErrorStrings	ends

displayPasteError:
	push	si
	clr	bx
	call	GeodeGetAppObject		; ^lbx:si = app obj
	tst	bx
	jz	afterError
	push	bx
	mov	bx, handle ErrorStrings
	call	MemLock
	push	ds
	mov	ds, ax
assume ds:ErrorStrings
	mov	cx, {word} ds:[PasteErrorString]
assume ds:nothing
	pop	ds
	pop	bx
	mov	dx, size GenAppDoDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION, 0>
	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, cx
	movdw	ss:[bp].GADDP_dialog.SDP_helpContext, 0
	movdw	ss:[bp].GADDP_finishOD, 0
	mov	ss:[bp].GADDP_message, 0
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, dx
	mov	bx, handle ErrorStrings
	call	MemUnlock
afterError:
	pop	si
	retn
endif

VisTextReplaceWithTransferFormat	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TT_RelocateGraphics

DESCRIPTION:	Relocate graphics in a run array after they have been possibly
		mangled

CALLED BY:	INTERNAL

PASS:
	ax - VM block containing graphics element array
	bx - VM file
	es:di - array of dwords of correct VM trees

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
	Tony	12/29/92		Initial version

------------------------------------------------------------------------------@
TT_RelocateGraphics	proc	far	uses ax, cx, dx, si, di, bp, ds
	.enter

	tst	ax
	jz	exit
	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si = element array

	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count
	jcxz	done
	mov	dx, ds:[si].CAH_elementSize
	add	si, ds:[si].CAH_offset
relocateLoop:
	cmp	ds:[si].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	next

	tstdw	ds:[si].VTG_vmChain		;does it have a vmChain?
;;
;; Don't jump to next, as that will skip the incrementing of the ptr 
;; into the fix-up table, and skipping an element in the fix-up table
;; means that the wrong values will be stored in the VisTextGraphic 
;; element's vmChain field from this element on.  (cassie - 7/94)
;;
;;	jz	next
	jz	afterCopy			 ;no, don't do the fix up
	cmpdw	ds:[si].VTG_vmChain, es:[di], ax ;has the value changed?
	jz	afterCopy			 ;no, don't need to do fix up
	movdw	ds:[si].VTG_vmChain, es:[di], ax ;do the fix up
	call	VMDirty			
afterCopy:
	add	di, size dword			 ;point to next fix up VMChain
next:
	add	si, dx				 ;point to next graphic element
	loop	relocateLoop

done:
	call	VMUnlock

exit:
	.leave
	ret

TT_RelocateGraphics	endp

TextTransfer ends
