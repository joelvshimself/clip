#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Quantizes sampling coordinates for a brief pixelated cat transition.
/// `amount`: 0 = crisp, 1 = coarsest blocks.
[[ stitchable ]]
half4 loadingCatPixelation(
    float2 position,
    SwiftUI::Layer layer,
    float amount
) {
    if (amount <= 0.001f) {
        return layer.sample(position);
    }

    const float minBlock = 1.0f;
    const float maxBlock = 36.0f;
    float blockSize = mix(minBlock, maxBlock, clamp(amount, 0.0f, 1.0f));
    float2 blockOrigin = floor(position / blockSize) * blockSize;
    float2 samplePoint = blockOrigin + blockSize * 0.5f;
    return layer.sample(samplePoint);
}
