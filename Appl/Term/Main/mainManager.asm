COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Main
FILE:		mainManager.asm

AUTHOR:		Dennis Chow, September 6, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/ 6/89        Initial revision.

DESCRIPTION:
	Manager for the main module (event handling thread) of the term appl.

	$Id: mainManager.asm,v 1.1 97/04/04 16:55:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Main = 1

;------------------------------------------------------------------------------
;	Include common definitions.
;------------------------------------------------------------------------------
include	mainInclude.def

;------------------------------------------------------------------------------
;	Local variables.
;------------------------------------------------------------------------------
idata segment
include	mainVariable.def
idata ends

;------------------------------------------------------------------------------
;	Include resources for this module
;------------------------------------------------------------------------------
include termui.rdef

;------------------------------------------------------------------------------
;	Include code for this module
;------------------------------------------------------------------------------
Main segment resource

include	mainMain.asm		; Main code file for this module.
include	mainLocal.asm		; Local routines
include mainProtocol.asm	; code for the protocol dialog box.
include mainConnection.asm	; code for connection dialog box
include mainEci.asm		; Responder-specific ECI handlers
include mainTimedDialog.asm	; TermTimedDialogClass


Main ends

	end
