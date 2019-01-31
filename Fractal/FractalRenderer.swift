//
//  FractalView.swift
//  Fractal
//
//  Created by Алексей Артюшин on 31/01/2019.
//  Copyright © 2019 Fractal. All rights reserved.
//

import MetalKit

public class FractalRenderer: NSObject {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var computePipelineState: MTLComputePipelineState!
    
    var fractalParameters: FractalParameters = FractalParameters(startX: 0, startY: 0, scale: 1.0)
    
    var viewSize: CGSize = .zero
    
    init(metalView: MTKView) {
        super.init()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU is not supported")
        }
        
        self.device = device
        
        metalView.device = device
        metalView.delegate = self
        metalView.framebufferOnly = false
        
        commandQueue = device.makeCommandQueue()
        
        do {
            let library = device.makeDefaultLibrary()
            
            guard let computeFunction = library?.makeFunction(name: "compute") else {
                fatalError("unable to make compute function from default library")
            }
            
            computePipelineState = try device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("unable to create compute pipeline state: \(error)")
        }
        
        self.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
    }
    
    func translate(dx: Float, dy: Float) {
        let width = Float(viewSize.width)
        let height = Float(viewSize.height)
        
        fractalParameters.startX += Float(dx / width) * (4 / fractalParameters.scale) * 2
        fractalParameters.startY += Float(dy / height) * (4 / fractalParameters.scale) * 2
    }
    
    func scale(_ scaleFactor: Float) {
        fractalParameters.scale = fractalParameters.scale - scaleFactor * fractalParameters.scale
    }
}

extension FractalRenderer: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewSize = size
    }
    
    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
                let commandBuffer = commandQueue.makeCommandBuffer(),
                let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        commandEncoder.setComputePipelineState(computePipelineState)
        
        commandEncoder.setTexture(drawable.texture, index: 0)
        commandEncoder.setBytes(&fractalParameters, length: MemoryLayout<FractalParameters>.stride, index: 1)
        
        let texturewWidth = drawable.texture.width
        let textureHeight = drawable.texture.height
        
        let threadsPerThreadgroup = MTLSizeMake(16, 16, 1)
        let threadGroups = MTLSizeMake(texturewWidth / threadsPerThreadgroup.width + 1, textureHeight / threadsPerThreadgroup.height + 1, 1)
        
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
