//
//  WavePullToRefreshView.swift
//  WavePullToRefresh
//
//  Created by Daisuke Kobayashi on 2016/02/18.
//  (C) 2016 RECRUIT LIFESTYLE CO., LTD.
//

import Foundation

class WavePullToRefreshView: UIView {
    // MARK:- Enumerations
    enum WavePullToRefreshState {
        case normal, refreshing
    }
    
    // MARK:- Properties
    let contentOffsetKeyPath = "contentOffset"
    var kvoContext = "contentOffsetContext"
    
    var state: WavePullToRefreshState = .normal {
        didSet {
            if self.state == oldValue { return }
            switch self.state {
            case .normal:
                self.stopAnimation()
            case .refreshing:
                self.animating = true
                self.startAnimation()
            }
        }
    }
    
    // callback when refresh called
    fileprivate var refreshCallback: ()->() = {}
    
    // views
    
    /**
    controlView's center point is endPoint or controlPoint of UIBezierPath
    * c[i] = controlViews[i].center
    * c[i]: endPoint, (c[i]): controlPoint
    
              (c[2])       (c[5])
    c[0](c[0])   \           /         c[6](c[6])
       \          \         /          /
        \__________\_______/__________/
               c[1] \     c[3](c[3])
                     \
                      \(c[4])
    
    pathes:
        | 1    | 2    | controlPoints    |
        |------|------|------------------|
        | c[0] | c[1] | 1: c[0], 2: c[2] |
        | c[1] | c[3] | 1: c[4], 2: c[3] |
        | c[3] | c[6] | 1: c[5], 2: c[6] |
    
    */
    fileprivate let controlViews = (0 ..< 7).map { _ in UIView() }
    
    let dropView = DropView()
    
    // layers
    fileprivate let shapeLayer = CAShapeLayer()
    fileprivate var options = WavePullToRefreshOption()
    
    fileprivate lazy var displayLink:CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(WavePullToRefreshView.updateShapeLayer))
        displayLink.isPaused = true
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
        return displayLink
    }()
    
    var animating = false {
        didSet {
            self.dropView.animating = animating
            self.displayLink.isPaused = !animating
        }
    }
    
    // MARK:- Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(options: WavePullToRefreshOption, frame: CGRect, refreshCallback: @escaping ()->()) {
        self.init(frame: frame)
        self.options = options
        self.refreshCallback = refreshCallback
        self.autoresizingMask = .flexibleWidth
        
        // controll views
        for view in self.controlViews {
            self.addSubview(view)
        }
        
        // drop view
        self.dropView.setOptions(options)
        self.addSubview(self.dropView)
        
        // add shape layer
        self.shapeLayer.fillColor = options.fillColor
        self.shapeLayer.actions = ["path" : NSNull(), "position" : NSNull(), "bounds" : NSNull()]
        self.layer.addSublayer(shapeLayer)
        
        self.bringSubview(toFront: self.dropView)
    }
    
    deinit {
        guard let scrollView = scrollView() else { return }
        scrollView.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &kvoContext)
    }
    
    // MARK:- Override Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        guard self.state != .refreshing && !self.animating else { return }
        
        let width = self.frame.size.width
        let height = self.height()
        let percent = height / self.options.animationStartOffsetY
        
        // self
        self.frame = CGRect(x: 0, y: -height, width: width, height: height)
        self.shapeLayer.path = self.path(self.controlViewCenters(controlViews))
        
        // drop view
        self.dropView.layoutSubviews(height, percent: percent)
    }
    
    override func willMove(toSuperview superView: UIView!) {
        self.superview?.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &kvoContext)
        
        if let scrollView = superView as? UIScrollView {
            scrollView.addObserver(self, forKeyPath: contentOffsetKeyPath, options: .initial, context: &kvoContext)
        }
    }
    
    /**
     Ovserving contentOffset of UIScrollView
     - parameter 
        object: UIScrollView
     */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard self.state != .refreshing && !self.animating else { return }
        
        if context == &kvoContext && keyPath == contentOffsetKeyPath {
            if let scrollView = object as? UIScrollView {
                
                // update views
                self.layoutSubviews()
                self.moveControlViewsToPoint()
                
                let offsetY = scrollView.contentOffset.y
                // check to refresh
                if offsetY < -self.options.animationStartOffsetY {
                    self.state = .refreshing
                    let offset = scrollView.contentOffset
                    scrollView.isScrollEnabled = false
                    scrollView.setContentOffset(offset, animated: false)
                    UIView.animate(withDuration: 0.5, animations: {
                        scrollView.setContentOffset(CGPoint.zero, animated: false)
                    }) 
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK:- Private Methods
    
    /**
    Call when state is set .Refresh
    */
    fileprivate func startAnimation() {
        // Callback when refreshing
        self.refreshCallback()

        // Wave animation
        UIView.animate(withDuration: 0.5, delay: 0,
            usingSpringWithDamping: 0.25, initialSpringVelocity: 0.6, options: [],
            animations: { [weak self] in
                if let s = self {
                    for view in s.controlViews {
                        view.center.y = 25
                    }
                }
            },
            completion: { [weak self] _ in
                if let s = self {
                    for view in s.controlViews {
                        view.center.y = 0
                    }
                }
            }
        )
        
        // Drop animation
        UIView.animate(withDuration: self.options.dropDuration, delay: 0,
            usingSpringWithDamping: 0.75, initialSpringVelocity: 0.2, options: UIViewAnimationOptions(),
            animations: { [weak self] in
                if let s = self {
                    s.dropView.center = CGPoint(x: s.dropView.center.x, y: s.options.dropY)
                }
            },
            completion: { _ in }
        )
    }
    
    /**
     Remove all animations and make scrolling enable
     */
    fileprivate func stopAnimation() {
        self.dropView.stopAnimation() {
            self.animating = false
        }
        
        for view in self.controlViews {
            view.layer.removeAllAnimations()
        }
        
        if let scrollView = self.scrollView() {
            scrollView.isScrollEnabled = true
        }
    }
    
    fileprivate func scrollView() -> UIScrollView? {
        return self.superview as? UIScrollView
    }
    
    /**
     Use for setting self.frame
     - returns: contentOffset.y, if it's minus, 0
     */
    fileprivate func height() -> CGFloat {
        guard let scrollView = self.scrollView() else { return 0.0 }
        return max(-scrollView.contentOffset.y, 0)
    }
    
    /**
     Return path for wave
     - parameter p: center of controlViews
     - returns: path for wave
     */
    fileprivate func path(_ p: [CGPoint]) -> CGPath {
        let bezierPath = UIBezierPath()
        
        assert(p.count == 7)
        
        bezierPath.move(to: CGPoint(x: 0, y: 0))
        bezierPath.addLine(to: CGPoint(x: 0, y: p[0].y))
        bezierPath.addCurve(to: p[1], controlPoint1: p[0], controlPoint2: p[2])
        bezierPath.addCurve(to: p[3], controlPoint1: p[4], controlPoint2: p[3])
        bezierPath.addCurve(to: p[6], controlPoint1: p[3], controlPoint2: p[5])
        bezierPath.addLine(to: CGPoint(x: p[6].x, y: 0))
        
        bezierPath.close()
        
        return bezierPath.cgPath
    }
    
    fileprivate func controlViewCenters(_ controlViews: [UIView]) -> [CGPoint] {
        return (0 ..< controlViews.count).map { i in controlViews[i].center(animating) }
    }
    
    fileprivate func waveHeight() -> CGFloat {
        return min(bounds.height / 3.0 * 1.6, WavePullToRefreshConst.waveHeight)
    }
    
    /**
     Set current controlView's center
     */
    fileprivate func moveControlViewsToPoint() {
        let width = self.bounds.width
        let waveHeight = self.waveHeight()
        let baseHeight = self.height() - waveHeight
        
        let points = controlViewPoints(width: width, baseHeight: baseHeight, waveHeight: waveHeight)
        
        for (i, controlView) in self.controlViews.enumerated() {
            controlView.center = points[i]
        }
    }
    
    fileprivate func controlViewPoints(width: CGFloat, baseHeight: CGFloat, waveHeight: CGFloat) -> [CGPoint] {
        return [
            CGPoint(x: 0, y: baseHeight),
            CGPoint(x: width * 0.35, y: baseHeight + waveHeight * 0.64),
            CGPoint(x: width * 0.22, y: baseHeight),
            CGPoint(x: width - width * 0.35 , y: baseHeight + waveHeight * 0.64),
            CGPoint(x: width / 2 , y: baseHeight + waveHeight * 1.36),
            CGPoint(x: width - (width * 0.22), y: baseHeight),
            CGPoint(x: width, y: baseHeight)
        ]
    }
    
    // MARK:- Internal Methods
    func updateShapeLayer() {
        self.shapeLayer.path = path(self.controlViewCenters(controlViews))
        self.dropView.updateLayers()
    }
}
