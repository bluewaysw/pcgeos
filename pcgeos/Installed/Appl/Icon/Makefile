##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Icon -- Makefile
# FILE: 	Makefile
# AUTHOR: 	, Mon Apr  7 16:51:02 PDT 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	iconec.geo		create an error-checking version
#	icon.geo		create a non error-checking version
#	full			create both of the above, plus tags
#	part			create only the error-checking version
#	tags			create a tags file from all the sources
#	depend			generate source file dependencies
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.geode
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.geode,v 1.4 92/01/03 20:17:45 johnm Exp $
#
###############################################################################

GEODE           = icon

DOCUMENT        = documentAddIcon.asm documentApplication.asm\
                  documentDatabase.asm documentDocument.asm\
                  documentIcon.asm documentImpex.asm documentManager.asm\
                  documentOptions.asm documentSaveIcon.asm\
                  documentToken.asm documentTransfer.asm documentUI.asm\
                  documentUtils.asm documentVisBitmap.asm\
                  documentConstant.def
FORMAT          = formatFlip.asm formatFormat.asm formatManager.asm\
                  formatTransform.asm formatUI.asm formatVMFile.asm\
                  formatConstant.def
PREVIEW         = previewManager.asm previewPreview.asm
SOURCE          = sourceLarge.asm sourceManager.asm sourcePointer.asm\
                  sourceSource.asm sourceUtils.asm sourceConstant.def\
                  sourceStrings.ui
UI              = uiColor.asm uiManager.asm uiNewClasses.asm uiConstant.def\
                  uiAddIcon.ui uiDocument.ui uiFormatMenu.ui uiGraphics.ui\
                  uiIconMenu.ui uiMain.ui uiManager.ui uiOptions.ui\
                  uiPreview.ui uiStrings.ui uiTokenDB.ui uiTransform.ui\
                  uiWriteSource.ui
VIEWER          = viewerKbd.asm viewerMain.asm viewerManager.asm\
                  viewerUI.asm viewerVisIcon.asm viewerConstant.def
OBJS            =

COMMON          = iconConstant.def iconDocument.def iconFile.def\
                  iconFormat.def iconGeode.def iconGlobal.def\
                  iconViewer.def
LOBJS           =
MODULES         = Document Format Preview Source UI Viewer
CMODULES        =
SRCS            = $(DOCUMENT) $(FORMAT) $(PREVIEW) $(SOURCE) $(UI)\
                  $(VIEWER) $(COMMON)
SUBDIRS         = Art Document Format Preview Source UI Viewer

#include	<geos.mk>		# system directory definitions
#include	<gpath.mk>		# set search paths for files

MAKEFILE	= Makefile
SYSMAKEFILE	= geode.mk

#if exists(local.mk)
#	include	"local.mk"
#else
#	include	<$(SYSMAKEFILE)>
#endif

#if 	exists($(DEPFILE))
#include	"$(DEPFILE)"
#endif

# Allow mkmf
