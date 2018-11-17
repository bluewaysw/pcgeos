COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		linktoolText.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/20/93   	Initial version.

DESCRIPTION:
	

	$Id: linktoolText.asm,v 1.1 97/04/04 18:01:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSTextFileSelectorChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Deal with a change in the file selector's status

PASS:		*ds:si	- FileSelectorTextClass object
		ds:di	- FileSelectorTextClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/20/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FSTextFileSelectorChange	method	dynamic	FileSelectorTextClass, 
					MSG_FS_TEXT_FILE_SELECTOR_CHANGE


		call	ShellAlloc2PathBuffers
		mov	dx, es
		mov	bp, offset PB2_path1
		mov	cx, size PB2_path1

		push	si
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
		mov	si, offset LinktoolFileSelector
		call	ObjCallInstanceNoLock

		push	ds
		segmov	ds, es
		mov	si, offset PB2_path1 
		mov	bx, cx			; disk handle
		mov	dx, -1			; use drive name
		mov	di, offset PB2_path2
		mov	cx, size PB2_path2
		call	FileConstructFullPath
		pop	ds

	; find the last component

		mov	bp, offset PB2_path2
		mov	cx, di
		sub	cx, bp
DBCS <		shr	cx, 1						>

		mov	si, di
		std	
;;		LocalLoadChar ax, C_BACKSLASH		;separator

		mov	al, C_BACKSLASH
		LocalFindChar 				;scasb/scasw
		cld
		jcxz	20$
		inc	di				;point at backslash
		inc	di				;point past backslash
DBCS <		inc	di						>
DBCS <		inc	di						>
		cmp	di, si			;if backslash is the end then
		je	20$			;use the whole thing

		mov	bp, di
20$:

		
		mov	dx, es
		clr	cx
		
		pop	si
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		call	ShellFreePathBuffer
		ret
FSTextFileSelectorChange	endm

