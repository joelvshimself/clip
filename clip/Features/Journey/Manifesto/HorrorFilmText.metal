#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Hash noise for film grain.
static float horrorHash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031f);
    p3 += dot(p3, p3.yzx + 33.33f);
    return fract((p3.x + p3.y) * p3.z);
}

/// Maps white text mask to red grain sampled from the silhouette texture.
[[ stitchable ]]
half4 horrorFilmText(
    float2 position,
    half4 color,
    float time,
    float grainStrength,
    SwiftUI::Layer textureLayer
) {
    half alpha = color.a;
    if (alpha < 0.02h) {
        return half4(0.0h);
    }

    float2 uv = position * 0.0045f;
    uv.x += time * 0.015f;
    half4 tex = textureLayer.sample(uv);
    half3 redGrain = tex.rgb;

    float grain = horrorHash(position + float2(time * 120.0f, time * 87.0f));
    grain = mix(grain, horrorHash(position * 1.7f + float2(time * 40.0f, 0.0f)), 0.45f);
    float scratch = step(0.992f, horrorHash(float2(floor(position.y * 0.08f), time * 8.0f)));
    float vignette = 0.88f + 0.12f * horrorHash(position * 0.02f);

    half3 outColor = redGrain;
    outColor *= half(0.72f + grainStrength * float(grain) * 0.55f);
    outColor += half(scratch * 0.35f);
    outColor *= half(vignette);
    outColor = clamp(outColor, half3(0.0h), half3(1.0h));

    return half4(outColor, alpha);
}
