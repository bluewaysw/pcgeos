load("//Tools/build:build.bzl", "bison")

cc_binary(
	name = "esp",
	srcs = [
		"assert.c",
		"assert.h",
		"class.h",
		"code.c",
		"code.h",
		"cond.h",
		"data.c",
		"data.h",
		"dword.h",
		"esp.h",
		"expr.c",
		"expr.h",
		"fixup.c",
		"fixup.h",
		"flopcode.h",
		"flopcodes.h",
		"keywords.h",
		"lmem.c",
		"main.c",
		"model.h",
		"object.c",
		"object.h",
		"opcodes.h",
		"scan.c",
		"scan.h",
		"segment.h",
		"symbol.c",
		"symbol.h",
		"table.c",
		"table.h",
		"type.c",
		"type.h",
		":parse.c",
	],
	deps = [
		"//Tools/include",
		"//Tools/include/compat",
		"//Tools/utils",
		":bisonlib",
	],
)

cc_binary(
	name = "printobj",
	srcs = ["printobj.c"],
	deps = [
		"//Tools/include",
		"//Tools/include/compat",
		"//Tools/utils",
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

