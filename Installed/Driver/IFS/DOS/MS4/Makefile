##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	MS4 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:16:52 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	ms4ec.geo		create an error-checking version
#	ms4.geo		create a non error-checking version
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

GEODE           = ms4
LIBNAME         = fsd
PROTOCONST      = FS
OBJS            = ms4Manager.obj
SRCS            = dosCMapMulti.asm dosCMapSJIS.asm dosCMapUS.asm\
                  dosConvert.asm dosConvertEUC.asm dosConvertJIS.asm\
                  dosConvertSJIS.asm dosCritical.asm dosDisk.asm\
                  dosDiskCopy.asm dosDrive.asm dosEntry.asm dosEnum.asm\
                  dosFileChange.asm dosFormat.asm dosFormatInit.asm\
                  dosIO.asm dosIdle.asm dosInitExit.asm dosLink.asm\
                  dosPath.asm dosPrimary.asm dosStrings.asm dosSuspend.asm\
                  dosUtils.asm dosVirtual.asm dosWaitPost.asm\
                  ms4Manager.asm ms4Strings.asm msDrive.asm msInitExit.asm\
                  msSFT.asm ms4Interface.def
LOBJS           =

SUBDIRS         = DBCS DOVE DOVEXIP PIZZA RESPONDER RESPXIP XIP

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
