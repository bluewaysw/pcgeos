##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:     PC GEOS Network System
# FILE:        socket.gp
#
# AUTHOR:      Eric Weber
#
#
#       $Id: socket.gp,v 1.1 97/04/07 10:46:15 newdeal Exp $
#
##############################################################################
#
# Specify the geode's permanent name
#
name	socket.lib
#
# Specify the type of geode
#
type library, single, discardable-dgroup

#
# Define the library entry point
#
entry	SocketEntry

#
# Import definitions from the kernel
#
library geos
library	ui
library	netutils

#
# Desktop-related things
#
longname        "Socket Library"
tokenchars      "SCKT"
tokenid         0

#
# Code resources
#
nosort
resource ApiCode		code read-only shared
resource StrategyCode		code read-only shared
resource UtilCode		code read-only shared
resource ExtraApiCode		code read-only shared
resource InfoApiCode		code read-only shared
resource FixedCode		code read-only shared fixed

# other resources
resource SocketControl		shared lmem
resource SocketQueues		shared lmem

#
# exported routines
#

#
# SocketRegister must be first, always.  It is used by drivers which do
# not check the protocol number of the library.
#
export  SocketRegister
#
# socket manipulation functions
#
export  SocketCreate
export  SocketBind
export  SocketBindInDomain
export  SocketGetSocketOption
export  SocketSetSocketOption
export  SocketConnect
export  SocketListen
export  SocketCheckListen
export  SocketAccept
export  SocketGetPeerName
export  SocketGetSocketName
export  SocketSend
export  SocketRecv
export  SocketCloseSend
export  SocketClose
export	SocketCloseDomainMedium
export  SocketCheckReady
export  SocketInterrupt
#
# autoload functions
#
export  SocketAddLoadOnMsg
export  SocketAddLoadOnMsgInDomain
export  SocketRemoveLoadOnMsg
export  SocketRemoveLoadOnMsgInDomain
#
# driver info functions
#
export  SocketGetDomains
export  SocketGetDomainMedia
export  SocketGetAddressMedium
export  SocketGetAddressController
export	SocketGetAddressSize
export	SocketCheckMediumConnection
export	SocketResolve
export	SocketCreateResolvedAddress
#
# utility functions
#
export  ECCheckSocket
export  DomainNameToIniCat
export  DomainNameDone

#
# C stubs
#
export  SOCKETCREATE
export  SOCKETBIND
export  SOCKETBINDINDOMAIN
export  SOCKETLISTEN
export  SOCKETADDLOADONMSG
export  SOCKETADDLOADONMSGINDOMAIN
export  SOCKETREMOVELOADONMSG
export  SOCKETREMOVELOADONMSGINDOMAIN
export  SOCKETCONNECT
export  SOCKETCHECKLISTEN
export  SOCKETACCEPT
export  SOCKETGETPEERNAME
export  SOCKETGETSOCKETNAME
export  SOCKETSEND
export  SOCKETRECV
export  SOCKETCLOSESEND
export  SOCKETCLOSE
export	SOCKETCLOSEDOMAINMEDIUM
export  SOCKETCHECKREADY
export	SOCKETGETDOMAINS
export	SOCKETGETDOMAINMEDIA
export	SOCKETGETADDRESSMEDIUM
export	SOCKETGETADDRESSCONTROLLER
export	SOCKETRESOLVE
export	SOCKETGETADDRESSSIZE
export	SOCKETCREATERESOLVEDADDRESS
export	SOCKETCHECKMEDIUMCONNECTION
export  SOCKETINTERRUPT
incminor
export	SOCKETGETINTSOCKETOPTION
export	SOCKETSETINTSOCKETOPTION
incminor
export	SocketOpenDomainMedium
export	SocketInterruptResolve
export	SOCKETOPENDOMAINMEDIUM
export	SOCKETINTERRUPTRESOLVE
incminor
export	SocketGetMediumAddress
export	SOCKETGETMEDIUMADDRESS
incminor
export	SocketReset
export	SOCKETRESET

incminor 
export	SocketSetMediumBusy
export  SOCKETSETMEDIUMBUSY

incminor
export  SocketResolveLinkLevelAddress
export  SOCKETRESOLVELINKLEVELADDRESS
