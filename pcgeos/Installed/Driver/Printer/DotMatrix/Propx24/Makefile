##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Propx24 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:41:21 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	propx24ec.geo		create an error-checking version
#	propx24.geo		create a non error-checking version
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

GEODE           = propx24
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = propx24Manager.obj
SRCS            = printcomAdmin.asm printcomDotMatrixBuffer.asm\
                  printcomDotMatrixPage.asm printcomEntry.asm\
                  printcomEpsonColor.asm printcomIBM24Text.asm\
                  printcomIBMJob.asm printcomIBMStyles.asm\
                  printcomIBMX24Cursor.asm printcomIBMX24Dialog.asm\
                  printcomIBMX24Graphics.asm printcomInfo.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm propx24ControlCodes.asm\
                  propx24DriverInfo.asm propx24Manager.asm\
                  propx24bjIBMInfo.asm propx24generInfo.asm\
                  propx24generwInfo.asm propx24pp24pInfo.asm\
                  propx24ps1Info.asm propx24Constant.def
LOBJS           =

SUBDIRS         = JEDI Zoomer

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
