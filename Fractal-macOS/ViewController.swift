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

    var previousPoint: NSPoint?
    var renderer: FractalRenderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let metalView = view as? MTKView else {
            fatalError("view is must be a MTKView")
        }
        
        renderer = FractalRenderer(metalView: metalView)
        
        setupGestureRecognizers()
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        
        let sensitinity: Float = 0.05
        let delta = Float(event.deltaY) * sensitinity

        renderer.scale(delta)
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

        var distance = NSPoint(x: translation.x, y: translation.y)
        
        if let previousPoint = previousPoint {
            distance = NSPoint(x: previousPoint.x - translation.x, y: previousPoint.y - translation.y)
        }
        
        renderer.translate(dx: Float(distance.x), dy: -Float(distance.y))

        previousPoint = translation
    }

    @objc private func onScroll(_ sender: NSMagnificationGestureRecognizer) {
        print("magnification: \(sender.magnification)")
    }
}

