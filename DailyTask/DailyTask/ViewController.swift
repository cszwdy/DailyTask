//
//  ViewController.swift
//  DailyTask
//
//  Created by Emiaostein on 08/01/2018.
//  Copyright © 2018 Emiaostein. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3 * 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        if let label = cell.contentView.viewWithTag(100) as? UILabel {
            switch indexPath.item % 3 {
            case 0:
                label.text = "Success"
            case 1:
                label.text = "Error"
            case 2:
                label.text = "Loading"
            default:
                ()
            }
        }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        switch indexPath.item % 3 {
        case 0:
            FuckingHUD.present(style: .success("Success", "You have registed successfully."))
        case 1:
            FuckingHUD.present(style: .error("Error", "Fail to approval money."))
        case 2:
            FuckingHUD.present(style: .loading("Loading", "Please waiting for buying."))
        default:
            ()
        }
        
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            cell?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (position) in
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                cell?.transform = .identity
            }, completion: nil)
        }
    }
}

