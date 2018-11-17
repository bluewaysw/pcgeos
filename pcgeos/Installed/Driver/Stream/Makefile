##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Stream -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:15:53 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	streamec.geo		create an error-checking version
#	stream.geo		create a non error-checking version
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

GEODE           = stream
LIBNAME         = stream
OBJS            = stream.obj
SRCS            = stream.asm
LOBJS           =

LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = stream
SUBDIRS         = DBCS Filestr IRPort IrCOMM Netstr PIZZA Parallel Serial

PRODUCTS	= DBCS

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

# Allow mkmf
