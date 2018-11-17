COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosapplC.asm

AUTHOR:		Adam de Boor, May  5, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 5/92		Initial revision


DESCRIPTION:
	C stubs for global routines in this module.
		

	$Id: dosapplC.asm,v 1.1 97/04/05 01:11:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DosapplCode	segment	resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	_DosExec

C DECLARATION:	extern word
		    DosExec(const char *prog,
			     DiskHandle progDisk,
			     const char *arguments,
			     const char *execDir,
			     DiskHandle execDisk,
			     word flags);
		Note: The strings passed in *cannot* be pointing to the
			movable XIP code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jenny	10/93		"DOSEXEC" -> "_DosExec" since it's cdecl
------------------------------------------------------------------------------@
_DosExec	proc	far	prog:fptr.char, progDisk:hptr, arguments:fptr.char,
				execDir:fptr.char, execDisk:hptr, flags:word
					uses si, di, bp, ds, es
	.enter

	lds	si, prog
	les	di, arguments
	mov	bx, progDisk
	mov	cx, flags
	mov	ax, execDisk
	mov	dx, execDir.segment
	mov	bp, execDir.offset	; NOTE: WE CAN TRASH THIS AS WE HAVE
					;  NO LOCAL VARIABLES, AND Esp OPTIMIZES
					;  THE .LEAVE TO NOT REQUIRE BP TO BE
					;  MAINTAINED.
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptrs passed in are valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, dxbp					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	call	DosExec

	mov	ss:[TPD_error], ax

	.leave
	ret

_DosExec	endp



if FULL_EXECUTE_IN_PLACE
DosapplCode	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysLocateFileInDosPath

C DECLARATION:	extern DiskHandle
		    SysLocateFileInDosPath(const char *fname,
		    				char *buffer);
			Note: "fname" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
SYSLOCATEFILEINDOSPATH	proc	far	fname:fptr.far, buffer:fptr.far
				uses si, di, ds, es
	.enter

	lds	si, fname
	les	di, buffer
	call	SysLocateFileInDosPath

	jc	error
	mov	ss:[TPD_error], 0
	mov_trash	ax, bx
	jmp	common

error:
	mov	ss:[TPD_error], ax
common:

	.leave
	ret

SYSLOCATEFILEINDOSPATH	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
DosapplCode	segment	resource
endif


DosapplCode	ends
