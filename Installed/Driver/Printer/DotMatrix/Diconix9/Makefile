##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Diconix9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:44:20 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	diconix9ec.geo		create an error-checking version
#	diconix9.geo		create a non error-checking version
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

GEODE           = diconix9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = diconix9Manager.obj
SRCS            = Text/Font/fontDiconixInfo.asm Text/textGetLineSpacing.asm\
                  Text/textLoadEpsonSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm diconix9ControlCodes.asm\
                  diconix9DriverInfo.asm diconix9Manager.asm\
                  diconix9Text.asm diconix9d150Info.asm\
                  diconix9d300wInfo.asm printcomAdmin.asm\
                  printcomCountryDialog.asm printcomDiconixCursor.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonJob.asm\
                  printcomEpsonMXGraphics.asm printcomEpsonStyles.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm diconix9Constant.def
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
