#   $Id: local.mk,v 1.1 97/04/18 11:57:00 newdeal Exp $
ASMWARNINGS	:=  -Wfield -Wshadow -Wprivate -Wunreach -Wunknown -Wrecord -Wfall_thru -Winline_data -Wassume
#include <$(SYSMAKEFILE)>
#ASMFLAGS	+= -Wall -DREAD_CHECK -DWRITE_CHECK
#ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK
#ASMFLAGS	+= -Wall
