##############################################################################
#
#	Copyright (c) GlobalPC 1998-- All Rights Reserved
#
# PROJECT:	SSL library
# FILE:		ssl.gp
#
# AUTHOR:	Brian Chin, Nov 4 1998
#
#	$Id:$
#
##############################################################################

#
# Specify the geode's permanent name
#
name    ssl.lib

#
# Specify the type of geode
#
type library, single, c-api

#
# Define the library entry point
#
entry SSLLIBRARYENTRY

#
# Import definitions from the kernel
#
library geos
library ansic
library socket

ifdef COMPILE_OPTION_MAP_HEAP
#library mapheap
endif

#
# Desktop-related things
#
longname        "SSL Library"
tokenchars      "SSL "
tokenid         0

usernotes       "based on SSLeay 0.9.0b 29-Jun-1998"

#
# Code resources
#
nosort
resource FixedCallbacks		fixed read-only code shared

#
# exported routines
#
skip 1
export SSLV2_CLIENT_METHOD
export SSLEAY_ADD_SSL_ALGORITHMS
export SSL_CTX_NEW
export SSL_CTX_FREE
export SSL_NEW
export SSL_FREE
export SSL_SET_FD
export SSL_CONNECT
export SSL_SHUTDOWN
export SSL_READ
export SSL_WRITE
incminor
export SSLV23_CLIENT_METHOD
export SSLV3_CLIENT_METHOD
export SSL_SET_SSL_METHOD
export SSL_GET_SSL_METHOD
