COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Start up application
FILE:		rstartupManager.asm

AUTHOR:		Jason Ho, Apr  3, 1995

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		4/ 3/95   	Initial revision


DESCRIPTION:
	Manager file for Start up application
		

	$Id: rstartupManager.asm,v 1.1 97/04/04 16:52:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;		       Include files
;------------------------------------------------------------------------------

include stdapp.def
include Objects/winC.def
include assert.def
include rwtime.def		; World time stuffs
include initfile.def		; to read init file stuffs
include timedate.def		; for date/time stuffs
include contdb.def
include foamdb.def
include system.def		; SysShutdown stuffs
include fileEnum.def		; for deleting stuffs
include Internal/patch.def	; for IsMultiLanguageModeOn
include sysstats.def		; SGIT_UI_PROCESS / SysGetInfo shme..

include Internal/Resp/eci_oem.def	; eci stuffs

;------------------------------------------------------------------------------
;		       Libraries used
;------------------------------------------------------------------------------
UseLib ui.def
UseLib foam.def
UseLib rwtime.def

;
; Include our definitions here so that we can use the classes in ui.def as
; our superclasses.
;
include rstartup.def

if DO_ECI_SIM_CARD_CHECK
UseLib Internal/Resp/vp.def

include Internal/Resp/vpmisc.def	; misc vp consts from Reza
					; will not need this when we
					; get the revised version.
endif

;
; There must be an instance of every class in idata.
;
; idata   segment
; idata   ends

;------------------------------------------------------------------------------
;		       Resources
;------------------------------------------------------------------------------
include	 rstartup.rdef		; include compiled UI definitions
include  rstartupProcess.asm	; Code for Process class
include  rstartupECI.asm	; Code to handle ECI messages
include  rstartupLangList.asm	; Code for Language Dynamic List class
include  rstartupUtils.asm	; misc utils
include  rstartupApp.asm	; Code for application class
