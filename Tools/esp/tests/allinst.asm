COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Esp Test Suite
FILE:		allinst.asm

AUTHOR:		Adam de Boor, Sep  1, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 1/89		Initial revision


DESCRIPTION:
	Test file to cause Esp to assemble all possible instructions.
	The proper encoding is given beside each one.
	
	Assembling this file should produce the following messages:

warning: file "allinst.asm", line 147: defaulting operand size to byte
warning: file "allinst.asm", line 170: defaulting operand size to byte
warning: file "allinst.asm", line 192: je to a different segment -- transformed to far jump
warning: file "allinst.asm", line 277: defaulting operand size to byte
warning: file "allinst.asm", line 282: defaulting operand size to byte
warning: file "allinst.asm", line 456: immediate value (-4) not allowed as destination -- swapping with source
warning: file "allinst.asm", line 458: immediate value (256) not allowed as destination -- swapping with source
warning: file "allinst.asm", line 189: jump out of range by 142 bytes -- transformed to near jump
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
farbiff 	segment para public 'CODE'
reallyfarproc	proc	far
		ret
reallyfarproc	endp

fardwordvar	dd	?
farwordvar	dw	?
farbytevar	db	?

farbiff		ends

stackbiff	segment stack
		dw	8 dup(33cch)

stackdwordvar	dd	?
stackwordvar	dw	?
stackbytevar	db	?
stackbiff	ends

biff		segment para public 'CODE'

		assume	cs:biff, ds:biff, es:farbiff, ss:stackbiff

farproc		proc	far
		ret
farproc		endp

nearproc 	proc 	near
		ret
nearproc 	endp

dwordvar	dd	?
wordvar		dw	?
bytevar		db	?

main		proc	far
		AAA				; 37
		AAD 				; d5 0a
		AAM				; d4 0a
		AAS				; 3f

		ADC	wordvar, ax		; 11 06 xx xx
		ADC	farbytevar, bl		; 26 10 1e xx xx
		ADC	cx, cs:wordvar		; 2e 13 0e xx xx
		ADC	dl, bytevar		; 12 16 xx xx
		ADC	al, 3			; 14 03
		ADC	ax, 201h		; 15 01 02
		ADC	bytevar, 17o		; 80 16 xx xx 0f
		ADC	stackwordvar, 513	; 36 81 16 xx xx 01 02
		ADC	{word} [si], 3		; 83 14 03
		
		ADD	{word}[bp][si], di	; 01 3a
		ADD	{byte}[bp][si+1], dh	; 00 72 01
		ADD	si, ds:[bp+260][di]	; 3e 03 b3 04 01
		ADD	bl, [bx][si]		; 02 18
		ADD	al, 0eh			; 04 0e
		ADD	ax, 603h		; 05 03 06
		ADD	farbytevar, 1010101b	; 26 80 06 xx xx 55
		ADD	stackwordvar, 19000	; 36 81 06 xx xx 38 4a
		ADD	{sword}[bx][di+2], -20h	; 83 41 02 e0

		AND	dh, farbytevar[bx]	; 26 22 b7 xx xx
		AND	si, stackwordvar[bp]	; 23 b6 xx xx
		AND	cs:wordvar, cx		; 2e 21 0e xx xx
		AND	bytevar, dl		; 20 16 xx xx
		AND	al, 3			; 24 03
		AND	ax, 201h		; 25 01 02
		AND	bx, -1			; 83 e3 ff
		AND	bytevar, NOT 3		; 80 26 xx xx fc
		AND	{word}[bx+di][800], 100h; 81 a1 20 03 00 01

		.286p
		ARPL	bx, si			; 63 f3
		ARPL	farwordvar, ax		; 26 63 06 xx xx
		.186
		BOUND	ax, dwordvar		; 62 06 xx xx
		.8086
		CALL	nearproc		; e8 xx xx
		CALL	farproc			; 0e e8 xx xx
		CALL	reallyfarproc		; 9a xx xx xx xx
		CALL	bx			; ff d3
		CALL	stackdwordvar[bx+si]	; 36 ff 98 xx xx
		CBW				; 98
		CLC				; f8
		CLD				; fc
		.ioenable
		CLI				; fa
		.286p
		CLTS				; 0f 06
		.8086
		CMC				; f5

		CMP	dh, farbytevar[bx]	; 26 3a b7 xx xx
		CMP	si, stackwordvar[bp]	; 3b b6 xx xx
		CMP	cs:wordvar, cx		; 2e 39 0e xx xx
		CMP	bytevar, dl		; 38 16 xx xx
		CMP	al, 3			; 3c 03
		CMP	ax, 201h		; 3d 01 02
		CMP	bx, -1			; 83 fb ff
		CMP	bytevar, NOT 3		; 80 3e xx xx fc
		CMP	{word}[bx+di][800], 100h; 81 b9 20 03 00 01

		CMPSB				; a6
		CMPSW				; a7
		CMPS	ss:[si], {word}es:[di]	; 36 a7
		CMPSB	es:			; 26 a6

		CWD				; 99
		DAA				; 27
		DAS				; 2f
		DEC	cx			; 49
		DEC	[bx]			; fe 0f + warning
		DEC	{word}cs:[bp+si]	; 2e ff 0a
		DIV	cx			; f7 f1
		DIV	farbytevar		; 26 f6 36 xx xx
		.186
		ENTER	16, 0			; c8 10 00 00
		.286p
		HLT				; f4
		IDIV	cx			; f7 f9
		IDIV	farbytevar		; 26 f6 3e xx xx
		
		IMUL	cx			; f7 e9
		IMUL	farbytevar		; 26 f6 2e xx xx
		;IMUL	ax, 3			;; 6b c0 03
		;IMUL	ax, wordvar, 200h	;; 69 06 00 02
		
		.ioenable
		IN	al, dx			; ec
		IN	al, 20h			; e4 20
		IN	ax, dx			; ed
		IN	ax, 80h			; e5 80
		
		INC	cx			; 41
		INC	[bx]			; fe 07 + warning
		INC	{word}cs:[bp+si]	; 2e ff 02
		
		INSB				; 6c
		INSW				; 6d
		
		;INS	{word}es:[di]		;; 6d
		;INS	farbytevar		;; 6c
		
		INT	3			; cc
		INT	21h			; cd 21h
		INTO				; ce
		IRET				; cf

		JA	jccgoal			; 77 xx
		JAE	jccgoal			; 73 xx
		JB	jccgoal			; 72 xx
		JBE	jccgoal			; 76 xx
		JC	jccgoal			; 72 xx
		JC	farproc			; 73 03 e9 xx xx + warning
		JCXZ	jccgoal			; e3 xx
		JE	jccgoal			; 74 xx
		JE	reallyfarproc		; 75 05 ea xx xx xx xx + warn
		JG	jccgoal			; 7f xx
		JGE	jccgoal			; 7d xx
		JL	jccgoal			; 7c xx
		JLE	jccgoal			; 7e xx
		JNA	jccgoal			; 76 xx
		JNAE	jccgoal			; 72 xx
		JNB	jccgoal			; 73 xx
		JNBE	jccgoal			; 77 xx
		JNC	jccgoal			; 73 xx
		JNE	jccgoal			; 75 xx
		JNG	jccgoal			; 7e xx
		JNGE	jccgoal			; 7c xx
		JNL	jccgoal			; 7d xx
		JNLE	jccgoal			; 7f xx
		JNO	jccgoal			; 71 xx
		JNP	jccgoal			; 7b xx
		JNS	jccgoal			; 79 xx
		JNZ	jccgoal			; 75 xx
		JO	jccgoal			; 70 xx
		JP	jccgoal			; 7a xx
		JPE	jccgoal			; 7a xx
		JPO	jccgoal			; 7b xx
		JS	jccgoal			; 78 xx
		JZ	jccgoal			; 74 xx
		JMP	nearproc		; e9 xx xx
		JMP	farproc			; e9 xx xx
		JMP	reallyfarproc		; ea xx xx xx xx
		JMP	jccgoal			; eb xx
jccgoal:
		JMP	ax			; ff e0
		JMP	dwordvar		; ff 2e xx xx		

		LAHF				; 9f
		LAR	ax, wordvar		; 0f 02 06 xx xx
		LDS	si, fardwordvar		; 26 c5 36 xx xx
		LES	di, {dword}[bx][si]	; c4 38
		LEA	bx, wordvar		; bb xx xx
		LEA	si, [bp+3]		; 8d 76 03
		.186
		LEAVE				; c9
		.286p
		LGDT	[si]			; 0f 01 14
		LIDT	dwordvar		; 0f 01 1e xx xx
		LLDT	ax			; 0f 00 d0
		LMSW	[bp][si][18]		; 0f 01 72 12
		LOCK	INC	{word}cs:[bp+si]; f0 2e ff 02
		
		LODSB				; ac
		LODSW				; ad
		LODS	bytevar			; ac
		LODS	farwordvar		; 26 ad
		LODSB	ss:			; 36 ac

looplabel:
		LOOP	looplabel		; e2 fe
		LOOPE	looplabel		; e1 fc
		LOOPNE	looplabel		; e0 fa
		LOOPZ	looplabel		; e1 f8
		LOOPNZ	looplabel		; e0 f6
		.286p
		LSL	ax, stackwordvar	; 36 0f 03 06 xx xx
		LTR	cx			; 0f 00 d9
		.8086
		MOV	wordvar, bx		; 89 1e xx xx
		MOV	[bx], al		; 88 07
		MOV	si, [bx][si]		; 8b 30
		MOV	dl, [bp]		; 8a 56 00
		MOV	wordvar, es		; 8c 06 xx xx
		MOV	ds, ax			; 8e d8
		MOV	ax, wordvar		; a1 xx xx
		MOV	al, farbytevar		; 26 a0 xx xx
		MOV	si, 4			; be 04 00
		MOV	dh, -3			; b6 fd
		MOV	type wordvar ptr [bx], 3; c7 07 03 00
		MOV	{byte}[bp-4], 'a'	; c6 46 fc 61

		MOVSB				; a4
		MOVSW				; a5
		MOVS	{word}es:[di], ss:[si]	; 36 a5
		MOVSB	es:			; 26 a4

		MUL	ax			; f7 e0
		MUL	bytevar			; f6 26 xx xx

		NEG	[bx]			; f6 1f + warning
		NEG	farwordvar		; 26 f7 1e xx xx
		
		NOP				; 90

		NOT	[bx]			; f6 17 + warning
		NOT	farwordvar		; 26 f7 16 xx xx
		
		OR	dh, farbytevar[bx]	; 26 0a b7 xx xx
		OR	si, stackwordvar[bp]	; 0b b6 xx xx
		OR	cs:wordvar, cx		; 2e 09 0e xx xx
		OR	bytevar, dl		; 08 16 xx xx
		OR	al, 3			; 0c 03
		OR	ax, 201h		; 0d 01 02
		OR	bx, -1			; 83 cb ff
		OR	bytevar, NOT 3		; 80 0e xx xx fc
		OR	{word}[bx+di][800], 100h; 81 89 20 03 00 01
		
		.ioenable
		OUT	dx, al			; ee
		OUT	dx, ax			; ef
		OUT	20h, al			; e6 20
		OUT	80h, ax			; e7 80
		
		.186
		OUTSB				; 6e
		OUTSW				; 6f
		OUTSB	es:			; 26 6e
		;OUTS	wordvar			;; 6f
		;OUTS	farbytevar		;; 26 6e
		.8086

		POP	ss			; 17
		POP	stackwordvar		; 36 8f 06 xx xx
		POP	ax			; 58
		
		.186
		POPA				; 61
		.8086
		POPF				; 9d
		
		PUSH	ss			; 16
		PUSH	wordvar			; ff 36 xx xx
		PUSH	bx			; 53
		.186
		PUSH	3			; 6a 03
		PUSH	256			; 68 00 01
		PUSHA				; 60
		.8086
		PUSHF				; 9c

		.186		; For immediate shifts > 1
		
		ROL	ax, 1			; d1 c0
		ROL	ax			; d1 c0
		ROL	wordvar, cl		; d3 06 xx xx
		ROL	{word}[bx], 3		; c1 07 03

		ROR	ax, 1			; d1 c8
		ROR	ax			; d1 c8
		ROR	wordvar, cl		; d3 0e xx xx
		ROR	{word}[bx], 3		; c1 0f 03

		RCL	ax, 1			; d1 d0
		RCL	ax			; d1 d0
		RCL	wordvar, cl		; d3 16 xx xx
		RCL	{word}[bx], 3		; c1 17 03

		RCR	ax, 1			; d1 d8
		RCR	ax			; d1 d8
		RCR	wordvar, cl		; d3 1e xx xx
		RCR	{word}[bx], 3		; c1 1f 03

		; leave .186 on for INSB/OUTSB
		.ioenable

		REP	MOVSB			; f3 a4
		REP	STOSW			; f3 ab
		REP	INSB			; f3 6c
		REP	OUTSW ss:		; f3 36 6f
		
		REPE	CMPS stackwordvar, farwordvar; f3 36 a7
		REPE	SCASB			; f3 ae
		
		REPZ	CMPS stackwordvar, farwordvar; f3 36 a7
		REPZ	SCASB			; f3 ae

		REPNE	CMPS stackwordvar, farwordvar; f2 36 a7
		REPNE	SCASB			; f2 ae
		
		REPNZ	CMPS stackwordvar, farwordvar; f2 36 a7
		REPNZ	SCASB			; f2 ae

		RETN				; c3
		RETN	4			; c2 04 00
		RETF				; cb
		RETF	1024			; ca 00 04

		SAHF				; 9e

		SHL	ax, 1			; d1 e0
		SHL	ax			; d1 e0
		SHL	wordvar, cl		; d3 26 xx xx
		SHL	{word}[bx], 3		; c1 27 03

		SHR	ax, 1			; d1 e8
		SHR	ax			; d1 e8
		SHR	wordvar, cl		; d3 2e xx xx
		SHR	{word}[bx], 3		; c1 2f 03

		SAL	ax, 1			; d1 e0
		SAL	ax			; d1 e0
		SAL	wordvar, cl		; d3 26 xx xx
		SAL	{word}[bx], 3		; c1 27 03

		SAR	ax, 1			; d1 f8
		SAR	ax			; d1 f8
		SAR	wordvar, cl		; d3 3e xx xx
		SAR	{word}[bx], 3		; c1 3f 03

		.8086

		SBB	dh, farbytevar[bx]	; 26 1a b7 xx xx
		SBB	si, stackwordvar[bp]	; 1b b6 xx xx
		SBB	cs:wordvar, cx		; 2e 19 0e xx xx
		SBB	bytevar, dl		; 18 16 xx xx
		SBB	al, 3			; 1c 03
		SBB	ax, 201h		; 1d 01 02
		SBB	bx, -1			; 83 db ff
		SBB	bytevar, NOT 3		; 80 1e xx xx fc
		SBB	{word}[bx+di][800], 100h; 81 99 20 03 00 01

		SCASB				; ae
		SCASW				; af
		SCAS	farbytevar		; ae
		SCAS	farwordvar		; af

		.286p
		SGDT	dwordvar		; 0f 01 06 xx xx
		SIDT	fardwordvar		; 26 0f 01 0e xx xx
		SLDT	bx			; 0f 00 c3
		SMSW	farwordvar[bx]		; 26 0f 01 a7 xx xx
		
		.8086
		STC				; f9
		STD				; fd
		
		.ioenable
		STI				; fb
		.8086

		STOSB				; aa
		STOSW				; ab
		STOS	farbytevar		; aa
		STOS	farwordvar		; ab

		.286p
		STR	{word}[bp]		; 0f 00 4e 00
		.8086

		SUB	dh, farbytevar[bx]	; 26 2a b7 xx xx
		SUB	si, stackwordvar[bp]	; 2b b6 xx xx
		SUB	cs:wordvar, cx		; 2e 29 0e xx xx
		SUB	bytevar, dl		; 28 16 xx xx
		SUB	al, 3			; 2c 03
		SUB	ax, 201h		; 2d 01 02
		SUB	bx, -1			; 83 eb ff
		SUB	bytevar, NOT 3		; 80 2e xx xx fc
		SUB	{word}[bx+di][800], 100h; 81 a9 20 03 00 01

		TEST	dh, farbytevar[bx]	; 26 84 b7 xx xx
		TEST	si, stackwordvar[bp]	; 85 b6 xx xx
		TEST	cs:wordvar, cx		; 2e 85 0e xx xx
		TEST	bytevar, dl		; 84 16 xx xx
		TEST	al, 3			; a8 03
		TEST	ax, 201h		; a9 01 02
		TEST	bytevar, NOT 3		; f6 06 xx xx fc
		TEST	NOT 3, bytevar		; f6 06 xx xx fc	
		TEST	{word}[bx+di][800], 100h; f7 81 20 03 00 01
		TEST	100h, {word}[bx+di][800]; f7 81 20 03 00 01

		.286p
		VERR	bx			; 0f 00 e3
		VERW	word ptr [es:bx+di]	; 26 0f 00 29

		WAIT				; 9b

		XCHG	ax, bx			; 93
		XCHG	cx, ax			; 91
		XCHG	farbytevar, dl		; 26 86 16 xx xx
		XCHG	dx, stackwordvar	; 36 87 16 xx xx

		XLAT	stackbytevar		; 36 d7
		XLATB				; d7
		cs:XLATB			; 2e d7

		XOR	dh, farbytevar[bx]	; 26 32 b7 xx xx
		XOR	si, stackwordvar[bp]	; 33 b6 xx xx
		XOR	cs:wordvar, cx		; 2e 31 0e xx xx
		XOR	bytevar, dl		; 30 16 xx xx
		XOR	al, 3			; 34 03
		XOR	ax, 201h		; 35 01 02
		XOR	bx, -1			; 83 f3 ff
		XOR	bytevar, NOT 3		; 80 36 xx xx fc
		XOR	{word}[bx+di][800], 100h; 81 b1 20 03 00 01

		ret
main		endp

biff		ends
