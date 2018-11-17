#
#	Local makefile for: text library
#
#	$Id: local.mk,v 1.1 97/04/07 11:19:19 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

.PATH.uih .PATH.ui: UI Ruler $(INSTALL_DIR)/UI $(INSTALL_DIR)/Ruler
UICFLAGS	+= -IUI -IRuler -I$(INSTALL_DIR)/UI -I$(INSTALL_DIR)/Ruler

.MAKEFLAGS = -dm
#include <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# XIP in Jedi version
#
ASMFLAGS	+= $(.TARGET:X\\[JediXIP\\]/*:S|JediXIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP

#
# GPC version
#
#  GPC_SEARCH - Search/Replace dialog layout
#  GPC_DOS_LONG_NAME	- Unlike DOS long name support in other geodes which
#			  expands various DOS name functionalities to include
#			  DOS long names, the DOS long name support here in
#			  Text Lib reduces the set of user-entered legal GEOS
#			  filename chars to the set of legal DOS long filename
#			  chars.  It disallows certain legal GEOS filename
#			  chars that are not legal DOS long filename chars to
#			  be entered at a filename input field.  Does not
#			  affect ordinary DOS filename input fields.
#  PROFILE_TIMES - Turn on a profiling mode of the text library that produces
#                  the file TEXTPROF.LOG in the document directory.  The program
#                  TEXTPROF.EXE (dos program) can be used to summarize the info
#                  since the file contains one word noting the profile point number
#                  followed by the time since the last hit.
#
#ASMFLAGS	+= -DGPC_SEARCH -DGPC_TEXT_STYLE -DGPC_SPELL -DGPC_ART -DGPC_DOS_LONG_NAME #-DPROFILE_TIMES
#UICFLAGS	+= -DGPC_SEARCH -DGPC_TEXT_STYLE -DGPC_SPELL -DGPC_ART -DGPC_DOS_LONG_NAME
#LINKFLAGS	+= -DGPC_SEARCH -DGPC_TEXT_STYLE -DGPC_SPELL -DGPC_ART -DGPC_DOS_LONG_NAME #-DPROFILE_TIMES
ASMFLAGS	+= -DGPC_TEXT_STYLE -DGPC_SPELL -DGPC_ART -DGPC_DOS_LONG_NAME #-DPROFILE_TIMES
UICFLAGS	+= -DGPC_TEXT_STYLE -DGPC_SPELL -DGPC_ART -DGPC_DOS_LONG_NAME
LINKFLAGS	+= -DGPC_TEXT_STYLE -DGPC_SPELL -DGPC_ART -DGPC_DOS_LONG_NAME #-DPROFILE_TIMES

ASMFLAGS	+= -DSIMPLE_RTL_SUPPORT=1


#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= $(.TARGET:X\\[DBCS\\]/*:S|DBCS| -DUSE_FEP |g)
UICFLAGS	+= $(.TARGET:X\\[DBCS\\]/*:S|DBCS| -DUSE_FEP |g)
LINKFLAGS	+= $(.TARGET:X\\[DBCS\\]/*:S|DBCS| -DUSE_FEP |g)
#endif
