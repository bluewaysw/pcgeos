COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Translation Libraries
FILE:		transSemaphore.asm

AUTHOR:		Jimmy Lefkowitz, July 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/91		Initial version (called libMain.asm)
	jenny	11/91		Added documentation and semaphore routines
	jenny	4/92		Changed file name and location

ROUTINES:
	Name				Description
	----				-----------
GLB	TransLibraryEntry		Initialization entry point
GLB	TransLibraryThreadPSem		P's semaphore around library
GLB	TransLibraryThreadVSem		V's semaphore around library

DESCRIPTION:
	Routines for using semaphores around translation libraries
	which use global variables.
		
	$Id: transSemaphore.asm,v 1.1 97/04/07 11:42:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry/initialization point for translation library

CALLED BY:	GLOBAL
		(Kernel calls upon loading library)

PASS:		di	- LibraryCallType enum
				LCT_ATTACH	- when first loaded
				LCT_NEW_CLIENT	- each time somebody wants us
				LCT_CLIENT_EXIT	- when the one who wants us
						  leaves
				LCT_DETACH	- when we should clean up and
						  die

RETURN:		carry	- clear if init went ok

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		When loading the library, allocate the semaphore and make the
		application own it.
		When unloading the library, scrap the semaphore.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	02/91		Initial version
		jenny	11/91		Added comments, fixed header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransLibraryEntry proc	far
		uses	bx, es
		.enter

		mov	bx, dgroup
		mov	es, bx
	;
	; When loading the library, allocate the semaphore and make the
	; application own it.
	;
		cmp	di, LCT_ATTACH
		jnz	checkDetach
		mov	bx, 1
		call	ThreadAllocSem
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	es:[threadSem], bx
		jmp	done
checkDetach:
	;
	; When unloading the library, scrap the semaphore.
	;
		cmp	di, LCT_DETACH
		jnz	done
		mov	bx, es:[threadSem]
		call	ThreadFreeSem
done:
		clc
		.leave
		ret
TransLibraryEntry endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransLibraryThreadPSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	P the semaphore around the use of the library

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:
		Get semaphore handle and P semaphore.

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/ 3/91		Initial version.
	jenny	11/91		Changed routine name, fixed header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransLibraryThreadPSem	proc	far	
		uses	ax, bx, es
		.enter
		mov	bx, dgroup
		mov	es, bx
		mov	bx, es:[threadSem]
		call	ThreadPSem
		.leave
		ret
TransLibraryThreadPSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransLibraryThreadVSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	V the semaphore around the use of the library

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:
		Get semaphore handle and V semaphore.

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/ 3/91		Initial version.
	jenny	11/91		Changed routine name, fixed header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransLibraryThreadVSem	proc	far	
		uses	ax, bx, es
		.enter
		mov	bx, dgroup
		mov	es, bx
		mov	bx, es:[threadSem]
		call	ThreadVSem
		.leave
		ret
TransLibraryThreadVSem	endp

ResidentCode	ends
