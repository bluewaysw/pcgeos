##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Cards Library -- Default deck
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Nov  7, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/ 7/89	Initial Revision
#
# DESCRIPTION:
#
#	$Id: local.mk,v 1.3 98/02/23 19:37:25 gene Exp $
#
###############################################################################

# NOTE: The following instructions used to automatically extract the protocol
# number from /Include/deckMap.def.  Since this can no longer happen on an
# NT build machine, ensure that if the protocol is changed in the header file,
# change the number here as well. -dhunter 2/11/2000

##if exists($(DEVEL_DIR)/Include/deckMap.def)
#_PROTO		!= egrep DECK_PROTO $(DEVEL_DIR)/Include/deckMap.def | \
#                   awk '{major=minor; minor=$$3} END {printf "%d.%d\n", major, minor}'
##else
#_PROTO		!= egrep DECK_PROTO $(INCLUDE_DIR)/deckMap.def | \
#                   awk '{major=minor; minor=$$3} END {printf "%d.%d\n", major, minor}'
##endif

_PROTO      = 6.0

GSUFF		= vm
GEODE		= geodeck
NO_EC		= 1
#if $(PRODUCT) == "NDO2000"
#if defined(DO_DBCS)
LINKFLAGS	+= -M DeckMap -c CARD -t DECK -l "NewDeal Deck"
#else
LINKFLAGS	+= -M DeckMap -c CARD -t DECK -l "NewDeal Default Deck"
#endif
#else
LINKFLAGS	+= -M DeckMap -c CARD -t DECK -l "Default Deck"
#endif
#include <$(SYSMAKEFILE)>

