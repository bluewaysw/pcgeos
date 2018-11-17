##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	goc -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Tony Requist, May 2, 1991
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	5/2/91		Initial Revision
#
# DESCRIPTION:
#	Special definitions for goc
#
#	$Id: local.mk,v 1.3 93/02/03 19:31:40 adam Exp $
#
###############################################################################

#if defined(unix)
LIBPREFIX       = lib
LIBSUFFIX       = a
#else
LIBPREFIX       =
LIBSUFFIX	= lib
#endif

CFLAGS		= -DYYDEBUG=1 -DLEXDEBUG=1 -DGOC
#CFLAGS		+= -DMEM_TRACE
#if defined(LINUX)
CFLAGS		+= -isystem ../utils -isystem .
#endif
YFLAGS		= -dv
LIBS		= $(.TARGET:H)/$(LIBPREFIX)utils.$(LIBSUFFIX)
#if !defined(unix)
LIBS		+= $(.TARGET:H)/$(LIBPREFIX)compat.$(LIBSUFFIX) \
		   $(.TARGET:H)/$(LIBPREFIX)utils.$(LIBSUFFIX)
#endif

.PATH.h		:  #clear for now
.PATH.h		: . $(INSTALL_DIR) \
                  ../include $(INSTALL_DIR:H)/include \
                  ../utils $(INSTALL_DIR:H)/utils

.PATH.goh	:
.PATH.goh	: . $(INSTALL_DIR)

.SUFFIXES	   : .$(LIBSUFFIX)
.PATH.$(LIBSUFFIX) : ../utils $(INSTALL_DIR:H)/utils \
		     ../compat $(INSTALL_DIR:H)/compat

#include    <$(SYSMAKEFILE)>

#
# Special rule to make sure parse.h exists before people try to include it
#
parse.h		: parse.c


.c.s:; $(CC) $(CFLAGS) -S $(.IMPSRC)

.SUFFIXES: .i

.c.i:; $(CC) $(CFLAGS) -E $(.IMPSRC)
