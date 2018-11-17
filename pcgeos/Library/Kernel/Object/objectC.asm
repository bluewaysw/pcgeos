COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Object
FILE:		objectC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the object routines

	$Id: objectC.asm,v 1.1 97/04/05 01:14:46 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjFreeObjBlock

C DECLARATION:	extern void
			_far _pascal ObjFreeObjBlock(MemHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJFREEOBJBLOCK	proc	far
	C_GetOneWordArg	bx,  cx, ax	;bx = block

	call	ObjFreeObjBlock
	ret

OBJFREEOBJBLOCK	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjInstantiate

C DECLARATION:	extern optr
			_far _pascal ObjInstantiate(MemHandle block,
						ClassStruct _far *class);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJINSTANTIATE	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = block, cx:dx = class

	push	si, di
	mov	es, cx
	mov	di, dx
	call	ObjInstantiate
	mov_tr	ax, si
	mov	dx, bx
	pop	si, di
	ret

OBJINSTANTIATE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjInstantiateForThread

C DECLARATION:	extern optr
			_far _pascal ObjInstantiateForThread(
						ThreadHandle thread,
						ClassStruct _far *class);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	2/2/96		Initial version

------------------------------------------------------------------------------@
OBJINSTANTIATEFORTHREAD	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = thread, cx:dx = class

	push	si, di
	mov	es, cx
	mov	di, dx
	call	ObjInstantiateForThread
	mov_tr	ax, si
	mov	dx, bx
	pop	si, di
	ret

OBJINSTANTIATEFORTHREAD	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	CObjSendToChildren

C DECLARATION:	extern word
			_far _pascal CObjSendToChildren(MemHandle mh,
					ChunkHandle chunk,
				    EventHandle message, word masterOffset,
				    word compOffset, word linkOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
COBJSENDTOCHILDREN	proc	far	mhan:hptr, chk:word, event:word,
					masterOffset:word,
					compOffset:word, linkOffset:word
				uses si, di, ds
	.enter

	clr	ax
	push	ax				;child to start at (first child)
	push	ax
	push	linkOffset
	push	cs				;callback
	mov	ax, offset OSTC_callback
	push	ax

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk				;*ds:si = object

	mov	bx, masterOffset
	mov	di, compOffset

	mov	cx, event
	call	ObjCompProcessChildren

	mov	bx, cx
	call	ObjFreeMessage

	.leave
	ret

COBJSENDTOCHILDREN	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	OSTC_callback

DESCRIPTION:	Callback routine for COBJSENDTOCHILDREN

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	cx - event to send

RETURN:
	cx - same

DESTROYED:
	ax, bx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 5/91		Initial version

------------------------------------------------------------------------------@
OSTC_callback	proc	far	uses cx
	.enter

	mov	bx, cx				;bx = message
	mov	cx, ds:[LMBH_handle]		;cx:si = destination
	call	MessageSetDestination
	mov	di, mask MF_RECORD		;don't free the event
	call	MessageDispatch
	clc					;don't stop enumerating
	.leave
	ret

OSTC_callback	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjFreeMessage

C DECLARATION:	extern void
			_far _pascal ObjFreeMessage(EventHandle event);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJFREEMESSAGE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	GOTO	ObjFreeMessage

OBJFREEMESSAGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjGetMessageInfo

C DECLARATION:	extern Method
			_far _pascal ObjGetMessageInfo(EventHandle event,
							optr _far *dest);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJGETMESSAGEINFO	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = event, cx:dx = dest

	push	si, di, ds
	mov	ds, cx
	mov	di, dx
	call	ObjGetMessageInfo
	mov	ds:[di].handle, cx
	mov	ds:[di].chunk, si
	pop	si, di, ds
	ret

OBJGETMESSAGEINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjGetMessageData
			Returns FALSE if register data

C DECLARATION:	extern Boolean
		_far _pascal ObjGetMessageData(EventHandle event,
						MessageDataStruct _far *data);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ChrisT	3/31/95		Initial version

------------------------------------------------------------------------------@
OBJGETMESSAGEDATA	proc	far

	C_GetThreeWordArgs	bx, cx, dx, ax  ; bx = event, cx:dx = data

	push	ds, si, bp
	movdw	dssi, cxdx
	call	ObjGetMessageData
	mov	ax, 0
	sbb	ax, 0		; ax = (carry ? TRUE, FALSE)
	mov	ds:[si].MDS_cx, cx
	mov	ds:[si].MDS_dx, dx
	mov	ds:[si].MDS_bp, bp
	pop	ds, si, bp
	ret

OBJGETMESSAGEDATA	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	MessageSetDestination

C DECLARATION:	extern void
			_far _pascal MessageSetDestination(EventHandle event,
						    optr dest);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Doug	8/92		Removed ability to change message

------------------------------------------------------------------------------@
MESSAGESETDESTINATION	proc	far	event:word, dest:optr
			uses si
	.enter

	mov	bx, event
	mov	cx, dest.handle
	mov	si, dest.chunk
	call	MessageSetDestination

	.leave
	ret

MESSAGESETDESTINATION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDuplicateResource

C DECLARATION:	extern MemHandle
			_far _pascal ObjDuplicateResource(MemHandle blockToDup,
						GeodeHandle owner,
						ThreadHandle burdenThread);
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJDUPLICATERESOURCE	proc	far	blockToDup:hptr, owner:hptr,
					burdenThread:hptr
	.enter

	mov	bx, blockToDup
	mov	ax, owner
	mov	cx, burdenThread
	call	ObjDuplicateResource
	mov_trash	ax, bx

	.leave
	ret

OBJDUPLICATERESOURCE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjFreeDuplicate

C DECLARATION:	extern void
			_far _pascal ObjFreeDuplicate(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJFREEDUPLICATE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	call	ObjFreeDuplicate
	ret

OBJFREEDUPLICATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjFreeChunk

C DECLARATION:	extern void
			_far _pascal ObjFreeChunk(MemHandle mh,
								word chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJFREECHUNK	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = handle, ax = chunk

	push	ds
	call	MemDerefDS
	call	ObjFreeChunk
	pop	ds
	ret

OBJFREECHUNK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjGetFlags

C DECLARATION:	extern word
			_far _pascal ObjGetFlags(MemHandle mh,
								word chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJGETFLAGS	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = handle, ax = chunk

	push	ds
	call	MemDerefDS
	call	ObjGetFlags
	pop	ds
	ret

OBJGETFLAGS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjSetFlags

C DECLARATION:	extern word
			_far _pascal ObjSetFlags(MemHandle mh, word chunk,
					    word bitsToSet, word bitsToClear);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJSETFLAGS	proc	far	mhan:hptr, chk:word, bitsToSet:word,
					bitsToClear:word
				uses ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	ax, chk
	mov	bl, bitsToSet.low
	mov	bh, bitsToClear.low
	call	ObjSetFlags

	.leave
	ret

OBJSETFLAGS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjMarkDirty

C DECLARATION:	extern word
			_far _pascal ObjMarkDirty(MemHandle mh, word chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJMARKDIRTY	proc	far	mhan:hptr, chk:word
				uses ds, si
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	call	ObjMarkDirty

	.leave
	ret

OBJMARKDIRTY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjIsObjectInClass

C DECLARATION:	extern Boolean
		    _far _pascal ObjIsObjectInClass(MemHandle mh,
					word chunk, ClassStruct _far *class);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJISOBJECTINCLASS	proc	far	mhan:sptr, chk:word, oclass:fptr
				uses si, di, ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	les	di, oclass
	clr	ax				; assume false
	call	ObjIsObjectInClass
	jnc	done				; yes, 0 = false
	dec	ax				; else, 0xffff = true
done:

	.leave
	ret

OBJISOBJECTINCLASS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjIsClassADescendant

C DECLARATION:	extern Boolean
		    ObjIsClassADescendant(ClassStruct *class1,
							ClassStruct *class2);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJISCLASSADESCENDANT	proc	far	class1:fptr, class2:fptr
				uses si, di, ds
	.enter

	les	di, class1
	lds	si, class2
	clr	ax				; assume false
	call	ObjIsClassADescendant
	jnc	done				; yes, 0 = false
	dec	ax				; else, 0xffff = true
done:

	.leave
	ret

OBJISCLASSADESCENDANT	endp

C_Common	ends

;---

C_System	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjIncInUseCount

C DECLARATION:	extern void
			_far _pascal ObjIncInUseCount(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJINCINUSECOUNT	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	push	ds
	call	MemDerefDS
EC <	push	si						>
EC <	clr	si						>
	call	ObjIncInUseCount
EC <	pop	si						>
	pop	ds
	ret

OBJINCINUSECOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDecInUseCount

C DECLARATION:	extern void
			_far _pascal ObjDecInUseCount(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJDECINUSECOUNT	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	push	ds
	call	MemDerefDS
EC <	push	si						>
EC <	clr	si						>
	call	ObjDecInUseCount
EC <	pop	si						>
	pop	ds
	ret

OBJDECINUSECOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjIncInteractibleCount

C DECLARATION:	extern void
			_far _pascal ObjIncInteractibleCount(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJINCINTERACTIBLECOUNT	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	push	ds
	call	MemDerefDS
EC <	push	si						>
EC <	clr	si						>
	call	ObjIncInteractibleCount
EC <	pop	si						>
	pop	ds
	ret

OBJINCINTERACTIBLECOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDecInteractibleCount

C DECLARATION:	extern void
			_far _pascal ObjDecInteractibleCount(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJDECINTERACTIBLECOUNT	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	push	ds
	call	MemDerefDS
EC <	push	si						>
EC <	clr	si						>
	call	ObjDecInteractibleCount
EC <	pop	si						>
	pop	ds
	ret

OBJDECINTERACTIBLECOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDoRelocation

C DECLARATION:	extern Boolean		/* TRUE if error */
		    _far _pascal ObjDoRelocation(ObjRelocationType type,
							MemHandle block,
							void _far *sourceData,
							void _far *destData);
			Note:The fptrs *cannot* be pointing to the XIP movable 
				code resource.
		
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJDORELOCATION	proc	far	otype:word, block:hptr, sourceData:fptr,
				destData:fptr
						uses si, ds
	clc
CRelocCommon	label	far
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, sourceData				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, destData					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	ax, otype
	mov	bx, block
	lds	si, sourceData
	mov	cx, ds:[si].offset
	mov	dx, ds:[si].segment
	jc	unreloc
	call	ObjDoRelocation
	jmp	common
unreloc:
	call	ObjDoUnRelocation
common:
	lds	si, destData
	mov	bx, 0				;bx = ret value
	jnc	noError
	dec	bx
noError:
	mov	ds:[si].offset, cx
	cmp	al, RELOC_ENTRY_POINT
	jnz	done
	mov	ds:[si].segment, dx
done:
	mov_trash	ax, bx

	.leave
	ret

OBJDORELOCATION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjDoUnRelocation

C DECLARATION:	extern Boolean		/* TRUE if error */
		    _far _pascal ObjDoUnRelocation(ObjRelocationType type,
							MemHandle block,
							void _far *sourceData,
							void _far *destData);
			Note:The fptrs *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJDOUNRELOCATION	proc	far
	stc
	jmp	CRelocCommon

OBJDOUNRELOCATION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjResizeMaster

C DECLARATION:	extern void
		    _far _pascal ObjResizeMaster(MemHandle mh,
							word chunk,
					    		word masterOffset,
							word newSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJRESIZEMASTER	proc	far	mh:hptr, chk:word, masterOffset:word,
					newSize:word
				uses si, ds
	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chk
	mov	ax, newSize
	mov	bx, masterOffset
	call	ObjResizeMaster

	.leave
	ret

OBJRESIZEMASTER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjInitializeMaster

C DECLARATION:	extern void
		    _far _pascal ObjInitializeMaster(MemHandle mh,
						    word chunk,
						    ClassStruct _far *class);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJINITIALIZEMASTER	proc	far	mh:hptr, chk:word, oclass:fptr
				uses si, di, ds
	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chk
	les	di, oclass
	call	ObjInitializeMaster

	.leave
	ret

OBJINITIALIZEMASTER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjInitializePart

C DECLARATION:	extern void
		    _far _pascal ObjInitializePart(MemHandle mh,
							word chunk,
					    		word masterOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJINITIALIZEPART	proc	far	mh:hptr, chk:word, masterOffset:word
				uses si, ds
	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chk
	mov	bx, masterOffset
	call	ObjInitializePart

	.leave
	ret

OBJINITIALIZEPART	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjTestIfObjBlockRunByCurThread

C DECLARATION:	extern Boolean
			_far _pascal ObjTestIfObjBlockRunByCurThread(
								MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJTESTIFOBJBLOCKRUNBYCURTHREAD	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	clr	ax
	call	ObjTestIfObjBlockRunByCurThread
	jnz	done
	dec	ax
done:
	ret

OBJTESTIFOBJBLOCKRUNBYCURTHREAD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjSaveBlock

C DECLARATION:	extern void
			_far _pascal ObjSaveBlock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJSAVEBLOCK	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = block

	call	ObjSaveBlock
	ret

OBJSAVEBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjMapSavedToState

C DECLARATION:	extern VMBlockHandle
			_far _pascal ObjMapSavedToState(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJMAPSAVEDTOSTATE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	ObjMapSavedToState
	jnc	done
	clr	ax
done:
	ret

OBJMAPSAVEDTOSTATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjMapStateToSaved

C DECLARATION:	extern MemHandle
			_far _pascal ObjMapStateToSaved(VMBlockHandle vmbh,
							GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJMAPSTATETOSAVED	proc	far
	C_GetTwoWordArgs	ax, bx,   cx,dx	;ax = vmbh, bx = geode

	call	ObjMapStateToSaved
	mov_trash	ax, bx
	jnc	done
	clr	ax
done:
	ret

OBJMAPSTATETOSAVED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjInitDetach

C DECLARATION:	extern void
		    _far _pascal ObjInitDetach(MetaMessage msg,
		    			MemHandle mh, word chunk,
					word callerID, MemHandle ackODHan,
					ChunkHandle ackODCh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJINITDETACH	proc	far	msg:word, obj:optr, callerID:word, ackOD:optr
				uses si, ds
	.enter

	mov	bx, obj.handle
	call	MemDerefDS
	mov	si, obj.chunk
	mov	cx, callerID
	mov	dx, ackOD.handle
	mov	ax, msg
	mov	bp, ackOD.chunk		; (no local vars, so can trash bp)
	call	ObjInitDetach

	.leave
	ret

OBJINITDETACH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjIncDetach

C DECLARATION:	extern void
			_far _pascal ObjIncDetach(MemHandle mh,
								word chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJINCDETACH	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = handle, ax = chunk

	push	ds
	call	MemDerefDS
	xchg	ax, si
	call	ObjIncDetach
	xchg	ax, si
	pop	ds
	ret

OBJINCDETACH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjEnableDetach

C DECLARATION:	extern void
			_far _pascal ObjEnableDetach(MemHandle mh,
								word chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJENABLEDETACH	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = handle, ax = chunk

	push	ds
	call	MemDerefDS
	xchg	ax, si
	call	ObjEnableDetach
	xchg	ax, si
	pop	ds
	ret

OBJENABLEDETACH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjLinkFindParent

C DECLARATION:	extern optr
			_far _pascal ObjLinkFindParent(MemHandle mh,
					word chunk, word masterOffset,
					word linkOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJLINKFINDPARENT	proc	far	mhan:hptr, chk:word, masterOffset:word,
					linkOffset:word
				uses si, di, ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	mov	bx, masterOffset
	mov	di, linkOffset
	call	ObjLinkFindParent
	mov	dx, bx
	mov_trash	ax, si

	.leave
	ret

OBJLINKFINDPARENT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjCompFindChildByOptr

C DECLARATION:	extern word
			_far _pascal ObjCompFindChildByOptr(MemHandle mh,
					word chunk, MemHandle childToFindHan,
					ChunkHandle childToFindCh,
					word masterOffset, word compOffset,
					word linkOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJCOMPFINDCHILDBYOPTR	proc	far	mhan:hptr, chk:word,
					childToFindHan:hptr,
					childToFindCh:word,
					masterOffset:word, compOffset:word,
					linkOffset:word
				uses si, di, ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	mov	cx, childToFindHan
	mov	dx, childToFindCh
	mov	ax, linkOffset
	mov	bx, masterOffset
	mov	di, compOffset
	push	bp
	call	ObjCompFindChild
	mov_trash	ax, bp
	pop	bp
	jnc	done
	mov	ax, -1
done:

	.leave
	ret

OBJCOMPFINDCHILDBYOPTR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjCompFindChildByNumber

C DECLARATION:	extern optr
			_far _pascal ObjCompFindChildByNumber(MemHandle mh,
					word chunk, word childToFind,
					word masterOffset, word compOffset,
					word linkOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJCOMPFINDCHILDBYNUMBER	proc	far	mhan:sptr, chk:word,
					childToFind:word,
					masterOffset:word, compOffset:word,
					linkOffset:word
				uses si, di, ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	clr	cx
	mov	dx, childToFind
	mov	ax, linkOffset
	mov	bx, masterOffset
	mov	di, compOffset
	push	bp
	call	ObjCompFindChild
	pop	bp
	mov_trash	ax, dx
	mov	dx, cx
	jnc	done
	clr	ax
	clr	dx
done:

	.leave
	ret

OBJCOMPFINDCHILDBYNUMBER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjCompAddChild

C DECLARATION:	extern optr
			_far _pascal ObjCompAddChild(MemHandle mh,
					word chunk, MemHandle objToAddHan,
					ChunkHandle objToAddCh, word flags,
					word masterOffset, word compOffset,
					word linkOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJCOMPADDCHILD	proc	far	mhan:sptr, chk:word,
					objToAddHan:hptr, objToAddCh:word,
					oflags:word, masterOffset:word,
					compOffset:word, linkOffset:word
				uses si, di, ds
	stc
CAddRemoveCommon	label	far
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	mov	cx, objToAddHan
	mov	dx, objToAddCh
	mov	ax, linkOffset
	mov	bx, masterOffset
	mov	di, compOffset
	push	bp
	mov	bp, oflags
	jnc	removeOrMove
	call	ObjCompAddChild
	jmp	common
removeOrMove:
	jz	move
	call	ObjCompRemoveChild
	jmp	common
move:
	call	ObjCompMoveChild
common:
	pop	bp

	.leave
	ret

OBJCOMPADDCHILD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjCompRemoveChild

C DECLARATION:	extern optr
			_far _pascal ObjCompRemoveChild(MemHandle mh,
					word chunk, MemHandle objToRemoveHan,
					ChunkHandle objToRemoveCh, word flags,
					word masterOffset, word compOffset,
					word linkOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJCOMPREMOVECHILD	proc	far
	or	ax, 1			;clear carry, clear zero
	jmp	CAddRemoveCommon

OBJCOMPREMOVECHILD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjCompMoveChild

C DECLARATION:	extern optr
			_far _pascal ObjCompMoveChild(MemHandle mh,
					word chunk, MemHandle objToMoveHan,
					ChunkHandle objToMoveCh, word flags,
					word masterOffset, word compOffset,
					word linkOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJCOMPMOVECHILD	proc	far
	and	ax, 0			;clear carry, set zero
	jmp	CAddRemoveCommon

OBJCOMPMOVECHILD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjCompProcessChildren

C DECLARATION:	extern optr
			_far _pascal ObjCompProcessChildren(MemHandle mh,
				ChunkHandle chunk, MemHandle firstHan,
				ChunkHandle firstCh,
				void _far *cbData, word masterOffset,
				word compOffset, word linkOffset,
				Boolean _far (*callback)
				    (MemHandle parentHan, ChunkHandle parentCh,
				     MemHandle childHan, ChunkHandle childCh,
				     void _far *cbData));
			Note: The callback *must* be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
OBJCOMPPROCESSCHILDREN	proc	far	mh:hptr, chk:word,
						firstHan:hptr, firstCh:word,
						stdCallback:word,
						cbData:fptr, masterOffset:word,
						compOffset:word,
						linkOffset:word,
						callback:fptr.far
				uses si, di, ds
	ForceRef	callback
	ForceRef	cbData
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, callback					>
EC <	tst	bx						>
EC <	jz	xipSafe						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	xipSafe:						>
EC <	popdw	bxsi						>
endif

	push	firstHan
	push	firstCh
	push	linkOffset
	mov	cx, SEGMENT_CS
	mov	ax, offset _OCPC_callback
	tst	callback.segment
	jnz	haveCallback
	mov	cx, stdCallback
haveCallback:
	pushdw	cxax

	mov	cx, ds				;cx = DS to pass

	mov	bx, mh
	call	MemDerefDS
	mov	si, chk
	mov	bx, masterOffset
	mov	di, compOffset
	call	ObjCompProcessChildren

	mov	ax, 0			; assume not aborted
	jnc	done
	dec	ax
done:

	.leave
	ret

OBJCOMPPROCESSCHILDREN	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_OCPC_callback

DESCRIPTION:	Callback routine for OBJCOMPPROCESSCHILDREN.  Call the
		real callback after pushing args on the stack

CALLED BY:	ObjCompProcessChildren

PASS:
	*ds:si - child
	*es:di - parent
	cx - DS to pass to callback
	ss:bp - inherited variables

RETURN:
	carry - set to end processing

DESTROYED:
	bx, si, di, es, ds all allowed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
				Boolean _far (*callback)
				    (MemHandle parentHan, ChunkHandle parentCh,
				     MemHandle childHan, ChunkHandle childCh,
				     void _far *cbData));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

_OCPC_callback		proc	far	mh:hptr, chk:word,
						firstHan:hptr, firstCh:word,
						stdCallback:word,
						cbData:fptr, masterOffset:word,
						compOffset:word,
						linkOffset:word,
						callback:fptr.far
				uses cx
	ForceRef	mh
	ForceRef	chk
	ForceRef	firstHan
	ForceRef	firstCh
	ForceRef	masterOffset
	ForceRef	compOffset
	ForceRef	linkOffset
	.enter inherit far

	push	es:[LMBH_handle]	;parentHan
	push	di			;parentCh
	push	ds:[LMBH_handle]	;childHan
	push	si			;childOff
	push	cbData.segment
	push	cbData.offset

	mov	ax, callback.offset
	mov	bx, callback.segment
	mov	ds, cx			; ds <- passed DS
	call	ProcCallFixedOrMovable

	; set carry of ax is non-zero

	tst_clc	ax
	jz	done
	stc
done:

	.leave
	ret

_OCPC_callback	endp

C_System	ends

;---

C_VarData	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjVarAddData

C DECLARATION:	extern void fptr *
			_far _pascal ObjVarAddDataType(MemHandle mh,
				ChunkHandle chnk,
				word dataType, word dataSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version
	doug	11/91		Modified to match merge of two "Add" functions

------------------------------------------------------------------------------@
OBJVARADDDATA	proc	far	mh:word, chnk:word,
					dataType:word, dataSize:word

	uses	ds, si

	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chnk		; *ds:si = object
	mov	ax, dataType
	mov	cx, dataSize
	call	ObjVarAddData
	mov	dx, ds			; dx:ax = ptr to extra data
	mov	ax, bx

	.leave

	ret
OBJVARADDDATA	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjVarDeleteData

C DECLARATION:	extern Boolean
			_far _pascal ObjVarDeleteData(MemHandle mh,
				ChunkHandle chnk,
				word dataType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

------------------------------------------------------------------------------@
OBJVARDELETEDATA	proc	far	mh:word, chnk:word,
					dataType:word

	uses	ds, si

	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chnk		; *ds:si = object
	mov	ax, dataType
	call	ObjVarDeleteData
	mov	ax, 0			; assume not deleted, FALSE
	jc	done			; not found, FALSE
	dec	ax			; else found and deleted, TRUE
done:

	.leave

	ret
OBJVARDELETEDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjVarDeleteDataAt

C DECLARATION:	extern void
			_far _pascal ObjVarDeleteDataAt(MemHandle mh,
				ChunkHandle chnk,
				word extraDataOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

------------------------------------------------------------------------------@
OBJVARDELETEDATAAT	proc	far	mh:word, chnk:word,
					extraDataOffset:word

	uses	ds, si

	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chnk		; *ds:si = object
	mov	bx, extraDataOffset
	call	ObjVarDeleteDataAt

	.leave

	ret
OBJVARDELETEDATAAT	endp

;
; C stub for ObjVarScanData is in Object/objectVarData.asm
;

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjVarFindData

C DECLARATION:	extern void fptr *
			_far _pascal ObjVarFindData(MemHandle mh,
				ChunkHandle chnk,
				word dataType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

------------------------------------------------------------------------------@
OBJVARFINDDATA	proc	far	mh:word, chnk:word,
				dataType:word

	uses	ds, si

	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chnk		; *ds:si = object
	mov	ax, dataType
	call	ObjVarFindData
	mov	dx, 0			; clr fptr in case not found
	mov	ax, dx
	jnc	done			; not found, done
	mov	dx, ds			; dx:ax = ptr to extra data
	mov	ax, bx
done:

	.leave

	ret
OBJVARFINDDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjVarDerefData

C DECLARATION:	extern void fptr *
			_far _pascal ObjVarDerefData(MemHandle mh,
				ChunkHandle chnk,
				word dataType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

------------------------------------------------------------------------------@
OBJVARDEREFDATA	proc	far	mh:word, chnk:word,
				dataType:word

	uses	ds, si

	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chnk		; *ds:si = object
	mov	ax, dataType
	call	ObjVarDerefData
	mov	dx, ds			; dx:ax = ptr to extra data
	mov	ax, bx

	.leave

	ret
OBJVARDEREFDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjVarDeleteDataRange

C DECLARATION:	extern void
			_far _pascal ObjVarDeleteDataRange(MemHandle mh,
				ChunkHandle chnk,
				word rangeStart, word rangeEnd,
				Boolean useStateFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

------------------------------------------------------------------------------@
OBJVARDELETEDATARANGE	proc	far	mh:word, chnk:word,
					rangeStart:word, rangeEnd:word,
					useStateFlag:word

	uses	ds, si

	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chnk		; *ds:si = object
	mov	cx, rangeStart
	mov	dx, rangeEnd
	push	bp
	mov	bp, useStateFlag	; 0 if FALSE, -1 (non-zero) if TRUE
	call	ObjVarDeleteDataRange
	pop	bp

	.leave

	ret
OBJVARDELETEDATARANGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjVarCopyDataRange

C DECLARATION:	extern void
			_far _pascal ObjVarCopyDataRange(MemHandle mh,
				ChunkHandle chnk,
				MemHandle destH, ChunkHandle destC,
				word rangeStart, word rangeEnd);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

------------------------------------------------------------------------------@
OBJVARCOPYDATARANGE	proc	far	mh:word, chnk:word,
					destH:word, destC:word,
					rangeStart:word, rangeEnd:word

	uses	ds, si

	.enter

	mov	bx, destH
	call	MemDerefES
	mov	bx, mh
	call	MemDerefDS
	mov	si, chnk		; *ds:si = object
	mov	cx, rangeStart
	mov	dx, rangeEnd
	push	bp
	mov	bp, destC		; *es:bp = dest. object
	call	ObjVarCopyDataRange
	pop	bp

	.leave

	ret
OBJVARCOPYDATARANGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjVarScanData

C DECLARATION:	extern void
			_far _pascal ObjVarScanData(MemHandle mh,
				ChunkHandle chnk,
				word numHandlers,
				VarDataCHandler _far *handlerTable,
				void _far *handlerData);
		
		HANDLER ROUTINE:
			extern void
				_far _pascal FooBar(MemHandle mh,
					ChunkHandle chnk,
					void _far *extraData,
					word dataType,
					void _far *handlerData);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

------------------------------------------------------------------------------@
OBJVARSCANDATA	proc	far	mh:word, chnk:word, numHandlers:word,
				handlerTable:fptr.VarDataCHandler,
				handlerData:fptr

	uses	ds, si, di
	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	si, chnk			; *ds:si = object

	push	bp				; save stack frame
	call	GetAndCheckVarDataStartEnd	; bx = start, bp = end, Z if =
	mov	dx, bp				; dx = end of variable data

	; Convert end ptr to relative offset, & keep that way until those
	; points where we need the absolute ptr.  This will keep the value
	; valid across calls to data handlers, which may legally add or remove
	; chunks in the block (though not add or remove var data elements)
	;
	pushf
	sub	dx, ds:[si]			; convert to relative offset
	popf
	pop	bp				; restore stack frame
	LONG je	done				; no variable data, done
	;
	; loop through variable data entries of this object
	;	*ds:si = object
	;	ds:bx = data entry in variable data area
	;	*handlerData = data for handlers
	;	dx = relative offset to end of variable data
	;
varDataLoop:
	mov	es, handlerTable.segment	; es:di = handler table
	mov	di, handlerTable.offset
	mov	cx, numHandlers			; cx = number of handlers
EC <	tst	cx							>
EC <	ERROR_Z	OVS_BAD_HANDLER_TABLE					>
	mov	ax, ds:[bx].VDE_dataType	; ax = data type
	andnf	ax, not mask VarDataFlags	; clear flags
	;
	; search for a handler for this data type in the handler table
	;	ax = data type (with VarDataFlags cleared)
	;	cx = number of remaining entries in handler table
	;	ds:bx = data entry
	;	on stack: (table offset)
	;
searchTableLoop:
	push	bx				; save data entry offset
	mov	bx, es:[di].VDCH_dataType
	andnf	bx, not mask VarDataFlags	; ignore flags
	cmp	ax, bx				; is this a handler?
	pop	bx				; retreive data entry offset
	je	foundHandler			; yes, process it
	add	di, size VarDataCHandler	; else, move to next one
	loop	searchTableLoop
nextVarData:
	push	bp				; save stack frame
	mov	bp, dx				; bp = end of variable data
	add	bp, ds:[si]			; convert to absolute ptr
	call	GetNextVarDataEntry		; ds:bx = next entry, Z if end
	pop	bp				; restore stack frame
	jne	varDataLoop			; more variable data,
						;	go back for more
	jmp	done				; else, done
	;
	; found handler for this data entry, call handler
	;	*ds:si = object
	;	ds:bx = data entry
	;	es:di = VarDataCHandler
	;
foundHandler:

EC <	push	ds:[bx].VDE_dataType		; make sure type unchanged >

	push	dx				; save relative offset to end

	mov	ax, bx				; ds:bx is ptr to data entry
	sub	ax, ds:[si]			; convert to relative offset
	push	ax				; from start of chunk & save

	;
	; push parameters for and call C data handler
	;	extern void
	;		_far _pascal FooBar(MemHandle mh,
	;					ChunkHandle chnk,
	;					void _far *extraData
	;					word dataType,
	;					void _far *handlerData);
	;
				; MemHandle mh
	push	mh
				; ChunkHandle chnk
	push	chnk
				; void _far *extraData
	push	ds				; data entry
				; word dataType
	mov	ax, ds:[bx].VDE_dataType	; data type
	add	bx, size VarDataEntry		; pass ptr to extra data
	push	bx
	andnf	ax, not mask VarDataFlags	; (clear flags for handler)
	push	ax
				; void _far *handlerData
	push	handlerData.segment
	push	handlerData.offset
	mov	ax, es:[di].VDCH_handler.offset
	mov	bx, es:[di].VDCH_handler.segment
	call	ProcCallFixedOrMovable		; call C handler
						;	trashes: ax, bx, cx, dx
	mov	bx, mh
	call	MemDerefDS			; in case object block moved

	pop	bx				; restore relative offset
	add	bx, ds:[si]			; convert to actual offset

	pop	dx				; restore relative offset to end

EC <	push	bx, dx, bp						>
EC <	call	GetAndCheckVarDataStartEnd				>
EC <	add	dx, ds:[si]			; convert to ptr	>
EC <	cmp	dx, bp				; make sure unchanged	>
EC <	ERROR_NE	OVS_VAR_DATA_HANDLER_ADDED_OR_REMOVED_DATA_ENTRY    >
EC <	pop	bx, dx, bp						>

EC <	pop	ax							>
EC <	cmp	ax, ds:[bx].VDE_dataType	; make sure unchanged	>
EC <	ERROR_NE	OVS_VAR_DATA_HANDLER_CHANGED_DATA_ENTRY		>
	jmp	short nextVarData		; do next var data entry

done:

	.leave

	ret
OBJVARSCANDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjBlockSetOutput

C DECLARATION:	extern void
			_far _pascal ObjBlockSetOutput(MemHandle mh,
						MemHandle outputh
						word outputc);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version

------------------------------------------------------------------------------@
OBJBLOCKSETOUTPUT	proc	far	mh:word,
					outputh:word, outputc:word

	uses	si, ds
	.enter
	mov	bx, mh
	call	MemDerefDS
	mov	bx, outputh
	mov	si, outputc
	call	ObjBlockSetOutput
	.leave
	ret

OBJBLOCKSETOUTPUT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ObjBlockGetOutput

C DECLARATION:	extern optr
			_far _pascal ObjBlockGetOutput(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version

------------------------------------------------------------------------------@
OBJBLOCKGETOUTPUT	proc	far	mh:word

	uses	si, ds
	.enter
	mov	bx, mh
	call	MemDerefDS
	call	ObjBlockGetOutput
	mov	dx, bx
	mov_trash	ax, si
	.leave
	ret

OBJBLOCKGETOUTPUT	endp

C_VarData	ends

	 SetDefaultConvention
