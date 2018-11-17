##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Setup -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Gene Anderson, Wed Jun 17 21:36:59 PDT 1998
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	setupec.geo		create an error-checking version
#	setup.geo		create a non error-checking version
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

GEODE           = setup
OBJS            = setup.obj
SRCS            = commonUtils.asm prefPrinter.asm setup.asm\
                  setupDispRes.asm setupMouse.asm setupPorts.asm\
                  setupPrinter.asm setupProcess.asm setupScreenClass.asm\
                  setupSerialNum.asm setupSysInfo.asm setupUI.asm\
                  setupUpgrade.asm setupUtils.asm setupVideo.asm\
                  setupConstant.def setupVariable.def setup.ui\
                  setupMouse.ui setupPrinter.ui setupSerialNum.ui\
                  setupSysInfo.ui setupUI.ui setupUpgrade.ui setupVideo.ui
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
