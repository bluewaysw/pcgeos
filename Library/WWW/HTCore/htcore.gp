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
#	$Id: htcore.gp,v 1.42.1.10 97/11/18 22:35:25 kkee Exp $
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

ifdef SSL_ENABLE
stack 8192
endif

#
# Libraries: list which libraries are used by the application.
#
library	geos
library ui
library ansic
library socket
library htmem
library math
ifdef SSL_ENABLE
library ssl
endif

#
# Entry point to the Library. 
#
entry HTCORELIBRARYENTRY

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource HTLISTDATA      	shared lmem no-discard
resource HTSTRINGDATA           shared lmem no-discard
resource HTSTRCODE		fixed read-only code shared

#
# Export routines
#	These are the routines exported by the library
#

#
# The Request Manager.
#
export ECCHECKREQUESTNOTLOCKED
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
export HTREQUESTSETCHARCBF
export HTREQUESTSETRESPONSEPARSER
export HTREQUESTSETPROXY
export HTREQUESTSENDDATA
export HTREQUESTADDHEADER
export HTREQUESTSUBMIT
export HTREQUESTKILL
export HTREQUESTKILLALL

export HTREQUESTGETRESPONSESTATUSCODE
export HTREQUESTGETRESPONSECONTENTLENGTH
export HTREQUESTGETRESPONSELASTMODIFIED
export HTREQUESTGETRESPONSEHEADER
export HTREQUESTGETBYTES

export HTREQUESTSETCACHEHIT
export HTREQUESTCACHEHIT

export HTREQUESTANCHOR

export HTSESSIONUSECACHE
export HTSESSIONLOOKUP
export HTSESSIONLOOKUPREQUEST

#
# The Error Manager.
#
export HTREQUESTADDERROR


#
# The MIME Parser and Generator, and Manager.
#
export HTMIMEClass
export HTMIMERqClass
export HTMIMECREATE
export HTMIMERQNEW

#
# The Tee stream.
#
export HTTeeClass
export HTTEECREATE

#
# The Policy Manager.
#
export HTPOLICYADDPROTOCOLHANDLER
export HTPOLICYSTREAMSTACK
export HTPOLICYCONTENTTYPETOFILEEXT


#
# The HTSocket and its Manager.
#
export HTSOCKETCREATE
export HTSOCKETDELETE
export HTSOCKETCLOSE
export HTSOCKETRESOLVEANDCONNECT
export HTSOCKETFASTRESOLVE
export HTSOCKETSEND
export HTSOCKETISCONNECTED
export HTSOCKETRECV
export HTSOCKETSTOP
export HTSOCKETSTATE
export HTSOCKETGETINFO
export HTSOCKETPUSH
export HTSTREAMSOCKETCREATE
export HTSHUTDOWN
export HTSocketClass

#
# The HTList Manager.
#
export ECCHECKHTLIST
export HTLISTNEW
export HTLISTNEWWID
export HTLISTDELETE
export HTLISTDELETEALLWID
export HTLISTDELETEALLITEMS
export HTLISTDELETERANGE
export HTLISTAPPEND
export HTLISTREPLACEITEM
export HTLISTFINDITEM
export HTLISTGETITEM
export HTLISTLOCKITEM
export HTLISTGETITEMSIZE
export HTLISTGETCOUNT
export HTLISTREMOVEITEM
export HTLISTUSEDSPACEWID

export HTASSOCLISTNEW
export HTASSOCLISTADD
export HTASSOCLISTLOOKUP
export HTASSOCLISTLOOKUPPTR
export HTASSOCLISTDELETE
export HTASSOCDWORDLISTADD
export HTASSOCDWORDLISTLOOKUP
export HTASSOCDWORDLISTREMOVE
export HTASSOCDWORDLISTDELETE
export HTASSOCDWORDLISTGETVALUE

#
# The synchronous request list manager.
#
export SListClass

#
# Object instantiation for Non-ObjInstantiateForThread Geos kernels
#
export HTOBJATTACH
export HTOBJDETACH
export HTOBJINSTANTIATEFORTHREAD
export HTOBJINSTANTIATEFORTHREADWID
export HTOBJDESTROYALLWID
export HTOBJUSEDSPACEWID

#
# HTString  & other string utilities
#
export ECCHECKHTSTRING
export HTSTRINGFOR
export HTSTRINGFORCASE
export HTSTRINGLOCK
export HTSTRINGUNLOCK
export HTSTRINGLEN
export HTSTRALLOCCOPY
export HTSTRALLOCCOPYWID
export HTSTRNALLOCCOPY
export HTSTRNALLOCCOPYWID
export HTSTRALLOCCAT
export HTSTRALLOCCATWID
export HTSTRNALLOCCAT
export HTSTRNALLOCCATWID
export HTSTRHTMEMALLOCCOPY
export HTSTRHTMEMALLOCCOPYWID
export STRLENHTMEM
export STRCPYHTMEM
export STRCATHTMEM
export STRCASECMP
export STRNCASECMP
export STRCASECMPHTMEMHANDLE
export STRNCASECMPHTMEMHANDLE
export STRCASESTR
export STRTOLOWER
export STRTOUPPER
export HTPARSETIME
export HTCHARNEW

#
# URI manager
#
export HTPARSEURI
export HTPARSEHTMEMHANDLEURI
export HTSIMPLIFYURI
export HTENCODEFORURI
export HTDECODEHEX
export HTDEFAULTPORT
export HTFILEURIOPEN

#
# The HTNet scheduler.
#
export HTNetSchedulerClass
export HTNETADDCALLBACKCOMMON
export HTNETREPORTPROGRESS
export HTNETSETPERSISTENT

#
# HTSuffix 
#
export HTSUFFIXCREATE

#
# file writer
#
export HTFWRITENEW
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
export HTANCHORDONE
export HTANCHORADDRESS
export HTANCHORSETPHYSICAL
export HTANCHORPHYSICAL
export HTANCHORSETMEMCACHE
export HTANCHORMEMCACHE
export HTANCHORCONTENTTYPE
export HTANCHORSETCONTENTTYPE
export HTANCHORCONTENTLENGTH
export HTANCHORSETCONTENTLENGTH
export HTANCHORDATE
export HTANCHORSETDATE
export HTANCHORLASTMODIFIED
export HTANCHORSETLASTMODIFIED
export HTANCHOREXPIRES
export HTANCHORSETEXPIRES
export HTANCHORSETDOCUMENT
export HTANCHORCACHEHIT
export HTANCHORSETXIMAGESCALE
export HTANCHORXIMAGESCALE
export HTANCHORADDHEADER
export HTANCHORGETHEADER
export HTANCHORSETHEADERDONE
export HTANCHORSETCOOKIE
export HTANCHORFINDCOOKIES

#
# The Access Authorization Manager
#
export HTAACOMPOSEAUTH
export HTAASETBASICUSERIDPASSWORD

#
# Encoding and decoding schemes and streams
#
export HTDECODENEW
export HTUUENCODE
export HTUUDECODE
export HTUUENCODEPTR
export HTUUDECODEPTR
export HTQPENCODE
export HTQPDECODE
export HTQPENCODEPTR
export HTQPDECODEPTR


