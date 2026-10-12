include stdapp.def
include vm.def
include library.def
include resource.def
include graphics.def

imp_TEXT segment public 'CODE'
		extrn	IMPORTPROCEDURE: far
		extrn	TESTFILE: far
imp_TEXT ends

global LibraryEntry: far
global TransExport: far
global TransImport: far
global TransGetFormat: far
global TransGetImportUI: far
global TransGetExportUI: far
global TransInitImportUI: far
global TransInitExportUI: far
global TransGetImportOptions: far
global TransGetExportOptions: far

INIT segment resource
		assume	cs:INIT

		db	"OK"
		dw	InfoResource
		dw	1
		dw	4000h
		db	"OK"

LibraryEntry proc far
		clc
		ret
LibraryEntry endp

INIT ends

InfoResource segment lmem LMEM_TYPE_GENERAL, mask LMF_IN_RESOURCE

		dw	fmtName, fmtMask
		D_OPTR	0
		D_OPTR	0
		dw	8000h
		dw	0

fmtName chunk char
		char	"WebP", 0
fmtName endc

fmtMask chunk char
		char	"*.web", 0
fmtMask endc

InfoResource ends

ASM segment resource
		assume	cs:ASM

TransExport proc far
		mov	ax, 4		; TE_EXPORT_NOT_SUPPORTED
		clr	bx
		ret
TransExport endp

TransImport proc far
	uses	es, ds, si, di
vmChain	local	dword
	.enter
		push	ds
		push	si
		push	ss
		lea	ax, vmChain
		push	ax
		mov	ax, idata
		mov	ds, ax
		call	IMPORTPROCEDURE
		mov	bx, dx
		movdw	dxcx, vmChain
	.leave
		ret
TransImport endp

TransGetFormat proc far
	uses	es, ds, si, di
	.enter
		push	si
		mov	ax, idata
		mov	ds, ax
		call	TESTFILE
		mov	cx, ax
		clr	ax
	.leave
		ret
TransGetFormat endp

TransGetImportUI proc far
		clr	ax
		clr	bx
		clr	cx
		clr	dx
		ret
TransGetImportUI endp

TransGetExportUI proc far
		clr	ax
		clr	bx
		clr	cx
		clr	dx
		ret
TransGetExportUI endp

TransGetImportOptions proc far
		clr	dx
		ret
TransGetImportOptions endp

TransGetExportOptions proc far
		clr	dx
		ret
TransGetExportOptions endp

TransInitImportUI proc far
		ret
TransInitImportUI endp

TransInitExportUI proc far
		ret
TransInitExportUI endp

ASM ends
