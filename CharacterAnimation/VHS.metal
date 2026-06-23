#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

float2 bendScreenCoordinates(float2 texturePoint, float bendAmount) {
    float2 centerOffset = 0.5 - texturePoint;
    texturePoint.x -= centerOffset.y * centerOffset.y * centerOffset.x * bendAmount;
    texturePoint.y -= centerOffset.x * centerOffset.x * centerOffset.y * bendAmount;
    return texturePoint;
}

[[stitchable]]
half4 vhsDisplayShader(float2 pixelPosition, SwiftUI::Layer sourceLayer, float elapsedTime, float2 viewSize) {
    float2 samplePoint = pixelPosition / viewSize;

    samplePoint = bendScreenCoordinates(samplePoint, 0.3);
    
    half4 outputColor;
    outputColor.r = sourceLayer.sample(float2(samplePoint.x, samplePoint.y) * viewSize).r;
    outputColor.g = sourceLayer.sample(float2(samplePoint.x, samplePoint.y) * viewSize).g;
    outputColor.b = sourceLayer.sample(float2(samplePoint.x, samplePoint.y) * viewSize).b;
    outputColor.a = sourceLayer.sample(float2(samplePoint.x, samplePoint.y) * viewSize).a;
    
    outputColor *= half4(0.95, 1.05, 0.95, 1);
    outputColor *= 2.8;

    float scanWave = clamp(0.35 + 0.35 * sin(3.5 * elapsedTime + samplePoint.y * viewSize.y * 1.5), 0.0, 1.0);
    float scanPower = pow(scanWave, 1.7);
    float scanBrightness = 0.4 + 0.7 * scanPower;
    outputColor *= half4(scanBrightness, scanBrightness, scanBrightness, 1);

    outputColor *= 1.0 + 0.01 * sin(110.0 * elapsedTime);
    float stripeMask = clamp((fmod(pixelPosition.x, 2.0) - 1.0) * 2.0, 0.0, 1.0);
    outputColor *= 1.0 - 0.65 * half4(stripeMask, stripeMask, stripeMask, 1);

    return outputColor;
}
