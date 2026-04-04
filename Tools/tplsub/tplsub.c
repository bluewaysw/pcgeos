#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define EXIT_OK        0
#define EXIT_ERROR     1

static void printUsage(void);
static int replaceStream(FILE *in, FILE *out, const char *tag, const char *value);

int main(int argc, char *argv[])
{
    FILE *in;
    FILE *out;
    const char *inputName;
    const char *outputName;
    const char *tag;
    const char *value;
    int result;

    in = NULL;
    out = NULL;
    result = EXIT_ERROR;

    if (argc != 5) {
        printUsage();
        return EXIT_ERROR;
    }

    inputName = argv[1];
    outputName = argv[2];
    tag = argv[3];
    value = argv[4];

    if (tag[0] == '\0') {
        printf("Error: tag must not be empty.\n");
        return EXIT_ERROR;
    }

    in = fopen(inputName, "rb");
    if (in == NULL) {
        printf("Error: cannot open input file: %s\n", inputName);
        return EXIT_ERROR;
    }

    out = fopen(outputName, "wb");
    if (out == NULL) {
        fclose(in);
        printf("Error: cannot create output file: %s\n", outputName);
        return EXIT_ERROR;
    }

    if (!replaceStream(in, out, tag, value)) {
        printf("Error: replacement failed.\n");
        goto cleanup;
    }

    result = EXIT_OK;

cleanup:
    if (out != NULL) {
        fclose(out);
    }
    if (in != NULL) {
        fclose(in);
    }

    return result;
}

static void printUsage(void)
{
    printf("TPLSUB - simple template tag replacer\n");
    printf("\n");
    printf("Usage:\n");
    printf("  tplsub <input> <output> <tag> <value>\n");
    printf("\n");
    printf("Example:\n");
    printf("  tplsub template.txt output.txt %%NAME%% Meyer\n");
}

static int replaceStream(FILE *in, FILE *out, const char *tag, const char *value)
{
    unsigned tagLen;
    char *matchBuf;
    unsigned matched;
    int ch;
    unsigned i;

    tagLen = (unsigned)strlen(tag);
    matched = 0;
    matchBuf = NULL;

    matchBuf = (char *)malloc(tagLen);
    if (matchBuf == NULL) {
        printf("Error: out of memory.\n");
        return 0;
    }

    while ((ch = fgetc(in)) != EOF) {
        if ((char)ch == tag[matched]) {
            matchBuf[matched] = (char)ch;
            matched++;

            if (matched == tagLen) {
                if (fwrite(value, 1, strlen(value), out) != strlen(value)) {
                    free(matchBuf);
                    return 0;
                }
                matched = 0;
            }
        } else {
            if (matched > 0) {
                if ((char)ch == tag[0]) {
                    for (i = 0; i < matched - 1; i++) {
                        if (fputc(matchBuf[i], out) == EOF) {
                            free(matchBuf);
                            return 0;
                        }
                    }
                    matchBuf[0] = matchBuf[matched - 1];
                    matched = 1;
                    matchBuf[matched - 1] = (char)ch;

                    if (matched == tagLen) {
                        if (fwrite(value, 1, strlen(value), out) != strlen(value)) {
                            free(matchBuf);
                            return 0;
                        }
                        matched = 0;
                    }
                } else {
                    for (i = 0; i < matched; i++) {
                        if (fputc(matchBuf[i], out) == EOF) {
                            free(matchBuf);
                            return 0;
                        }
                    }
                    matched = 0;

                    if (fputc(ch, out) == EOF) {
                        free(matchBuf);
                        return 0;
                    }
                }
            } else {
                if (fputc(ch, out) == EOF) {
                    free(matchBuf);
                    return 0;
                }
            }
        }
    }

    for (i = 0; i < matched; i++) {
        if (fputc(matchBuf[i], out) == EOF) {
            free(matchBuf);
            return 0;
        }
    }

    free(matchBuf);
    return 1;
}
