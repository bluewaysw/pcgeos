##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	OS2 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:17:27 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	os2ec.geo		create an error-checking version
#	os2.geo		create a non error-checking version
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

GEODE           = os2
LIBNAME         = fsd
PROTOCONST      = FS
OBJS            = os2Manager.obj
SRCS            = dosCritical.asm dosDisk.asm dosDiskCopy.asm dosDrive.asm\
                  dosEntry.asm dosEnum.asm dosFileChange.asm dosFormat.asm\
                  dosFormatInit.asm dosIO.asm dosIdle.asm dosInitExit.asm\
                  dosLink.asm dosPath.asm dosPrimary.asm dosStrings.asm\
                  dosSuspend.asm dosUtils.asm dosVirtual.asm os2Drive.asm\
                  os2InitExit.asm os2Manager.asm os2Strings.asm\
                  os2Utils.asm os2Interface.def os2Variable.def
LOBJS           =

PRODUCTS        = DBCS GB SJISGB

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

#if 	exists(DBCS/$(DEPFILE))
#include	"DBCS/$(DEPFILE)"
#endif

#if 	exists(GB/$(DEPFILE))
#include	"GB/$(DEPFILE)"
#endif

#if 	exists(SJISGB/$(DEPFILE))
#include	"SJISGB/$(DEPFILE)"
#endif

# Allow mkmf
