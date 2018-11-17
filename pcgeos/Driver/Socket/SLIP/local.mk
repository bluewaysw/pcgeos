###########################################################################
#
#	Copyright (c) Geoworks 1994.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# REVISION HISTORY:
#	Name	Date		Description
#	-----	----		------------
#	jwu	10/94		Initial Revision
#
# 	Local makefile for SLIP driver.
#
# DESCRIPTION:
#
# 	$Id: local.mk,v 1.1 97/04/18 11:57:20 newdeal Exp $
#
############################################################################


#
# TIA:
# 
# If defined, then the SLIP driver will assume the other end of the 
# connection is a UNIX machine with Tia installed.  Connections are
# established by logging in to the UNIX account and running Tia there.
#
# LOGIN_NAME_IN_PROMPT:
#
# If defined, the SLIP driver will look for the login name of the user
# when parsing the input data for the prompt.  TIA must be defined for 
# this to have an effect.
#

#ASMFLAGS	+= -DTIA -DLOGIN_NAME_IN_PROMPT
#ASMFLAGS	+= -DTIA


#include <$(SYSMAKEFILE)>

