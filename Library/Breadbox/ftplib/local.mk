############################################################################
#
#               Copyright (c) Breadbox Computer Company 1998
#                        -- All Rights Reserved --
#
# PROJECT:      FTP Client
# MODULE:       FTP Library
# FILE:         local.mk
#
# AUTHOR:       Gerd Boerrigter
#
# $Header: H:\\CVSROOT\\GEOS\\LIBRARY\\BREADBOX\\FTPLIB\\RCS\\local.mk 1.1 1998/12/11 16:45:37 gerdb Exp $
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   98-08-26  GerdB     Initial version.
#
# DESCRIPTION:
#   Local makefile for the FTP library.
#
############################################################################

#include <$(SYSMAKEFILE)>

GOCFLAGS += -L ftplib

# CCOMFLAGS += -DLOGFILE

LINKFLAGS += -N Copyright\20Breadbox\20Comp\201998

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
#PROTOCONST      = CALENDAR_LIBRARY
_PROTO = 1.0

