# Image source selection in Html4Par

Html4Par selects image URLs while parsing. The selected URL then uses
BbxBrow's ordinary image loading, caching and import paths.

## Selection policy

HTML_IMAGE_SELECT_SMALLEST in Library/Breadbox/Html4Par/internal.h is 1
by default. This chooses the smallest declared width or density within a
SRCSET, regardless of format. It does not compare downloaded file sizes.

Set the constant to 0 and rebuild Html4Par to select the smallest declared
width covering the viewport, or the largest available width if none covers
it. Unknown viewport width selects the smallest. Density selection retains
the existing smallest-density behavior, including an implicit 1x IMG SRC.
Equal descriptors retain the first candidate. A single bare URL is accepted.

PICTURE uses the first SOURCE with a usable SRCSET, matching MEDIA and
supported TYPE. The size policy does not change source ordering or media
matching. There is no format preference. An absent or empty TYPE needs no
capability check; an explicit TYPE uses BbxBrow's registered image drivers.

An absent or empty MEDIA matches. Otherwise only one min-width or max-width
expression with a nonnegative integer pixel value is supported. Boundaries
are inclusive; whitespace and case differences are accepted. Invalid or
compound expressions, and width expressions with unknown viewport width,
do not match.

The following IMG uses the selected picture source, then its own SRCSET,
then SRC. Its attributes and events remain intact. SOURCE creates no image
record. Pending source tokens are released on consumption, malformed picture
content, picture closure or parser cleanup, including image-limit rejection.

## Parser interface and width

ParseAnyFileWithImageSources appends an HTMLImageSourceContext pointer to
the arguments of ParseAnyFile. The context contains viewportWidth, with 0
meaning unknown, and an optional proc_HTMLImageMimeSupported callback. The
callback receives an ASCII MIME type, uses the Pascal calling convention,
and must not reenter the serialized parser. Neither input is retained after
parsing. Legacy entry points remain available; without the callback, explicitly
typed sources are skipped. Plain-text parsing ignores the context.

BbxBrow's ParseFrameHTML gets the frame text's HTI_viewWidth through
MSG_URL_TEXT_GET_IMAGE_SOURCE_WIDTH. HTS_VIEW_NOT_OPENED makes the getter
return 0. No GenView measurement is performed. This parse-time snapshot is
used for MEDIA in both policies; resize does not reselect sources, and cached
pages retain selected URLs. Fit to Window continues to control image geometry
separately from source selection.

## Check

Run perl Library/Breadbox/Html4Par/htmtest/check_image_sources.pl from the
source-tree root. It compiles the actual selectors, picture/image handlers
and MIME callback with host stubs, checks both size policies, media boundaries,
source ordering, fallback and token ownership, and verifies the GEOS handoff
and cleanup hooks. It does not run PC/GEOS.
