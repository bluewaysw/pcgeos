_TEXT segment para public 'CODE'
assume cs:_TEXT, ds:_TEXT, es:_TEXT, ss:_TEXT

org 100h

; GSETUP.COM
; Launcher for GSETUP.BAT.
; Resolves the launcher's own directory and executes:
;   %COMSPEC% /C <dir>\gsetup.bat <dir> <original args>
;
; Notes:
; - We shrink our memory block before EXEC because COM programs
;   initially own almost all DOS memory.
; - We first derive GEOS_DIST_DIR from current drive+directory and append
;   "FREEGEOS\60BETA". If that fails, we fall back to environment-trailer
;   executable-path extraction for compatibility.
; - The DOS environment trailer layout varies, so path extraction
;   probes multiple candidate offsets.

MAX_PATH_CHARS	equ	127
CMD_TAIL_MAX	equ	127

public _start

_start:
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		cli
		mov	ss, ax
		mov	sp, offset stackTop
		sti

		call	ShrinkMemoryForExec

		call	BuildGeosDistDirFromCwd
		jnc	GeosDistDirReady

		call	GetProgramPathFromEnv
		jc	ExitError

		call	ExtractDirectory
		jc	ExitError

GeosDistDirReady:
		call	BuildBatchPath
		jc	ExitError

		call	ResolveComspecPath
		jc	ExitError

		call	BuildCommandTail
		jc	ExitError

		call	ExecComspec
		jc	ExitError

		mov	ah, 4dh
		int	21h
		mov	ah, 4ch
		int	21h

ExitError:
		mov	dx, offset msgError
		mov	ah, 09h
		int	21h
		mov	ax, 4c01h
		int	21h


; COM programs start owning almost all free DOS memory.
; Shrink our block so COMMAND.COM can be EXECed reliably.
ShrinkMemoryForExec:
		push	ax
		push	bx

		mov	bx, offset programEnd
		add	bx, 15
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1

		mov	ah, 4ah
		int	21h

		pop	bx
		pop	ax
		ret


; Build "<drive>:\<cwd>\FREEGEOS\60BETA" into geosDistDir.
; CWD is read from DOS and does not include drive letter.
BuildGeosDistDirFromCwd:
		push	ax
		push	bx
		push	dx
		push	si
		push	di

		lea	di, geosDistDir
		xor	bx, bx

		mov	ah, 19h
		int	21h
		add	al, 'A'

		cmp	bx, MAX_PATH_CHARS
		jae	BuildGeosDistFromCwdFail
		mov	byte ptr [di], al
		inc	di
		inc	bx

		cmp	bx, MAX_PATH_CHARS
		jae	BuildGeosDistFromCwdFail
		mov	byte ptr [di], ':'
		inc	di
		inc	bx

		cmp	bx, MAX_PATH_CHARS
		jae	BuildGeosDistFromCwdFail
		mov	byte ptr [di], '\'
		inc	di
		inc	bx

		lea	si, cwdPath
		mov	dl, 0
		mov	ah, 47h
		int	21h
		jc	BuildGeosDistFromCwdFail

		lea	si, cwdPath
		cmp	byte ptr [si], 0
		je	BuildGeosDistAppendSuffix

BuildGeosDistCopyCwd:
		mov	al, byte ptr [si]
		or	al, al
		jz	BuildGeosDistCwdDone
		cmp	bx, MAX_PATH_CHARS
		jae	BuildGeosDistFromCwdFail
		mov	byte ptr [di], al
		inc	di
		inc	si
		inc	bx
		jmp	BuildGeosDistCopyCwd

BuildGeosDistCwdDone:
		cmp	bx, MAX_PATH_CHARS
		jae	BuildGeosDistFromCwdFail
		mov	byte ptr [di], '\'
		inc	di
		inc	bx

BuildGeosDistAppendSuffix:
		lea	si, geosDistSuffix

BuildGeosDistSuffixLoop:
		mov	al, byte ptr [si]
		cmp	bx, MAX_PATH_CHARS
		jae	BuildGeosDistFromCwdFail
		mov	byte ptr [di], al
		inc	di
		inc	si
		inc	bx
		or	al, al
		jnz	BuildGeosDistSuffixLoop

		clc
		jmp	BuildGeosDistFromCwdDone

BuildGeosDistFromCwdFail:
		stc

BuildGeosDistFromCwdDone:
		pop	di
		pop	si
		pop	dx
		pop	bx
		pop	ax
		ret


; Copy full executable path from environment trailer into progPath.
; Different DOS variants place the path trailer differently, so try
; multiple offsets after the environment double-NULL.
GetProgramPathFromEnv:
		push	ax
		push	bx
		push	dx
		push	si
		push	di
		push	es

		mov	bx, word ptr ds:[2ch]
		or	bx, bx
		jz	GetProgramPathFail
		mov	es, bx
		xor	si, si

FindEnvEndLoop:
		mov	al, byte ptr es:[si]
		or	al, al
		jnz	FindEnvEndAdvance
		cmp	byte ptr es:[si+1], 0
		je	FoundEnvEnd

FindEnvEndAdvance:
		inc	si
		jmp	FindEnvEndLoop

FoundEnvEnd:
		add	si, 2
		mov	dx, si

		mov	si, dx
		add	si, 2
		call	CopyProgramPathCandidate
		jnc	GetProgramPathDone

		mov	si, dx
		call	CopyProgramPathCandidate
		jnc	GetProgramPathDone

		mov	si, dx
		add	si, 4
		call	CopyProgramPathCandidate
		jnc	GetProgramPathDone

		jmp	GetProgramPathFail

GetProgramPathDone:
		clc
		jmp	GetProgramPathExit

GetProgramPathFail:
		stc

GetProgramPathExit:
		pop	es
		pop	di
		pop	si
		pop	dx
		pop	bx
		pop	ax
		ret


; Copy one candidate executable path from ES:SI into progPath and validate.
CopyProgramPathCandidate:
		push	si
		push	di

		lea	di, progPath
		call	CopyEsStringToDs
		jc	CopyProgramPathFail

		lea	si, progPath
		call	PathLooksUsable
		jc	CopyProgramPathFail

		clc
		jmp	CopyProgramPathExit

CopyProgramPathFail:
		stc

CopyProgramPathExit:
		pop	di
		pop	si
		ret


; Accept only non-empty strings that look like paths.
; Require that basename is "gsetup.com" (case-insensitive).
PathLooksUsable:
		push	ax
		push	bx
		push	dx
		push	si

		xor	bx, bx
		mov	dx, si

PathLooksLoop:
		mov	al, byte ptr [si]
		or	al, al
		jz	PathLooksDone
		cmp	al, '\'
		je	PathLooksFound
		cmp	al, '/'
		je	PathLooksFound
		inc	si
		jmp	PathLooksLoop

PathLooksFound:
		lea	dx, [si+1]
		mov	bx, 1
		inc	si
		jmp	PathLooksLoop

PathLooksDone:
		cmp	bx, 0
		je	PathLooksFail

		mov	si, dx
		lea	bx, launcherName
		call	CompareCaseInsensitive
		jc	PathLooksFail

		clc
		jmp	PathLooksExit

PathLooksFail:
		stc

PathLooksExit:
		pop	si
		pop	dx
		pop	bx
		pop	ax
		ret


; Compare DS:SI with DS:BX case-insensitively until both hit NUL.
; CF=0 if equal, CF=1 if different.
CompareCaseInsensitive:
		push	ax
		push	dx

CompareLoop:
		mov	al, byte ptr [si]
		mov	dl, byte ptr [bx]

		cmp	al, 'a'
		jb	CompareAlReady
		cmp	al, 'z'
		ja	CompareAlReady
		sub	al, 20h

CompareAlReady:
		cmp	dl, 'a'
		jb	CompareDlReady
		cmp	dl, 'z'
		ja	CompareDlReady
		sub	dl, 20h

CompareDlReady:
		cmp	al, dl
		jne	CompareFail
		or	al, al
		jz	CompareOk
		inc	si
		inc	bx
		jmp	CompareLoop

CompareOk:
		clc
		jmp	CompareExit

CompareFail:
		stc

CompareExit:
		pop	dx
		pop	ax
		ret


; Strip executable filename from progPath into geosDistDir.
ExtractDirectory:
		push	ax
		push	bx
		push	si
		push	di

		lea	si, progPath
		lea	di, geosDistDir
		xor	bx, bx

ExtractCopyLoop:
		mov	al, byte ptr [si]
		mov	byte ptr [di], al
		inc	si
		inc	di
		or	al, al
		jz	ExtractCopyDone
		inc	bx
		cmp	bx, MAX_PATH_CHARS
		jae	ExtractFail
		jmp	ExtractCopyLoop

ExtractCopyDone:
		cmp	bx, 0
		je	ExtractFail
		dec	di
		dec	di

FindSlashLoop:
		cmp	di, offset geosDistDir
		jb	ExtractFail
		mov	al, byte ptr [di]
		cmp	al, '\'
		je	ExtractFoundSlash
		cmp	al, '/'
		je	ExtractFoundSlash
		dec	di
		jmp	FindSlashLoop

ExtractFoundSlash:
		mov	ax, di
		sub	ax, offset geosDistDir
		cmp	ax, 2
		jne	ExtractFoundNonRoot
		cmp	byte ptr geosDistDir+1, ':'
		jne	ExtractFoundNonRoot
		mov	byte ptr [di+1], 0
		clc
		jmp	ExtractDone

ExtractFoundNonRoot:
		mov	byte ptr [di], 0
		clc
		jmp	ExtractDone

ExtractFail:
		stc

ExtractDone:
		pop	di
		pop	si
		pop	bx
		pop	ax
		ret


; Build "<GEOS_DIST_DIR>\gsetup.bat" into batchPath.
BuildBatchPath:
		push	ax
		push	bx
		push	si
		push	di

		lea	si, geosDistDir
		lea	di, batchPath
		xor	bx, bx

BuildBatchCopyLoop:
		mov	al, byte ptr [si]
		or	al, al
		jz	BuildBatchCopied
		cmp	bx, MAX_PATH_CHARS
		jae	BuildBatchFail
		mov	byte ptr [di], al
		inc	si
		inc	di
		inc	bx
		jmp	BuildBatchCopyLoop

BuildBatchCopied:
		cmp	bx, 0
		je	BuildBatchFail

		mov	al, byte ptr [di-1]
		cmp	al, '\'
		je	BuildBatchAppendName
		cmp	al, '/'
		je	BuildBatchAppendName

		cmp	bx, MAX_PATH_CHARS
		jae	BuildBatchFail
		mov	byte ptr [di], '\'
		inc	di
		inc	bx

BuildBatchAppendName:
		lea	si, batchName

BuildBatchNameLoop:
		mov	al, byte ptr [si]
		cmp	bx, MAX_PATH_CHARS
		jae	BuildBatchFail
		mov	byte ptr [di], al
		inc	di
		inc	si
		inc	bx
		or	al, al
		jnz	BuildBatchNameLoop

		clc
		jmp	BuildBatchDone

BuildBatchFail:
		stc

BuildBatchDone:
		pop	di
		pop	si
		pop	bx
		pop	ax
		ret


; Resolve COMSPEC value from environment.
; If not found, leave comspecPath empty and let ExecComspec use fallbacks.
ResolveComspecPath:
		push	ax
		push	bx
		push	si
		push	di
		push	es

		mov	bx, word ptr ds:[2ch]
		or	bx, bx
		jz	ResolveFallback
		mov	es, bx
		xor	si, si

ResolveNextVar:
		mov	al, byte ptr es:[si]
		or	al, al
		jnz	ResolveCheck
		cmp	byte ptr es:[si+1], 0
		je	ResolveFallback
		inc	si
		jmp	ResolveNextVar

ResolveCheck:
		push	si
		lea	di, comspecKey
		call	MatchEnvPrefix
		pop	si
		jc	ResolveSkipVar

		add	si, 8
		lea	di, comspecPath
		call	CopyEsStringToDs
		jc	ResolveFallback
		clc
		jmp	ResolveDone

ResolveSkipVar:
		mov	al, byte ptr es:[si]
		inc	si
		or	al, al
		jnz	ResolveSkipVar
		jmp	ResolveNextVar

ResolveFallback:
		mov	byte ptr comspecPath, 0
		clc

ResolveDone:
		pop	es
		pop	di
		pop	si
		pop	bx
		pop	ax
		ret


; Build "/C <batchPath> <geosDistDir> [arg1] [arg2]" into cmdTail.
; We only forward the first two arguments after gsetup.com because
; gsetup.bat supports INSTALL, INSTALL -F, and ACTIVATE.
BuildCommandTail:
		push	ax
		push	bx
		push	cx
		push	si
		push	di

		lea	di, cmdTail+1
		xor	bx, bx

		lea	si, slashC
		call	AppendDsStringToCmd
		jc	BuildCmdFail

		lea	si, batchPath
		call	AppendDsStringToCmd
		jc	BuildCmdFail

		mov	al, ' '
		call	AppendCharToCmd
		jc	BuildCmdFail

		lea	si, geosDistDir
		call	AppendDsStringToCmd
		jc	BuildCmdFail

		xor	cx, cx
		mov	cl, byte ptr [80h]
		mov	si, 81h
		call	AppendOneTailArg
		jc	BuildCmdFail
		call	AppendOneTailArg
		jc	BuildCmdFail

BuildCmdFinalize:
		mov	byte ptr cmdTail, bl
		mov	byte ptr [di], 0dh
		clc
		jmp	BuildCmdDone

BuildCmdFail:
		stc

BuildCmdDone:
		pop	di
		pop	si
		pop	cx
		pop	bx
		pop	ax
		ret


; Append one whitespace-delimited argument from the PSP command tail.
; Input: CX bytes remaining, SI current tail pointer.
; Output: argument appended as " <arg>" when present.
AppendOneTailArg:
		push	ax

		call	SkipTailWhitespace
		jcxz	AppendOneTailArgDone

		mov	al, byte ptr [si]
		cmp	al, 0dh
		je	AppendOneTailArgDone

		mov	al, ' '
		call	AppendCharToCmd
		jc	AppendOneTailArgFail

AppendOneTailArgCopy:
		jcxz	AppendOneTailArgDone
		mov	al, byte ptr [si]
		cmp	al, ' '
		je	AppendOneTailArgDone
		cmp	al, 9
		je	AppendOneTailArgDone
		cmp	al, 0dh
		je	AppendOneTailArgDone
		call	AppendCharToCmd
		jc	AppendOneTailArgFail
		inc	si
		dec	cx
		jmp	AppendOneTailArgCopy

AppendOneTailArgDone:
		clc
		jmp	AppendOneTailArgExit

AppendOneTailArgFail:
		stc

AppendOneTailArgExit:
		pop	ax
		ret


SkipTailWhitespace:
SkipTailWhitespaceLoop:
		jcxz	SkipTailWhitespaceDone
		mov	al, byte ptr [si]
		cmp	al, ' '
		je	SkipTailWhitespaceAdvance
		cmp	al, 9
		je	SkipTailWhitespaceAdvance
		cmp	al, 0dh
		je	SkipTailWhitespaceDone
		jmp	SkipTailWhitespaceDone

SkipTailWhitespaceAdvance:
		inc	si
		dec	cx
		jmp	SkipTailWhitespaceLoop

SkipTailWhitespaceDone:
		ret


AppendDsStringToCmd:
		push	ax
		push	si

AppendDsStringLoop:
		mov	al, byte ptr [si]
		or	al, al
		jz	AppendDsStringDone
		call	AppendCharToCmd
		jc	AppendDsStringFail
		inc	si
		jmp	AppendDsStringLoop

AppendDsStringDone:
		clc
		jmp	AppendDsStringExit

AppendDsStringFail:
		stc

AppendDsStringExit:
		pop	si
		pop	ax
		ret


AppendCharToCmd:
		cmp	bx, CMD_TAIL_MAX
		jae	AppendCharFail
		mov	byte ptr [di], al
		inc	di
		inc	bx
		clc
		ret

AppendCharFail:
		stc
		ret


; Compare env var prefix at ES:SI with DS:DI key (case-insensitive).
; Returns CF=0 if key matches, CF=1 otherwise.
MatchEnvPrefix:
		push	ax
		push	bx
		push	si
		push	di

MatchPrefixLoop:
		mov	bl, byte ptr [di]
		or	bl, bl
		jz	MatchPrefixYes

		mov	al, byte ptr es:[si]
		or	al, al
		jz	MatchPrefixNo

		cmp	al, 'a'
		jb	MatchPrefixAlReady
		cmp	al, 'z'
		ja	MatchPrefixAlReady
		sub	al, 20h

MatchPrefixAlReady:
		cmp	bl, 'a'
		jb	MatchPrefixBlReady
		cmp	bl, 'z'
		ja	MatchPrefixBlReady
		sub	bl, 20h

MatchPrefixBlReady:
		cmp	al, bl
		jne	MatchPrefixNo
		inc	si
		inc	di
		jmp	MatchPrefixLoop

MatchPrefixYes:
		clc
		jmp	MatchPrefixDone

MatchPrefixNo:
		stc

MatchPrefixDone:
		pop	di
		pop	si
		pop	bx
		pop	ax
		ret


; Copy ASCIIZ from ES:SI to DS:DI.
CopyEsStringToDs:
		push	ax
		push	bx
		push	si
		push	di

		xor	bx, bx

CopyEsLoop:
		mov	al, byte ptr es:[si]
		or	al, al
		jz	CopyEsDone
		cmp	bx, MAX_PATH_CHARS
		jae	CopyEsFail
		mov	byte ptr [di], al
		inc	di
		inc	si
		inc	bx
		jmp	CopyEsLoop

CopyEsDone:
		cmp	bx, 0
		je	CopyEsFail
		mov	byte ptr [di], 0
		clc
		jmp	CopyEsExit

CopyEsFail:
		stc

CopyEsExit:
		pop	di
		pop	si
		pop	bx
		pop	ax
		ret


; Copy ASCIIZ from DS:SI to DS:DI.
CopyDsStringToDs:
		push	ax
		push	bx
		push	si
		push	di

		xor	bx, bx

CopyDsLoop:
		mov	al, byte ptr [si]
		or	al, al
		jz	CopyDsDone
		cmp	bx, MAX_PATH_CHARS
		jae	CopyDsFail
		mov	byte ptr [di], al
		inc	di
		inc	si
		inc	bx
		jmp	CopyDsLoop

CopyDsDone:
		cmp	bx, 0
		je	CopyDsFail
		mov	byte ptr [di], 0
		clc
		jmp	CopyDsExit

CopyDsFail:
		stc

CopyDsExit:
		pop	di
		pop	si
		pop	bx
		pop	ax
		ret


ExecComspec:
		push	ax
		push	bx
		push	cx
		push	si
		push	di
		push	dx

		mov	ax, ds
		mov	word ptr execCmdSeg, ax
		mov	word ptr execFcb1Seg, ax
		mov	word ptr execFcb2Seg, ax

		cmp	byte ptr comspecPath, 0
		je	ExecTryZ
		lea	dx, comspecPath
		call	ExecComspecPath
		jnc	ExecComspecDone

ExecTryZ:
		lea	si, fallbackComspecZ
		lea	di, comspecPath
		call	CopyDsStringToDs
		jc	ExecTryC
		lea	dx, comspecPath
		call	ExecComspecPath
		jnc	ExecComspecDone

ExecTryC:
		lea	si, fallbackComspecC
		lea	di, comspecPath
		call	CopyDsStringToDs
		jc	ExecTryBare
		lea	dx, comspecPath
		call	ExecComspecPath
		jnc	ExecComspecDone

ExecTryBare:
		lea	si, fallbackComspec
		lea	di, comspecPath
		call	CopyDsStringToDs
		jc	ExecComspecFail
		lea	dx, comspecPath
		call	ExecComspecPath
		jc	ExecComspecFail

		clc
		jmp	ExecComspecDone

ExecComspecFail:
		stc

ExecComspecDone:
		pop	dx
		pop	di
		pop	si
		pop	cx
		pop	bx
		pop	ax
		ret


ExecComspecPath:
		push	ax
		push	bx

		lea	bx, execBlock
		mov	ax, 4b00h
		int	21h
		jc	ExecComspecPathFail
		clc
		jmp	ExecComspecPathDone

ExecComspecPathFail:
		stc

ExecComspecPathDone:
		pop	bx
		pop	ax
		ret


progPath		db	MAX_PATH_CHARS+1 dup (0)
geosDistDir		db	MAX_PATH_CHARS+1 dup (0)
batchPath		db	MAX_PATH_CHARS+1 dup (0)
comspecPath		db	MAX_PATH_CHARS+1 dup (0)
cmdTail			db	CMD_TAIL_MAX+2 dup (0)
cwdPath			db	65 dup (0)

batchName		db	'gsetup.bat', 0
geosDistSuffix		db	'FREEGEOS\60BETA', 0
comspecKey		db	'COMSPEC=', 0
fallbackComspec		db	'COMMAND.COM', 0
fallbackComspecC	db	'C:\COMMAND.COM', 0
fallbackComspecZ	db	'Z:\COMMAND.COM', 0
launcherName		db	'gsetup.com', 0
slashC			db	'/C ', 0
msgError		db	'GSETUP launcher failed.', 13, 10, '$'

execBlock:
execEnvSeg		dw	0
execCmdOff		dw	offset cmdTail
execCmdSeg		dw	0
execFcb1Off		dw	5ch
execFcb1Seg		dw	0
execFcb2Off		dw	6ch
execFcb2Seg		dw	0

stackArea		db	256 dup (0)
stackTop		label	byte
programEnd		label	byte

_TEXT ends
end _start
