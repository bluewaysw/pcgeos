COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Esp Test Suite
FILE:		macro.asm

AUTHOR:		Adam de Boor, Sep  4, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 4/89		Initial revision


DESCRIPTION:
	This file is designed to test the macro facilities of Esp
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
biff	macro	arg1, arg2
	dw	arg1
	ifnb <arg2>
	local	whiffle
whiffle	dw	arg2
	endif
	endm
mungo	segment
	; dw 3
	biff	3
	; dw 4 / ??0001: dw 5
	biff	4, 5
	; f1 db 1 / f2 db 2 / f3 db 3
	irp	x, <1, 2, 3>
f&x	db	x
	endm
	; mov ax, 1 / mov ax, 1 / mov ax, 1
	rept	3
	mov	ax, 1
	endm
	; 'h' 'h' 'h' 'i' 'i' 'i' ' ' ' ' ' ' 't' 't' 't' ...
	irpc	q,<hi there mom>
	rept	3
	db	'q'
	endm
	endm
;ha label byte / db 'h' / ia label byte / db 'i' /
;hb label byte / db 'h', 'h' / ib label byte / db 'i', 'i' /
;hc label byte / db 'h', 'h', 'h' / ic label byte / db 'i', 'i', 'i'
	irp	q, <a,b,c>
		irpc r, <hi>
r&&q	label byte
			rept 'q'-'`'
			db	'r'
			endm
		endm
	endm
mungo	ends
