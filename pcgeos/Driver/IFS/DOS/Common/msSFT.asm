COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		msSFT.asm

AUTHOR:		Adam de Boor, Mar 16, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/16/92		Initial revision


DESCRIPTION:
	Code common to all MS DOS IFS drivers to manipulate the linked-list
	SFT used by MS DOS.
		

	$Id: msSFT.asm,v 1.1 97/04/10 11:55:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPointToSFTEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the numbered SFT entry (must be resident so
		FSHandleInfo can work)

CALLED BY:	EXTERNAL
PASS:		al	= SFN of entry to find
RETURN:		carry clear if ok:
			es:di	= SFTEntry for the thing
		carry set if SFN invalid
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPointToSFTEntry proc	far	uses ax
		.enter
		segmov	es, dgroup, di
		les	di, es:[sftStart]
		clr	ah
	;
	; Loop until we find the right block.
	;
blockLoop:
		cmp	es:[di].SFTBH_numEntries, ax
		ja	haveBlock
		;
		; Reduce ax by number in this block and advance to next.
		;
		sub	ax, es:[di].SFTBH_numEntries
		les	di, es:[di].SFTBH_next
		cmp	di, NIL
		stc
		jz	done
		jmp	blockLoop
haveBlock:
	;
	; ES:DI = SFTBlockHeader of containing block. Add offset into
	; block of desired entry (cx * size SFTEntry + offset SFTBH_entries)
	;
		add	di, offset SFTBH_entries
		tst	ax
		jz	done		; Don't multiply if ax is 0...
		push	dx
if _MS3
	 	; sft entry varies in size between versions of 3.x (q.v.
		; MSLocateFileTable)
		push	ds
		segmov	ds, dgroup, dx
		mov	dx, ds:[sftEntrySize]
		pop	ds
else
		mov	dx, size SFTEntry
endif
		mul	dx
		add	di, ax
		pop	dx
		clc
done:
		.leave
		ret
DOSPointToSFTEntry endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCompareSFTEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two entries in the file table.

CALLED BY:	DOSCompareFiles
PASS:		ds:si	= SFTEntry 1
		es:di	= SFTEntry 2
RETURN:		ZF set if ds:si and es:di refer to the same disk file
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCompareSFTEntries proc near
		.enter
if not _MS2
        ;
        ; Make sure both entries are either devices or files and either
        ; both local or both remote.
        ;
                mov     ax, es:[di].SFTE_flags.SFTF_file
                xor     ax, ds:[si].SFTE_flags.SFTF_file
                test    ax, (mask SFTFF_ISDEV or mask SFTFF_REMOTE)
                jnz     done

                mov     ax, es:[di].SFTE_flags.SFTF_file

                ; XXX: if the file is remote, we've no way (yet) to uniquely
                ; identify the beast, so just say they're not equal if
                ; the thing be remote.

                test    ax, mask SFTFF_REMOTE
                jnz     done

                ;
                ; If the thing is a file, see if the directory index, directory
                ; LBN and initial clusters match. Can't do such checks for a
                ; device b/c a device has no file space.
                ;
                test    ax, mask SFTFF_ISDEV
                jnz     checkDev

;       For a file that was recently created and has just been cached (never
;       committed to disk), if DOS opens it again, the initial cluster for the
;       new instance will be 0, not the cluster allocated for the thing. This
;       may only happen if you open the thing read-only (since you won't be
;       able to modify the file, why go to the trouble of searching for
;       an already-open instance and get the initCluster from there?). Anyway,
;       I think the directory's LBN and the index in that directory should
;       be sufficient, along with the drive number, to identify the file
;       uniquely -- ardeb 6/15/90
;
;               mov     ax, es:[di].SFTE_initCluster
;               cmp     ax, ds:[si].SFTE_initCluster
;               jne     done

                mov     al, es:[di].SFTE_dirIndex
                cmp     al, ds:[si].SFTE_dirIndex
                jne     done
if	_MS3
                mov     ax, es:[di].SFTE_dirLBN
                cmp     ax, ds:[si].SFTE_dirLBN
else
		cmpdw	es:[di].SFTE_dirLBN, ds:[si].SFTE_dirLBN, ax
endif	; _MS3
                jne     done
                mov     al, {byte}ds:[si].SFTE_flags
                xor     al, {byte}es:[di].SFTE_flags
                andnf   al, mask SFTFF_DRIVE
                jnz     done
checkDev:
                ;
                ; See if the DCB field points to the same place. No need to
                ; check anything *in* the DCB, I don't think -- if the files are
                ; on the same device, they should have the same DCB...unless the
                ; user has created disk aliases. In that case one could
                ; conceivably compare the deviceHeader and unit fields of the
                ; DCB (except for a device...) but it doesn't seem worth it.
                ; This way the device and file code can share this here code...
                ;
                mov     ax, es:[di].SFTE_DCB.low
                cmp     ax, ds:[si].SFTE_DCB.low
                jne     done
                mov     ax, es:[di].SFTE_DCB.high
                cmp     ax, ds:[si].SFTE_DCB.high
                ;
                ; XXX: Compare names too? Probably not worth it.
                ;
endif
done:
		.leave
		ret
DOSCompareSFTEntries endp


;Moved into Resident resource 4/21/93 by EDS. See DOSUtilOpen.
;Resident	ends
;PathOps		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSExtendSFT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend the SFT by a reasonable amount to allow us to
		open more files, now the current SFT is full.

CALLED BY:	DOSAllocOpOpen, DOSAllocOpCreate, DOSUtilOpen
PASS:		ax	= ERROR_TOO_MANY_OPEN_FILES
RETURN:		carry set if couldn't extend
		carry clear if caller should try again.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MSExtendSFT	proc	far
		uses	ds, di, es, ax, cx, bx
		.enter
	;
	; Make sure all entries are actually used up. There are certain
	; things (e.g. TOPS) that are fascist and will hose us big time,
	; telling us there's no room when we know damn well there is.
	; Rather than constantly extending the SFT until we run out of
	; memory, we'd like to catch this...
	;
		call	LoadVarSegDS

		les	di, ds:[sftStart]
nextBlock:
	;
	; See if hit the last block (ptr is -1)
	;
		cmp	di, NIL
		je	doExtend
	;
	; Fetch number of entries in the block and advance di to the
	; first of them.
	;
		mov	cx, es:[di].SFTBH_numEntries
		push	di
		add	di, size SFTBlockHeader
nextEntry:
	;
	; A reference count of 0 means the entry is unused. We just
	; fetch the thing into ax before advancing to the next entry to
	; make the loop as nice as possible.
	;
if size SFTE_refCount eq word
		mov	ax, es:[di].SFTE_refCount
 if _MS3
		add	di, ds:[sftEntrySize]
 else
		add	di, size SFTEntry
 endif
		tst	ax
else	; _MS2
		mov	al, es:[di].SFTE_refCount
		add	di, size SFTEntry
		tst	al
endif
		loopne	nextEntry
	;
	; Point es:di at next block in case we went through the entire
	; block.
	;
		pop	di
		les	di, es:[di].SFTBH_next
		jne	nextBlock	; If didn't stop b/c of an unused slot,
					;  check the next block
		stc			; Signal error -- DO NOT TRY TO EXTEND
		jmp	done
doExtend:	
		les	di, ds:[sftEnd]		;point es:di at last SFT block
	;
	; allocate a block for new SFT entries and make it owned by us.
	; 
		mov	bx, handle 0
		mov	ax, SFT_EXTEND_NUM_ENTRIES * size SFTEntry + \
				size SFTBlockHeader
if _MS3
		tst	ds:[isPC3_0]
		jz	doAlloc
		mov	ax, SFT3_EXTEND_NUM_ENTRIES * size SFT30Entry + \
				size SFTBlockHeader
doAlloc:
endif	; _MS3
		mov	cx, ALLOC_FIXED or (mask HAF_ZERO_INIT shl 8)
		call	MemAllocSetOwner
		jc	done

	;
	; Point former tail block at the new block.
	; 
		mov	es:[di].SFTBH_next.offset, 0
		mov	es:[di].SFTBH_next.segment, ax

	;
	; Record new block as tail
	;
		mov	ds:[sftEnd].offset, 0
		mov	ds:[sftEnd].segment, ax

	;
	; Initialize new block header (rest of block initialized to zero
	; by MemAlloc)
	;
		mov	es, ax
		clr	di

		mov	es:[di].SFTBH_next.offset, NIL
		mov	es:[di].SFTBH_numEntries, SFT_EXTEND_NUM_ENTRIES

		; carry cleared by 'clr di'
done:
		.leave
		ret
MSExtendSFT	endp

;PathOps	ends
Resident	ends

