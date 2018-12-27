##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		spell.gp
#
# AUTHOR:	Tony, 2/90
#
#
# Parameters file for: spell.geo
#
#	$Id: spell.gp,v 1.1 97/04/07 11:07:32 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name spell.lib
#
# Long name
#
longname "Spell Check Library"
#
# DB Token
#
tokenchars "SPLL"
tokenid 0

usernotes	"The American Heritage Electronic Dictionary \xa91989 by Houghton Mifflin Co. All rights reserved."
#
# Specify geode type
#
type	library, single
#
# Define library entry point
#
entry	SpellEntry
#
# Import kernel routine definitions
#
library	geos
library	ansic
library ui
library text

#
# Define resources other than standard discardable code
#
nosort
resource FixedCode fixed code read-only
resource ThesaurusCode	code read-only shared
resource SpellCode	code read-only shared
resource SpellControlCommon	code read-only shared
resource HyphenCode	code read-only shared
resource SpellInit	code read-only shared
resource SpellControlCode	code read-only shared
resource TextControlCode	code read-only shared
resource ETCODE	code read-only shared
resource IPCODE	code read-only shared
resource ICS1	code read-only shared
resource INIT	code read-only shared
resource EXIT	code read-only shared
resource IPPRINT	code read-only shared
resource CODE	code read-only shared
resource IHCODE	code read-only shared
resource STDLIB	code read-only shared
resource ETINFLEC	code read-only shared
resource ETSEARCH	code read-only shared
resource ETUNFLEC	code read-only shared
resource ETUTIL	code read-only shared
resource ACCENT	code read-only shared
resource CORRECT	code read-only shared
resource ICGETSEG	code read-only shared
resource CAPCOD	code read-only shared
resource CACHE	code read-only shared
resource CLITIC	code read-only shared
resource CLITICCAP	code read-only shared
resource CLITIC2	code read-only shared
resource COMPOUND	code read-only shared
resource COMPOUND2	code read-only shared
resource COMPOUND3	code read-only shared
resource COMPOUND4	code read-only shared
resource CORQUAD2	code read-only shared
resource CORQUAD	code read-only shared
resource PARSE	code read-only shared
resource IPCORRECT	code read-only shared
resource IHINIT	code read-only shared
resource IPD1	code read-only shared
resource IPHYPHEN	code read-only shared
resource IPSRCH	code read-only shared
resource IPD2	code read-only shared
resource WILD	code read-only shared
resource Strings shared lmem read-only
resource EditUserDictControlUI ui-object read-only shared
resource SpellControlToolboxUI ui-object read-only shared
resource AppTCMonikerResource	lmem read-only shared
ifndef GPC_SPELL
resource AppTMMonikerResource	lmem read-only shared
resource AppTCGAMonikerResource	lmem read-only shared
endif
resource SpellControlUI ui-object read-only shared

resource ControlStrings shared lmem read-only

resource ThesControlUI ui-object read-only shared
resource ThesControlToolboxUI ui-object read-only shared

resource ThesStrings shared lmem read-only

ifdef	GP_FULL_EXECUTE_IN_PLACE
resource SpellControlInfoXIP	read-only shared
endif

# Put this stuff in a fixed read-only segment, to reduce heap usage on
# XIP platforms	

# are these resources automatically created by the C compiler?  Not for BC45!
ifdef __BORLANDC__
resource GRAMMAR_SEG shared fixed read-only
resource GRAM_ADD_SEG shared fixed read-only
resource DEF_ORD_SEG shared fixed read-only
resource SYN_ORD_SEG shared fixed read-only
resource SPEC_GRAM_SEG shared fixed read-only
resource EXC_ORDN_SEG shared fixed read-only
resource EXC_GRAM_SEG shared fixed read-only
else
resource GRAMMAR shared fixed read-only
resource GRAM_ADD shared fixed read-only
resource DEF_ORD shared fixed read-only
resource SYN_ORD shared fixed read-only
resource SPEC_GRAM shared fixed read-only
resource EXC_ORDN shared fixed read-only
resource EXC_GRAM shared fixed read-only
endif

#
# This is locked down on the fly...
#
resource ATT_TABLE shared read-only


#
# Class structures resource
#
resource SpellClassStructures	fixed read-only shared

#
# Special segment aliases for MetaWare library code. We want their contents
# to be loaded into our CODE segment. The class is ok, but we need to specify
# new alignment and combine type so they're the same as the segment into
# which their contents are being loaded.
#
load _MWDIVL_ "CODE" as CODE word public
load _MWMPYL_ "CODE" as CODE word public

#
# Exported routines (and classes)
#
# The order is important for the first group of routines, as there is
# a corresponding enumerated type (SpellRoutine) in Internal/spelllib.def
#
export	ICCheckWord
export	ICGetTextOffsets
export	ICGetErrorFlags
export	ICResetSpellCheck

export	ICCheckForEmbeddedPunctuation
export	ICGetLanguage
export	ICInit
export	ICExit
export	ICSpl
export	ICGetAlternate
export	ICIgnore
export	ICAddUser
export	ICDeleteUser
export	ICBuildUserList
export	ICUpdateUser
export	ICResetIgnore
export	ICGetNumAlts
export	ICSetTask
export	ICStopCheck


export	Hyphenate

export	ThesControlClass
export	SpellControlClass
export	EditUserDictionaryControlClass
export	SuggestListClass

#
# XIP-enabled
#

incminor

export	ThesaurusGetMeanings
export	ThesaurusGetSynonyms

export	THESAURUSGETMEANINGS
export	THESAURUSGETSYNONYMS

export	ICCHECKWORD
export	ICGETTEXTOFFSETS
export	ICGETERRORFLAGS
export	ICRESETSPELLCHECK

export	ICCHECKFOREMBEDDEDPUNCTUATION
export	ICGETLANGUAGE
export	ICINIT
export	ICEXIT
export	ICSPL
export	ICGETALTERNATE
export	ICIGNORE
export	ICADDUSER
export	ICDELETEUSER
export	ICBUILDUSERLIST
export	ICUPDATEUSER
export	ICRESETIGNORE
export	ICGETNUMALTS
export	ICSETTASK
export	ICSTOPCHECK

export	Hyphenate as HYPHENATE

incminor

export	ICGetAnagrams
export	ICGetWildcards

export	ICGETANAGRAMS
export	ICGETWILDCARDS
