##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Nec24 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:43:36 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	nec24ec.geo		create an error-checking version
#	nec24.geo		create a non error-checking version
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

GEODE           = nec24
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = nec24Manager.obj
SRCS            = Color/Correct/correctInk.asm Text/Font/fontNECInfo.asm\
                  Text/textGetLineSpacing.asm\
                  Text/textLoadEpsonSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEval1ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm nec24ControlCodes.asm nec24Dialog.asm\
                  nec24DriverInfo.asm nec24Manager.asm nec24Text.asm\
                  nec24p2200Info.asm nec24p3300Info.asm nec24p6Info.asm\
                  nec24p6monoInfo.asm nec24p7Info.asm nec24p7monoInfo.asm\
                  printcomAdmin.asm printcomDotMatrixBuffer.asm\
                  printcomDotMatrixPage.asm printcomEntry.asm\
                  printcomEpsonColor.asm printcomEpsonJob.asm\
                  printcomEpsonLQ2Cursor.asm printcomEpsonLQ2Graphics.asm\
                  printcomEpsonStyles.asm printcomInfo.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm nec24Constant.def nec24.ui
LOBJS           =

SUBDIRS         = Zoomer

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
