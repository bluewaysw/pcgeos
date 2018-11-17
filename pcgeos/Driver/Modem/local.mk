###########################################################################
#
#	Copyright (c) Geoworks 1994.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# REVISION HISTORY:
#	Name	Date		Description
#	-----	----		------------
#	jwu	3/95		Initial Revision
#
# 	Local makefile for modem driver.
#
# DESCRIPTION:
#
# 	$Id: local.mk,v 1.1 97/04/18 11:47:54 newdeal Exp $
#
############################################################################


#
# This will cause an ldf file to be created for the driver so clients
# can do "driver modem" in their gp file.
#

LIBOBJ = $(DEVEL_DIR)/Include/modem.ldf

#
# VIRTUAL_SERIAL
# 
# Defining this flag allows additional responses from GSM modems to 
# be recognized by the modem driver.  
#

ASMFLAGS	+= -DVIRTUAL_SERIAL

#
# HANGUP_LOG
#
# Defining this flag will cause the driver to send a dial status command
# to the modem on ModemClose, appending everything the modem reports to a
# timestamped log file.
#

#ASMFLAGS	+= -DHANGUP_LOG

#include <$(SYSMAKEFILE)>

