//
//  OnboardingHostingController.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import UIKit
import SwiftUI

class OnboardingHostingController: UIHostingController<OnboardingView> {
    
    private let onboardingViewModel: OnboardingViewModel
    weak var delegate: OnboardingHostingControllerDelegate?
    
    init() {
        self.onboardingViewModel = OnboardingViewModel()
        let onboardingView = OnboardingView(viewModel: onboardingViewModel)
        super.init(rootView: onboardingView)
        
        setupNotificationObserver()
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the view controller modal and fullscreen
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .coverVertical
    }
    
    func setBluetoothPeripheralManager(_ manager: BluetoothPeripheralManager) {
        onboardingViewModel.setBluetoothPeripheralManager(manager)
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onboardingCompleted),
            name: .onboardingCompleted,
            object: nil
        )
    }
    
    @objc private func onboardingCompleted() {
        delegate?.onboardingDidComplete()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

protocol OnboardingHostingControllerDelegate: AnyObject {
    func onboardingDidComplete()
}