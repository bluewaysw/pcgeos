##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Kernel
# FILE:		ansic.gp
#
# AUTHOR:	Tony, 2/90
#
# Parameters file for: ansic.geo
#
#	$Id: ansic.gp,v 1.1 97/04/04 17:42:24 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name ansic.lib
#
# Long name
#
longname "ANSI C Library"
#
# DB Token
#
tokenchars "ANSI"
tokenid 0
#
# Specify geode type
#
type	library, single
#
# Define library entry point
#
entry	AnsiCEntry
#
# Import kernel routine definitions
# 
library	geos
library math
#
# Non-standard resources
#
nosort

resource MAINCODE	code read-only shared fixed
resource InitCode	preload, shared, read-only, code, discard-only
resource FORMAT		code read-only shared
resource STRINGCODE	code read-only shared fixed
resource WCC_TEXT       code read-only shared fixed
ifdef DO_DBCS
resource FORMATSBCS	code read-only shared
resource STRINGCODESBCS	code read-only shared
endif

#
# Exported routines
#
export sprintf	as _sprintf
export VSPRINTF

#export strlen   as STRLEN
export STRLEN

export strchr	as STRCHR
export strrchr	as STRRCHR

export strpos	as STRPOS
export strrpos	as STRRPOS

export strcpy	as STRCPY
export strncpy	as STRNCPY

export strcmp	as STRCMP
export strncmp	as STRNCMP

export strcat	as STRCAT
export strncat_old

export strspn	as STRSPN
export strcspn	as STRCSPN

export strpbrk	as STRPBRK
export strrpbrk	as STRRPBRK

export strstr	as STRSTR

export STRREV

#export atoi     as ATOI
export ATOI

export ITOA

export memccpy_old as MEMCCPY_OLD
export memcpy_old as MEMCPY_OLD

export memset_old as MEMSET_OLD
export memchr_old as MEMCHR_OLD
export memcmp_old as MEMCMP_OLD

export _Malloc	as _MALLOC
export _Free	as _FREE
export _ReAlloc	as _REALLOC

export FSEEK
export fopen	as FOPEN
export fclose	as FCLOSE
export FTELL
export fwrite	as FWRITE
export fread	as FREAD
export fgetc	as FGETC_OLD
export fflush	as FFLUSH
export rename	as RENAME
export fdopen	as FDOPEN
export fdclose	as FDCLOSE
export qsort	as QSORT
export bsearch	as BSEARCH

incminor

publish MEMCHR
publish MEMCMP
publish MEMCPY
publish MEMMOVE
publish MEMSET

publish MEMCCPY

incminor

publish STRNCAT

#
# XIP-enabled
#

incminor

export feof	as FEOF
export FGETS

incminor

export fgetc	as FGETC

incminor

export sscanf	as _sscanf
export fscanf	as _fscanf

#
# Borland C RTL
#

incminor

#publish F_LDIV@
#publish F_LMOD@
#publish F_LUDIV@
#publish F_LUMOD@
#publish F_LXLSH@
#publish F_LXMUL@
#publish F_LXRSH@
#publish F_LXURSH@
#publish F_PADA@
#publish F_PADD@
#publish F_PCMP@
#publish F_PDEA@
#publish F_PINA@
#publish F_PSBA@
#publish F_PSBP@
#publish F_PSUB@
#publish F_SCOPY@
#publish F_SPUSH@
skip 19

#
# For DBCS, SBCS routines
#
ifdef DO_DBCS
export sprintfsbcs	as _sprintfsbcs
export VSPRINTFSBCS
export STRLENSBCS
export strchrsbcs	as STRCHRSBCS
export strrchrsbcs	as STRRCHRSBCS
export strpossbcs	as STRPOSSBCS
export strrpossbcs	as STRRPOSSBCS
export strcpysbcs	as STRCPYSBCS
export strncpysbcs	as STRNCPYSBCS
export strcmpsbcs	as STRCMPSBCS
export strncmpsbcs	as STRNCMPSBCS
export strcatsbcs	as STRCATSBCS
export STRNCATSBCS
export strspnsbcs	as STRSPNSBCS
export strcspnsbcs	as STRCSPNSBCS
export strpbrksbcs	as STRPBRKSBCS
export strrpbrksbcs	as STRRPBRKSBCS
export strstrsbcs	as STRSTRSBCS
export STRREVSBCS
export ATOISBCS
export ITOASBCS
else
skip 21
endif

incminor

publish __U4M
publish __U4D
publish __I4M
publish __I4D
publish __CHP
