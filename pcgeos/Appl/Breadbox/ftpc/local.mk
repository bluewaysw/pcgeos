##########################################################################
#
#              Copyright (c) Breadbox Computer Company 1998
#                       -- All Rights Reserved --
#
# PROJECT:      FTP Client
# MODULE:       FTP Application
# FILE:         local.mk
#
# AUTHOR:       Gerd Boerrigter
#
# $Header: H:\\CVSROOT\\GEOS\\APPL\\BREADBOX\\FTPC\\RCS\\local.mk 1.1 1998/12/11 16:53:19 gerdb Exp $
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   98-06-02  GerdB     Initial version.
#
# DESCRIPTION:
#   Local makefile for the FTP application.
#
##########################################################################

#include <$(SYSMAKEFILE)>

# GOCFLAGS +=

LINKFLAGS += -r -N Copyright\20Breadbox\20Company\201998

#
# Set this flag if you want to see the commands being passed to the 
# server.  Useful for debugging.  Must also be turned on with a 
# [ftp]
# logging = true
#
# This also turns on the log file stuff in the ftp lib (instead of having
# a separate compile flag in that lib.  So we leave this flag on and use the
# .ini setting to turn screen and file logging on/off.

GOCFLAGS += -DALLOW_SHOW_LOGGING

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
#PROTOCONST      = FTP_LIBRARY
#_PROTO = 1.0

#GREV ?= grev
#REVFILE = $(GEODE).rev
#_REL    !=      $(GREV) neweng $(REVFILE) -R -s
#_PROTO  !=      $(GREV) getproto $(REVFILE) -P
