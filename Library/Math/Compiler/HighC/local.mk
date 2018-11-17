# $Id: local.mk,v 1.1 97/04/05 01:22:45 newdeal Exp $

GSUFF	= lib

#undef GEODE

.MAIN		: float.lib long.lib

long.lib	: long.obj .IGNORE
	cmp -s long.obj long.lib || cp -p long.obj long.lib


float.lib	: math.obj .IGNORE
	cmp -s math.obj float.lib || cp -p math.obj float.lib

#include <$(SYSMAKEFILE)>
