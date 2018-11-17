##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PMake -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 22, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/22/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for pmake
#
#	$Id: local.mk,v 1.4 92/07/27 12:22:30 adam Exp $
#
###############################################################################
#
# Search for .h files in the source directories only.
#
#if defined(sun)
.PATH.h		: ../prefix $(INSTALL_DIR:H)/prefix \
		  ../src/src $(INSTALL_DIR:H)/src/src \
		  ../src/lib/lst $(INSTALL_DIR:H)/src/lib/lst \
		  ../src/lib/include $(INSTALL_DIR:H)/src/lib/include \
		  ../src/customs $(INSTALL_DIR:H)/src/customs \
		  ../src/unix $(INSTALL_DIR:H)/src/unix

#else
.PATH.h		:
.PATH.h		: ../src/src $(INSTALL_DIR:H)/src/src \
                  ../src/lib/lst $(INSTALL_DIR:H)/src/lib/lst \
		  ../src/lib/include $(INSTALL_DIR:H)/src/lib/include \
		  ../src/customs $(INSTALL_DIR:H)/src/customs \
		  ../src/nt $(INSTALL_DIR:H)/src/nt
#endif

#
# Find the libraries in the machine-dependent directories, though.
#
#if defined(sun)
.PATH.a		: ../lib/lst $(INSTALL_DIR:H)/lib/lst \
		  ../lib/sprite $(INSTALL_DIR:H)/lib/sprite
#else
.SUFFIXES	: .lib
.PATH.lib	: ../lib/lst $(INSTALL_DIR:H)/lib/lst \
		  ../../compat $(INSTALL_DIR:H:H)/Tools/compat \
		  ../../utils $(INSTALL_DIR:H:H)/Tools/utils
#endif

#
# Perform extra optimizations
#

#if defined(sun)
CFLAGS		+= -Wall -fstrength-reduce -finline-functions
#endif

#
# Define the libraries we use
#
#if defined(sun)
LIBS		= $(.TARGET:H)/liblst.a $(.TARGET:H)/libsprite.a
#else
LIBS		= $(.TARGET:H)/compat.lib $(.TARGET:H)/utils.lib
#endif

#include	<$(SYSMAKEFILE)>
