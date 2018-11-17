COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		kerr
FILE:		app.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains a kerr application

	$Id: kerr.asm,v 1.1 97/04/04 16:58:23 newdeal Exp $

------------------------------------------------------------------------------@

;
; Standard include files
;
include	geos.def
include	heap.def
include geode.def
include resource.def
include	ec.def
include system.def

include object.def
include	graphics.def
include	win.def
include lmem.def
include timer.def
include Objects/processC.def	; need for ui.def

include localize.def	; for Resources file

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def

;------------------------------------------------------------------------------
;			Resource Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

kerr_ProcessClass	class GenProcessClass

MSG_KERR_HANDLE_TABLE_FULL		message
MSG_KERR_LOW_ON_HANDLES		message
MSG_KERR_ILLEGAL_HANDLE		message
MSG_KERR_FATAL_ERROR			message
MSG_KERR_UNRECOVERABLE_ERROR		message
MSG_KERR_MEMORY_FULL			message

MSG_KERR_DIVIDE_0			message
MSG_KERR_OVERFLOW			message
MSG_KERR_BOUND			message
MSG_KERR_FPU				message
MSG_KERR_SINGLE_STEP			message
MSG_KERR_ILLEGAL_INSTRUNCTION	message
MSG_KERR_PROTECTION_FAULT	message
MSG_KERR_STACK_EXCEPTION	message

MSG_KERR_DIVIDE_0_REAL			message
MSG_KERR_OVERFLOW_REAL			message
MSG_KERR_BOUND_REAL			message
MSG_KERR_SINGLE_STEP_REAL		message
MSG_KERR_BREAKPOINT_REAL		message
MSG_KERR_ILLEGAL_INSTRUCTION_REAL	message
MSG_KERR_PROTECTION_FAULT_REAL		message
MSG_KERR_STACK_EXCEPTION_REAL		message

MSG_KERR_SET_NOTIFY_FLAGS	message
;	cx	= new SysNotifyFlags

MSG_KERR_SYS_NOTIFY_1		message
MSG_KERR_SYS_NOTIFY_2		message
kerr_ProcessClass	endc

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		kerr.rdef

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

	kerr_ProcessClass	mask CLASSF_NEVER_SAVED

idata	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

CommonCode segment resource

;---

KerrHandleTableFull	method dynamic	kerr_ProcessClass,
					MSG_KERR_HANDLE_TABLE_FULL
	mov	bx, handle 0
	mov	ax, MSG_META_DUMMY
deathLoop:
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	deathLoop
KerrHandleTableFull	endm

;---

KerrLowOnHandles	method dynamic	kerr_ProcessClass,
					MSG_KERR_LOW_ON_HANDLES
	mov	bx, handle 0
	mov	ax, MSG_META_DUMMY
lowLoop:
	mov	di, mask MF_CAN_DISCARD_IF_DESPERATE or mask MF_FORCE_QUEUE
	call	ObjMessage
	jnc	lowLoop

	ret
KerrLowOnHandles	endm

;---

KerrIllegalHandle	method dynamic	kerr_ProcessClass,
					MSG_KERR_ILLEGAL_HANDLE
	mov	bx, 0x1234
	call	MemLock
	ret
KerrIllegalHandle	endm

;---

KerrFatalError	method dynamic	kerr_ProcessClass, MSG_KERR_FATAL_ERROR
	ERROR	0x1234
KerrFatalError	endm

;---

KerrUnrecoverableError	method dynamic	kerr_ProcessClass,
					MSG_KERR_UNRECOVERABLE_ERROR
	mov	dx, offset fooFile
	mov	al, FileAccessFlags <FE_EXCLUSIVE,FA_READ_WRITE>
	mov	ah, FILE_CREATE_TRUNCATE
	clr	cx
	call	FileCreate		;ax = handle

	mov	bx, ax
	mov	al, FILE_NO_ERRORS
	mov	cx, 1000
	call	FileRead

	ret
KerrUnrecoverableError	endm

idata	segment
fooFile	char	"foo",0
idata	ends

;---

KerrMemoryFull	method dynamic	kerr_ProcessClass, MSG_KERR_MEMORY_FULL

deathLoop:
	mov	ax, 20000
	mov	cx, ALLOC_FIXED or (mask HAF_NO_ERR shl 8)
	call	MemAlloc
	jmp	deathLoop

KerrMemoryFull	endm

;---

KerrDivide0	method dynamic	kerr_ProcessClass, MSG_KERR_DIVIDE_0
	int	0
	ret
KerrDivide0	endm

;---

KerrOverflow	method dynamic	kerr_ProcessClass, MSG_KERR_OVERFLOW
	int	4
	ret
KerrOverflow	endm

;---

KerrBound	method dynamic	kerr_ProcessClass, MSG_KERR_BOUND
	int	5
	ret
KerrBound	endm

;---

KerrFPU	method dynamic	kerr_ProcessClass, MSG_KERR_FPU
	int	2
	ret
KerrFPU	endm

;---

KerrSingleStep	method dynamic	kerr_ProcessClass, MSG_KERR_SINGLE_STEP
	int	1
	ret
KerrSingleStep	endm

;---

KerrIllegalInstrunction	method dynamic	kerr_ProcessClass,
					MSG_KERR_ILLEGAL_INSTRUNCTION
	int	6
	ret
KerrIllegalInstrunction	endm

;---

KerrProtectionFault	method dynamic	kerr_ProcessClass,
					MSG_KERR_PROTECTION_FAULT
	int	13
	ret
KerrProtectionFault	endm

;---

KerrStackException	method dynamic	kerr_ProcessClass,
					MSG_KERR_STACK_EXCEPTION
	int	12
	ret
KerrStackException	endm

;---

KerrDivide0Real	method dynamic	kerr_ProcessClass, MSG_KERR_DIVIDE_0_REAL

	clr	cl
	div	cl

	ret
KerrDivide0Real	endm

;---

KerrOverflowReal	method dynamic	kerr_ProcessClass,
						MSG_KERR_OVERFLOW_REAL

	mov	al, 40h
	shl	al			; OF set
	into

	ret
KerrOverflowReal	endm

;---

bounds	sword	1, 2

KerrBoundReal	method dynamic	kerr_ProcessClass, MSG_KERR_BOUND_REAL

	clr	ax
	bound	ax, cs:[bounds]

	ret
KerrBoundReal	endm

;---

KerrSingleStepReal	method dynamic	kerr_ProcessClass,
						MSG_KERR_SINGLE_STEP_REAL

	pushf
	pop	ax
	BitSet	ax, CPU_TRAP
	push	ax
	popf
	nop

	ret
KerrSingleStepReal	endm

;---

KerrBreakpointReal	method dynamic	kerr_ProcessClass,
						MSG_KERR_BREAKPOINT_REAL

	nop
	int	3

	ret
KerrBreakpointReal	endm

;---

KerrIllegalInstructionReal	method dynamic	kerr_ProcessClass,
					MSG_KERR_ILLEGAL_INSTRUCTION_REAL

	; "LOCK CMP AX, AX", illegal prefix use for this instruction.  This
	; raises an exception only on 386 processors or above.
	.inst	db 0xf0 | cmp	ax, ax

	ret
KerrIllegalInstructionReal	endm

;---

KerrProtectionFaultReal	method dynamic	kerr_ProcessClass,
					MSG_KERR_PROTECTION_FAULT_REAL

	; Operand crossing offset 65536, using general segment reg.  (This
	; might not cause a fault to us if HIMEM.SYS is loaded but EMM386.EXE
	; is not.  I don't know why.)
	segmov	ds, 0x8000		; just somewhere such that ds:0xffff
					;  is valid as far as the processor
					;  is concerned.
	mov	ax, {word} ds:[0xffff]

	; Instruction longer than 15 bytes.  Here we use 12 LOCK prefixes,
	; plus a 4-byte instruction which by itself is a valid instruction
	; to be used with LOCK and accesses valid memory.  (This causes a
	; fault to us even when HIMEM.SYS is loaded.)
	mov	bp, sp
	.inst	db	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0,
			0xf0, 0xf0, 0xf0, 0xf0
	or	{byte} ss:[bp], 0	; 4 bytes

	ret
KerrProtectionFaultReal	endm

;---

KerrStackExceptionReal	method dynamic	kerr_ProcessClass,
					MSG_KERR_STACK_EXCEPTION_REAL

	; Operand crossing offset 65536, using stack segment reg.  (This
	; might not cause a fault to us if HIMEM.SYS is loaded.)
	mov	ax, {word} ss:[0xffff]

	ret
KerrStackExceptionReal	endm

;---

udata	segment
notifyFlags	SysNotifyFlags <>
udata	ends

idata 	segment
string1	char	"String # 1", 0
string2 char	"String # 2", 0
idata	ends

KerrSetNotifyFlags method dynamic kerr_ProcessClass,
					MSG_KERR_SET_NOTIFY_FLAGS
	mov	ds:[notifyFlags], cx
	ret
KerrSetNotifyFlags endm

KerrSysNotify1 method dynamic kerr_ProcessClass,
					MSG_KERR_SYS_NOTIFY_1
	mov	ax, ds:[notifyFlags]
	mov	si, offset string1
	clr	di
	call	SysNotify
	ret
KerrSysNotify1 endm

KerrSysNotify2 method dynamic kerr_ProcessClass,
					MSG_KERR_SYS_NOTIFY_2
	mov	ax, ds:[notifyFlags]
	mov	si, offset string1
	mov	di, offset string2
	call	SysNotify
	ret
KerrSysNotify2 endm

CommonCode	ends

end
