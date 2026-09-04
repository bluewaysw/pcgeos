#
# mkmf finds product directories by their is_a_product marker and records
# them in the generated Makefile's PRODUCTS variable. Keep that list
# available for explicit builds, but clear it before geode.mk so the
# products do not become dependencies of the default full target.
# The default is regular SBCS NC and EC; command-line PRODUCTS overrides it,
# for example: pmake "PRODUCTS=JS" full
#
PRODUCTS =

#include <$(SYSMAKEFILE)>

# Product feature matrix:
#   regular       SBCS, neither JavaScript nor AutoBrowse
#   DBCS          DBCS character mode only
#   JS/JSDBCS     JAVASCRIPT_SUPPORT (plus DBCS for JSDBCS)
#   AB/ABDBCS     COMPILE_OPTION_AUTO_BROWSE (plus DBCS for ABDBCS)
# Html4Par derives HTML_SCRIPT_SUPPORT when either JavaScript or AutoBrowse
# is enabled. Keep caller-supplied COMPILE_OPTIONS in a private variable:
# pmake command-line variables cannot be appended to by a makefile.
# All legacy variants can be built explicitly, for example:
#   pmake "PRODUCTS=DBCS JS JSDBCS AB ABDBCS" full
#
COMPILE_OPTIONS ?=
_HTML4PAR_OPTIONS := $(COMPILE_OPTIONS)
_HTML4PAR_OPTIONS += $(.TARGET:X\\[JS\\]/*:S|JS| -DJAVASCRIPT_SUPPORT |g)
_HTML4PAR_OPTIONS += $(.TARGET:X\\[JSDBCS\\]/*:S|JSDBCS| -DJAVASCRIPT_SUPPORT |g)
_HTML4PAR_OPTIONS += $(.TARGET:X\\[AB\\]/*:S|AB| -DCOMPILE_OPTION_AUTO_BROWSE |g)
_HTML4PAR_OPTIONS += $(.TARGET:X\\[ABDBCS\\]/*:S|ABDBCS| -DCOMPILE_OPTION_AUTO_BROWSE |g)

GOCFLAGS += $(_HTML4PAR_OPTIONS)
CCOMFLAGS += $(_HTML4PAR_OPTIONS:S|JAVASCRIPT_SUPPORT|JAVASCRIPT_SUPPORT=1|g)
LINKFLAGS += $(_HTML4PAR_OPTIONS)
