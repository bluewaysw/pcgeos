COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fileEC.asm

AUTHOR:		Adam de Boor, Apr  9, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 9/90		Initial revision


DESCRIPTION:
	Error-checking routines.
		

	$Id: fileEC.asm,v 1.1 97/04/05 01:11:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK

COMMENT @-----------------------------------------------------------------------

FUNCTION:       CheckAccessFlags

DESCRIPTION:    Make sure DOS access flags are ok.

CALLED BY:      INTERNAL (FileCreate, FileOpen)

PASS:           al - access flags for FileCreate and FileOpen

RETURN:         Fatal error if flags are bad

DESTROYED:      none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Tony    10/88           Initial version
-------------------------------------------------------------------------------@

CheckAccessFlags        proc    far
        push    ax
        and     al, mask FAF_EXCLUDE
        jz      CAF_error
	cmp	al, FE_EXCLUSIVE shl offset FAF_EXCLUDE
	jb	CAF_error
	cmp	al, FE_NONE shl offset FAF_EXCLUDE
	ja	CAF_error
	pop	ax
	push	ax
	and	al, mask FAF_MODE
	cmp	al, FA_READ_WRITE shl offset FAF_MODE
	ja	CAF_error
        pop     ax
        ret
CAF_error:
        ERROR   OPEN_BAD_FLAGS
CheckAccessFlags        endp

endif	; ERROR_CHECK

; THIS IS NOW IN THE NON-EC AS WELL...
COMMENT @----------------------------------------------------------------------

FUNCTION:       ECCheckFileHandle

DESCRIPTION:    Make sure a handle is actually a file handle.

CALLED BY:      INTERNAL (FileFind)

PASS:           bx - file handle

RETURN:         call to FatalError if assertions fail

DESTROYED:      nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Cheng   4/89            Initial version
	Jenny	9/91		Rewrote ECCheckFileHandleFar
------------------------------------------------------------------------------@
ECCheckFileHandle        proc    far	uses ds
        .enter
        LoadVarSeg      ds

EC <	call	CheckHandleLegal					>

NEC <	FAST_CHECK_HANDLE_LEGAL						>

        cmp     ds:[bx].HG_type, SIG_FILE  	;assert file handle
	jne	bad
        cmp     ds:[bx][HF_owner], 0            ;assert not empty
	je	bad
        .leave
        ret
bad:
        ERROR   ILLEGAL_HANDLE
ECCheckFileHandle        endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckNotAfterFilesClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the filesystem hasn't been shut down before 
		attempting to lock down a movable resource for a call.

CALLED BY:	(INTERNAL) ProcCallFixedOrMovable, ResourceCallInt,
			   ProcCallModuleRoutine
PASS:		ds	= kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	ERROR_CHECK
kcode	segment	resource
ECCheckNotAfterFilesClosed proc	near
		.enter
		tst	ds:[fileExited]
		ERROR_NZ CANNOT_CALL_MOVABLE_ROUTINE_AFTER_FILESYSTEM_SHUT_DOWN
		.leave
		ret
ECCheckNotAfterFilesClosed endp
kcode	ends
endif	; ERROR_CHECK
