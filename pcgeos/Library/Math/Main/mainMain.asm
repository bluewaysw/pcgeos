COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mainMain.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/22/92		Initial version.
	witt	11/17/93	DBCS-ized strings and code

DESCRIPTION:
	

	$Id: mainMain.asm,v 1.1 97/04/05 01:22:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment
	idataSem		hptr	0 ; semafore for idata variables
	threadListHan		hptr	0 ; handle of thread list block
	stackDepth		word	0 ; depth of stack for current client
	currentThread		hptr	0 ; current active thread
	hardwareLibrary		hptr	0 ; library handle of hardware library
	hardwareStackDepth	word	0 ; depth of hardware stack
	softwareStackHandle	hptr	0 ; handle of software stack

	;
	; Flag set non-zero to cope with unfortunate side-effect of recent
	; changes to call LCT_NEW_CLIENT_THREAD for dynamically-loaded libraries
	; that the loading geode didn't know about before. When a geode that
	; depends on us is loaded by the file manager, and we load the
	; coprocessor library, we get an LCT_NEW_CLIENT_THREAD because the
	; coprocessor library uses us, and we are unknown to whoever is
	; loading the geode that uses us. Similarly, when the last client that
	; uses us is being unloaded, and we unload the coprocessor library,
	; we get an extra LCT_CLIENT_THREAD_EXIT, after having set
	; stackHanOffset to 0, resulting in our freeing the core block of
	; the geode being unloaded, which isn't good.
	;
	; So.... we set this before the GeodeUseLibrary/GeodeFreeLibrary and
	; clear it afterwards. If it's non-zero when the LCT_CLIENT_THREAD_EXIT
	; or LCT_NEW_CLIENT_THREAD comes in, we just ignore it.
	; 
	ignoreClientThreadChange byte	0
idata	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	MathLibraryEntry

DESCRIPTION:	Do library initialization.

CALLED BY:	INTERNAL ()

PASS:		nothing

RETURN:		carry - set for error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	when we first load in the library (by the kernel) we must do a
	bunch of thing:

	1) Allocate a word of the ThreadPrivateData mini-heap to use for
	   storing the handle of each thread's FP stack.

	2) check the INI file for coprocessor information

		i) if they have a corprocessor listed, load in the
		   appropriate hardware library

		ii) otherwise do a detection to see if they have a 80x87

		iii) if no coprocessor just use emulation (i.e. do nothing)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init segment resource

ife	FULL_EXECUTE_IN_PLACE
category	char	"math",0
key		char	"coprocessor",0
	LocalDefNLString	coproc_name, <"XXXXXXXX.XXX",0>
endif

MathLibraryEntry	proc	far
	uses	ax, bx, cx, ds
	.enter

NOFXIP<	segmov	ds, dgroup, ax			;ds <- seg addr of dgroup >
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	mov	cx, 1				;cx <- # words for ThreadPriv*

	shl	di
	call	cs:[libraryEntryFuncs][di]

	.leave
	ret

libraryEntryFuncs	nptr.near	\
	allocStackSpace,		; LCT_ATTACH
	freeStackSpace,			; LCT_DETACH
	doNothing,			; LCT_NEW_CLIENT
	newClientThread,		; LCT_NEW_CLIENT_THREAD
	clientThreadExit,		; LCT_CLIENT_THREAD_EXIT
	doNothing			; LCT_CLIENT_EXIT
.assert length libraryEntryFuncs eq LibraryCallType

	;--------------------
	; LCT_ATTACH
	; ds	= dgroup
	; cx	= 1
allocStackSpace:
if FULL_EXECUTE_IN_PLACE
EC <	push	bx, ax, ds						>
EC <	mov	ax, ds							>
EC <	mov	bx, handle dgroup					>
EC <	call	MemDerefDS						>
EC <	mov	bx, ds							>
EC <	cmp	ax, bx							>
EC <	ERROR_NE	NOT_DGROUP					>
EC <	pop	bx, ax, ds						>
endif
	; 
	; Copy the predefined format names from strings resource into 
	; FormatParams table in dgroup.
	;
	call	FloatFormatInitFormatNames
	;
	; Incorporate any localization information into the predefined formats
	;
	call	FloatFormatLocalizeFormats

	;
	; Allocate a word of space in every thread's ThreadPrivateData to store
	; the handle of the floating-point stack.
	; 
	mov	bx, handle 0			;bx <- our handle
	call	ThreadPrivAlloc			;carry set for error
	jnc	afterAlloc
	retn					; return carry set

afterAlloc:
	mov	ds:[stackHanOffset], bx		;save offset of FP stack handle
	;
	; Allocate a semaphore to control access to our global vars.
	; 
	mov	bx, 1
	call	ThreadAllocSem
	mov	ax, handle 0
	call	HandleModifyOwner
	mov	ds:[idataSem], bx

ife	FULL_EXECUTE_IN_PLACE

	;Loading a coprocessor library won't work on full-XIP, so we
	; leave it out.

	;
	; See if user specified a particular coprocessor library.
	; 
	push	ds, bp, es, di
	segmov	ds, cs, si
	mov	es, si
	mov	di, offset coproc_name	; es:di = library name buffer
	mov	si, offset category	; ds:si = category
	mov	cx, ds
	mov	dx, offset key		; cx:dx = key
	mov	bp, size coproc_name shl offset IFRF_SIZE
	call	InitFileReadString
	mov	dl, 1			; assume we have a coprocessor
	mov	si, di			; cs:si = name of library to use
	pop	ds, bp, es, di
	jnc	loadCoprocLibrary

	;
	; No library specified, so auto-detect the thing.
	; 
	call	DetectCoProcessor	; cs:si <- library name to use

loadCoprocLibrary:
	tst	dl
	jz	attachDone		; no coprocessor today thanks

	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath

	mov	ds:[ignoreClientThreadChange], TRUE

	push	ds
	segmov	ds, cs
	clr	ax
	mov	bx, ax
	call	GeodeUseLibrary			; bx <- library handle
	call	FilePopDir
	pop	ds

	mov	ds:[ignoreClientThreadChange], FALSE

	;
	; if the hardware library is not available then we can just pretend
	; we don't have a coprocessor, and let the software do all the work
	; 
	jc	attachDone
	
	;
	; Else find how big the hardware stack is.
	; 
	mov	ds:[hardwareLibrary], bx
	mov	ax, MR_GET_HARDWARE_STACK_SIZE
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	clc					; must do this since carry
						; may be trashed by ProcCLR
	mov	ds:[hardwareStackDepth], cx
	
	; we now do something really sick....
	; we get the relocation table of the hardware library
	; and write it directly over the relocation table
	; of the emulator so that the hardware routines get called
	; directly in lieu of the emulation routine.....beleive it!!!
	mov	bx, ds:[hardwareLibrary]
	call	OverwriteRelocationTable
attachDone:
endif
	clc	
	retn

	;--------------------
	; LCT_NEW_CLIENT_THREAD
	; ds	= dgroup
	; 
newClientThread:

if FULL_EXECUTE_IN_PLACE
EC <	push	bx, ax, ds						>
EC <	mov	ax, ds							>
EC <	mov	bx, handle dgroup					>
EC <	call	MemDerefDS						>
EC <	mov	bx, ds							>
EC <	cmp	ax, bx							>
EC <	ERROR_NE	NOT_DGROUP					>
EC <	pop	bx, ax, ds						>
endif

	tst	ds:[ignoreClientThreadChange]
	jnz	newThreadDone

	;
	; Perform a FloatInit for the new thread that might be using us.
	; 
	mov	ax, FP_DEFAULT_STACK_ELEMENTS
	tst	ds:[hardwareLibrary]
	jz	doFloatInit
	sub	ax, ds:[hardwareStackDepth]	; take out elements that are
						;  actually in the coprocessor

doFloatInit:
	mov	bl, FLOAT_STACK_GROW
	call	FloatInit
	tst	ds:[hardwareLibrary]
	jz	newThreadDone
	call	FloatHardwareInit
newThreadDone:
	retn

	;--------------------
	; LCT_CLIENT_THREAD_EXIT
	; ds	= dgroup
clientThreadExit:
	tst	ds:[ignoreClientThreadChange]
	jnz	threadExitDone

	call	FloatExit
	tst	ds:[hardwareLibrary]
	jz	threadExitDone
	call	FloatHardwareExit
EC <	ERROR_C	BAD_HARDWARE_EXIT	>
threadExitDone:
	retn

	;--------------------
	; LCT_DETACH
	; ds	= dgroup
	; cx	= 1
freeStackSpace:

if FULL_EXECUTE_IN_PLACE
EC <	push	bx, ax, ds						>
EC <	mov	ax, ds							>
EC <	mov	bx, handle dgroup					>
EC <	call	MemDerefDS						>
EC <	mov	bx, ds							>
EC <	cmp	ax, bx							>
EC <	ERROR_NE	NOT_DGROUP					>
EC <	pop	bx, ax, ds						>
endif

	;
	; Release the space in ThreadPrivateData
	; 
	clr	bx
	xchg	bx, ds:[stackHanOffset]		;bx <- offset of FP stack handle
	call	ThreadPrivFree
	;
	; Free the semaphore guarding our global vars.
	; 
	mov	bx, ds:[idataSem]
	call	ThreadFreeSem
	mov	bx, ds:[hardwareLibrary]
	tst	bx
	jz	afterFree

	; ok, well there is some more grossness that must happen here, I will
	; try and explain...if you noticed on LCT_ATTACH we got rid of one
	; reference to the Math Library thus allowing us to get the LCT_DETACH
	; before we actually freed the CoProcessor Library, now we want to
	; Unload the CoProcessor without it trying to send another LCT_DETACH
	; to the MathLibrary, so we add two references to the Math Library
	; so it will not try to unload it when it unloads the coprocessor
	; library, and the kernel will go ahead and unload the library anyways
	; since it thinks that there are no more references to the Math Library
	push	bx
	mov	bx, handle 0	
	call	GeodeAddReference
	call	GeodeAddReference
	pop	bx
	mov	ds:[ignoreClientThreadChange], TRUE
	call	GeodeFreeLibrary
	mov	ds:[ignoreClientThreadChange], FALSE
doNothing:
afterFree:
	clc
	retn
MathLibraryEntry	endp

ForceRef MathLibraryEntry

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetectCoProcessor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	figure out what processor and coprocesseor is around if any

CALLED BY:	MathLibraryEntry

PASS:		nothing

RETURN:		dh:	CPU type
			01:	8086 or 8088
			02:	80286
			03:	80386dx or 80386sx
			04:	80486dx or 80486sx

		dl:	Coprocessor type
			00:	none installed
			01:	8087
			02:	80287	
			03:	80387dx or 80387sx
			04:	80487dx or 80487sx

		cs:si = name of intel library if any to use...

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/30/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ife	FULL_EXECUTE_IN_PLACE

;	Cannot use coprocessor libraries on full-xip systems, as calls
;	to the math library cannot be redirected.

EC <	LocalDefNLString	intel8087,	<"int8087e.geo",0>	>
EC < 	LocalDefNLString	intel80X87,	<"intx87ec.geo",0>	>
NEC <	LocalDefNLString	intel8087,	<"int8087.geo",0>  	>
NEC <	LocalDefNLString	intel80X87,	<"intx87.geo",0> 	>


CoProcessorChips nptr \
	offset	intel8087,		; 80087		
	offset	intel8087,		; 80287
	offset	intel80X87,		; 80387		
	offset	intel80X87		; 80487		

if FULL_EXECUTE_IN_PLACE
idata	segment
endif

NDP_STATUS	dw	-1

if FULL_EXECUTE_IN_PLACE
idata	ends
endif

DetectCoProcessor	proc	near
	uses	ds
	.enter
	call	SYSGETCONFIG		; dl <- gets processor type
	mov	dh, dl
	clr	dl			; clear return value
	fninit
NOFXIP<	segmov	ds, cs							>
FXIP<	push	bx							>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS		; ds = dgroup			>
FXIP<	pop	bx							>
	fnstsw	{word}ds:[NDP_STATUS]

	; if we can't write the status word, no processor
	tst	{byte}ds:[NDP_STATUS]
	jnz	done			; noCoprocessor
	
	; next, we check to see if a valid control word can be written
	; if not, no CoProcessor is present. Don't use WAIT forms!!!

	fnstcw	{word}ds:[NDP_STATUS]
	and	{word}ds:[NDP_STATUS], 103fh
	cmp	{word}ds:[NDP_STATUS], 3fh	; correct value
	jne	done			; noCoprocessor
	; assume coprocessor matches the cpu, only case it doesn't is
	; 386 and 287, if CPU is 386 check for this pair
	; because the value returned by SYSGETCONFIG is 0 for the
	; 8086 and 8088, inc value to 1 if its zero since we want to
	; return 1 for the 8086, 8088, 80186
	mov	dl, dh
	tst	dl
	jnz	cont
	inc	dl
cont:
	cmp	dh, 3			; check for 386
	jne	done			; if not 386 we are done
	; a 386 can have either a 387 or a 287 installed, it is only
	; necessary to know this if 387 specific instructions will
	; be used or if a denormal exception handler is to be used
	; Remeber that the NDP has been initialized to its default
	; values.
	; 1. Generate +infinity
	; 2. Generate -infinity
	; 3. 287 says that +infinity == -infinity, 387 says they
	; are different

	fdiv	
	fld1				; put a 1 on the stack
	fldz				; put a 0 on the stack
	fdiv				; divide 1/0 leave +inf on stack
	fld	st			; duplicate +inf
	fchs				; change the sign
	fcompp				; compare and discard
	fstsw	ds:[NDP_STATUS]
	mov	ax, ds:[NDP_STATUS]
	sahf
	jne	done			; if not equal, 387
	dec	dl			; otherwise 287
done:
	tst	dl
	jz	exit
	mov	bl, dl
	shl	bl
	clr	bh
	mov	si, cs:[CoProcessorChips-2][bx]	; ds:si <- string for library
						; name
	; 	ax <- return value	
exit:
	.leave
	ret
DetectCoProcessor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OverwriteRelocationTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	 we get the relocation table of the hardware library
	 and write it directly over the relocation table
	 of the emulator so that the hardware routines get called
	 directly in lieu of the emulation routine.....beleive it!!!

CALLED BY:	MathLibraryEntry

PASS:		bx  = hardware library handle
		
RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		to get the relocation tables we lock down the core blocks
		of the two library's and access into the relocation
		tables directly

KNOWN BUGS/SIDEFFECTS/IDEAS:	this is crazy...


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OverwriteRelocationTable	proc	near
	uses	ds
	.enter
	push	bx
	call	MemLock		
	mov	ds, ax			; ds:0 <- core bock of hardware lib
	mov	bx, handle 0
	call	MemLock
	push	bx
	mov	es, ax			; es:0 <- core block of emulator lib
	mov	cx, ds:[GH_exportEntryCount]
	sub	cx, MATH_LIBRARY_FIRST_ENTRY_POINT_TO_OVERWRITE

	mov	si, ds:[GH_exportLibTabOff]
	mov	di, es:[GH_exportLibTabOff]
	mov	bx, MATH_LIBRARY_FIRST_ENTRY_POINT_TO_OVERWRITE
	shl	bx
	shl	bx
	add	si, bx			; put ds:si beyond first few routines
	shl	cx			; bx = size(fptr)/2 * # of entries
	rep	movsw			; copy tables

	; because of the fact that the CoProcessor library references the
	; math library, the math library will not get an LCT_DETACH until
	; the CoProcessor is unloaded, of course we want to unload the
	; beast in LCT_DETACH, so to avoid this problem, we get rid of
	; the extra reference to the math library, so that we will get
	; the LCT_DETACH at which point we will deal with hooey (see 
	; the LCT_DETACH code for details...)
	; NOTE: We cannot use GeodeRemoveReference here, as we only have the
	; one reference from the coprocessor library until such time as we
	; return from LCT_ATTACH. If we were to use GeodeRemoveReference, we
	; would unload ourselves, which wouldn't be good.
	dec	es:[GH_geodeRefCount]
	pop	bx
	call	MemUnlock
	pop	bx
	call	MemUnlock
	.leave
	ret
OverwriteRelocationTable	endp
endif	



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatInitFormatNames

DESCRIPTION:	Copy the predefined format names from the localized lmem
		resource into the pre-defined FormatParams structures.

CALLED BY:	INTERNAL (MathLibraryEntry)

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatInitFormatNames	proc	near
	uses	bx,cx,ds,si,es,di
	.enter

	mov	cx, NUM_PRE_DEF_FORMATS
NOFXIP<	segmov	es, dgroup, ax						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	mov	di, offset FormatPreDefTbl	; es:di <- predef table
	mov	bx, handle FloatFormatStrings
	push	bx
	call	MemLock				; lock strings resource
	mov	ds, ax
	mov	si, offset FormatNames		; ds:si <- string table
	mov	si, ds:[si]			; deref

initLoop:
EC<	cmp	es:[di].FP_signature, FORMAT_PARAMS_ID >
EC<	ERROR_NE FLOAT_FORMAT_BAD_PARAMS >
	push	di
	add	di, offset FP_formatName
	push	si
	mov	si, {word} ds:[si]		; ds:si <- format name

	;
	; copy localized string over
	;
	LocalCopyString

	pop	si
	add	si, 2
	pop	di				; retrieve ptr to FormatParams
	add	di, size FormatParams		; on to next FormatParams
	loop	initLoop			; loop while not done

	pop	bx
	call	MemUnlock			; unlock strings resource

	.leave
	ret
FloatFormatInitFormatNames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatLocalizeFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	re-initialize localization information

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatLocalizeFormats	proc	far
	uses	ax
	.enter
	call	FloatFormatLocalizeFormats
	.leave
	ret
FloatLocalizeFormats	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatFormatLocalizeFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inclde user's localization preferences in the number formats

CALLED BY:	MathLibraryEntry()
PASS:		none
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatFormatLocalizeFlags	record
	FFLF_USE_DECIMAL_DIGITS:1
	FFLF_USE_LEAD_ZERO:1
	:6
FloatFormatLocalizeFlags	end

FloatFormatLocalizeStruct	struct
	FFLS_flags	FloatFormatLocalizeFlags
	FFLS_routine	nptr.near
FloatFormatLocalizeStruct	ends

	; # L
	; D e
	; i a
	; g d
	;   0
formatLocalizeInfo	FloatFormatLocalizeStruct \
	<<0,1,0,0,0,0,0,0>, FLNumberFormat>,	;FORMAT_ID_GENERAL
	<<1,1,0,0,0,0,0,0>, FLNumberFormat>,	;FORMAT_ID_FIXED
	<<1,1,0,0,0,0,0,0>, FLNumberFormat>,	;FORMAT_ID_FIXED_WITH_COMMAS
	<<0,1,0,0,0,0,0,0>, FLNumberFormat>,	;FORMAT_ID_FIXED_INTEGER
	<<1,1,0,0,0,0,0,0>, FLCurrencyFormat>,	;FORMAT_ID_CURRENCY
	<<1,1,0,0,0,0,0,0>, FLCurrencyFormat>,	;FORMAT_ID_CURRENCY_WITH_COMMAS
	<<0,1,0,0,0,0,0,0>, FLCurrencyFormat>,	;FORMAT_ID_CURRENCY_INTEGER
	<<1,0,0,0,0,0,0,0>, FLNumberFormat>,	;FORMAT_ID_PERCENTAGE
	<<0,0,0,0,0,0,0,0>, FLNumberFormat>,	;FORMAT_ID_PERCENTAGE_INTEGER
	<<1,1,0,0,0,0,0,0>, FLNumberFormat>,	;FORMAT_ID_THOUSANDS
	<<1,1,0,0,0,0,0,0>, FLNumberFormat>,	;FORMAT_ID_MILLIONS
	<<1,0,0,0,0,0,0,0>, FLNumberFormat>	;FORMAT_ID_SCIENTIFIC

FloatFormatLocalizeFormats		proc	near
	uses	bx, cx, dx, di, si, es, ds
nFormat		local	NumberFormatFlags
nDigits		local	byte
cFormat		local	CurrencyFormatFlags
cDigits		local	byte
SBCS< cSymbol	local	CURRENCY_SYMBOL_LENGTH dup(char)	>
DBCS< cSymbol	local	CURRENCY_SYMBOL_LENGTH dup(wchar)	>

	.enter

	;
	; Get the current localization values
	;
	call	LocalGetNumericFormat
	mov	ss:nFormat, al
	mov	ss:nDigits, ah
	segmov	es, ss
	lea	di, ss:cSymbol
	call	LocalGetCurrencyFormat
	mov	ss:cFormat, al
	mov	ss:cDigits, ah
	;
	; For each predefined format, munge it based on the localization info
	;
NOFXIP<	segmov	ds, dgroup, ax						>
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	mov	cx, (length formatLocalizeInfo)
	mov	di, offset FormatPreDefTbl	;ds:di <- ptr to format
	mov	si, offset formatLocalizeInfo	;cs:si <- ptr to info
			CheckHack <(offset FP_params.FFAP_FLOAT) eq 0>
formatLoop:
	mov	dl, cs:[si].FFLS_flags		;dl <- FloatFormatLocalizeFlags
	call	cs:[si].FFLS_routine
	add	di, (size FormatParams)		;ds:di <- ptr to next format
	add	si, (size FloatFormatLocalizeStruct)
	loop	formatLoop			;loop while more formats

	.leave
	ret
FloatFormatLocalizeFormats		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLNumberFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Localize a numeric format

CALLED BY:	FloatFormatLocalizeFormats()
PASS:		ds:di - ptr to FormatParams
		dl - FloatFormatLocalizeFlags
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLNumberFormat		proc	near
	.enter	inherit	FloatFormatLocalizeFormats

	;
	; Number format -- deal with number of decimal digits
	;
	mov	al, ss:nDigits
	call	FLDecimalDigits
	;
	; Number format -- deal with lead zero
	;
	test	dl, mask FFLF_USE_LEAD_ZERO
	jz	skipNumLeadZero
	mov	bl, ss:nFormat
	mov	bh, mask NFF_LEADING_ZERO
	call	FLLeadZero
skipNumLeadZero:

	.leave
	ret
FLNumberFormat		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLCurrencyFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Localize a currency format

CALLED BY:	FloatFormatLocalizeFormats()
PASS:		ds:di - ptr to FormatParams
		dl - FloatFormatLocalizeFlags
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLCurrencyFormat		proc	near
	.enter	inherit	FloatFormatLocalizeFormats

	;
	; Currency format -- deal with number of decimal digits
	;
	mov	al, ss:cDigits
	call	FLDecimalDigits
	;
	; Currency format -- deal with lead zero
	;
	mov	bl, ss:cFormat
	mov	bh, mask CFF_LEADING_ZERO
	call	FLLeadZero
	;
	; Currency format -- deal with currency symbol
	;
	call	FLCurrencySymbol
	;
	; Currency format -- deal with the minus sign or parentheses
	;
	call	FLCurrencySign

	.leave
	ret
FLCurrencyFormat		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLLeadZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle localizing leading zero information

CALLED BY:	FloatFormatLocalizeFormats()
PASS:		ds:di - ptr to FormatParams
		ss:bp - inherited locals
		bl - flags from localization info
		bh - flag to check
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLLeadZero		proc	near
	.enter	inherit	FloatFormatLocalizeFormats

	mov	ax, mask FFAF_NO_LEAD_ZERO	;assume lead zero not set
	test	bl, bh				;set in localization info?
	jz	noNumLeadZero			;branch if not set
	clr	ax
noNumLeadZero:
	andnf	ds:[di].formatFlags, not (mask FFAF_NO_LEAD_ZERO)
	ornf	ds:[di].formatFlags, ax

	.leave
	ret
FLLeadZero		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLDecimalDigits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle localizing decimal digits flag

CALLED BY:	FLNumberFormat(), FLCurrencyFormat()
PASS:		ds:di - ptr to FormatParams
		ss:bp - inherited locals
		dl - FloatFormatLocalizeFlags
		al - # decimal digits (from number or currency)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLDecimalDigits		proc	near
	.enter

	test	dl, mask FFLF_USE_DECIMAL_DIGITS
	jz	skipDigits
	mov	ds:[di].decimalLimit, al
skipDigits:

	.leave
	ret
FLDecimalDigits		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLSymbolSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle adding a space to the symbol string if required

CALLED BY:	FLCurrencyFormat()
PASS:		ss:bp - inherited locals
		es:di - ptr to dest string
RETURN:		es:di - updated if necessary
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLSymbolSpace		proc	near
	.enter	inherit FLCurrencyFormat

	test	ss:cFormat, mask CFF_SPACE_AROUND_SYMBOL
	jz	noSymbolSpace
	mov	ax, ' '
	LocalPutChar	esdi, ax
noSymbolSpace:

	.leave
	ret
FLSymbolSpace		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLCopyString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a NULL-terminated string w/o the NULL

CALLED BY:	UTLITIY
PASS:		ds:si - ptr to source
		es:di - ptr to dest
RETURN:		es:di - ptr after last char copied
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLCopyString		proc	near
	uses	si
	.enter

	LocalCopyString				;copy me jesus
	LocalPrevChar esdi			;back up to NULL

	.leave
	ret
FLCopyString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLCurrencySymbol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Localize the currency format

CALLED BY:	FLCurrencyFormat()
PASS:		ss:bp - inherited locals
		ds:di - ptr to FormatParams
RETURN:		none
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLCurrencySymbol		proc	near
	uses	ds, es, di, si
	.enter	inherit	FLCurrencyFormat

	clr	ax
	mov	{char}ds:[di].header, al	;nuke existing
	mov	{char}ds:[di].trailer, al	;nuke existing
	;
	; Truncate the system currency format if necessary to allow for
	; the optional space.
	;
SBCS<	mov	{char}ss:cSymbol[PAD_STR_LEN-1], al		>
DBCS<	mov	{wchar}ss:cSymbol[PAD_STR_LEN-2], ax		>
	andnf	ds:[di].formatFlags, not (mask FFAF_HEADER_PRESENT or \
					  mask FFAF_TRAILER_PRESENT)
	segmov	es, ds
	segmov	ds, ss
	lea	si, ss:cSymbol			;ds:si <- ptr to source
	test	ss:cFormat, mask CFF_SYMBOL_BEFORE_NUMBER
	jnz	currencyBefore

	ornf	es:[di].formatFlags, mask FFAF_TRAILER_PRESENT
	add	di, offset trailer
	call	FLSymbolSpace
	call	FLCopyString
	jmp	afterCurrencySymbol

currencyBefore:
	ornf	es:[di].formatFlags, mask FFAF_HEADER_PRESENT
	add	di, offset header
	call	FLCopyString
	call	FLSymbolSpace
afterCurrencySymbol:
SBCS<	mov	{char}es:[di], C_NULL	>
DBCS<	mov	{wchar}es:[di], C_NULL	>

	.leave
	ret
FLCurrencySymbol		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLCurrencySign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Localize the sign for currency

CALLED BY:	FLCurrencyFormat()
PASS:		ss:bp - inherited locals
		ds:di - ptr to FormatParams
RETURN:		none
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLCurrencySign		proc	near
	uses	cx
	.enter	inherit	FLCurrencyFormat

	;
	; Assume using minus sign before
	;
	clr	ax, cx				;ax <- post char, cx <- post +
	mov	dx, '-'				;dx <- pre char
	mov	bh, ss:cFormat			;bh <- CurrencyFormatFlags
	;
	; Calculate the postition flags and sign character(s)
	;
	mov	bl, mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER
	test	bh, mask CFF_NEGATIVE_SIGN_BEFORE_SYMBOL
	jz	negNotBeforeSymbol
	mov	bl, mask FFAF_SIGN_CHAR_TO_PRECEDE_TRAILER
negNotBeforeSymbol:

	test	bh, mask CFF_NEGATIVE_SIGN_BEFORE_NUMBER
	jnz	gotSignPos
	xchg	ax, dx				;ax, dx <- swap pre/post chars
gotSignPos:

	test	bh, mask CFF_USE_NEGATIVE_SIGN
	jnz	gotSignChars
	mov	dx, '('
	mov	ax, ')'
	mov	cx, ' '				;cx <- post positive char
	clr	bl				;bl <- reset for () format
	mov	{word}ds:[di].postPositive[0], C_SPACE
gotSignChars:

	;
	; Set the flags and characters
	;
	clr	bh
	andnf	ds:[di].formatFlags, not (\
			mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER or \
			mask FFAF_SIGN_CHAR_TO_PRECEDE_TRAILER)
	ornf	ds:[di].formatFlags, bx

	mov	{word}ds:[di].preNegative[0], dx
DBCS <	mov	{wchar}ds:[di].preNegative[2], C_NULL			>
	mov	{word}ds:[di].postNegative[0], ax
	clr	ax
DBCS <	mov	{wchar}ds:[di].postNegative[2], ax			>
	mov	{word}ds:[di].prePositive[0], ax
	mov	{word}ds:[di].postPositive[0], cx
DBCS <	mov	{wchar}ds:[di].postPositive[2], ax			>

	.leave
	ret
FLCurrencySign		endp

Init ends
