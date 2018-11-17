##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PrefMgr -- Makefile
# FILE: 	Makefile
# AUTHOR: 	, Mon Apr  7 17:46:13 PDT 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	prefmgrec.geo		create an error-checking version
#	prefmgr.geo		create a non error-checking version
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

GEODE           = prefmgr
OBJS            = prefmgr.obj
SRCS            = commonUtils.asm customSpin.asm prefPrinter.asm\
                  prefmgr.asm prefmgrApplication.asm prefmgrDialogGroup.asm\
                  prefmgrDynamic.asm prefmgrFormats.asm prefmgrInitExit.asm\
                  prefmgrModem.asm prefmgrModule.asm prefmgrModuleList.asm\
                  prefmgrMtdHan.asm prefmgrPrinter.asm prefmgrReboot.asm\
                  prefmgrSerial.asm prefmgrText.asm\
                  prefmgrTitledSummons.asm prefmgrUtils.asm\
                  prefmgrApplication.def prefmgrClass.def\
                  prefmgrConstant.def prefmgrGeode.def prefmgrMacros.def\
                  prefmgrVariable.def prefmgr.ui
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
