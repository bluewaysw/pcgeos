COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Thread
FILE:		threadPrivate.asm

AUTHOR:		Adam de Boor, Nov 30, 1989

ROUTINES:
	Name			Description
	----			-----------
    GLB	ThreadPrivAlloc		Obtain the right to space in the private
    				data for all threads.
    GLB ThreadPrivFree		Release	right to space.
    EXT ThreadPrivExit		Check for space allocated by an exiting
				geode, release it if there.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/30/89	Initial revision


DESCRIPTION:
	Functions for managing the extra space at the end of the
	ThreadPrivateData for all threads.

	Space in the "heap" is allocated by word. The allocation of the 
	"heap" is tracked in the kernel thread's private data (kTPD), with each
	word in TPD_heap containing either 0, to indicate it's free, or
	the handle of the owning geode (in case the geode exits w/o freeing
	the space).
		

	$Id: threadPrivate.asm,v 1.1 97/04/05 01:15:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GLoad segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadPrivAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate words in all threads's private data.

CALLED BY:	GLOBAL
PASS:		cx	= number of words required (contiguous)
		bx	= handle of geode that will "own" the space
RETURN:		bx	= offset of start of range
		carry set if no contiguous block large enough.
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Allocation is performed on a first-fit basis as it's simplest,
	especially given the tiny size of the heap we're using.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: Geode Semaphore should be owned by calling thread (should only
	      be called in LibraryEntry routines.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadPrivAlloc	proc	far	uses es, di, ax, cx, dx, bp
		.enter
		LoadVarSeg	es
		lea	di, kTPD.TPD_heap
		mov	dx, cx
		mov	cx, length kTPD.TPD_heap
		mov	bp, bx
		call	FindContiguousWords
		mov	bx, bp
		.leave
		ret
ThreadPrivAlloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadPrivFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a range of thread-private space owned by a geode

CALLED BY:	GLOBAL
PASS:		bx	= offset into thread-private space to be freed
		cx	= number of words being released
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: Geode Semaphore should be owned by calling thread (should only
	      be called in LibraryEntry routines.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadPrivFree	proc	far	uses es, di, ax
		.enter
		LoadVarSeg	es
		lea	di, kTPD[bx]

		clr	ax
		;
		; ERRORCHECK: make sure all slots are actually allocated
		;
EC <		push	di						>
EC <		push	cx						>
EC <		repne	scasw						>
EC <		ERROR_Z	THREAD_PRIVATE_DATA_NOT_ALLOCATED		>
EC <		pop	cx						>
EC <		pop	di						>
		;
		; ERRORCHECK: Make sure all slots owned by same geode
		;
EC <		push	cx, ds, si					>
EC <		mov	si, es						>
EC <		mov	ds, si						>
EC <		lea	si, [di+2]					>
EC <		dec	cx						>
EC <		repe	cmpsw						>
EC <		ERROR_NZ THREAD_PRIVATE_DATA_OWNED_BY_SOMEONE_ELSE	>
EC <		pop	cx, ds, si					>

		;
		; Clear out all slots
		;
   		rep	stosw
		
		.leave
		ret
ThreadPrivFree	endp

GLoad ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadPrivExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release any thread-private space owned by an exiting geode

CALLED BY:	FreeGeodeBlocks
PASS:		ax	= handle of core block of exiting geode
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadPrivExit	proc	near	uses	es, di, cx
		.enter
		LoadVarSeg	es
		lea	di, kTPD.TPD_heap
		mov	cx, length kTPD.TPD_heap
scanLoop:
		repne	scasw		; Search for matchin slot
		jne	done		; None -- all done
		mov	{word}es:[di-2], 0 ; Free that slot
		jcxz	done		; Avoid infinite loop, since
					;  mov won't alter ZF and REPNE will
					;  abort right off if CX is 0 on entry.
		jmp	scanLoop
done:
		.leave
		ret
ThreadPrivExit	endp
