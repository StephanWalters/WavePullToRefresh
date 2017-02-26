//
//  UIView.swift
//  WavePullToRefresh
//
//  Created by Daisuke Kobayashi on 2016/02/18.
//  (C) 2016 RECRUIT LIFESTYLE CO., LTD.
//

import Foundation

public extension UIView {
    // MARK:- Internal Methods
    func center(_ usePresentationLayer: Bool) -> CGPoint {
        guard usePresentationLayer, let presentationLayer = layer.presentation() as? CALayer
            else { return center}
        return presentationLayer.position
    }
    func bounds(_ usePresentationLayer: Bool) -> CGRect {
        guard usePresentationLayer, let presentationLayer = layer.presentation() as? CALayer
            else { return bounds}
        return presentationLayer.bounds
    }
}
