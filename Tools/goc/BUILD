load("//Tools/build:build.bzl", "bison")

cc_binary(
	name = "goc",
	srcs = [
		"buf.c",
		"buf.h",
		"cond.c",
		"cond.h",
		"depends.c",
		"depends.h",
		"goc.c",
		"goc.h",
		"japan.h",
		"map.c",
		"map.h",
		"output.c",
		"scan.c",
		"scan.h",
		"semantic.c",
		"sprite.h",
		"stringt.c",
		"stringt.h",
		"strwid.c",
		"strwid.h",
		"symbol.c",
		"symbol.h",
		":parse.c",
	],
	deps = [
		"//Tools/include",
		"//Tools/include/compat",
		"//Tools/utils",
		":bisonlib",
	],
)

cc_library(
	name = "bisonlib",
	srcs = [":parse.h"],
	includes = [""]
)

bison(
	name = "parse",
	src = "parse.y"
)

