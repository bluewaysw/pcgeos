############################################################################
#
#               Copyright (c) Breadbox Computer Company 1998
#                        -- All Rights Reserved --
#
# PROJECT:      Generic Database System
# MODULE:       Basic Database System
# FILE:         local.mk
#
# AUTHOR:       Gerd Boerrigter
#
# $Header: /Home Bulletin Board/Library/BasicDB/LOCAL.MK 24    7/16/98 18:29 Gerdb $
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   98-03-09  GerdB     Initial version.
#
# DESCRIPTION:
#   Local makefile for the Multimedia Extension Library.
#
############################################################################

#include <$(SYSMAKEFILE)>

XGOCFLAGS += -L basicdb
XLINKFLAGS += -N (C)98\20Breadbox\20Computer\20Company

