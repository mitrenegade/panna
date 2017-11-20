//
//  TutorialViewController.swift
//  Balizinha
//
//  Created by Bobby Ren on 11/7/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//
// https://spin.atomicobject.com/2015/12/23/swift-uipageviewcontroller-tutorial/

import UIKit

protocol TutorialDelegate: class {
    func didTapTutorial()
    func didClickNext()
}

class TutorialViewController: UIViewController {
    
    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var pageViewController: UIPageViewController!
    
    weak var delegate: TutorialDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let firstViewController = orderedViewControllers.first {
            pageViewController.setViewControllers([firstViewController],
                                                  direction: .forward,
                                                  animated: true,
                                                  completion: nil)
        }
    }
    
    @IBAction func handleGesture(_ gesture: UIGestureRecognizer) {
        print("tapped")
        delegate?.didTapTutorial()
    }
    
    @IBAction func didClickButton(_ sender: UIButton) {
        delegate?.didClickNext()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? UIPageViewController {
            pageViewController = controller
            controller.dataSource = self
        }
    }

    fileprivate class func pageAt(_ page: Int) -> UIViewController {
        let identifiers = ["TutorialPage0", "TutorialPage1", "TutorialPage2"]
        guard page < identifiers.count else { return UIViewController() }

        let tutorialPage = UIStoryboard(name: "Tutorial", bundle: nil).instantiateViewController(withIdentifier: identifiers[page])
        return tutorialPage
    }
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [TutorialViewController.pageAt(0), TutorialViewController.pageAt(1), TutorialViewController.pageAt(2)]
    }()
    
}

extension TutorialViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = pageViewController.viewControllers?.first,
            let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }
}
