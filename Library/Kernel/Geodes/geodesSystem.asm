COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeSystem.asm

ROUTINES:
	Name			Description
	----			-----------

TABLES:
	Name			Description
	----			-----------
	SystemGeodeTable		Table of GeodeEnumStruct's for all system GEODEs

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file contains routines to handle GEODEs.

	$Id: geodesSystem.asm,v 1.1 97/04/05 01:11:58 newdeal Exp $

-------------------------------------------------------------------------------@

NUMBER_OF_SYSTEM_GEODES	=	0

if	0

GEODE_HANDLE_SYSDR	=	1
GEODE_HANDLE_SYSLIB	=	2


SystemGeodeTable	label	word

	; Dummy driver

	word	mask GA_DRIVER or mask GA_SYSTEM	;attributes
	word	GEODE_TYPE_DRIVER			;file type
	word	CURRENT_GEODE_VERSION		;version
	word	0				;core size
	byte	'SysDr   '			;name
	byte	'DRVR'				;name extension
	word	1				;revision
	word	GEODE_HANDLE_SYSDR		;handle
	word	offset SysDrInfoTable		;segment (used to store offset
						;to init table)

	; Dummy library

	word	mask GA_LIBRARY or mask GA_SYSTEM	;attributes
	word	GEODE_TYPE_LIBRARY		;file type
	word	CURRENT_GEODE_VERSION		;version
	word	0				;core size
	byte	'SysLib  '			;name
	byte	'LBRY'				;name extension
	word	1				;revision
	word	GEODE_HANDLE_SYSLIB		;handle
	word	offset SysLibEntryTable		;segment (used to store offset
						;to entry point table)

EndSystemGeodeTable	label	word

endif

;-----------------------------------------------------------------------------
;		Test system driver
;-----------------------------------------------------------------------------

if	0

SysDrInfoTable	label	word
	word	2222h			;driver attributes
	word	3333h			;driver type
	dword	SysDrStrategy		;strategy
	byte	'SYSDR   '		;logical name

SysDrStrategy	proc	far
	cmp	di,DR_INIT
	jz	init
	cmp	di,DR_EXIT
	jz	exit
	mov	ax,1234h
	ret
init:
	clc
	ret
exit:
	ret
SysDrStrategy	endp

endif

;-----------------------------------------------------------------------------
;		Test system library
;-----------------------------------------------------------------------------

if	0

SysLibEntryTable	word	offset	SysLibPlus2
			word	offset	SysLibPlus4

SysLibPlus2	proc	far
	add	ax,2
	ret
SysLibPlus2	endp

SysLibPlus4	proc	far
	add	ax,4
	ret
SysLibPlus4	endp

endif
