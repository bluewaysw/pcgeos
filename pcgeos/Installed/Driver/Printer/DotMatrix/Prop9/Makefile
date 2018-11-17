##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Prop9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:42:05 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	prop9ec.geo		create an error-checking version
#	prop9.geo		create a non error-checking version
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

GEODE           = prop9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = prop9Manager.obj
SRCS            = printcomAdmin.asm printcomDotMatrixBuffer.asm\
                  printcomDotMatrixPage.asm printcomEntry.asm\
                  printcomEpsonColor.asm printcomEpsonFXGraphics.asm\
                  printcomEpsonMXCursor.asm printcomIBM9Text.asm\
                  printcomIBMJob.asm printcomIBMPropDialog.asm\
                  printcomIBMStyles.asm printcomInfo.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm prop92380Info.asm prop92381Info.asm\
                  prop9ControlCodes.asm prop9DriverInfo.asm\
                  prop9Manager.asm prop9bj130Info.asm prop9pp2Info.asm\
                  prop9xlInfo.asm prop9Constant.def
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
