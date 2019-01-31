//
//  ViewController.swift
//  Fractal-iOS
//
//  Created by Алексей Артюшин on 31/01/2019.
//  Copyright © 2019 Fractal. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    var renderer: FractalRenderer!
    var previousPoint: CGPoint?
    var previousScale: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView else {
            fatalError("view is must be a MTKView")
        }
        
        renderer = FractalRenderer(metalView: metalView)
        
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(onPinchGesture(_:)))
        view.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    @objc private func onPanGesture(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        print("translation: \(translation)")
        
        guard sender.state != .ended else {
            return
        }
        
        var distance = CGPoint(x: translation.x, y: translation.y)
        sender.setTranslation(.zero, in: view)
        
        renderer.translate(dx: -Float(distance.x), dy: -Float(distance.y))
    }
    
    @objc private func onPinchGesture(_ sender: UIPinchGestureRecognizer) {
        guard sender.state != .ended else {
            previousScale = nil
            return
        }
        
        let sensitinity: Float = 0.8
        var delta = Float(sender.scale) * sensitinity

        if let previousScale = previousScale {
            delta = Float(previousScale - sender.scale) * sensitinity
        } else {
            previousScale = sender.scale
            return
        }
        
        previousScale = sender.scale
        
        print("scaling by: \(delta) (original: \(sender.scale)")
        
        renderer.scale(delta)
    }
}

