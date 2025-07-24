//
//  SimplifiedDashboardHostingController.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import UIKit
import SwiftUI

class SimplifiedDashboardHostingController: UIHostingController<SimplifiedDashboardView> {
    
    private let dashboardViewModel: SimplifiedDashboardViewModel
    
    init() {
        self.dashboardViewModel = SimplifiedDashboardViewModel()
        let dashboardView = SimplifiedDashboardView(viewModel: dashboardViewModel)
        super.init(rootView: dashboardView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view controller
        navigationItem.largeTitleDisplayMode = .never
        
        // Set up the tab bar item
        tabBarItem = UITabBarItem(
            title: "Glucose",
            image: UIImage(systemName: "heart.fill"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
    }
    
    func setBgReadingsAccessor(_ accessor: BgReadingsAccessor) {
        dashboardViewModel.setBgReadingsAccessor(accessor)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure the view model starts updating when the view appears
        dashboardViewModel.startRealTimeUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop updates when view disappears to save battery
        dashboardViewModel.stopRealTimeUpdates()
    }
}