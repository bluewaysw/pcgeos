###############################################################################
#
# Search for #define
#
# $Id: define.awk,v 1.1 94/01/12 18:31:08 joon Exp $
#
###############################################################################

/#define/ {
    if ((NF >= 3) && match($1, /#define/)) {
	outputLine = sprintf("%s:%s:%d", $2, FILENAME, NR)
	printf("%-100s\n", outputLine)
    }
}
