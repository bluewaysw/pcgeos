##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epshi24 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:43:13 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	epshi24ec.geo		create an error-checking version
#	epshi24.geo		create a non error-checking version
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

GEODE           = epshi24
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = epshi24Manager.obj
SRCS            = Color/Correct/correctGamma30.asm\
                  Color/Correct/correctInk.asm epshi24ControlCodes.asm\
                  epshi24DriverInfo.asm epshi24Manager.asm\
                  epshi24lq1010Info.asm epshi24lq1050Info.asm\
                  epshi24lq2550Info.asm epshi24lq510Info.asm\
                  epshi24lq850Info.asm epshi24lq860Info.asm\
                  epshi24lq950Info.asm printcomAdmin.asm\
                  printcomCountryDialog.asm printcomDotMatrixBuffer.asm\
                  printcomDotMatrixPage.asm printcomEntry.asm\
                  printcomEpsonColor.asm printcomEpsonJob.asm\
                  printcomEpsonLQ2Cursor.asm printcomEpsonLQ2Graphics.asm\
                  printcomEpsonLQText.asm printcomEpsonStyles.asm\
                  printcomInfo.asm printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm epshi24Constant.def
LOBJS           =

SUBDIRS         = DBCS Pizza Zoomer

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
