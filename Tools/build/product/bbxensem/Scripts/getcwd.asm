_TEXT segment para public 'CODE'
assume cs:_TEXT, ds:_TEXT, es:_TEXT, ss:_TEXT

org 100h

; GETCWD.COM
; Given the batch path (%0) and an output batch filename, write:
;   SET GEOS_DIST_DIR=<fully qualified directory of gsetup.bat>
;
; Usage:
;   GETCWD <gsetup-path> <output-batch-file>

MAX_PATH_CHARS	equ	127

public _start

_start:
		; COM program setup.
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

		; Parse two arguments from command tail.
		call	ParseArgs
		jc	ExitError

		; Canonicalize script path to full DOS path.
		call	ResolveScriptPath
		jc	ExitError

		; Strip trailing "\GSETUP.BAT" to produce GEOS_DIST_DIR.
		call	ExtractDirectory
		jc	ExitError

		; Create output batch and emit one SET line.
		call	CreateOutputFile
		jc	ExitError

		lea	dx, setPrefix
		call	WriteCString
		jc	WriteError

		lea	dx, geosDistDir
		call	WriteCString
		jc	WriteError

		lea	dx, lineEnd
		call	WriteCString
		jc	WriteError

		call	CloseOutputFile
		jc	ExitError

		mov	ax, 4c00h
		int	21h

WriteError:
		call	CloseOutputFile

ExitError:
		mov	ax, 4c01h
		int	21h


ParseArgs:
		push	ax
		push	cx
		push	si
		push	di

		xor	cx, cx
		mov	cl, byte ptr ds:[80h]
		jcxz	ParseFail

		lea	si, ds:[81h]

		call	SkipWhitespace
		lea	di, scriptArg
		call	CopyToken
		jc	ParseFail

		call	SkipWhitespace
		lea	di, outBatArg
		call	CopyToken
		jc	ParseFail

		clc
		jmp	ParseDone

ParseFail:
		stc

ParseDone:
		pop	di
		pop	si
		pop	cx
		pop	ax
		ret


SkipWhitespace:
SkipWhitespaceLoop:
		jcxz	SkipWhitespaceDone
		mov	al, byte ptr [si]
		cmp	al, ' '
		je	SkipWhitespaceAdvance
		cmp	al, 9
		je	SkipWhitespaceAdvance
		cmp	al, 0dh
		je	SkipWhitespaceDone
		jmp	SkipWhitespaceDone

SkipWhitespaceAdvance:
		inc	si
		dec	cx
		jmp	SkipWhitespaceLoop

SkipWhitespaceDone:
		ret


CopyToken:
		push	bx

		xor	bx, bx

CopyTokenLoop:
		jcxz	CopyTokenDone
		mov	al, byte ptr [si]
		cmp	al, ' '
		je	CopyTokenDone
		cmp	al, 9
		je	CopyTokenDone
		cmp	al, 0dh
		je	CopyTokenDone
		cmp	bl, MAX_PATH_CHARS
		jae	CopyTokenOverflow

		stosb
		inc	si
		dec	cx
		inc	bl
		jmp	CopyTokenLoop

CopyTokenDone:
		mov	al, 0
		stosb
		cmp	bl, 0
		je	CopyTokenEmpty
		clc
		jmp	CopyTokenExit

CopyTokenOverflow:
		stc
		jmp	CopyTokenExit

CopyTokenEmpty:
		stc

CopyTokenExit:
		pop	bx
		ret


ResolveScriptPath:
		push	ax
		push	si
		push	di

		lea	si, scriptArg
		lea	di, scriptFull
		mov	ax, 6000h
		int	21h
		jc	ResolveFail

		clc
		jmp	ResolveDone

ResolveFail:
		stc

ResolveDone:
		pop	di
		pop	si
		pop	ax
		ret


ExtractDirectory:
		push	ax
		push	si
		push	di

		lea	si, scriptFull
		lea	di, geosDistDir

CopyPathLoop:
		lodsb
		stosb
		or	al, al
		jnz	CopyPathLoop

		dec	di
		cmp	di, offset geosDistDir
		jb	ExtractFail

FindSlashLoop:
		cmp	byte ptr [di], '\'
		je	FoundSlash
		cmp	byte ptr [di], '/'
		je	FoundSlash
		cmp	di, offset geosDistDir
		je	ExtractFail
		dec	di
		jmp	FindSlashLoop

FoundSlash:
		mov	ax, di
		sub	ax, offset geosDistDir
		cmp	ax, 2
		jne	FoundNonRoot
		cmp	byte ptr geosDistDir+1, ':'
		jne	FoundNonRoot
		mov	byte ptr [di+1], 0
		clc
		jmp	ExtractDone

FoundNonRoot:
		mov	byte ptr [di], 0
		clc
		jmp	ExtractDone

ExtractFail:
		stc

ExtractDone:
		pop	di
		pop	si
		pop	ax
		ret


CreateOutputFile:
		push	cx
		push	dx

		lea	dx, outBatArg
		xor	cx, cx
		mov	ah, 3ch
		int	21h
		jc	CreateFail

		mov	word ptr outHandle, ax
		clc
		jmp	CreateDone

CreateFail:
		stc

CreateDone:
		pop	dx
		pop	cx
		ret


CloseOutputFile:
		push	ax
		push	bx

		mov	bx, word ptr outHandle
		cmp	bx, 0ffffh
		je	CloseDone

		mov	ah, 3eh
		int	21h
		mov	word ptr outHandle, 0ffffh
		jc	CloseFail

CloseDone:
		clc
		jmp	CloseExit

CloseFail:
		stc

CloseExit:
		pop	bx
		pop	ax
		ret


WriteCString:
		push	ax
		push	bx
		push	cx
		push	dx
		push	si

		mov	si, dx
		xor	cx, cx

WriteLenLoop:
		mov	al, byte ptr [si]
		or	al, al
		jz	WriteLenDone
		inc	si
		inc	cx
		jmp	WriteLenLoop

WriteLenDone:
		mov	bx, word ptr outHandle
		mov	ah, 40h
		int	21h
		jc	WriteFail
		cmp	ax, cx
		jne	WriteFail

		clc
		jmp	WriteDone

WriteFail:
		stc

WriteDone:
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret


outHandle	dw	0ffffh

scriptArg	db	MAX_PATH_CHARS+1 dup (0)
outBatArg	db	MAX_PATH_CHARS+1 dup (0)
scriptFull	db	MAX_PATH_CHARS+1 dup (0)
geosDistDir	db	MAX_PATH_CHARS+1 dup (0)

setPrefix	db	'SET GEOS_DIST_DIR=', 0
lineEnd		db	13, 10, 0

_TEXT ends
end _start
