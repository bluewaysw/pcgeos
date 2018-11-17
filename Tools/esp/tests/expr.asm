COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Esp Test Suite
FILE:		expr.asm

AUTHOR:		Adam de Boor, Oct  7, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/ 7/89	Initial revision


DESCRIPTION:
	A file to test all the expression operators and the expression
	parser and evaluator in general..
		
	Expect the following warning:
warning: file "tests/expr.asm", line 93: b used without MASK or OFFSET operator


	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

rec	record	a:3, b:4
et	etype 	word, 11, 3
e1	enum	et, 13	; 13
e2	enum	et	; 16

struct	struc
    q	dw	?
    r	byte
    s	sptr.struct
struct	ends

biff	segment	resource
label1	db	1
label2	dw	2
a1	dw	3, 4, 5
	public	label2
	dw	label1+1	; 01 00 + rel
	dw	1+label1	; 01 00 + rel
	dw	label2-1	; ff ff + rel
	dw	label2-label1	; 01 00
	dw	3*6		; 12 00
	dw	6/3		; 02 00
	dw	6 or 1		; 07 00 
	dw	6 xor 3		; 05 00
	dw	6 and 3		; 02 00
	dw	6 shl 1		; 0c 00
	dw	6 shr 1		; 03 00
	dw	65536*2/4	; 00 80
	dw	6 mod 4		; 02 00
	dw	6 eq 6		; ff ff
	dw	6 eq 1		; 00 00
	dw	6 ne 6		; 00 00
	dw	6 ne 1		; ff ff
	dw	6 lt 6		; 00 00
	dw	6 lt 7		; ff ff
	dw	6 gt 1		; ff ff
	dw	6 gt 7		; 00 00
	dw	6 le 6		; ff ff
	dw	6 le -3		; 00 00
	dw	6 ge -3		; ff ff
	dw	6 ge 2000h	; 00 00
	dw	-6		; fa ff
	db	high label2	; 00 byte rel
	db	low label2	; 00 byte rel (01 eventually)
	db	high 0a5a6h	; a5
	db	low 0a5a6h	; a6
	dw	type label2	; 02 00
	dw	type a1		; 02 00
	dw	not 6		; f9 ff
	dw	length a1	; 03 00
	dw	length label1	; 01 00
	dw	seg a1		; 00 00 + seg rel to biff
	dw	offset label2	; 00 00 + rel to label2
	dw	size a1		; 06 00
	db	.type a1	; 2a (def,dir,data)
	db	.type label2	; aa
	db	.type ax	; 32
foo:
	db	.type foo	; 29
	db	.type 3		; 24
	db	.type mooch	; 00
	db	.type biff	; a4
	db	width a		; 03
	db	mask b		; 0f
	db	b		; 00 + warning
	.masm
	db	b		; 00
	.nomasm
	db	e1		; 0d
	db	e2		; 10
	db	first et	; 0b
	dw	handle label1	; 00 00 seg rel to biff
	dw	resid label1	; 00 00 resource rel to biff

	db	rec		; 7f
	db	struct		; 05
	dw	et		; 13 00
biff	ends
	
