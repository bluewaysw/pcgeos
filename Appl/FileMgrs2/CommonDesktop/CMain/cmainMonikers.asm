COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop -- Init
FILE:		cmainMonikers.asm

AUTHOR:		Martin Turon, Oct  3, 1992

ROUTINES:
	Type	Name			Description
	----	----			-----------
	INT	SetUpDesktopMonikers	Installs all desktop icons in TokenDB
	INT	LookUpDesktopMonikers	Loads default monikers into
					global variables in dgroup

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/3/92		Initial version


DESCRIPTION:
	Code and tables to handle adding standard desktop monikers to
	the token database.

RCS STAMP:
	$Id: cmainMonikers.asm,v 1.5 98/08/20 05:41:03 joon Exp $

=============================================================================@

if _WRITABLE_TOKEN_DATABASE


COMMENT @-------------------------------------------------------------------
		HOW TO ADD ARTWORK.

	1) put pcx file in appropriate /CommonDesktop/CArt/PCX
	2) update /CommonDesktop/CArt/convert
	3) add 2 resources to all affected .gp files:
		- resource of moniker list
		- resource of monikers
	4) add definitions to a global .def file (cdesktopGlobal.def)
	5) update the following list:
		- desktopMonikerTable
----------------------------------------------------------------------------@


InitCode segment resource



COMMENT @-------------------------------------------------------------------
		SetUpDesktopMonikers
----------------------------------------------------------------------------

SYNOPSIS:	Makes sure that all desktop tokens are defined in the
		TokenDB.

CALLED BY:	INTERNAL - DesktopOpenApplication

PASS:		nothing
RETURN:		nothing
DESTROYED:	cx, bp, di, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/18/89	added header
	martin	12/29/92	revised to use ShellDefineTokens

----------------------------------------------------------------------------@
SetUpDesktopMonikers	proc	near
	uses	es
	.enter
	segmov	es, cs
	mov	di, offset desktopMonikerTable
FXIP<	mov	cx, DESKTOP_MONIKER_TABLE_SIZE				>
FXIP<	call	SysCopyToStackESDI					>
	clr	cx, bp, si
	call	ShellDefineTokens
FXIP<	call	SysRemoveFromStack					>

if _DOS_LAUNCHERS
	mov	di, offset launcherMonikerTable
	mov	si, MANUFACTURER_ID_DOS_LAUNCHER
FXIP<	segmov	es, cs							>
FXIP<	mov	cx, LAUNCHER_MONIKER_TABLE_SIZE				>
FXIP<	call	SysCopyToStackESDI					>
	clr	cx, bp
	call	ShellDefineTokens
FXIP<	call	SysRemoveFromStack					>
endif		; _DOS_LAUNCHERS

	.leave
	ret
SetUpDesktopMonikers	endp


;-----------------------------------------------------------------
;	NewDesk monikers that are installed in the token.db.
;-----------------------------------------------------------------
if	_NEWDESK
desktopMonikerTable	label	TokenMoniker

if _APP_MONIKER
TokenMoniker	< <'nDSK'>,	DeskMonikerList			>
endif

TokenMoniker	< <'nFDR'>,	NDFileFolderMonikerList		>
TokenMoniker	< <'nFIL'>,	NDDosDataMonikerList		>
TokenMoniker	< <'nAPP'>,	DefaultGEOSApplMonikerList	>
TokenMoniker	< <'nDAT'>,	DefaultGEOSDataMonikerList	>
TokenMoniker	< <'nDOS'>,	NDDosApplMonikerList		>
TokenMoniker	< <'TMPL'>,	NDTemplateMonikerList		>
TokenMoniker	< <'ndWB'>,	NDWasteBasketMonikerList	>
TokenMoniker	< <'nHLP'>,	NDHelpMonikerList		>
TokenMoniker	< <'nPTR'>,	NDPrinterMonikerList		>
TokenMoniker	< <'FL52'>,	NDFiveInchDiskMonikerList	>
TokenMoniker	< <'FL35'>,	NDThreeInchDiskMonikerList	>
TokenMoniker	< <'HDSK'>,	NDHardDriveMonikerList		>
TokenMoniker	< <'CDRM'>,	NDCDRomMonikerList		>
TokenMoniker	< <'NDSK'>,	NDNetDriveMonikerList		>
TokenMoniker	< <'RDSK'>,	NDRamDiskMonikerList		>
TokenMoniker	< <'VDSK'>,	NDRemovableDiskMonikerList	>
TokenMoniker	< <'ZDSK'>,	NDZipDiskMonikerList		>
TokenMoniker	< <'nMYC'>,	NDMyComputerMonikerList		>
TokenMoniker	< <'nWOR'>,	NDWorldMonikerList		>
TokenMoniker	< <'nDOC'>,	NDDocumentMonikerList		>
ifdef GPC
if _NEWDESK
TokenMoniker	< <'ndWF'>,	NDFullWasteBasketMonikerList	>
endif
TokenMoniker	< <'ndHO'>,	NDHomeOfficeFolderMonikerList	>
TokenMoniker	< <'ndOr'>,	NDOrganizeFolderMonikerList	>
TokenMoniker	< <'ndPL'>,	NDPlayAndLearnFolderMonikerList	>
TokenMoniker	< <'ndCU'>,	NDComputerUtilsFolderMonikerList >
TokenMoniker	< <'ndAc'>,	NDAccessoriesFolderMonikerList	>
TokenMoniker	< <'ndAO'>,	NDAddOnsFolderMonikerList	>
;TokenMoniker	< <'ndMS'>,	NDMainScreenMonikerList		>
TokenMoniker	< <'ndSU'>,	NDSignUpMonikerList		>
;DOS files
TokenMoniker	< <'dJPG'>,	GPCdJPGMonikerList		>
TokenMoniker	< <'dGIF'>,	GPCdGIFMonikerList		>
TokenMoniker	< <'dPNG'>,	GPCdPNGMonikerList		>
TokenMoniker	< <'dCSV'>,	GPCdCSVMonikerList		>
TokenMoniker	< <'dWKS'>,	GPCdWKSMonikerList		>
TokenMoniker	< <'dVCF'>,	GPCdVCFMonikerList		>
TokenMoniker	< <'dTXT'>,	GPCdTXTMonikerList		>
TokenMoniker	< <'dRTF'>,	GPCdRTFMonikerList		>
TokenMoniker	< <'dDOC'>,	GPCdDOCMonikerList		>
TokenMoniker	< <'dHTM'>,	GPCdHTMMonikerList		>
TokenMoniker	< <'dPAK'>,	GPCdPAKMonikerList		>
TokenMoniker	< <'dPDF'>,	GPCdPDFMonikerList		>
TokenMoniker	< <'dQIF'>,	GPCdQIFMonikerList		>
TokenMoniker	< <'dWAV'>,	GPCdWAVMonikerList		>
TokenMoniker	< <'dUPD'>,	GPCdUPDMonikerList		>
TokenMoniker    < <'dEFT'>,     GPCdEFTMonikerList              >
TokenMoniker    < <'dZIP'>,     GPCdZIPMonikerList              >
endif

byte		TOKEN_MONIKER_END_OF_LIST
endif		; if _NEWDESK

if	_GMGR

if	not _ZMGR
;-----------------------------------------------------------------
;	GeoManager monikers that are installed in the token.db.
;-----------------------------------------------------------------

desktopMonikerTable	label	TokenMoniker

if _APP_MONIKER
TokenMoniker	< <'DESK'>,	DeskMonikerList			>
endif

TokenMoniker	< <'FLDR'>,	FldrMonikerList			>
TokenMoniker	< <'FILE'>,	FileMonikerList			>
TokenMoniker	< <'gAPP'>,	DefaultGEOSApplMonikerList	>
TokenMoniker	< <'gDAT'>,	DefaultGEOSDataMonikerList	>
TokenMoniker	< <'gDOS'>,	DosApplMonikerList		>
TokenMoniker	< <'TMPL'>,	TemplateMonikerList		>
TokenMoniker	< <'ZDSK'>,	ZipDiskMonikerList		>

byte		TOKEN_MONIKER_END_OF_LIST

else

if	not _PMGR
;-----------------------------------------------------------------
;	ZManager monikers that are installed in the token.db.
;-----------------------------------------------------------------
desktopMonikerTable	TokenMoniker	\
	< <'ZMGR'>,	DeskMonikerList				>,
	< <'FLDR'>,	FldrMonikerList				>,
	< <'FILE'>,	FileMonikerList				>,
	< <'gAPP'>,	DefaultGEOSApplMonikerList		>,
	< <'gDAT'>,	DefaultGEOSDataMonikerList		>,
	< <'gDOS'>,	DosApplMonikerList			>,
	< <'TMPL'>,	TemplateMonikerList			>
	byte		TOKEN_MONIKER_END_OF_LIST
else
;-----------------------------------------------------------------
;	PManager monikers that are installed in the token.db.
;-----------------------------------------------------------------
desktopMonikerTable	TokenMoniker	\
	< <'PMCN'>,	DeskMonikerList				>,
	< <'FLDR'>,	FldrMonikerList				>,
	< <'FILE'>,	FileMonikerList				>,
	< <'gAPP'>,	DefaultGEOSApplMonikerList		>,
	< <'gDAT'>,	DefaultGEOSDataMonikerList		>,
	< <'gDOS'>,	DosApplMonikerList			>,
	< <'TMPL'>,	TemplateMonikerList			>
	byte		TOKEN_MONIKER_END_OF_LIST
endif	; if	(not _PMGR)
endif	; if	(not _ZMGR)

endif	; if	_GMGR

FXIP<DESKTOP_MONIKER_TABLE_SIZE	= $-desktopMonikerTable		>

if _DOS_LAUNCHERS
;-----------------------------------------------------------------
;	FileManagers that have launcher creation need to make
; sure they include at least one launcher token, incase the user
; biffs their tokenDB and all the provided launcher tokens.  Default
; to the regular GEOS appl icon.
;-----------------------------------------------------------------
launcherMonikerTable	TokenMoniker	\
	< <'DLCH'>,	DefaultGEOSApplMonikerList		>
	byte		TOKEN_MONIKER_END_OF_LIST
FXIP<LAUNCHER_MONIKER_TABLE_SIZE = $-launcherMonikerTable	>
endif	; _DOS_LAUNCHERS


InitCode ends

endif	; _WRITABLE_TOKEN_DATABASE
