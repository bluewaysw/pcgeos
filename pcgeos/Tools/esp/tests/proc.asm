COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Esp Test Suite
FILE:		proc.asm

AUTHOR:		Adam de Boor, Sep  5, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 5/89		Initial revision


DESCRIPTION:
	This file is intended to test the procedure facilities of Esp
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

biff		segment

		public	main
main		proc	far USES ax, cx	arg1:3 dup(word), arg2:byte
M_temp		local	word
M_tempb		local	byte
M_tempd		local	fptr.far
		uses	ds
		.enter
		mov	ax, arg1
		mov	M_temp, ax
		mov	ax, cx
		mov	cl, 3
		mov	M_tempb, 0
1$:
		add	M_tempb, cl
		loop	1$
		.leave
		ret
main		endp
biff		ends
