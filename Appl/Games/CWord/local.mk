#
#	Local makefile for: Crossword Project
#
#	$Id: local.mk,v 1.1 97/04/04 15:13:58 newdeal Exp $

ASMFLAGS	+= -Wall
ASMFLAGS	+= -D_BBXENSEM
UICFLAGS	+= -D_BBXENSEM

#include <$(SYSMAKEFILE)>
