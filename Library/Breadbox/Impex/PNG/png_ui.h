/*
 * Data block passed between TransGet???portOptions and Trans???port
 */

typedef enum {
    AT_TRESHOLD = 0,
    AT_BLEND
} aTransformMethod;

struct ie_uidata {
    aTransformMethod method;
    // byte alphaThreshold;
    // RGBValue blendColor;
};
