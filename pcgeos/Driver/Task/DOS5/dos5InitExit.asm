COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dos5InitExit.asm

AUTHOR:		Adam de Boor, May 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/30/92		Initial revision


DESCRIPTION:
	...
		

	$Id: dos5InitExit.asm,v 1.1 97/04/18 11:58:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5OpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start-up for real

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		ds = es = dgroup
		cx	= AppAttachFlags
		dx	= handle of AppLaunchBlock
		bp	= handle of extra block from state file, or 0 if none.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5OpenApplication method dynamic DOS5Class, MSG_GEN_PROCESS_OPEN_APPLICATION
		.enter
	;
	; Let our superclass do its work, so we can biff whatever we want.
	; 
		mov	di, offset DOS5Class
		CallSuper	MSG_GEN_PROCESS_OPEN_APPLICATION
	;
	; See if DOS version is >= 3.0, where int 2f was first defined.
	;
		mov	ax, MSDOS_GET_VERSION shl 8
		call	FileInt21
		cmp	al, 3
		jb	done
	;
	; Yup. See if a switcher's in evidence.
	;
		clr	bx
		mov	di, bx
		mov	es, bx
		mov	ax, MSS2F_DETECT_SWITCHER
		call	DOS5Int2f
		
		mov	ds:[callInAddr].offset, di
		mov	ds:[callInAddr].segment, es
		
		mov	ax, es
		or	ax, di
		jz	done	; null call-in address, so no t/s
	;
	; Yup. Hook up with it, in case it won't call our int 2f hook.
	; 

		segmov	es, ds
		mov	di, offset dos5CBI
		mov	ax, MSSIF_HOOK_CALLOUT
		call	ds:[callInAddr]
		
	;
	; Catch int 2F so we can properly respond there, too.
	; 
		mov	di, offset old2f
		mov	ax, 0x2f
		mov	bx, segment DOS52FIntercept
		mov	cx, offset DOS52FIntercept
		call	SysCatchInterrupt
	;
	; Now find the keyboard driver and tell it to notify us about Ctrl+Esc
	; 
		mov	ax, GDDT_KEYBOARD
		call	GeodeGetDefaultDriver
		mov_tr	bx, ax
		push	ds
		call	GeodeInfoDriver
		mov	ax, ds:[si].DIS_strategy.offset
		mov	bx, ds:[si].DIS_strategy.segment
		pop	ds
		
		mov	ds:[keyboardStrat].offset, ax
		mov	ds:[keyboardStrat].segment, bx
		
		mov	ah, mask SS_LCTRL		; XXX: allow RCTRL too?
		mov	cx, (CS_CONTROL shl 8) or VC_ESCAPE
		mov	bx, handle 0
		mov	bp, MSG_DOS5_HOTKEY_PRESSED
		mov	di, DR_KBD_ADD_HOTKEY
		call	ds:[keyboardStrat]
done:
		.leave
		ret
DOS5OpenApplication endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5CloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut down the process

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		ds = es = dgroup
RETURN:		cx	= extra state block to save
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5CloseApplication method dynamic DOS5Class, MSG_GEN_PROCESS_CLOSE_APPLICATION
		.enter
		mov	di, offset DOS5Class
		CallSuper	MSG_GEN_PROCESS_CLOSE_APPLICATION
		
		push	cx
		mov	ax, ds:[callInAddr].offset
		or	ax, ds:[callInAddr].segment
		jz	done
	;
	; Tell the keyboard driver to ignore the hotkey.
	; 
		mov	ah, mask SS_LCTRL
		mov	cx, (CS_CONTROL shl 8) or VC_ESCAPE
		mov	bx, handle 0
		mov	bp, MSG_DOS5_HOTKEY_PRESSED
		mov	di, DR_KBD_REMOVE_HOTKEY
		call	ds:[keyboardStrat]
	;
	; Unhook from int 2fh
	; 
		mov	ax, 0x2f
		mov	di, offset old2f
		call	SysResetInterrupt
	;
	; Unhook from the task switcher itself.
	; 
		mov	di, offset dos5CBI
		mov	ax, MSSIF_UNHOOK_CALLOUT
		call	ds:[callInAddr]
done:
		pop	cx
		.leave
		ret
DOS5CloseApplication endm

Movable		ends
