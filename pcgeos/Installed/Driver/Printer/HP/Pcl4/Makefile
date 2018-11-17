##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Pcl4 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:36:52 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	pcl4ec.geo		create an error-checking version
#	pcl4.geo		create a non error-checking version
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

GEODE           = pcl4
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = pcl4Manager.obj
SRCS            = Graphics/graphicsCommon.asm downloadDuplexInfo.asm\
                  downloadInfo.asm ibm4019Info.asm ibm4039Info.asm\
                  internalDuplexInfo.asm internalInfo.asm\
                  laserjet2CompInfo.asm laserjet2Info.asm\
                  laserjet3SiInfo.asm laserjet4Info.asm\
                  paintjetXL300Info.asm pcl4ControlCodes.asm\
                  pcl4DriverInfo.asm pcl4Manager.asm pcl4Tables.asm\
                  ppdsInfo.asm printcomAdmin.asm printcomEntry.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomPCL4Cursor.asm printcomPCL4Dialog.asm\
                  printcomPCL4Graphics.asm printcomPCL4Job.asm\
                  printcomPCL4Page.asm printcomPCL4Styles.asm\
                  printcomPCL4Text.asm printcomPCLStream.asm\
                  printcomTables.asm totalResetInfo.asm pcl4Constant.def
LOBJS           =

SUBDIRS         = JEDI RESPONDER Zoomer

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
