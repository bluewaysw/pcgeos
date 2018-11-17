COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	GeoSafari
FILE:		safariBitmap.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/5/99		Initial revision

DESCRIPTION:
	Code for loading and drawing bitmaps

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include safariGeode.def
include safariConstant.def

	SetGeosConvention

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAFARIIMPORTBITMAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import a bitmap file

CALLED BY:	GLOBAL

PASS:		filename - ptr to file name
		fileHan - ptr to file to import into
RETURN:		VM block handle
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SAFARIIMPORTBITMAP	proc	far	filename:fptr.TCHAR, fileHan:hptr
	uses	ds, si
	.enter

	lds	si, ss:filename
	mov	bx, ss:fileHan
	call	SafariImportBitmap

	.leave
	ret
SAFARIIMPORTBITMAP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAFARIFREEBITMAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a bitmap file

CALLED BY:	GLOBAL

PASS:		VM block handle
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SAFARIFREEBITMAP	proc	far
	C_GetTwoWordArgs ax,bx   dx,cx	;ax = VMBlockHandle, bx=file handle

	call	SafariFreeBitmap

	ret
SAFARIFREEBITMAP	endp

CommonCode	ends
