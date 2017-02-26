//
//  WavePullToRefreshConst.swift
//  WavePullToRefresh
//
//  Created by Daisuke Kobayashi on 2016/02/18.
//  (C) 2016 RECRUIT LIFESTYLE CO., LTD.
//

import UIKit

struct WavePullToRefreshConst {
    // MARK:- Properties
    static let tag = 999
    static let height: CGFloat = 80
    static let waveHeight: CGFloat = 80
    static let spinSpeed: CGFloat = 0.05
    static let maxIndicatorRadius: CGFloat = 50
}

open class WavePullToRefreshOption {
    // MARK:- Properties
    
    open var animationStartOffsetY: CGFloat = 80
    open var dropDuration: TimeInterval = 0.75
    open var dropY: CGFloat = UIScreen.main.bounds.height * 0.85
    
    open var fillColor = UIColor(red: 106/255, green: 172/255, blue: 184/255, alpha: 1).cgColor
    open var indicatorColor = UIColor.white.cgColor
    open var indicatorImageView: UIImageView?
    
    public init() {
        
    }
}
