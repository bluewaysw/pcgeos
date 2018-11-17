COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

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
	TransLibraryThreadPSem		P's semaphore around library
	TransLibraryThreadVSem		V's semaphore around library

DESCRIPTION:
	Routines for using semaphores around translation libraries
	which use global variables.
		
	$Id: transLibEntry.asm,v 1.1 97/04/07 11:42:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; REENTRANT_CODE indicates whether or not a translation library uses
; global variables and therefore requires a semaphore around it.
; REENTRANT_CODE must be set before this file is included.
;

ifndef	REENTRANT_CODE

ErrMessage	<Error - Set REENTRANT_CODE TRUE or FALSE before including this file.>

else

if	REENTRANT_CODE eq FALSE

include	transSemaphore.asm

else

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

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Do nothing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jenny	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransLibraryEntry proc	far
		clc
		ret
TransLibraryEntry endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransLibraryThreadPSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dummy routine for translation libraries without semaphore

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
		Do nothing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransLibraryThreadPSem	proc	far	
	clc
	ret
TransLibraryThreadPSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransLibraryThreadVSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dummy routine for translation libraries without semaphore

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
		Do nothing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransLibraryThreadVSem	proc	far	
	clc
	ret
TransLibraryThreadVSem	endp

ResidentCode	ends

endif
endif
