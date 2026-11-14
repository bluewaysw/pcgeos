##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Geos WWW Library.
# FILE:		htcore.gp
#
# AUTHOR:	Kok Kin Kee, Aug  1, 1996
#
#
# The WWW Library core parameter file.
#
#	$Id: htcore.gp,v 1.1 97/04/07 11:48:51 newdeal Exp $
#
##############################################################################
#
name htcore.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"WWW Core Library"
tokenchars	"HTW3"
tokenid		0

#
# Specify geode type: is a library. 
#
type	library, single, c-api

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ui
library ansic
library socket
library htmem
library math

#
# Entry point to the Library. 
#
entry HTCORELIBRARYENTRY

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource HTLISTDATA      	shared lmem no-discard
resource HTSTRINGDATA           shared lmem discardable

# resource HTFIXEDCODERESOURCE    fixed read-only code shared

#
# Export routines
#	These are the routines exported by the library
#

#
# The Request Manager.
#
export HTREGISTER
export HTUNREGISTER
export HTREQUESTCREATE
export HTREQUESTDELETE
export HTREQUESTSETREQUESTLINE
export HTREQUESTSETMETHOD
export HTREQUESTSETURI
export HTREQUESTGETURI
export HTREQUESTSETHTTPVERSION
export HTREQUESTSETRELOADMODE
export HTREQUESTSETBEFORECALLBACKLIST
export HTREQUESTSETREQUESTCALLBACKLIST
export HTREQUESTSETAFTERCALLBACKLIST
export HTREQUESTSETPROTOCOLLIST
export HTREQUESTSETPOSTCALLBACK
export HTREQUESTSETRESPONSEPARSER
export HTREQUESTSETPROXY
export HTREQUESTSETDATASOURCE
export HTREQUESTSETGENERALHEADERMASK
export HTREQUESTSETREQUESTHEADERMASK
export HTREQUESTSETENTITYHEADERMASK
export HTREQUESTSUBMIT
export HTREQUESTKILL
export HTREQUESTKILLALL
export HTREQUESTSHUTDOWN

export HTREQUESTGETRESPONSESTATUSCODE
export HTREQUESTGETRESPONSECONTENTLENGTH
export HTREQUESTGETRESPONSELASTMODIFIED
export HTREQUESTGETBYTESREAD

#
# The Error Manager.
#
export HTREQUESTADDERROR


#
# The MIME Parser and Generator, and Manager.
#
export HTMIMEClass
export HTMIMERqClass

export HTMIMERQNEW

#
# The Tee stream.
#
export HTTeeClass
export HTTEECREATE

#
# The Policy Manager.
#
export HTPOLICYADDCLIENT
export HTPOLICYDELETECLIENT
export HTPOLICYADDPROTOCOLHANDLER
export HTPOLICYSTREAMSTACK


#
# The HTSocket and its Manager.
#
export HTSocketClass

export HTSOCKETCREATE
export HTSOCKETDELETE
export HTSHUTDOWN

#
# The HTList Manager.
#
export ECCHECKHTLIST
export HTLISTNEW
export HTLISTDELETE
export HTLISTDELETEALLITEMS
export HTLISTDELETERANGE
export HTLISTAPPEND
export HTLISTPREPEND
export HTLISTREPLACEITEM
export HTLISTFINDITEM
export HTLISTGETITEM
export HTLISTGETITEMSIZE
export HTLISTGETCOUNT
export HTLISTREMOVEITEM
#
# The synchronous request list manager.
#
export SListClass


#
# HTString  & other string utilities
#
export ECCHECKHTSTRING
export HTSTRINGFOR
export HTSTRINGLOCK
export HTSTRINGUNLOCK
export HTSTRINGLEN
export HTSTRALLOCCOPY
export HTSTRALLOCCAT
export HTSTRHTMEMALLOCCOPY
export STRLENHTMEM
export STRCPYHTMEM
export STRCATHTMEM
export STRCASECMP
export STRCASECMPHTMEMHANDLE
export STRNCASECMP
export STRCASESTR
export STRTOLOWER
export STRTOUPPER
export HTPARSETIME

#
# URI manager
#
export HTPARSEURI
export HTPARSEHTMEMHANDLEURI
export HTSIMPLIFYURI

#
# The HTNet scheduler.
#
export HTNetSchedulerClass
export HTNETADDCALLBACKCOMMON
export HTNETREPORTPROGRESS

#
# HTSuffix 
#
export HTSUFFIXCREATE

#
# file writer
#
export HTFWriteClass

#
# HTGuess
#
export HTGuessClass

#
# The Core Stream classes and utilities.
#
export HTStreamClass
export HTStructuredClass
export HTProtocolClass

export HTUTILCHANGECLASS
export HTUTILCHANGECLASSTOHTSTREAMCLASS
export HTSTREAMGROWINPUTSTREAMSTACK

export ECCHECKSTREAM


#
# The Anchor Manager
#
export HTANCHORNEW
export HTANCHORFIND
export HTANCHORADDRESS
export HTANCHORSETPHYSICAL
export HTANCHORPHYSICAL
export HTANCHORCONTENTTYPE
export HTANCHORSETCONTENTTYPE
export HTANCHORCONTENTLENGTH
export HTANCHORSETCONTENTLENGTH
export HTANCHORLASTMODIFIED
export HTANCHORSETLASTMODIFIED
export HTANCHOREXPIRES
export HTANCHORSETEXPIRES
export HTANCHORSETDOCUMENT


#
# The Access Authorization Manager
#
export HTAACOMPOSEAUTH
export HTAASETBASICUSERIDPASSWORD
export HTUUENCODE
export HTUUDECODE

