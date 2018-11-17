###########################################################################
#
#	Copyright (c) Geoworks 1994.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# REVISION HISTORY:
#	Name	Date		Description
#	-----	----		------------
#	jwu	11/94		Initial Revision
#
# 	Local makefile for TCP/IP driver.
#
# DESCRIPTION:
#
# 	$Id: local.mk,v 1.1 97/04/18 11:57:18 newdeal Exp $
#
############################################################################


#
# PROTO_CONFIG_ALLOWED:
#  Definiting this flag allows configuration of the driver at the protocol
#  levels.  
#
# MERGE_TCP_SEGMENTS:
#  Defining this flags allows TCP packets that will be placed in the
#  reassembly queue to be merged with existing contiguous packets
#  already in the queue.  Actually only the preceding packet is check
#  for continuity.  This prevents memory problems when the sender
#  decides to send many small packets instead of large packets, as the
#  packets in the reassembly queue are left locked on the heap while in
#  the queue.
#
# WRITE_LOG_FILE:
#  Defining this flag allows logging to take place.  Must be defined
#  before the other logging flags can be used.  Serves no purpose
#  when this flag is used alone.
#
# LOG_STATS:
#  This flags causes the protocols to keep track of statistics and 
#  write them to the log file when the driver is exited.
#
# LOG_HDRS:
#  This flag causes the packet headers of incoming and outgoing packets
#  to be written to the log file.
#  
# LOG_DATA:
#  This flag causes the contents of the packets to also be written to
#  the log file.  Must be used in conjunction with LOG_HDRS.  If data
#  being transmitted in packets is not user-readable ascii text, it may
#  be better not to use this flag.
#
# LOG_EVENTS:
#  This flag causes actions performed by the driver to be logged, e.g. 
#  dropping a packet, fragmenting a packet, dropping duplicate bytes, 
#  timeouts, etc.
#

ASMFLAGS	+= -DPROTO_CONFIG_ALLOWED
GOCFLAGS	+= -DPROTO_CONFIG_ALLOWED

ASMFLAGS	+= -DMERGE_TCP_SEGMENTS
GOCFLAGS	+= -DMERGE_TCP_SEGMENTS
CCOMFLAGS	+= -DMERGE_TCP_SEGMENTS

#ASMFLAGS	+= -DWRITE_LOG_FILE -DLOG_HDRS -DLOG_DATA -DLOG_EVENTS -DLOG_STATS
#CCOMFLAGS	+= -DWRITE_LOG_FILE -DLOG_HDRS -DLOG_DATA -DLOG_EVENTS -DLOG_STATS

#ASMFLAGS	+= -DWRITE_LOG_FILE -DLOG_STATS
#CCOMFLAGS 	+= -DWRITE_LOG_FILE -DLOG_STATS

#ASMFLAGS	+= -DWRITE_LOG_FILE -DLOG_EVENTS
#CCOMFLAGS	+= -DWRITE_LOG_FILE -DLOG_EVENTS

#
# - tcpipEntry.asm and tcpipSocket.asm call C routines using Pascal convention
# - in HighC, geos.h sets CALLEE_POPS_STACK, which is Pascal
#   with C naming conventions
# - BorlandC doesn't support this, so we declare those called C routines as
#   _pascal (instead of using full Pascal convention) and use uppercase name
#   equates in tcpipGlobal.def (we can't use full Pascal convention like PPP
#   does because we need to import the ProcessClass for tcpip.goc)
#
CCOMFLAGS	+= -DCALLCONV=_pascal
ASMFLAGS	+= -DPASCAL_CONV

#
# Hmmm...this is a hack
#
_PROTO		= 7.2

#
# Do not comment out this line.  Used to make dgroup discardable.
#
GOCFLAGS	+= -CTcpipClassStructures

# STATIC_LINK_RESOLVER
#  This flag causes the resolver library to be statically linked to the
#  driver, rather than dynamically loaded and unloaded for
#  starting and stopping every IP address resolution.  For devices with
#  slow file access and little or no cache, this speeds things up since
#  GeodeUseLibrary performs a geode search by long filename on each call.
#  (Besides, resolve's fixed memory footprint when inactive is only
#  800 bytes...)

ASMFLAGS    += -DSTATIC_LINK_RESOLVER
LINKFLAGS   += -DSTATIC_LINK_RESOLVER

#include <$(SYSMAKEFILE)>




