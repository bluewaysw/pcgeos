/*
 * OpenSpellGEOS: spelling, thesaurus and hyphenation for PC/GEOS Ensemble.
 * SPDX-License-Identifier: Apache-2.0
 *
 * This translation unit makes the replacement modules visible to the existing
 * mkmf C-source discovery. The public assembler entry points remain unchanged.
 * Each adapter selects the resource expected by its existing assembler caller;
 * the common reader starts in OpenLexCode. Plain C is intentional here: these are
 * implementations of existing C ABIs, with no new GEOS object classes.
 *
 * The supplied Watcom/glue combination cannot resolve LPUBDEF references to
 * static Pascal helpers. Uniquely prefixed helper functions therefore have
 * external object-file linkage; none is exported by spell.gp. Static data
 * remains private. Keep this distinction when adding implementation helpers.
 *
 * See TechDocs/Markdown/OpenSpellGEOS.md for installation, build evidence, resource
 * limits and the exact scope of the replacement. Do not build this file with
 * the platform's default -3 instruction selection: local.mk appends -0 for
 * both EC and NC builds, keeping generated code usable on an 8086/286.
 */
#ifdef __WATCOMC__
/* Keep the reader separate so IH/ET need not load spelling-only code. */
#pragma code_seg("OpenLexCode")
#endif
#include "openlex.inc"
#include "geosbridge.inc"
#include "icgeos.inc"
#include "openht.inc"
