###########################################################################
#
#	Copyright (c) Geoworks 1995.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# REVISION HISTORY:
#	Name	Date		Description
#	-----	----		------------
#	jwu	5/95		Initial Revision
#
# 	Local makefile for PPP driver.
#
# DESCRIPTION:
#
# 	$Id: local.mk,v 1.6 97/09/23 18:47:56 jwu Exp $
#
############################################################################


#
# LOGGING_ENALBED
# 	Defining this flag allows data to be written to a log file.
#
# CONFIG_ALLOWED
#	Enable configuration of the protocol from the INI file.
#	Do not enable this unless you know what you are mucking with!
#
# USE_CCP
#	Turn on this flag to use data compression in PPP.  Must be
#	used in conjunction with at least one of PRED_1 or STAC.
#
# PRED_1
#	Predictor1 compression protocol.  Define this flag to 
#	compress data or decompress incoming data with Predictor1.  
#	Must be used in conjunction with USE_CCP to have any effect.
#
# STAC_LZS
#	Stac LZS compression protocol.  Define this flag to 
#	compress data or decompress incoming data with Stac LZS.
#	Must be used in conjunction with USE_CCP to have any effect.
#
#	ATTENTION !!!
#	Do not compile a shipping version of PPP with this flag
#	defined unless Geoworks has a license from Stac Electronics.
#
# MPPC
#	MPPC compression protocol.  Define this flag to compress
#	or decompress data using Microsoft Point-to-Point Compression.
#	Must be used in conjunction with USE_CCP to have any effect.
#
#	ATTENTION !!!
#	Do not compile a shipping version of PPP with this flag
#	defined unless Geoworks has a license from Stac Electronics.
#	(MPPC is based off Stac LZS.)
#
# MSCHAP
#	Support Microsoft variation of CHAP password authentication.
#

ASMFLAGS	+= -DCONFIG_ALLOWED -DMSCHAP
CCOMFLAGS 	+= -DCONFIG_ALLOWED -DMSCHAP
GOCFLAGS	+= -DCONFIG_ALLOWED -DMSCHAP

#if $(PRODUCT) == "NDO2000"
ASMFLAGS	+= -DUSE_CCP -DPRED_1
CCOMFLAGS 	+= -DUSE_CCP -DPRED_1
GOCFLAGS	+= -DUSE_CCP -DPRED_1
#endif

#
# Uncomment to turn on debugging.
#
ASMFLAGS	+= -DLOGGING_ENABLED
CCOMFLAGS	+= -DLOGGING_ENABLED
GOCFLAGS	+= -DLOGGING_ENABLED

#
# - pppMain.asm and pppUtils.asm call C routines using Pascal convention
# - in HighC, geos.h sets CALLEE_POPS_STACK, which is Pascal
#   with C naming conventions
# - BorlandC doesn't support this, so we use full Pascal convention
#   and use uppercase name equates in pppGlobal.def
#
#CCOMFLAGS	+= -p
ASMFLAGS	+= -DPASCAL_CONV

#
# Add this line to make PPP use the stac library.
#
#LINKFLAGS	+= -DSTAC_LZS -DMPPC

#
# Hmmm...this is a hack
#
_PROTO		= 7.2

#include <$(SYSMAKEFILE)>



