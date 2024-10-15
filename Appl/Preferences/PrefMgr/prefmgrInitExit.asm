COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmgrInitExit.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

DESCRIPTION:
	

	$Id: prefmgrInitExit.asm,v 1.2 98/04/24 01:04:24 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

FUNCTION:	PrefMgrCreateNewStateFile

DESCRIPTION:	Create a new state file (or rather, don't)

CALLED BY:	UI (MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE

PASS:		cx	- AppAttachMode
		dx	- Block handle of AppInstanceReference

RETURN:		ax	- handle of extra block of state data (= 0)

DESTROYED:	cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/93		Initial version

------------------------------------------------------------------------------@

if	_SIMPLE
PrefMgrCreateNewStateFile	method	PrefMgrClass,
					 MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
	clr	ax
	ret
PrefMgrCreateNewStateFile	endm
endif




COMMENT @----------------------------------------------------------------------

FUNCTION:	PrefMgrCloseApplication

DESCRIPTION:	

PASS:		ds, es - dgroup

RETURN:		cx - 0

DESTROYED:	ax,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

PrefMgrCloseApplication	method	PrefMgrClass, MSG_GEN_PROCESS_CLOSE_APPLICATION

	
		call	InitFileCommit
		clr	cx
		ret
PrefMgrCloseApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open any specified module

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		*ds:si	= PrefMgrClass object
		ds:di	= PrefMgrClass instance data
		ax	= message #

		cx - AppAttachFlags
		dx - hptr of AppLaunchBlock (0 if none)
		bp - hptr of extra state block (0 if none)

RETURN:		AppLaunchBlock, state block - presevered
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/7/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrOpenApplication	method dynamic PrefMgrClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
		.enter
	;
	; If we're passed a module name, we'll run in single-module mode.
	; Set PrefMgrPrimary to not usable before calling our superclass
	; instead of after, so as to save unnecessary UI work.
	;
		test	cx, mask AAF_DATA_FILE_PASSED
		jz	callSuper
		;pusha
		push	ax, cx, dx, bx, bp, si, di
		mov	bx, handle PrefMgrPrimary
		mov	si, offset PrefMgrPrimary
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjMessageNone
		;popa
		pop	ax, cx, dx, bx, bp, si, di
callSuper:
	;
	; Call our superclass to bring things on screen
	;
		push	cx, dx
		mov	di, offset PrefMgrClass
		call	ObjCallSuperNoLock
		pop	cx, dx
	;
	; See if there is any 'document' specified, and use that as
	; the module to open.
	;
		test	cx, mask AAF_DATA_FILE_PASSED
		jz	noModule
		mov	bx, dx				;bx <- ALB handle
		call	MemLock
		mov	es, ax
		mov	di, ALB_dataFile		;es:di <- module
		call	SwitchToModuleByName
		mov	ds:[singleModuleMode], BB_TRUE

noModule:

		.leave
		ret
PrefMgrOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchToModuleByName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch to the module specified by name, freeing the currently
		loaded module if any.

CALLED BY:	PrefMgrOpenApplication, PMAMetaIacpNewConnection
PASS:		es:di	= module name
RETURN:		CF set if module not found
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/16/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchToModuleByName	proc	near
		uses	ds
		.enter
		;pusha
		push	ax, cx, dx, bx, bp, si, di
	;
	; Get the module name and convert it to a module #
	;
		call	ConvertModuleNameToNumber
		jc	done				;branch if not found
	;
	; Call ourselves to bring up the module.  This will free any existing
	; module.
	;
		mov	si, cx				;si <- module #
		mov	ax, MSG_PREF_MGR_ITEM_SELECTED
		mov	di, mask MF_CALL
		mov	bx, handle 0
		call	ObjMessage

		clc

done:
		pop	ax, cx, dx, bx, bp, si, di
		;popa
		.leave
		ret
SwitchToModuleByName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertModuleNameToNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the passed module name to a module number

CALLED BY:	PrefMgrOpenApplication
PASS:		es:di - ptr to module name
RETURN:		cx - module #
		carry - set if not found
DESTROYED:	everything except es
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/7/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertModuleNameToNumber	proc	near
		uses	es
		.enter

	;
	; Lock the module array in the TOC file
	;
		push	es, di
		segmov	es, dgroup, bx			;es <- dgroup
		call	PrefMgrSetPath
		call	TocGetFileHandle
		mov	di, es:[moduleArray]		;di <- VM block handle
		clr	ax, dx				;dx:ax <- element #
		call	HugeArrayLock			;ds:si <- element
		pop	es, di
							;dx <- element size
		mov_tr	cx, ax				;cx <- # elements
		stc					;assume no modules
		jcxz	done				;branch if no modules
	;
	; Search through the module list
	;
		clr	cx				;cx <- element #
searchLoop:
		push	si, cx
		mov	cx, dx				;cx <- element size
		sub	cx, offset PME_name		;cx <- name size
		lea	si, ds:[si].PME_name		;ds:si <- module name
		call	LocalCmpStrings
if	ERROR_CHECK
	; To cope with a non-EC module name being passed in EC environment
	; (such as from SysTrayTriggerClass in SpecUI), we also try to match
	; the non-EC module name with non-EC versions of our EC name entries.
		je	hasResult
		LocalCmpChar	es:[di], 'E'
		jne	skipECSpace
		LocalCmpChar	es:[di+TCHAR], 'C'
		jne	skipECSpace
		LocalCmpChar	es:[di+2*TCHAR], ' '
		jne	skipECSpace

	; Passed module name is already EC version.  So no need to match again.
		tst	sp				;clear ZF
		jmp	hasResult

skipECSpace:
		add	si, 3 * size TCHAR
		sub	cx, 3
		call	LocalCmpStrings
hasResult:
endif	; ERROR_CHECK
		pop	si, cx
		je	unlock				;branch if found, CF=0
	;
	; Didn't match -- move to next element
	;
		inc	cx				;cx <- element #
		call	HugeArrayNext			;dx <- element size
		tst	ax				;more elements?
		jnz	searchLoop			;branch if so
	;
	; No matches found -- return an error
	;
		stc					;carry <- not found
unlock:
	;
	; Unlock the array element and return module found
	;
		call	HugeArrayUnlock			;flags preserved
done:

		.leave
		ret
ConvertModuleNameToNumber	endp