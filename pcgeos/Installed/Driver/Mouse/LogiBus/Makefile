##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	LogiBus -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:26:42 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	logibusec.geo		create an error-checking version
#	logibus.geo		create a non error-checking version
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

GEODE           = logibus
LIBNAME         = mouse
PROTOCONST      = MOUSE
OBJS            = logibus.obj
SRCS            = ../mouseCommon.asm logibus.asm
LOBJS           =

SUBDIRS         = DBCS PIZZA

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
