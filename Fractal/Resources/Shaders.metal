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
    
    for (int i = 0; i < 1000; i++) {
        // z * z + c
        z = float2(z.x * z.x - z.y * z.y + c.x,
                   2.0f * z.x * z.y + c.y);
        
        if (z.x*z.x + z.y*z.y > 4)
            break;
        
        it = it + 1;
    }
    
    float colorComponent = 1 - (it / 64.0f);
    
    float3 color = float3(colorComponent, colorComponent, colorComponent);
    
    output.write(float4(color, 1), gid);
}
