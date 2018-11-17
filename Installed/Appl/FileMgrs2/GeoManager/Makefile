##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GeoManager -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Gene Anderson, Sat May 16 22:00:50 PDT 1998
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	geomanagerec.geo		create an error-checking version
#	geomanager.geo		create a non error-checking version
#	full			create both of the above, plus tags
#	part			create only the error-checking version
#	tags			create a tags file from all the sources
#	depend			generate source file dependencies
#
# DESCRIPTION:
#	Makefile for a Specific File Manager geode.
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.desktop
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.desktop,v 1.10 94/10/29 12:38:42 brianc Exp $
#
###############################################################################

GEODE           = geomanager
SPECCOMMON      = CommonGM

BITMAP          = cbitmapGeneric.asm cbitmapManager.asm
DESKDISPLAY     = cdeskdisplayApplication.asm cdeskdisplayClass.asm\
                  cdeskdisplayDirTool.asm cdeskdisplayDriveLetter.asm\
                  cdeskdisplayDriveTool.asm cdeskdisplayFileOp.asm\
                  cdeskdisplayManager.asm cdeskdisplayPathname.asm\
                  cdeskdisplayTitledTrigger.asm cdeskdisplayTool.asm\
                  cdeskdisplayToolArea.asm cdeskdisplayConstant.def\
                  cdeskdisplayVariable.def
DESKVIS         = cdeskvisClass.asm cdeskvisManager.asm\
                  cdeskvisConstant.def cdeskvisVariable.def
FOLDER          = cfolderActionObscure.asm cfolderButton.asm\
                  cfolderCode.asm cfolderCursor.asm cfolderDisplay.asm\
                  cfolderEC.asm cfolderFileChange.asm cfolderIcon.asm\
                  cfolderKeyboard.asm cfolderManager.asm cfolderMisc.asm\
                  cfolderOperations.asm cfolderPlacement.asm\
                  cfolderPrint.asm cfolderRecord.asm cfolderSelect.asm\
                  cfolderUtils.asm cfolderConstant.def cfolderVariable.def
LAUNCHER        = clauncherManager.asm cwFileSelectorClass.asm
MAIN            = cmainChangeDir.asm cmainCreateLauncher.asm\
                  cmainDiskOps.asm cmainFileOps.asm cmainFolder.asm\
                  cmainInit.asm cmainLauncher.asm cmainLoadApp.asm\
                  cmainManager.asm cmainMonikers.asm cmainOpenClose.asm\
                  cmainProcess.asm cmainZoomer.asm cmainConstant.def\
                  cmainMacros.def cmainVariable.def
SHOBJ           = cshobjDelete.asm cshobjManager.asm cshobjMoveCopy.asm\
                  cshobjOpen.asm cshobjReceive.asm cshobjUtils.asm\
                  cshobjConstant.def cshobjVariable.def
TOOL            = ctoolManager.asm ctoolProcess.asm ctoolToolMgr.asm\
                  ctoolToolTrigger.asm ctoolToolTrigger.def\
                  ctoolVariable.def
TREE            = ctreeClass.asm ctreeManager.asm ctreeOutline.asm\
                  ctreeScan.asm ctreeUtils.asm ctreeConstant.def\
                  ctreeVariable.def
UI              = cuiManager.asm cuiConstant.def chelp.ui cuiDisk.ui\
                  cuiFileOper.ui cuiFolderTemplate.ui cuiGMMonikers.ui\
                  cuiGetInfo.ui cuiIconArea.ui cuiLauncher.ui cuiMain.ui\
                  cuiMisc.ui cuiMonikers.ui cuiRFSD.ui cuiStrings.ui\
                  cuiTree.ui cuiZoomer.ui
UTIL            = cutilCommon.asm cutilDummyObj.asm cutilEC.asm\
                  cutilError.asm cutilFileOpHigh.asm cutilFileOpLow.asm\
                  cutilFileOpMiddle.asm cutilFileOpRedwood.asm\
                  cutilManager.asm cutilUtil.asm cutilGlobal.def\
                  cutilVariable.def
VIEW            = cviewManager.asm
COMMON          = cdesktopConstant.def cdesktopGeode.def cdesktopGlobal.def\
                  cdesktopMacro.def cdesktopToolManager.def
MODULES         = Bitmap DeskDisplay DeskVis Folder Launcher Main ShObj\
                  Tool Tree UI Util View
SRCS            = $(BITMAP) $(DESKDISPLAY) $(DESKVIS) $(FOLDER) $(LAUNCHER)\
                  $(MAIN) $(SHOBJ) $(TOOL) $(TREE) $(UI) $(UTIL) $(VIEW)\
                  $(COMMON)

#include	<geos.mk>		# system directory definitions
#include	<gpath.mk>		# set search paths for files

MAKEFILE	= Makefile
SYSMAKEFILE	= geode.mk

#if exists(local.mk)
#	include	"local.mk"
#else
#	include	<$(SYSMAKEFILE)>
#endif

#
# Look in the common-desktop module too.
#
-IFLAGS		+= -I../$(SPECCOMMON) -I$(INSTALL_DIR:H)/$(SPECCOMMON) \
		   -I../$(SPECCOMMON)/C$(.TARGET:T:R) \
		   -I$(INSTALL_DIR:H)/$(SPECCOMMON)/C$(.TARGET:T:R) \
		   -I../CommonDesktop -I$(INSTALL_DIR:H)/CommonDesktop \
		   -I../CommonDesktop/C$(.TARGET:T:R) \
		   -I$(INSTALL_DIR:H)/CommonDesktop/C$(.TARGET:T:R)
		   
DEPFLAGS	+= -I../$(SPECCOMMON) -I$(INSTALL_DIR:H)/$(SPECCOMMON) \
		   -I../$(SPECCOMMON)/C$bi \
		   -I$(INSTALL_DIR:H)/$(SPECCOMMON)/C$bi \
		   -I../CommonDesktop -I$(INSTALL_DIR:H)/CommonDesktop \
		   -I../CommonDesktop/C$bi -I$(INSTALL_DIR:H)/CommonDesktop/C$bi

CSOURCE_PATHS	= $(MODULES:S|^|../$(SPECCOMMON)/C|g) \
		  $(MODULES:S|^|../CommonDesktop/C|g) \
		  $(MODULES:S|^|$(INSTALL_DIR:H)/$(SPECCOMMON)/C|g) \
		  $(MODULES:S|^|$(INSTALL_DIR:H)/CommonDesktop/C|g) \
		  ../$(SPECCOMMON) $(INSTALL_DIR:H)/$(SPECCOMMON) \
		  ../CommonDesktop $(INSTALL_DIR:H)/CommonDesktop

.PATH.def	: $(CSOURCE_PATHS) 
.PATH.asm	: $(CSOURCE_PATHS)
.PATH.ui	: $(CSOURCE_PATHS) UI $(INSTALL_DIR)/UI Art $(INSTALL_DIR)/Art
.PATH.uih	: $(CSOURCE_PATHS) UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI -I../$(SPECCOMMON)/CUI \
		   -I$(INSTALL_DIR:H)/$(SPECCOMMON)/CUI \
		   -I../$(SPECCOMMON) \
		   -I$(INSTALL_DIR:H)/$(SPECCOMMON) \
		   -I../CommonDesktop/CUI \
		   -I$(INSTALL_DIR:H)/CommonDesktop/CUI \
		   -I../CommonDesktop \
		   -I$(INSTALL_DIR:H)/CommonDesktop

#
# Include dependencies if they're around
#
#if 	exists($(DEPFILE))
#include	"$(DEPFILE)"
#endif

# Allow mkmf
