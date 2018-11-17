include stdapp.def
include vm.def
include objects\gCtrlC.def
include library.def
include resource.def    ; idata/udata, ProcCallFixedOrMovable etc.
include gstring.def

UseLib math.def


include Internal/heapInt.def

ErrorHandlerContext	struct
	EHC_ss	word
	EHC_ds	word
	EHC_es	word
	EHC_di	word
	EHC_si	word
	EHC_cs	word
	EHC_ip	word
	EHC_sp	word
	EHC_bp	word
	EHC_stackBot	word
ErrorHandlerContext	ends

global _set_error_handler:far


	SetDefaultConvention

; WARNING: THIS ROUTINE MUST BE LOCATED IN A FIXED RESOURCE!  RCI WILL SCREW
; UP THE ALGORITHM IF IT OCCURS BETWEEN THIS ROUTINE AND ITS CALLER!
; Thanks for your cooperation. -Dave

ASM_FIXED  		segment resource

_set_error_handler	proc far	errorContextP:fptr.word
		uses	es, di
		.enter
		mov	ax, size ErrorHandlerContext
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		tst	bx
		jz	returnMem
		mov	cx, es		; original ES
		mov	es, ax
		clr	ax
		mov	es:[EHC_ss], ss
		mov	es:[EHC_ds], ds
		mov	es:[EHC_es], cx
		mov	es:[EHC_di], di
		mov	es:[EHC_si], si
		mov	ax, ss:[bp]	; caller's BP
		mov	es:[EHC_bp], ax
		mov	ax, ss:[bp]+2	; return off
		mov	es:[EHC_ip], ax
		mov	ax, ss:[bp]+4	; return seg
		mov	es:[EHC_cs], ax
		mov	ax, bp
		add	ax, 2		; SP to return to caller
		mov	es:[EHC_sp], ax
		mov	ax, ss:[TPD_stackBot]
		mov	es:[EHC_stackBot], ax
		call	MemUnlock
returnMem:
		mov	es, errorContextP.segment
		mov	di, errorContextP.offset
		mov	es:[di], bx
		mov	ax, 0			; error handler set
		.leave
		ret
_set_error_handler	endp

	SetGeosConvention

ASM_FIXED                ends
