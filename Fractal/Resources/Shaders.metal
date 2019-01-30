//
//  Shaders.metal
//  Fractal
//
//  Created by Алексей Артюшин on 24/01/2019.
//  Copyright © 2019 Fractal. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "FractalParameters.h"

#define ITERS 200.0f

kernel void compute(texture2d<float, access::write> output [[ texture(0) ]],
                    uint2 gid [[ thread_position_in_grid ]],
                    constant FractalParameters &params [[ buffer(1) ]]) {
    float width = float(output.get_width());
    float height = float(output.get_height());
    
    // discard out of boundaries threads
    if (gid.x >= width || gid.y > height) {
        return;
    }
    
    float2 c = float2(4.0f / width * float(gid.x) / params.scale + params.startX - 2.0f / params.scale,
                      4.0f / height * float(gid.y) / params.scale + params.startY - 2.0f / params.scale);
    
    float2 z = float2(0, 0);
    float it = 0;
    
    while (z.x*z.x + z.y*z.y < 4 && it < ITERS) {
        // z * z + c
        z = float2(z.x * z.x - z.y * z.y + c.x,
                   2.0f * z.x * z.y + c.y);
        
        it = it + 1;
    }
    
    float r = 0, g = 0, b = 0;
    
    r = -pow((it / ITERS - 0.5) * 2, 2.0f) + 1;
    g = r / 3;
    b = 0;
    
    float3 color = float3(r, g, b);
    
    output.write(float4(color, 1), gid);
}
