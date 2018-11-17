##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# FILE:		pen.gp
#
# AUTHOR:	Tony, 2/90
#
#
# Parameters file for: spell.geo
#
#	$Id: pen.gp,v 1.1 97/04/05 01:28:09 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name pen.lib
#
# Long name
#
longname "Pen Support Library"
#
# DB Token
#
tokenchars "PENL"
tokenid 0

#
# Specify geode type
#
type	library, single

#
# Import kernel routine definitions
#
library	geos
library	ui

#platform zoomer

#
# Define resources other than standard discardable code
#
nosort
resource FileCode	code read-only shared
resource C_Pen	code read-only shared
resource InkCommon	code read-only shared
resource InkEdit	code read-only shared
resource InkFile	code read-only shared
resource Strings shared ui-object read-only
resource Cursors lmem read-only shared
resource AppTCMonikerResource  lmem read-only shared
resource AppTMMonikerResource  lmem read-only shared
resource AppTCGAMonikerResource  lmem read-only shared
resource InkControlUI ui-object read-only shared
resource InkControlToolboxUI ui-object read-only shared
resource ControlStrings lmem read-only shared
resource Strings shared ui-object read-only
resource PenClassStructures	fixed read-only shared


#
# Exported routines (and classes)
#
export	InkClass
export	InkControlClass

export	InkDBInit
export	InkDBGetHeadFolder
export	InkFolderGetContents
export	InkFolderCreateSubFolder
export	InkFolderMove
export	InkFolderDelete
export	InkFolderGetNumChildren
export	InkFolderDisplayChildInList
export	InkNoteCreate
export	InkNoteGetPages
export	InkNoteSetTitle
export	InkFolderSetTitle
export	InkGetTitle
export	InkGetParentFolder
export	InkNoteSetKeywords
export	InkNoteGetKeywords
export	InkNoteDelete
export	InkNoteMove
export	InkNoteSetModificationDate
export	InkNoteGetModificationDate
export	InkNoteGetCreationDate
export	InkNoteFindByTitle
export	InkNoteFindByKeywords
export	InkFolderDepthFirstTraverse
export	InkSendTitleToTextObject
export	InkNoteSetTitleFromTextObject
export	InkFolderSetTitleFromTextObject
export	InkNoteSetKeywordsFromTextObject
export	InkNoteSendKeywordsToTextObject
export	InkNoteLoadPage
export	InkNoteSavePage
export	InkNoteCreatePage
export	InkFolderGetChildInfo
export	InkDBGetDisplayInfo
export	InkDBSetDisplayInfo
export	InkFolderGetChildNumber
export	InkNoteGetNumPages
export	InkSetDocPageInfo
export	InkGetDocPageInfo
export	InkSetDocGString
export	InkGetDocGString
export	InkSetDocCustomGString
export	InkGetDocCustomGString
export	InkNoteSetNoteType
export	InkNoteGetNoteType
export	InkNoteCopyMoniker

#
# C Stub routines
#
export INKDBINIT
export INKDBGETHEADFOLDER as UPGRADE_INKDBGETHEADFOLDER
export INKDBGETDISPLAYINFO
export INKDBSETDISPLAYINFO
export INKSETDOCPAGEINFO
export INKGETDOCPAGEINFO
export INKSETDOCGSTRING
export INKGETDOCGSTRING
export INKSETDOCCUSTOMGSTRING
export INKGETDOCCUSTOMGSTRING
export INKSENDTITLETOTEXTOBJECT
export INKGETTITLE
export INKGETPARENTFOLDER
export INKFOLDERSETTITLEFROMTEXTOBJECT
export INKFOLDERSETTITLE
export INKNOTESETTITLEFROMTEXTOBJECT
export INKNOTESETTITLE
export INKFOLDERGETCONTENTS
export INKFOLDERGETNUMCHILDREN
export INKFOLDERDISPLAYCHILDINLIST
export INKFOLDERGETCHILDINFO
export INKFOLDERGETCHILDNUMBER
export INKFOLDERCREATESUBFOLDER
export INKFOLDERMOVE
export INKFOLDERDELETE
export INKFOLDERDEPTHFIRSTTRAVERSE
export INKNOTECREATE
export INKNOTECOPYMONIKER
export INKNOTEGETPAGES
export INKNOTEGETNUMPAGES
export INKNOTECREATEPAGE
export INKNOTELOADPAGE
export INKNOTESAVEPAGE
export INKNOTESETKEYWORDSFROMTEXTOBJECT
export INKNOTESETKEYWORDS
export INKNOTEGETKEYWORDS
export INKNOTESENDKEYWORDSTOTEXTOBJECT
export INKNOTEDELETE
export INKNOTEMOVE
export INKNOTESETMODIFICATIONDATE
export INKNOTEGETMODIFICATIONDATE
export INKNOTEGETCREATIONDATE
export INKNOTEGETNOTETYPE
export INKNOTESETNOTETYPE
export INKNOTEFINDBYTITLE
export INKNOTEFINDBYKEYWORDS

incminor

export InkCompress
export InkDecompress
export INKCOMPRESS
export INKDECOMPRESS

incminor InkNewForBullet

incminor
# SHIPPED TO BULLET

incminor BackspaceInk
#
# XIP-enabled
#

export InkMPClass

incminor

publish	INKDBGETHEADFOLDER

incminor InkNewForDrag

incminor ClipInkDigitizerCoords

export InkGetBoundsInDigitizerCoords
export INKGETBOUNDSINDIGITIZERCOORDS
export InkClipDigitizerCoordsInk
export INKCLIPDIGITIZERCOORDSINK
