//
/*-
 * ---license-start
 * eu-digital-green-certificates / dgca-wallet-app-ios
 * ---
 * Copyright (C) 2021 T-Systems International GmbH and all other contributors
 * ---
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ---license-end
 */
//  
//  CertPagesController.swift
//  DGCAWallet
//  
//  Created by Yannick Spreen on 4/30/21.
//  

import UIKit

class CertPagesController: UIPageViewController {
    weak var embeddingVC: DCCViewerController?

    var index = 0
    let vcs: [UIViewController] = [
        UIStoryboard(name: "DCCCertificateViewer", bundle: .main).instantiateViewController(withIdentifier: "code"),
        UIStoryboard(name: "DCCCertificateViewer", bundle: .main).instantiateViewController(withIdentifier: "infoTable")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let embeddingVC = embeddingVC else { return }
          
        self.dataSource = self
        self.delegate = self
          
        index = embeddingVC.isSaved ? 0 : 1
        setViewControllers([vcs[index]], direction: .forward, animated: false)
        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        appearance.pageIndicatorTintColor = UIColor.disabledText
        appearance.currentPageIndicatorTintColor = UIColor.walletBlack
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setBrightness()
    }

    func setBrightness() {
        index == 0 ? Brightness.forceFull() : Brightness.reset()
        Brightness.forceFull()
    }
}

extension CertPagesController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = vcs.firstIndex(of: viewController) ?? 0
        return index == 0 ? nil : vcs[index - 1]
    }

    func pageViewController( _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = vcs.firstIndex(of: viewController) ?? vcs.count - 1
        return index == vcs.count - 1 ? nil : vcs[index + 1]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return vcs.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return index
    }
}

extension CertPagesController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed, let controller = pageViewController.viewControllers?.first else { return }
        index = vcs.firstIndex(of: controller) ?? 0
        setBrightness()
    }
}
