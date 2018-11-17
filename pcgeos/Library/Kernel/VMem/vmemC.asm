COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/VMem
FILE:		vmemC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the vmem routines

	$Id: vmemC.asm,v 1.1 97/04/05 01:15:48 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMAlloc

C DECLARATION:	extern VMBlockHandle
			_far _pascal VMAlloc(VMFileHandle file, word size,
								word userId);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMALLOC	proc	far
	C_GetThreeWordArgs	bx, cx, ax,  dx	;bx = file, cx = size, ax = id

	call	VMAlloc
	ret

VMALLOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMFind

C DECLARATION:	extern VMBlockHandle
			_far _pascal VMFind(VMFileHandle file,
				VMBlockHandle startBlock, word userId);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMFIND	proc	far
	C_GetThreeWordArgs	bx, cx, ax,  dx	;bx = file, cx = start, ax = id

	call	VMFind
	ret

VMFIND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMFree

C DECLARATION:	extern void
			_far _pascal VMFree(VMFileHandle file,
							VMBlockHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMFREE	proc	far
	C_GetTwoWordArgs	bx, ax,  cx,dx	;bx = file, ax = vm block

	call	VMFree
	ret

VMFREE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMModifyUserID

C DECLARATION:	extern void
			_far _pascal VMModifyUserID(VMFileHandle file,
					VMBlockHandle block, word userId);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMMODIFYUSERID	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = blk, cx = id

	call	VMModifyUserID
	ret

VMMODIFYUSERID	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMInfo

C DECLARATION:	extern Boolean
		    _far _pascal VMInfo(VMFileHandle file, VMBlockHandle block,
						VMInfoStruct _far *info);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMINFO	proc	far	file:word, block:word, info:fptr
				uses di, es
	.enter

	mov	bx, file
	mov	ax, block
	call	VMInfo

	push	di
	les	di, info
	stosw				;mh
	mov_trash	ax, cx
	stosw				;size
	pop	ax
	stosw				;userId

	mov	ax, 0			;assume false
	jc	done			;if error, return false
	dec	ax			;else return true
done:
	.leave
	ret

VMINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMGetDirtyState

C DECLARATION:	extern word
			_far _pascal VMGetDirtyState(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMGETDIRTYSTATE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	VMGetDirtyState
	ret

VMGETDIRTYSTATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMGetMapBlock

C DECLARATION:	extern VMBlockHandle
			_far _pascal VMGetMapBlock(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMGETMAPBLOCK	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	VMGetMapBlock
	ret

VMGETMAPBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMUpdate

C DECLARATION:	extern word
			_far _pascal VMUpdate(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMUPDATE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	VMUpdate
	mov	ss:[TPD_error], ax
	ret

VMUPDATE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMGetAttributes

C DECLARATION:	extern word
			_far _pascal VMGetAttributes(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMGETATTRIBUTES	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	VMGetAttributes
	clr	ah
	ret

VMGETATTRIBUTES	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMAttach

C DECLARATION:	extern VMBlockHandle
			_far _pascal VMAttach(VMFileHandle file,
					VMBlockHandle block, MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMATTACH	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = blk, cx = han

	call	VMAttach
	ret

VMATTACH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMDetach

C DECLARATION:	extern MemHandle
			_far _pascal VMDetach(VMFileHandle file,
				VMBlockHandle block, GeodeHandle owner);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMDETACH	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = blk, cx = own
	mov	dx, di
	call	VMDetach
	mov_tr	ax, dx
	xchg	ax, di				; fixup DI & return handle in AX
	ret

VMDETACH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMMemBlockToVMBlock

C DECLARATION:	extern VMBlockHandle
			_far _pascal VMMemBlockToVMBlock(MemHandle mh,
						VMFileHandle _far *file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMMEMBLOCKTOVMBLOCK	proc	far
	C_GetThreeWordArgs	bx, cx, ax,  dx	;bx = file, cx = seg, ax = off

	push	si, ds
	mov	ds, cx
	mov_trash	si, ax
	call	VMMemBlockToVMBlock
	mov	ds:[si], bx
	pop	si, ds
	ret

VMMEMBLOCKTOVMBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMVMBlockToMemBlock

C DECLARATION:	extern MemHandle
			_far _pascal VMVMBlockToMemBlock(VMFileHandle file,
							VMBlockHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMVMBLOCKTOMEMBLOCK	proc	far
	C_GetTwoWordArgs	bx, ax,  cx,dx	;bx = file, ax = vm block

	call	VMVMBlockToMemBlock
	ret

VMVMBLOCKTOMEMBLOCK	endp

C_Common	ends

;-

C_System	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMSetMapBlock

C DECLARATION:	extern void
			_far _pascal VMSetMapBlock(VMFileHandle file,
							VMBlockHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMSETMAPBLOCK	proc	far
	C_GetTwoWordArgs	bx, ax,  cx,dx	;bx = file, ax = vm block

	call	VMSetMapBlock
	ret

VMSETMAPBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMPreserveBlocksHandle

C DECLARATION:	extern void
			_far _pascal VMPreserveBlocksHandle(VMFileHandle file,
							VMBlockHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMPRESERVEBLOCKSHANDLE	proc	far
	C_GetTwoWordArgs	bx, ax,  cx,dx	;bx = file, ax = vm block

	call	VMPreserveBlocksHandle
	ret

VMPRESERVEBLOCKSHANDLE	endp



if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMOpen

C DECLARATION:	extern VMFileHandle
			_far _pascal VMOpen(const char *name, word flags,
					word mode, word compression);
			Note: "name" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMOPEN	proc	far	fname:fptr, flags:word, mode:word, compression:word
						uses ds
	.enter

	mov	al, flags.low
	mov	ah, mode.low
	mov	cx, compression
	lds	dx, fname
	call	VMOpen

	mov	ss:[TPD_error], ax
	mov_trash	ax, bx
	jnc	done
	clr	ax
done:

	.leave
	ret

VMOPEN	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMClose

C DECLARATION:	extern word
			_far _pascal VMClose(VMFileHandle file,
							Boolean noErrorFlag);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMCLOSE	proc	far
	C_GetTwoWordArgs	bx, ax   cx,dx	;bx = file, ax = no errors

	call	VMClose
	jc	haveRetval
	mov	ax, 0		; 11/2/93: return 0 on error, but don't trash 
				;  carry, as old apps may be relying on it
				;  as a (lame) workaround for the bug that
				;  used to be here.
haveRetval:
	mov	ss:[TPD_error], ax
	ret

VMCLOSE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMSetAttributes

C DECLARATION:	extern word
			_far _pascal VMSetAttributes(VMFileHandle file,
					word attrToSet, word AttrToClear);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMSETATTRIBUTES	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = set, cx = clr

	mov	ah, cl
	call	VMSetAttributes
	clr	ah
	ret

VMSETATTRIBUTES	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMGrabExclusive

C DECLARATION:	extern VMStartExclusiveReturnValue
    			_far _pascal VMGrabExclusive(VMFileHandle file,
				  word timeout,
				  word operation, word _far *currentOperation);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMGRABEXCLUSIVE	proc	far	fhan:word, timeout:word,
					operation:word, currentOperation:fptr
			uses ds
	.enter

	mov	bx, fhan
	mov	ax, operation
	mov	cx, timeout
	call	VMGrabExclusive
	tst	currentOperation.segment
	jz	done
	lds	bx, currentOperation
	mov	ds:[bx], cx
done:
	.leave
	ret

VMGRABEXCLUSIVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMReleaseExclusive

C DECLARATION:	extern void
			_far _pascal VMReleaseExclusive(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMRELEASEEXCLUSIVE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	VMReleaseExclusive
	ret

VMRELEASEEXCLUSIVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMCheckForModifications

C DECLARATION:	extern Boolean
		    _far _pascal VMCheckForModifications(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMCHECKFORMODIFICATIONS	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	clr	ax			;assume no modifications
	call	VMCheckForModifications
	jnc	done
	dec	ax
done:
	ret

VMCHECKFORMODIFICATIONS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMSetReloc

C DECLARATION:	extern void
			_far _pascal VMSetReloc(VMFileHandle file,
					void _far (*reloc)(VMFileHandle file,
							VMBlockHandle block,
							MemHandle mh,
							void _far *data,
							VMRelocType type));
			Note: The routine pointed by "reloc" *must* be
				fixed.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMSETRELOC	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax	;bx = file, cx = seg, dx = off

	call	VMSetReloc
	ret

VMSETRELOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMSave

C DECLARATION:	extern Boolean
			_far _pascal VMSave(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMSAVE	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	VMSave

	mov	ax, 0
	jnc	done
	dec	ax
done:
	ret

VMSAVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMSaveAs

C DECLARATION:	extern VMFileHandle
			_far _pascal VMSaveAs(VMFileHandle file,
						const char _far *fname,
						word flags, word mode,
						word compression);
			Note: "fname" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMSAVEAS	proc	far	file:word, fname:fptr, flags:word, mode:word,
				compression:word
						uses ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, fname					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	al, flags.low
	mov	ah, mode.low
	mov	bx, file
	mov	cx, compression
	lds	dx, fname
	call	VMSaveAs

	mov	ss:[TPD_error], ax
	mov_trash	ax, bx
	jnc	done
	clr	ax
done:

	.leave
	ret

VMSAVEAS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMRevert

C DECLARATION:	extern void
			_far _pascal VMRevert(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMREVERT	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	VMRevert
	ret

VMREVERT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMCopyVMChain

C DECLARATION:	extern VMBlockHandle
			_far _pascal VMCopyVMChain(VMFileHandle sourceFile,
			       			   VMBlockHandle sourceChain,
			       			   VMFileHandle destFile);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMCOPYVMCHAIN	proc	far	sourceFile:word, sourceChain:dword,
				destFile:word
	.enter	

	mov	bx, sourceFile
	mov	dx, destFile
	mov	ax, sourceChain.high
	mov	bp, sourceChain.low

;	DON'T DO THIS - It trashes BP first
;	movdw	bpax, sourceChain

	call	VMCopyVMChain
	mov	dx, bp
	xchg	dx, ax
	.leave
	ret

VMCOPYVMCHAIN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMFreeVMChain

C DECLARATION:	extern void
			_far _pascal VMFreeVMChain(VMFileHandle file,
						   VMBlockHandle chain);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMFREEVMCHAIN	proc	far	fileHan:hptr, chainHan:dword
	.enter	
	mov	bx, fileHan

;	DON'T DO THIS - It trashes BP first
;	movdw	bpax, chainHan

	mov	ax, chainHan.high
	mov	bp, chainHan.low
	call	VMFreeVMChain
	.leave
	ret

VMFREEVMCHAIN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMCompareVMChains

C DECLARATION:	extern Boolean
			_far _pascal VMCompareVMChains(VMFileHandle sourceFile,
				   		VMBlockHandle sourceChain,
				   		VMFileHandle destFile,
				   		VMBlockHandle destChain);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMCOMPAREVMCHAINS	proc	far	sourceFile:word, sourceChain:dword,
					destFile:word, destChain:dword
	.enter

	mov	bx, sourceFile
	movdw	dicx, destChain
	mov	dx, destFile

;	DON'T DO THIS - It trashes BP first
;	movdw	bpax, sourceChain

	mov	ax, sourceChain.high
	mov	bp, sourceChain.low
	call	VMCompareVMChains
	mov	ax, 0
	jnc	done
	dec	ax
done:
	.leave
	ret

VMCOMPAREVMCHAINS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMInfoVMChain

C DECLARATION:	extern Boolean
			_far _pascal VMInfoVMChain(VMFileHandle sourceFile,
				   		VMBlockHandle sourceChain,
						dword *chainSize,
						word *vmBlockCount,
						word *dbItemCount
						);

Returns TRUE if an error was found the the VMChain.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kertes	1/95		Initial version

------------------------------------------------------------------------------@
VMINFOVMCHAIN	proc	far	sourceFile:word, sourceChain:dword,
				chainSize:fptr.dword, vmBlockCount:fptr.word,
				dbItemCount:fptr.word
ForceRef VMINFOVMCHAIN
	uses si,di,ds
	.enter
	;
	; set up for real function call
	;
	push	bp				; save locals

	mov	bx, sourceFile
	mov	ax, sourceChain.high
	mov	bp, sourceChain.low
	call	VMInfoVMChain			; cxdx is size in bytes
						; si <- vm blocks in chain
						; di <- dm items in chain
						; carry set if bad chain

	pop	bp				; restore locals

	mov	ax, 0				; assume all ok
	jnc	haveReturnValue
	dec	ax				; error occured
haveReturnValue:

	;
	; store size and block counts in the return vars
	;
	mov	bx, si			; save block count
	lds	si, vmBlockCount
	mov	ds:[si], bx
	lds	si, dbItemCount
	mov	ds:[si], di
	lds	si, chainSize
	movdw	ds:[si], cxdx
		
	.leave
	ret

VMINFOVMCHAIN	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMCopyVMBlock

C DECLARATION:	extern VMBlockHandle
			_far _pascal VMCopyVMBlock(VMFileHandle sourceFile,
			       			   VMBlockHandle sourceBlock,
			       			   VMFileHandle destFile);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMCOPYVMBLOCK	proc	far	sourceFile:word, sourceBlock:word,
				destFile:word
	.enter

	mov	bx, sourceFile
	mov	ax, sourceBlock
	mov	dx, destFile
	call	VMCopyVMBlock

	.leave
	ret

VMCOPYVMBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECVMCheckVMFile

C DECLARATION:	extern void
			_far _pascal ECVMCheckVMFile(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECVMCHECKVMFILE	proc	far
if	ERROR_CHECK
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	ECVMCheckVMFile
	ret
else
	ret	2
endif

ECVMCHECKVMFILE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECVMCheckVMBlockHandle

C DECLARATION:	extern void
			_far _pascal ECVMCheckVMBlockHandle(VMFileHandle file,
						VMBlockHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECVMCHECKVMBLOCKHANDLE	proc	far
if	ERROR_CHECK
	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = file, ax = block

	call	ECVMCheckVMBlockHandle
	ret
else
	ret	4
endif

ECVMCHECKVMBLOCKHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECVMCheckMemHandle

C DECLARATION:	extern void
				_far _pascal ECVMCheckMemHandle(MemHandle han);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECVMCHECKMEMHANDLE	proc	far
if	ERROR_CHECK
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	ECVMCheckMemHandle
	ret
else
	ret	2
endif

ECVMCHECKMEMHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMSetExecThread

C DECLARATION:	extern void
			_far _pascal VMSetExecThread(VMFileHandle file,
							ThreadHandle thread);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMSETEXECTHREAD	proc	far
	C_GetTwoWordArgs	bx,ax,   dx,cx	;bx = file, ax = thread

	call	VMSetExecThread
	ret

VMSETEXECTHREAD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMAllocLMem

C DECLARATION:	extern VMBlockHandle
			    _far _pascal VMAllocLMem(VMFileHandle file,
					LMemType ltype, word headerSize);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMALLOCLMEM	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = type, cx = sz

	call	VMAllocLMem
	ret

VMALLOCLMEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMGetHeaderInfo

C DECLARATION:	extern void
			_far _pascal VMGetHeaderInfo(VMFileHandle file,
						VMHeaderInfoStruct *vmInfo);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	7/19/94    	Initial version

------------------------------------------------------------------------------@
VMGETHEADERINFO	proc	far	file:word, vmInfo:fptr
	uses	es, di
	.enter

	mov	bx, file
	call	VMGetHeaderInfo

	les	di, vmInfo
	stosw				; vmInfo->usedBlocks = ax
	mov_tr	ax, cx
	stosw				; vmInfo->headerSize = cx
	mov_tr	ax, dx
	stosw				; vmInfo->freeBlocks = dx

	.leave
	ret
VMGETHEADERINFO	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	VMDiscardDirtyBlocks

C DECLARATION:	extern word
			_far _pascal VMDiscardDirtyBlocks(VMFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
VMDISCARDDIRTYBLOCKS	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	VMDiscardDirtyBlocks
	mov	ss:[TPD_error], ax
	ret
VMDISCARDDIRTYBLOCKS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMSetDirtyLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extrn void
			_far _pascal VMSetDirtyLimit(VMFileHandle file,
						word dirtyLimit);
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	12/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMSETDIRTYLIMIT	proc	far
	C_GetTwoWordArgs	bx,cx,  ax,dx	; bx=file, cx=limit

	call	VMSetDirtyLimit
	ret
VMSETDIRTYLIMIT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMEnforceHandleLimits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extrn void
			_far _pascal VMEnforceHandleLimits(VMFileHandle file,
					word low, word high);
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/28/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMENFORCEHANDLELIMITS	proc	far
	C_GetThreeWordArgs	bx,cx,dx,  ax	; bx=file, cx=low, dx=high

	call	VMEnforceHandleLimits
	ret
VMENFORCEHANDLELIMITS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayLockDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern void
			_far _pascal HugeArrayLockDir(VMFileHandle vmFile, 
						   VMBlockHandle vmBlock,
						   void _far *_far *elemPtr);
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUGEARRAYLOCKDIR proc	far  vmFile:hptr, vmBlock:hptr, elemPtr:fptr.far
	uses	di, ds, si
	.enter
	mov	bx, vmFile		; load up routine parameters
	mov	di, vmBlock
	call	HugeArrayLockDir
	lds	si, elemPtr
	mov	ds:[si].offset, 0
	mov	ds:[si].segment, ax
	.leave
	ret
HUGEARRAYLOCKDIR endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayUnlockDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern void
		    _far _pascal HugeArrayUnlockDir (void _far *_far *elemPtr);
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUGEARRAYUNLOCKDIR proc	far
	C_GetOneDWordArg	dx,ax, bx,cx
	push	ds
	mov	ds, dx
	call	HugeArrayUnlockDir
	pop	ds
	ret
HUGEARRAYUNLOCKDIR endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayCreate

C DECLARATION:	extern VMBlockHandle 
			_far _pascal HugeArrayCreate(VMFileHandle file, 
						     word elemSize,
						     word headerSpace);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUGEARRAYCREATE	proc	far
	C_GetThreeWordArgs	bx, cx, ax,  dx	;bx = file, cx = elemSize, 
						;ax = extra header space
	xchg	ax, di			; di <- header space
	call	HugeArrayCreate
	xchg	ax, di			; return block handle & restore di
	ret
HUGEARRAYCREATE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayDestroy

C DECLARATION:	extern void 
			_far _pascal HugeArrayDestroy(VMFileHandle file, 
						      VMBlockHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUGEARRAYDESTROY	proc	far
	C_GetTwoWordArgs	bx,cx, ax,dx	;bx = file, cx = block, 
	xchg	cx, di
	call	HugeArrayDestroy
	xchg	cx, di
	ret
HUGEARRAYDESTROY	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	ECCheckHugeArray

C DECLARATION:	extern void 
			_far _pascal ECCheckHugeArray(VMFileHandle file, 
						      VMBlockHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCHECKHUGEARRAY	proc	far
	C_GetTwoWordArgs	bx,cx, ax,dx	;bx = file, cx = block, 
	xchg	cx, di
	call	ECCheckHugeArrayFar
	xchg	cx, di
	ret
ECCHECKHUGEARRAY	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayCompressBlocks

C DECLARATION:	extern void 
		   _far _pascal HugeArrayCompressBlocks(VMFileHandle file, 
						        VMBlockHandle block);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HUGEARRAYCOMPRESSBLOCKS	proc	far
	C_GetTwoWordArgs	bx,cx, ax,dx	;bx = file, cx = block, 
	xchg	cx, di
	call	HugeArrayCompressBlocks
	xchg	cx, di
	ret
HUGEARRAYCOMPRESSBLOCKS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayLock

C DECLARATION:	extern dword 
			_far _pascal HugeArrayLock(VMFileHandle vmFile, 
						   VMBlockHandle vmBlock,
						   dword elemNum,
						   void _far *_far *elemPtr,
						   word *size);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYLOCK	proc	far  vmFile:hptr, vmBlock:hptr, elemNum:dword, 
			     elemPtr:fptr.far, elemSize:fptr.word
	uses	ds, si, di
	.enter
	mov	bx, vmFile		; load up routine parameters
	mov	di, vmBlock
	mov	ax, elemNum.low
	mov	dx, elemNum.high
	call	HugeArrayLock		; dx <- size of element
	push	dx			; Save size of element
	push	cx			; save # elements before this one
		
	mov	cx, ds			; save returned pointer
	mov	bx, si
	lds	si, elemPtr
	mov	ds:[si].offset, bx
	mov	ds:[si].segment, cx

	pop	dx			; dx <- # elements before this one
					; ax <- # elements after this one
	pop	cx			; cx <- element size
	lds	si, elemSize		; ds:si <- ptr to word
	mov	{word} ds:[si], cx	; Save element size
	.leave
	ret
HUGEARRAYLOCK	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayUnlock

C DECLARATION:	extern void 
			_far _pascal HugeArrayUnlock(const void _far *elemPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYUNLOCK	proc	far  
	C_GetOneDWordArg	dx,ax, bx,cx
	push	ds
	mov	ds, dx
	call	HugeArrayUnlock
	pop	ds
	ret
HUGEARRAYUNLOCK	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayAppend

C DECLARATION:	extern dword 
			_far _pascal HugeArrayAppend(VMFileHandle vmFile,
						     VMBlockHandle vmBlock,
						     word numElem,
						     const void _far *initData);
			Note:"initData" *cannot* be pointing to the XIP
				movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYAPPEND	proc	far	vmFile:hptr, vmBlock:hptr, numElem:word,
			    	initData:fptr
	uses	si, di, bp
	.enter
	mov	bx, vmFile
	mov	di, vmBlock
	mov	cx, numElem
	mov	si, initData.offset
	mov	bp, initData.segment
	call	HugeArrayAppend
	.leave
	ret
HUGEARRAYAPPEND	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayInsert

C DECLARATION:	extern void 
			_far _pascal HugeArrayInsert(VMFileHandle vmFile,
						     VMBlockHandle vmBlock,
						     word numElem,
						     dword elemNum,
						     const void _far *initData);
			Note: "initData" *cannot* be pointing to the XIP
				movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYINSERT	proc	far	vmFile:hptr, vmBlock:hptr, numElem:word,
			    	elemNum:dword, initData:fptr
	uses	si, di, bp
	.enter
	mov	bx, vmFile
	mov	di, vmBlock
	mov	cx, numElem
	mov	ax, elemNum.low
	mov	dx, elemNum.high
	mov	si, initData.offset
	mov	bp, initData.segment
	call	HugeArrayInsert
	.leave
	ret
HUGEARRAYINSERT	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayReplace

C DECLARATION:	extern void 
			_far _pascal HugeArrayReplace(VMFileHandle vmFile,
						     VMBlockHandle vmBlock,
						     word numElem,
						     dword elemNum,
						     const void _far *initData);
			Note: "initData" *cannot* be pointing to the XIP
				movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYREPLACE proc	far	vmFile:hptr, vmBlock:hptr, numElem:word,
			    	elemNum:dword, initData:fptr
	uses	si, di, bp
	.enter
	mov	bx, vmFile
	mov	di, vmBlock
	mov	cx, numElem
	mov	ax, elemNum.low
	mov	dx, elemNum.high
	mov	si, initData.offset
	mov	bp, initData.segment
	call	HugeArrayReplace
	.leave
	ret
HUGEARRAYREPLACE endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayDelete

C DECLARATION:	extern void 
			_far _pascal HugeArrayDelete(VMFileHandle vmFile,
						     VMBlockHandle vmBlock,
						     word numElem,
						     dword elemNum);
						     

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYDELETE proc	far	vmFile:hptr, vmBlock:hptr, numElem:word,
			    	elemNum:dword
	uses	di
	.enter
	mov	bx, vmFile
	mov	di, vmBlock
	mov	cx, numElem
	mov	ax, elemNum.low
	mov	dx, elemNum.high
	call	HugeArrayDelete
	.leave
	ret
HUGEARRAYDELETE endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayGetCount

C DECLARATION:	extern dword 
			_far _pascal HugeArrayGetCount(VMFileHandle vmFile,
						     VMBlockHandle vmBlock);
						     

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYGETCOUNT proc	far	
	C_GetTwoWordArgs	bx,cx, ax,dx
	xchg	cx, di				; saves value of di
	call	HugeArrayGetCount		; return value in dx.ax
	xchg	cx, di
	ret
HUGEARRAYGETCOUNT endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayNext

C DECLARATION:	extern word 
			_far _pascal HugeArrayNext(void _far *_far *elemPtr,
						   word *size);
						    
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYNEXT	proc	far	elemPtr:fptr.fptr, elemSize:fptr.word
	uses	ds, si
	.enter
	lds	bx, elemPtr			; ds:bx -> pointer
	mov	si, ds:[bx].offset
	mov	ds, ds:[bx].segment
	call	HugeArrayNext			; return value in dx.ax
	push	dx				; save element size

	mov	cx, si
	mov	dx, ds
	lds	si, elemPtr
	mov	ds:[si].offset, cx		; store new pointer
	mov	ds:[si].segment, dx

	pop	dx				; dx <- element size
	lds	si, elemSize			; ds:si <- ptr to word
	mov	{word} ds:[si], dx		; Save element size
	.leave
	ret
HUGEARRAYNEXT	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayPrev

C DECLARATION:	extern word 
			_far _pascal HugeArrayPrev(void _far *_far *elemPtr1,
						   void _far *_far *elemPtr2,
						   word *size);
						    
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYPREV	proc	far	elemPtr1:fptr.fptr, elemPtr2:fptr.fptr,
				elemSize:fptr.word
	uses	ds, si, di
	.enter
	lds	bx, elemPtr1			; ds:bx -> pointer
	mov	si, ds:[bx].offset
	mov	ds, ds:[bx].segment
	call	HugeArrayPrev			; return value in dx.ax
	push	dx				; save size

	mov	cx, si
	mov	dx, ds
	mov	bx, di
	lds	si, elemPtr1
	mov	ds:[si].offset, cx		; store new pointer
	mov	ds:[si].segment, dx
	lds	si, elemPtr2
	mov	ds:[si].offset, bx		; store new pointer
	mov	ds:[si].segment, dx

	pop	dx				; dx <- element size
	lds	si, elemSize			; ds:si <- ptr to word
	mov	{word} ds:[si], dx		; Save element size
	.leave
	ret
HUGEARRAYPREV	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayExpand

C DECLARATION:	extern word 
			_far _pascal HugeArrayExpand(void _far *_far *elemPtr,
						   word	numElem,
						   const void _far *initData);
			Note:"initData" *cannot* be pointing to the XIP movable
				code resource.
						    
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYEXPAND	proc	far	elemPtr:fptr.fptr, numElem:word, initData:fptr
	uses	ds, si, di
	.enter
	lds	bx, elemPtr			; ds:bx -> pointer
	mov	si, ds:[bx].offset
	mov	ds, ds:[bx].segment
	mov	cx, numElem
	mov	di, initData.offset
	push	bp
	mov	bp, initData.segment
	call	HugeArrayExpand			; return value in dx.ax
	pop	bp
	mov	cx, si
	mov	dx, ds
	lds	si, elemPtr
	mov	ds:[si].offset, cx		; store new pointer
	mov	ds:[si].segment, dx
	.leave
	ret
HUGEARRAYEXPAND	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayContract

C DECLARATION:	extern word 
			_far _pascal HugeArrayContract(void _far *_far *elemPtr,
						       word numElem);
						    
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYCONTRACT	proc	far	
	C_GetThreeWordArgs	ax, bx, cx, dx	; ax=seg, bx=off, cx=num
	push	ds, si
	mov	ds, ax
	push	ax
	mov	si, ds:[bx].offset
	mov	ds, ds:[bx].segment
	call	HugeArrayContract		; return value in dx.ax
	mov	cx, si
	mov	dx, ds
	pop	ds
	mov	ds:[bx].offset, cx
	mov	ds:[bx].segment, dx
	pop	ds, si
	ret
HUGEARRAYCONTRACT	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayDirty

C DECLARATION:	extern void 
			_far _pascal HugeArrayDirty(const void _far *elemPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYDIRTY	proc	far  
	C_GetOneDWordArg	dx,ax, bx,cx
	push	ds
	mov	ds, dx
	call	HugeArrayDirty
	pop	ds
	ret
HUGEARRAYDIRTY	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayResize

C DECLARATION:	extern void 
			_far _pascal HugeArrayResize(VMFileHandle vmFile,
						     VMBlockHandle vmBlock,
						     dword elemNum,
						     word newSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYRESIZE	proc	far  vmFile:hptr, vmBlock:hptr,
			    	elemNum:dword, newSize:word
	uses	di
	.enter
	mov	bx, vmFile
	mov	di, vmBlock
	movdw	dxax, elemNum
	mov	cx, newSize
	call	HugeArrayResize
	.leave
	ret
HUGEARRAYRESIZE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeArrayEnum

C DECLARATION:	extern Boolean
	    _far _pascal HugeArrayEnum(
				VMFileHandle fh,
				VMBlockHandle vb,
				Boolean _far (*callback),   /* TRUE = stop */
				dword startElement,
				dword count,
				void _far *enumData,
			    	(void _far *element, void _far *enumData));
		Note: "enumData" cannot be pointing in the XIP movable code
			resource.
		      "callback" must be vfptr.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
HUGEARRAYENUM	proc	far	fh:hptr, vb:hptr, callback:fptr.far,
				startElement:dword, count:dword,
				enumData:fptr
	uses	si, di, ds
	ForceRef	enumData
	ForceRef	callback
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, callback					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, enumData					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	dx, ds			; dx <- ds to pass to callback

	push	fh
	push	vb

	mov	bx, cs
	mov	di, offset _HUGEARRAYENUM_callback
	pushdw	bxdi

	pushdw	startElement
	pushdw	count

	call	HugeArrayEnum

	mov	ax, 0
	jnc	done
	dec	ax
done:

	.leave
	ret

HUGEARRAYENUM	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	_HUGEARRAYENUM_callback

DESCRIPTION:	Callback routine for HUGEARRAYENUM

CALLED BY:	HugeArrayEnum

PASS:
	ds:di	- Element
	ax	- Element size
	dx	- real ds to pass callback
	ss:bp	- Inherited variables

RETURN:
	carry	- Set to stop

DESTROYED:
	ax, cx, dx, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

				Boolean _far (*callback)   /* TRUE = stop */
				    (void _far *element, void _far *enumData));

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

_HUGEARRAYENUM_callback	proc	far
	uses	dx
	.enter inherit	HUGEARRAYENUM

	push	ds			;save ds

	; push arguments to callback

	pushdw	dsdi			;element
	pushdw	enumData

	mov	ds, dx

	mov	ax, callback.offset
	mov	bx, callback.segment
	call	ProcCallFixedOrMovable

	pop	ds			;restore ds

	; ax non-zero to stop

	tst	ax			;clears carry
	jz	done			;zero means leave carry clear
	stc
done:

	.leave
	ret

_HUGEARRAYENUM_callback	endp

C_System	ends

	SetDefaultConvention
