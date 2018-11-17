##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Dumb -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:47:31 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	dumbec.geo		create an error-checking version
#	dumb.geo		create a non error-checking version
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

GEODE           = dumb
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = dumbManager.obj
SRCS            = Text/Font/fontDumbInfo.asm Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRunAddX.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEvalDummyTractor.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm dumbControlCodes.asm dumbDialog.asm\
                  dumbDriverInfo.asm dumbInfo.asm dumbManager.asm\
                  dumbText.asm printcomAdmin.asm printcomDotMatrixPage.asm\
                  printcomDumbSpaceCursor.asm printcomEntry.asm\
                  printcomEpsonJob.asm printcomHex0Stream.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomNoGraphics.asm\
                  printcomNoStyles.asm printcomTables.asm dumbConstant.def\
                  dumb.ui
LOBJS           =

SUBDIRS         =

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
