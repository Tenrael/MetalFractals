//
//  ViewController.swift
//  Fractal
//
//  Created by Алексей Артюшин on 24/01/2019.
//  Copyright © 2019 Fractal. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {

    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var computePipelineState: MTLComputePipelineState!
    
    var fractalParameters: FractalParameters = FractalParameters(startX: 0.0, startY: 0.0, scale: 2.0)
    var previousPoint: NSPoint?
    
    var viewSize: NSSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let metalView = view as? MTKView else {
            fatalError("view is must be a MTKView")
        }
        
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        do {
            let library = device.makeDefaultLibrary()!
            let kernel = library.makeFunction(name: "compute")!
            computePipelineState = try device.makeComputePipelineState(function: kernel)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        metalView.device = device
        metalView.framebufferOnly = false
        metalView.delegate = self
        
        setupGestureRecognizers()
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        
        let delta = event.deltaY
        
        fractalParameters.scale = fractalParameters.scale - Float(delta) * 0.05 * fractalParameters.scale
        
        print("new scale: \(fractalParameters.scale)")
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        guard let metalView = view as? MTKView else {
            return
        }
        
        viewSize = NSSize(width: metalView.currentDrawable!.texture.width, height: metalView.currentDrawable!.texture.height)
    }
    
    private func setupGestureRecognizers() {
        let panGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(onPanAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        let magnificationRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(onScroll(_:)))
        view.addGestureRecognizer(magnificationRecognizer)
    }
    
    @objc private func onPanAction(_ sender: NSPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        guard sender.state != .ended else {
            previousPoint = nil
            return
        }
        
        if let previousPoint = previousPoint {
            let distance = NSPoint(x: previousPoint.x - translation.x, y: previousPoint.y - translation.y)
            fractalParameters.startX += Float(distance.x / viewSize.width) * (4 / fractalParameters.scale) * 2
            fractalParameters.startY += -Float(distance.y / viewSize.height) * (4 / fractalParameters.scale) * 2
        } else {
            fractalParameters.startX += Float(translation.x / viewSize.width) * (4 / fractalParameters.scale) * 2
            fractalParameters.startY += -Float(translation.y / viewSize.height) * (4 / fractalParameters.scale) * 2
        }
        
        previousPoint = translation
    }
    
    @objc private func onScroll(_ sender: NSMagnificationGestureRecognizer) {
        print("magnification: \(sender.magnification)")
    }
}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable, let commandBuffer = commandQueue.makeCommandBuffer(), let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        computeEncoder.setComputePipelineState(computePipelineState)
        
        computeEncoder.setTexture(drawable.texture, index: 0)
        
        computeEncoder.setBytes(&fractalParameters, length: MemoryLayout<FractalParameters>.stride, index: 1)
        
        let texturewWidth = drawable.texture.width
        let textureHeight = drawable.texture.height
        
        let threadsPerThreadgroup = MTLSizeMake(16, 16, 1)
        let threadGroups = MTLSizeMake(texturewWidth / threadsPerThreadgroup.width + 1, textureHeight / threadsPerThreadgroup.height + 1, 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
