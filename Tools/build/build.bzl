def bison(name, src):
    CFILE = "%s.c" % name
    HFILE = "%s.h" % name
    native.genrule(
        name = name,
        srcs = [src],
        outs = [CFILE, HFILE],
        cmd = "bison --defines=$(location {}) --output=$(location {}) $<".format(HFILE, CFILE)
    )

