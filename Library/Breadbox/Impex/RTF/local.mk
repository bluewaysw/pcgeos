#include <$(SYSMAKEFILE)>

# Defining FAKE_DOC adds a second format to the impex list.  This format
# pretends to be the Microsoft Word 8.0 export format.  The "DOC" file
# extension is used, but the data is exported unchanged in the RTF format.
# This is perfectly acceptable for Word users, since opening such a file
# causes Word to transparently import the RTF.

# XASMFLAGS += -DFAKE_DOC

GOCFLAGS	+= $(.TARGET:X\\[TOOLS\\]/*:S|TOOLS| -DDO_HELP |g)
CCOMFLAGS	+= $(.TARGET:X\\[TOOLS\\]/*:S|TOOLS| -DDO_HELP |g)
XGOCFLAGS = -L rtf
#  XCCOMFLAGS = -WDE
