##############################################################################
#
# 	Copyright (c) GeoWorks 1998 -- All Rights Reserved
#
# PROJECT:	Geobrowser
# MODULE:	ftp
# FILE: 	local.mk
# AUTHOR: 	Jeremy Broestl, June 29, 1998
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jeremyb	6/29/98	    	Initial version
#
# DESCRIPTION:
#	local makefile for infoserv
#
#	$Id: local.mk,v 1.1.1.2 98/07/19 18:54:31 jeremyb Exp $
#
###############################################################################


GOCFLAGS	+= -DBROTHER_KERNEL
CCOMFLAGS       += -DBROTHER_KERNEL
ASMFLAGS	+= -DBROTHER_KERNEL
LINKFLAGS	+= -DBROTHER_KERNEL

#include <$(SYSMAKEFILE)>
