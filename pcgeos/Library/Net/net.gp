##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Network Library
# FILE:		net.gp
#
# REVISION HISTORY:
#	Eric	2/92		Initial version
#
# DESCRIPTION:	
#	This library allows PC/GEOS applications to access the Network
#	facilities such as messaging, semaphores, print queues, user account
#	info, file info, etc.
#
# RCS STAMP:
#	$Id: net.gp,v 1.1 97/04/05 01:25:08 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
# This is the name that the TaskMax driver will look for, to notify
# us that a switch is about to occur.
#
name net.lib

type	library, single

#
# Define the library entry point
#
entry NetLibraryEntry
#
# Import definitions from the kernel
#
library geos
# library ui			; 1-5-93 Why? Removed.  Insik.
# library text
# library sound
#
# Desktop-related things
# 
longname	"Net Library"
tokenchars	"NTLB"
tokenid		0

#
# Specify alternate resource flags for anything non-standard
#
nosort
resource NetInitCode			code read-only shared discard-only
resource NetUserInfoCode		code read-only shared
resource NetSemaphoreCode		code read-only shared
resource NetMessageCode			code read-only shared
resource NetServerCode			code read-only shared
resource C_Net				code read-only shared
resource NetCommonCode			code read-only shared
resource NetProcStrings			lmem data read-only
ifdef GP_FULL_EXECUTE_IN_PLACE
resource NetXIPCode			code fixed read-only shared
endif

#
# Driver Init/Registeration
#
ifdef GP_FULL_EXECUTE_IN_PLACE
export	NetRegisterDomainXIP as NetRegisterDomain
export	NetUnregisterDomainXIP as NetUnregisterDomain
else
export	NetRegisterDomain
export	NetUnregisterDomain
endif

#
# Export entry points
#

#
# User information
#
export	NetGetConnectionNumber
export	NetUserGetLoginName
export	NetUserGetFullName
export	NetUserCheckIfInGroup
export	NetEnumConnectedUsers
export	NetEnumUsers

export	NetObjMessage

export	NetOpenSem
export	NetPSem
export	NetVSem
export	NetCloseSem
export	NetVAllSem
export	NetInfoSem

#
# Entry points for network drivers ONLY
#
export	NetCreateHECB
export	NetUnpackHugeECBAndDispatchLocalMessage
export	NetEnumCallback

#
# Connection / User info
#
export	NetGetDefaultConnectionID
export	NetVerifyUserPassword
export	NetGetServerNameTable
export 	NetGetConnectionIDTable
export	NetScanForServer
export 	NetServerAttach
export 	NetServerLogin
export 	NetServerLogout
export 	NetServerChangeUserPassword
export 	NetServerVerifyUserPassword
export 	NetServerGetNetAddr
export 	NetServerGetWSNetAddr
export 	NetMapDrive

#
# Entry points for messaging
#
export  NetMsgOpenPort 
export  NetMsgClosePort 
export  NetMsgCreateSocket 
export  NetMsgDestroySocket 
export  NetMsgSendBuffer 
export  NetMsgSetTimeOut 

#
# Entry points for printing
#
export  NetPrintEnumPrintQueues
export	NetPrintStartCapture
export	NetPrintEndCapture
export	NetPrintCancelCapture
export	NetPrintFlushCapture
export	NetPrintGetCaptureQueue

#
# Text messaging API
#
export	NetTextMessageSend
export	NetTextMessagePoll

#
# Network object API
#
export	NetObjectReadPropertyValue
export	NetObjectEnumProperties

#
# C exported routines
#
export	NETUSERGETLOGINNAME
export	NETUSERCHECKIFINGROUP
export  NETGETDEFAULTCONNECTIONID
export 	NETVERIFYUSERPASSWORD
export	NETGETSERVERNAMETABLE
export 	NETGETCONNECTIONIDTABLE
export	NETSCANFORSERVER
export 	NETSERVERATTACH
export 	NETSERVERLOGIN
export 	NETSERVERLOGOUT
export 	NETSERVERCHANGEUSERPASSWORD
export 	NETSERVERVERIFYUSERPASSWORD
export 	NETSERVERGETNETADDR
export 	NETSERVERGETWSNETADDR
export 	NETMAPDRIVE
export 	NETGETCONNECTIONNUMBER
export	NETMSGOPENPORT
export	NETMSGCLOSEPORT
export	NETMSGCREATESOCKET
export	NETMSGDESTROYSOCKET
export	NETMSGSENDBUFFER
export	NETMSGSETTIMEOUT
export	NETENUMUSERS
export	NETENUMCONNECTEDUSERS

##############################
# NOT YET FULLY PORTED TO 2.0
##############################
#export	NetWare_IPXGetInterNetworkAddress
#

#
# New entry points -- add here to avoid upping the major protocol
#

export	NetGetVolumeName
export	NetPrintGetBanner
export	NetPrintSetBanner
export	NetPrintSetBannerStatus
export	NetPrintGetBannerStatus

incminor
export	NetGetDriveCurrentPath
export	NetGetStationAddress

incminor
export	NetUnmapDrive
export 	NETUNMAPDRIVE

export	NETOPENSEM
export	NETCLOSESEM
export	NETPSEM
export	NETVSEM
export  NETPRINTSETBANNERSTATUS

export  NetPrintSetTimeout
export	NetPrintGetTimeout
export  NETPRINTSETTIMEOUT
#
# XIP-enabled
#

