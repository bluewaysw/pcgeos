########################################################################
#
#     Copyright (c) Jens-Michael Gross 1996-97 -- All Rights Reserved
#
# PROJECT:      Multimedia Extensions for GEOS
# MODULE:       CD audio support library
# FILE:         local.mk
#
# AUTHOR:       Jens-Michael Gross
#
# RCS STAMP:
#   $Id: LOCAL.MK 1.0 1997/07/30 20:00:13 JMG Exp $
#
# DESCRIPTION:
#   Local makefile for the Multimedia Extension Library.
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   97-07-30  JMG       Initial Version.
#
########################################################################

#include <$(SYSMAKEFILE)>

GOCFLAGS += -L cdaudio
CCOMFLAGS += -WDE -w -Od
# CCOMFLAGS += -O2 -w -w-amp -w-cln -w-pin
