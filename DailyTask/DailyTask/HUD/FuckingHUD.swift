//
//  FuckingHUD.swift
//  DailyTask
//
//  Created by Emiaostein on 12/01/2018.
//  Copyright © 2018 Emiaostein. All rights reserved.
//

import Foundation
import UIKit

protocol HUDViewControllerFactory: Equatable {
    func makeHUDViewController() -> UIViewController
}

enum FuckingHUDStyle: HUDViewControllerFactory {
    
    case success(String, String)
    case error(String, String)
    case loading(String, String)
    case notify(String)
    case progress(String, String, Float)
    
    static func ==(lhs: FuckingHUDStyle, rhs: FuckingHUDStyle) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lt, let lst), .success(let rt, let rst)):
            return lt == rt && lst == rst
        case (.error(let lt, let lst), .error(let rt, let rst)):
            return lt == rt && lst == rst
        case (.loading(let lt, let lst), .loading(let rt, let rst)):
            return lt == rt && lst == rst
        case (.notify(let lt), .notify(let rt)):
            return lt == rt
        case (.progress(let lt, let lst, let lp), .progress(let rt, let rst, let rp)):
            return lt == rt && lst == rst && lp == rp
        case (_, .error(_, _)):
            return false
        case (_, .loading(_, _)):
            return false
        case (_, .notify(_)):
            return false
        case (_, .progress(_, _, _)):
            return false
        case (.progress(_, _, _), .success(_, _)):
            return false
        case (.notify(_), .success(_, _)):
            return false
        case (.loading(_, _), .success(_, _)):
            return false
        case (.error(_, _), .success(_, _)):
            return false
        }
    }
    
    func makeHUDViewController() -> UIViewController {
        let hud = UIStoryboard(name: "FuckingHUD", bundle: nil).instantiateViewController(withIdentifier: "HUD")
        let imageView =  hud.view.viewWithTag(100) as! UIImageView
        let title = hud.view.viewWithTag(101) as! UILabel
        let subtitle = hud.view.viewWithTag(102) as! UILabel
        
        switch self {
        case .success(let t, let st):
            imageView.image = #imageLiteral(resourceName: "hud-success")
            title.text = t
            subtitle.text = st
        case .error(let t, let st):
            imageView.image = #imageLiteral(resourceName: "hud-error")
            title.text = t
            subtitle.text = st
        case .loading(let t, let st):
            imageView.animationImages = (0..<8).map{return UIImage(named: "hud-loading-\($0)")!}
            imageView.animationDuration = 0.5
            imageView.startAnimating()
            title.text = t
            subtitle.text = st
        case .notify(let t):
            title.text = t
        case .progress(let t, _, _):
            title.text = t
        }
        
        return hud
    }
}

enum FuckingHUDState {
    case presenting(FuckingHUDStyle)
    case cancelling
    case dismissing(FuckingHUDStyle)
    case dismissed
}

fileprivate protocol FuckingHUDInterface {
    
    static var state: FuckingHUDState {get}
    
    static func present(style: FuckingHUDStyle, dismissDelay: TimeInterval)
    static func update(style: FuckingHUDStyle)
    static func dismiss(completed:(()->())?)
}

extension FuckingHUDInterface {
    fileprivate static var topestViewController: UIViewController? {
        var top = UIApplication.shared.keyWindow?.rootViewController
        while top?.presentedViewController != nil {
            top = top?.presentedViewController
        }
        return top
    }
}

final class FuckingHUD: FuckingHUDInterface {
    
    static private(set) var dismissIndicator = 0
    static private(set) var state: FuckingHUDState = .dismissed
    static private weak var presentedViewController: FuckingHUDViewController?

    static func present(style: FuckingHUDStyle, dismissDelay: TimeInterval = 1.3) {
        DispatchQueue.main.async {
            switch state {
            case .presenting(let currentStyle):
                if currentStyle == style {
                    return
                } else {
                    dismissIndicator += 1
                    let i = dismissIndicator
                    willCancel(completed: {
                        willPresent(style: style, completed: {
                            if i == dismissIndicator {
                                willDismiss(style: style,dismissDelay: dismissDelay) {
                                    if i == dismissIndicator {
                                        dismiss(completed: {
                                            dismissIndicator -= 1
                                        })
                                    }
                                }
                            }
                        })
                    })
                }
            case .cancelling:
                return
            case .dismissing(let currentStyle):
                if currentStyle == style {
                    return
                } else {
                    dismissIndicator += 1
                    let i = dismissIndicator
                    willCancel(completed: {
                        if i == dismissIndicator {
                            willPresent(style: style, completed: {
                                if i == dismissIndicator {
                                    willDismiss(style: style, dismissDelay: dismissDelay) {
                                        if i == dismissIndicator {
                                            dismiss(completed: {
                                                dismissIndicator -= 1
                                            })
                                        }
                                    }
                                }
                                
                            })
                        }
                    })
                }
            case .dismissed:
                dismissIndicator += 1
                let i = dismissIndicator
                willPresent(style: style, completed: {
                    if i == dismissIndicator {
                        willDismiss(style: style, dismissDelay: dismissDelay) {
                            if i == dismissIndicator {
                                dismiss(completed: {
                                    dismissIndicator -= 1
                                })
                            }
                        }
                    }
                })
            }          
        }
    }
    
    static private func willCancel(completed:@escaping ()->()) {
        print("~.will cancel")
        state = .cancelling
        if let presenting = presentedViewController {
            presenting.dis(completed: { (vc) in
                vc.view.removeFromSuperview()
                vc.removeFromParentViewController()
                completed()
            })
        } else {
            completed()
        }
    }
    
    static private func willPresent(style: FuckingHUDStyle, completed:()->()) {
        print("1.will present")
        state = .presenting(style)
        guard let top = topestViewController else {completed(); return}
        let vc = createHUDViewController()
        vc.hudViewController = style.makeHUDViewController()
        vc.view.isUserInteractionEnabled = false
        top.addChildViewController(vc)
        top.view.addSubview(vc.view)
        presentedViewController = vc
        completed()
    }
    
    static private func willDismiss(style: FuckingHUDStyle, dismissDelay: TimeInterval, completed:@escaping ()->()) {
        print("2. will dismiss")
        state = .dismissing(style)
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            completed()
        }
    }
    
    static func update(style: FuckingHUDStyle) {
        
    }
    
    static func dismiss(completed:(()->())?) {
        DispatchQueue.main.async {
            if let presented = presentedViewController {
                presented.dis { vc in
                    print("3. did dismiss")
                    presented.view.removeFromSuperview()
                    presented.removeFromParentViewController()
                    state = .dismissed
                    completed?()
                }
            } else {
                state = .dismissed
                completed?()
            }
        }
    }
}

extension FuckingHUD {
    static func createHUDViewController() -> FuckingHUDViewController {
        let vc = UIStoryboard(name: "FuckingHUD", bundle: nil).instantiateViewController(withIdentifier: "main") as! FuckingHUDViewController
        return vc
    }
}


class FuckingHUDViewController: UIViewController {
    
    fileprivate var hudViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let hud = hudViewController {
            addChildViewController(hud)
            view.addSubview(hud.view)
            let v = hud.view!
            v.center = view.center
            v.alpha = 0.0
            v.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {[weak self] in
            guard let sf = self, let v = sf.hudViewController?.view else {return}
            v.alpha = 1.0
            v.transform = .identity
        }) { (position) in
        }
    }
    
    func dis(completed:@escaping (UIViewController)->()) {
        UIView.animate(withDuration: 0.15, animations: {[weak self] in
            guard let sf = self, let v = sf.hudViewController?.view else {return}
            v.alpha = 0.0
            v.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) {[weak self] (finished) in
            guard let sf = self else {return}
            completed(sf)
        }
    }
    
}
