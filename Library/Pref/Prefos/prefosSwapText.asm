COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefosSwapfile.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/21/93   	Initial version.

DESCRIPTION:
	

	$Id: prefosSwapText.asm,v 1.1 97/04/05 01:34:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefOSSwapTextLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load the swap filename -- if none, then construct a
		path using SP_PRIVATE_DATA, and the default swap filename.

PASS:		*ds:si	- PrefOSSwapTextClass object
		ds:di	- PrefOSSwapTextClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SBCS <defSwapName	char	"SWAP", 0				>
DBCS <defSwapName	wchar	"SWAP", 0				>

PrefOSSwapTextLoadOptions	method	dynamic	PrefOSSwapTextClass, 
					MSG_GEN_LOAD_OPTIONS

	.enter

	sub	sp, size PathName
	mov	di, sp
	segmov	es, ss

	;
	; Look for the filename in the .INI file
	;

	push	ds, si

	mov	cx, ss
	mov	ds, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key	


	mov	bp, size PathName
	call	InitFileReadString
	jnc	setText

	;
	; use default (es:di - text buffer)
	;

	mov	dx, TRUE		; dx <- add drive specifier
	mov	bx, SP_PRIVATE_DATA	; bx <- disk handle
	mov	si, offset cs:defSwapName
	segmov	ds, cs			; ds:si <- tail
	mov	cx, size PathName	; cx <- size of same
	push	di
	call	FileConstructFullPath
	pop	di

setText:
	pop	ds, si
	mov	dx, ss
	mov	bp, di
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock

	add	sp, size PathName
	.leave
	ret
PrefOSSwapTextLoadOptions	endm

