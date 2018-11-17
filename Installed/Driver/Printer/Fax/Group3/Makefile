##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Group3 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:38:14 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	group3ec.geo		create an error-checking version
#	group3.geo		create a non error-checking version
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

GEODE           = group3
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = group3Manager.obj
SRCS            = Job/jobPaperInfo.asm Stream/streamWrite.asm\
                  UI/uiGetMain.asm group3AddrBook.asm group3Common.asm\
                  group3CoverPage.asm group3CoverSheet.asm\
                  group3DeleteTrigger.asm group3DeviceInfo.asm\
                  group3DialAssist.asm group3DriverInfo.asm\
                  group3EndJob.asm group3EndPage.asm group3EvalFaxUI.asm\
                  group3IACP.asm group3InkDelete.asm group3Manager.asm\
                  group3OffsetTables.asm group3PrintSwath.asm\
                  group3QuickNumber.asm group3StartJob.asm\
                  group3StartPage.asm group3Strings.asm group3Tables.asm\
                  group3UI.asm printcomAdmin.asm printcomEntry.asm\
                  printcomInfo.asm printcomNoColor.asm printcomNoStyles.asm\
                  printcomNoText.asm printcomTables.asm group3AddrBook.def\
                  group3Constant.def group3CoverPage.def\
                  group3DialAssist.def group3.ui group3AddrBook.ui\
                  group3CoverSheet.ui group3DialAssist.ui
LOBJS           =

SUBDIRS         = Art

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
