# $Id: local.mk,v 1.1 97/04/04 17:43:54 newdeal Exp $

GSUFF	= lib

#undef GEODE
#undef LIBOBJ

.MAIN		: borland.lib

borland.lib	: borland.obj .IGNORE
	cmp -s borland.obj borland.lib || stripsym borland.obj borland.lib

#include <$(SYSMAKEFILE)>
