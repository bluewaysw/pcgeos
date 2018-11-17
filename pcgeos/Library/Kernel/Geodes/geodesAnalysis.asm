COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeAnalysis.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/92		Initial version

DESCRIPTION:
	This file contains code to analyze PC/GEOS

	$Id: geodesAnalysis.asm,v 1.1 97/04/05 01:11:55 newdeal Exp $

-------------------------------------------------------------------------------@

ife	ANALYZE_WORKING_SET
MAX_WS_RESOURCES	equ	0
endif

;---

if	ANALYZE_WORKING_SET

DEFAULT_WS_TIME	=	60*5

idata segment

WSFlags	record
    WSF_CODE:1
    WSF_OBJECT:1
WSFlags end

wsFlags		WSFlags		(mask WSF_CODE)

wsGeode		hptr		;handle of geode we're analyzing

wsSize		word		;working set size
maxWSSize	word
wsTotalSize	word
wsTotalCode	word
wsResCount	word
wsCodeCount	word

workingSetTime	word	DEFAULT_WS_TIME	;working set definition in seconds

curLocked	word
; The current # resources locked

curSizeLocked	word	;In paragraps

maxLocked	word
; The max # resources locked

maxSizeLocked	word	;In paragraphs

maxResourceSize	word	;In paragraphs

MAX_WS_RESOURCES	equ	500

WSResourceFlags	record
    WSRF_IN_USE:1
    WSRF_IN_WORKING_SET:1
    WSRF_IN_MAX_WORKING_SET:1
WSResourceFlags	end

WSResourceEntry	struct
    WSRE_handle		hptr
    WSRE_uses		word
    WSRE_loads		word
    WSRE_loadsInWS	word
    WSRE_lastUse	word
    WSRE_inUseStart	word
    WSRE_totalInUse	word
    WSRE_totalInWS	word
    WSRE_flags		WSResourceFlags
WSResourceEntry	ends

wsResourceList	WSResourceEntry	MAX_WS_RESOURCES dup (<>)

idata ends


COMMENT @----------------------------------------------------------------------

FUNCTION:	WorkingSetResourceInUse

DESCRIPTION:	Note that a resource is in use

CALLED BY:	INTERNAL

PASS:
	ds - kdata
	bx - resource handle

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
	Tony	4/14/92		Initial version

------------------------------------------------------------------------------@
WorkingSetResourceInUse	proc	near
	push	ax
	mov	al, mask WSF_CODE
	call	InUseCommon
	pop	ax
	ret

WorkingSetResourceInUse	endp

;---

WorkingSetObjBlockInUse	proc	near
	push	ax
	mov	al, mask WSF_OBJECT
	call	InUseCommon
	pop	ax
	ret

WorkingSetObjBlockInUse	endp

;---

InUseCommon	proc	near	uses si
	.enter

	pushf
	mov	si, ds							
	cmp	si, segment idata
	ERROR_NZ	-1


	test	al, ds:wsFlags
	LONG jz	done

	cmp	ds:[bx].HM_lockCount, 1
	jnz	noXIPCheck

        inc     ds:[curLocked]
	mov	ax, ds:[curLocked]
        cmp     ax, 0f000h                      ; Ignore while underflowed
        jae     10$
	cmp	ax, ds:[maxLocked]
	jbe	10$
	mov	ds:[maxLocked], ax
10$:
	mov	ax, ds:[bx].HM_size
        cmp     ax, ds:[maxResourceSize]
	jbe	15$
	mov	ds:[maxResourceSize], ax
15$:
	add	ax, ds:[curSizeLocked]
	mov	ds:[curSizeLocked], ax
        cmp     ax, 0f000h                      ; Ignore while underflowed
        jae     20$
        cmp     ax, ds:[maxSizeLocked]
	jbe	20$
	mov	ds:[maxSizeLocked], ax
20$:

noXIPCheck:


	mov	ax, ds:wsGeode
	tst	ax
	jz	doit
	cmp	ax, ds:[bx].HM_owner
	LONG jnz done
doit:

	; find the resource

	call	FindWSResource			;ds:si = resource
	jnc	notNew
	mov	ds:[si].WSRE_handle, bx
	mov	ds:[si].WSRE_uses, 0
	mov	ds:[si].WSRE_loads, 1
	mov	ds:[si].WSRE_totalInUse, 0
	mov	ds:[si].WSRE_totalInWS, 0
	mov	ds:[si].WSRE_flags, 0
	mov	ds:[si].WSRE_loadsInWS, 0
	mov	ds:[si+(size WSResourceEntry)].WSRE_handle, 0
	mov	ax, ds:[bx].HM_size
	add	ds:wsTotalSize, ax
	inc	ds:wsResCount
	test	ds:[bx].HM_flags, mask HF_LMEM
	jnz	notCode
	add	ds:wsTotalCode, ax
	inc	ds:wsCodeCount
notCode:
notNew:

	inc	ds:[si].WSRE_uses

	cmp	ds:[bx].HM_lockCount, 1
	jnz	done

	mov	ax, ds:systemCounter.low
	mov	ds:[si].WSRE_inUseStart, ax
	test	ds:[si].WSRE_flags, mask WSRF_IN_WORKING_SET
	jnz	alreadyInWorkingSet
	mov	ax, ds:[bx].HM_size
	add	ax, ds:wsSize
	mov	ds:wsSize, ax
        cmp     ax, 0f000h                      ; Ignore while underflowed
        jae     alreadyInWorkingSet
        cmp     ax, ds:maxWSSize
	jb	alreadyInWorkingSet
	mov	ds:maxWSSize, ax

	; mark all blocks in the current working set as being in the
	; max working set

	push	si
	mov	si, offset wsResourceList
rloop:
	tst	ds:[si].WSRE_handle
	jz	loopdone
	test	ds:[si].WSRE_flags, mask WSRF_IN_WORKING_SET
	jz	next
	ornf	ds:[si].WSRE_flags, mask WSRF_IN_MAX_WORKING_SET
next:
	add	si, size WSResourceEntry
	jmp	rloop
loopdone:
	pop	si

alreadyInWorkingSet:
	ornf	ds:[si].WSRE_flags, mask WSRF_IN_USE or mask WSRF_IN_WORKING_SET

done:
	popf
	.leave
	ret

InUseCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	WorkingSetResourceNotInUse

DESCRIPTION:	Note that a resource is not in use

CALLED BY:	INTERNAL

PASS:
	ds - kdata
	bx - resource handle

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
	Tony	4/14/92		Initial version

------------------------------------------------------------------------------@
WorkingSetResourceNotInUse	proc	near
	push	ax
	mov	al, mask WSF_CODE
	call	NotInUseCommon
	pop	ax
	ret

WorkingSetResourceNotInUse	endp

;---

WorkingSetObjBlockNotInUse	proc	near
	push	ax
	mov	al, mask WSF_OBJECT
	call	NotInUseCommon
	pop	ax
	ret

WorkingSetObjBlockNotInUse	endp

;---

NotInUseCommon	proc	near	uses si
	.enter

	pushf
	mov	si, ds							
	cmp	si, segment idata
	ERROR_NZ	-1


	test	al, ds:wsFlags
	jz	done

        cmp     ds:[bx].HM_lockCount, 1
	jnz	done

;	Decrement the # locked blocks, and subtract out the size of this block

        dec     ds:[curLocked]
        mov     ax, ds:[bx].HM_size
	sub	ds:[curSizeLocked], ax

; Do not crash even if the current size of locked resources temporarily
; underflows. This happens if we have two overlapping InUse calls
; for the same resource that together bring the lock count from 0 to 2.
; In this case, we could miss the 0->1 transition and never count the resource
; as used. The two corresponding NotInUse operations may then drive the
; total count of locked resources below zero. We account for this by not
; letting underflowed totals affect our maximum values, hoping that the
; inverse error (missing an unlock) will eventually bring us back in line
; and keep us right at least "on average"... -- mgroeber 11/24/00

;        ERROR_C -1

	mov	ax, ds:wsGeode
	tst	ax
	jz	doit
	cmp	ax, ds:[bx].HM_owner
	jnz	done
doit:

	; find the resource

	call	FindWSResource			;ds:si = resource
	jc	done

	; update total in use time

	mov	ax, ds:systemCounter.low
	mov	ds:[si].WSRE_lastUse, ax
	sub	ax, ds:[si].WSRE_inUseStart
	add	ds:[si].WSRE_totalInUse, ax

	andnf	ds:[si].WSRE_flags, not mask WSRF_IN_USE

done:
	popf
	.leave
	ret

NotInUseCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	WorkingSetResourceLoaded

DESCRIPTION:	Handle a resource being loaded

CALLED BY:	INTERNAL

PASS:
	ds - kdata
	bx - resource

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
	Tony	4/14/92		Initial version

------------------------------------------------------------------------------@
WorkingSetResourceLoaded	proc	near	uses ax, si
	.enter
	pushf

	tst	ds:wsFlags
	jz	done

	mov	ax, ds:wsGeode
	tst	ax
	jz	doit
	cmp	ax, ds:[bx].HM_owner
	jnz	done
doit:

	; find the resource

	call	FindWSResource			;ds:si = resource
	jc	done

	inc	ds:[si].WSRE_loads
	test	ds:[si].WSRE_flags, mask WSRF_IN_WORKING_SET
	jz	done
	inc	ds:[si].WSRE_loadsInWS

done:
	popf
	.leave
	ret

WorkingSetResourceLoaded	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	WorkingSetTick

DESCRIPTION:	Handle a tick

CALLED BY:	INTERNAL

PASS:
	ds - kdata

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/14/92		Initial version

------------------------------------------------------------------------------@
WorkingSetTick	proc	near	uses si
	.enter

	tst	ds:wsFlags
	jz	done

	mov	si, offset wsResourceList
rloop:
	tst	ds:[si].WSRE_handle
	jz	done

	; move the resource out of the working set if needed

	test	ds:[si].WSRE_flags, mask WSRF_IN_WORKING_SET
	jz	next
	inc	ds:[si].WSRE_totalInWS		;inc time in working set

	test	ds:[si].WSRE_flags, mask WSRF_IN_USE
	jnz	next
	tst	ds:workingSetTime		;if zero then skip
	jz	next
	mov	ax, ds:systemCounter.low
	sub	ax, ds:[si].WSRE_lastUse
	cmp	ax, ds:workingSetTime
	jb	next
	andnf	ds:[si].WSRE_flags, not mask WSRF_IN_WORKING_SET
	mov	bx, ds:[si].WSRE_handle
	mov	ax, ds:[bx].HM_size
	sub	ds:wsSize, ax
next:
	add	si, size WSResourceEntry
	jmp	rloop

done:
	.leave
	ret

WorkingSetTick	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindWSResource

DESCRIPTION:	Find a resource in the working set list

CALLED BY:	INTERNAL

PASS:
	ds - kdata
	bx - resource handle

RETURN:
	ds:si - WSResourceEntry
	carry - set if this is pointing at a new entry

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/14/92		Initial version

------------------------------------------------------------------------------@
FindWSResource	proc	near
	mov	si, offset wsResourceList
findloop:
	cmp	bx, ds:[si].WSRE_handle
	jz	found
	tst	ds:[si].WSRE_handle
	jz	notFound
	add	si, size WSResourceEntry
	cmp	si, (offset wsResourceList) + (size wsResourceList)
	jb	findloop
	ERROR	-1
found:
	clc
	ret
notFound:
	stc
	ret

FindWSResource	endp

endif
