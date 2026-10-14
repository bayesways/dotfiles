// Ghost Lab: cursor smear + a short arrival flash.
// MIT license. Copyright (c) 2026 Ghost Lab contributors.
// Permission is granted to use, copy, modify, distribute, sublicense, and sell
// this software with this notice retained. Provided AS IS, without warranty.
// Uses Ghostty cursor uniforms; this is not a generic Shadertoy shader.
// Change TRAIL_SECONDS to tune persistence. Reload Ghostty after editing.
const float TRAIL_SECONDS = 0.22;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    float elapsed = max(0.0, iTime - iTimeCursorChange);
    if (elapsed >= TRAIL_SECONDS || iFocus == 0) return;

    // Ghostty reports the top-left corner in a Y-up coordinate system.
    vec2 size = max(iCurrentCursor.zw, vec2(1.0));
    vec2 head = iCurrentCursor.xy + vec2(size.x, -size.y) * 0.5;
    vec2 oldSize = max(iPreviousCursor.zw, vec2(1.0));
    vec2 previous = iPreviousCursor.xy + vec2(oldSize.x, -oldSize.y) * 0.5;
    vec2 travel = head - previous;
    float distanceMoved = length(travel);
    if (distanceMoved < 0.5) return;

    float progress = clamp(elapsed / TRAIL_SECONDS, 0.0, 1.0);
    float fade = (1.0 - progress) * (1.0 - progress);
    // Tail catches the head quickly at first, then settles gently.
    vec2 tail = mix(previous, head, 1.0 - pow(1.0 - progress, 3.0));
    vec2 axis = head - tail;
    float axisSquared = max(dot(axis, axis), 0.001);
    float along = clamp(dot(fragCoord - tail, axis) / axisSquared, 0.0, 1.0);
    float perpendicular = length(fragCoord - (tail + axis * along));
    vec2 direction = travel / distanceMoved;
    float halfWidth = 0.5 * (abs(direction.x) * size.y + abs(direction.y) * size.x);
    float radius = max(1.0, halfWidth * mix(0.18, 0.85, along));
    float ribbon = 1.0 - smoothstep(radius, radius + 1.5, perpendicular);
    float halo = exp(-perpendicular / max(2.0, radius * 1.4));
    float amount = fade * (0.55 * ribbon + 0.12 * halo) * mix(0.25, 1.0, along);

    // A brief glow outside the cursor on arrival, without hiding cursor text.
    vec2 outside = max(abs(fragCoord - head) - size * 0.5, vec2(0.0));
    float edgeDistance = length(outside);
    float flash = exp(-edgeDistance / 3.0) * exp(-elapsed * 40.0);
    bool insideCursor = all(lessThanEqual(abs(fragCoord - head), size * 0.5));
    if (!insideCursor) amount += flash * 0.3;
    else amount = 0.0;

    vec3 color = clamp(iCurrentCursorColor.rgb, 0.0, 1.0);
    fragColor.rgb = mix(fragColor.rgb, color, clamp(amount, 0.0, 0.85));
    // Preserve input alpha so background transparency still works.
}
