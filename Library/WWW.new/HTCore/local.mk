##############################################################################
#
# 	Copyright (c) GeoWorks 1997 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR: 	Kok Kin Kee, April 7, 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	kkee	4/7/97	    	Initial version
#
# DESCRIPTION:
#	local makefile for www library
#
#	$Id: local.mk,v 1.2.4.3 97/10/22 17:02:39 kkee Exp $
#
###############################################################################

# Define TRUNK for use as conditional compilations in trunk, ReleaseResponder,
# and other main versions.

# Define __LOG_OUTPUT_HTSOCK__ to enable logging of socket data to server.

# Define __LOG_INPUT_HTSOCK__ to enable loggin of socket data from server.

GOCFLAGS	+= -L htcore -DBROTHER_KERNEL
# -D__LOG_OUTPUT_HTSOCK__ -D__LOG_INPUT_HTSOCK_

CCOMFLAGS       += -DBROTHER_KERNEL
# -D__LOG_OUTPUT_HTSOCK__ -D__LOG_INPUT_HTSOCK_

CCOMFLAGS += -DSSL_ENABLE
GOCFLAGS += -DSSL_ENABLE
LINKFLAGS += -DSSL_ENABLE

#include <$(SYSMAKEFILE)>
