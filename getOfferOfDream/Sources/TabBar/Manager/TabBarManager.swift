import UIKit

// MARK: - TabBarManager

final class TabBarManager {
    weak var tabBar: UITabBar?
}

// MARK: - TabBarManagerProtocol

extension TabBarManager: TabBarManagerProtocol {
    func setup(tabBar: UITabBar) {
        self.tabBar = tabBar
        self.tabBar?.tintColor = .blue
    }
}