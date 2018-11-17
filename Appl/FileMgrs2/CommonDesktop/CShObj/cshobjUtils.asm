COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cshobjUtils.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
    INT ShellObjectChangeToFileQuickTransferDir 
				CD to the directory specified in the
				FileQuickTransferHeader

    INT ShellObjectCheckStudentTransferFromClassFolder 
				See if this is a student trying to make a
				transfer from a class folder or subfolder.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

DESCRIPTION:
	

	$Id: cshobjUtils.asm,v 1.2 98/06/03 13:46:33 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectChangeToFileQuickTransferDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CD to the directory specified in the FileQuickTransferHeader

CALLED BY:	ShellObjectThrowAwayEntry
		ShellObjectDeleteEntry
PASS:		cx:0 - FileQuickTransferHeader
RETURN:		bx   - cx:[FQTH_diskHandle]
		ds:dx- FQTH_pathname
		carry set on error, ax = FileError
DESTROYED:	cwd
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellObjectChangeToFileQuickTransferDir		proc	far
		.enter

		mov	ds, cx
		mov	bx, ds:[FQTH_diskHandle]
		mov	dx, offset FQTH_pathname
		call	FileSetCurrentPath

		.leave
		ret
ShellObjectChangeToFileQuickTransferDir		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectCheckStudentTransferFromClassFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this is a student trying to make a transfer from a class
		folder or subfolder.

CALLED BY:	ShellObjectDelete
PASS:		cx:0	- FileQuickTransferHeader
RETURN:		carry set if this is NOT a valid deletion
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	3/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _NEWDESKBA

desktopClassesDir	char	'DESKTOP', C_BACKSLASH, 'Classes', C_BACKSLASH, C_NULL
CHECK_LEN		equ	16

ShellObjectCheckStudentTransferFromClassFolder		proc	near
		uses	ax, ds, es, di, si, cx
		.enter

		call	IclasGetCurrentUserType
		cmp	ah, UT_TEACHER
		je	validUser
		cmp	ah, UT_OFFICE
		je	validUser

		mov	ds, cx
		mov	si, offset FQTH_pathname
		segmov	es, cs
		mov	di, offset cs:[desktopClassesDir]
		mov	cx, CHECK_LEN
		call	LocalCmpStrings
		jz	invalid

validUser:
		clc
done:
		.leave
		ret
invalid:
		stc
		jmp	done
ShellObjectCheckStudentTransferFromClassFolder		endp

endif
