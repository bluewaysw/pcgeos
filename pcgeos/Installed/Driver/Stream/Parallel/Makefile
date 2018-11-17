##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Parallel -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:15:29 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	parallelec.geo		create an error-checking version
#	parallel.geo		create a non error-checking version
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

GEODE           = parallel
LIBNAME         = parallel
PROTOCONST      = PARALLEL
OBJS            = parallelInit.obj parallelInt.obj parallelMain.obj
SRCS            = parallelInit.asm parallelInt.asm parallelMain.asm\
                  parallel.def
LOBJS           =

LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = parallel
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
