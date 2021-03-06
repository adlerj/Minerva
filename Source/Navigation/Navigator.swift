//
//  Navigator.swift
//  Minerva
//
//  Copyright © 2019 Optimize Fitness, Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol Navigator: UIAdaptivePresentationControllerDelegate, UINavigationControllerDelegate {
  typealias RemovalCompletion = (UIViewController) -> Void

  func present(_ viewController: UIViewController, animated: Bool, completion: RemovalCompletion?)

  func dismiss(_ viewController: UIViewController, animated: Bool, completion: RemovalCompletion?)

  func push(_ viewController: UIViewController, animated: Bool, completion: RemovalCompletion?)

  func setViewControllers(_ viewControllers: [UIViewController], animated: Bool, completion: RemovalCompletion?)

  @discardableResult
  func popToRootViewController(animated: Bool) -> [UIViewController]?

  @discardableResult
  func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]?

  @discardableResult
  func popViewController(animated: Bool) -> UIViewController?
}

extension Navigator {

  public func push(_ viewController: UIViewController, animated: Bool) {
    push(viewController, animated: animated, completion: nil)
  }

  public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
    setViewControllers(viewControllers, animated: animated, completion: nil)
  }

  public func present(_ viewController: UIViewController, animated: Bool) {
    present(viewController, animated: animated, completion: nil)
  }

  public func dismiss(_ viewController: UIViewController, animated: Bool) {
    dismiss(viewController, animated: animated, completion: nil)
  }
}

public final class BasicNavigator: NSObject {

  public let navigationController: UINavigationController
  private var completions = [UIViewController: RemovalCompletion]()

  public init(
    navigationController: UINavigationController = UINavigationController(),
    parent: Navigator? = nil
  ) {
    self.navigationController = navigationController
    super.init()
    navigationController.delegate = self
    navigationController.presentationController?.delegate = parent
  }

  // MARK: - Private

  private func runCompletion(for controller: UIViewController) {
    guard let completion = completions[controller] else { return }
    completion(controller)
    completions[controller] = nil
  }
}

// MARK: - NavigatorType
extension BasicNavigator: Navigator {

  public func present(_ viewController: UIViewController, animated: Bool, completion: RemovalCompletion?) {
    if let completion = completion {
      completions[viewController] = completion
    }
    navigationController.present(viewController, animated: animated, completion: nil)
  }

  public func dismiss(_ viewController: UIViewController, animated: Bool, completion: RemovalCompletion?) {
    var viewControllers = [UIViewController]()
    func calculateDismissingViewControllers(from vc: UIViewController?) {
      guard let vc = vc else { return }

      viewControllers.append(vc)
      if let navigationController = vc as? UINavigationController {
        viewControllers.append(contentsOf: navigationController.viewControllers)
      }
      return calculateDismissingViewControllers(from: vc.presentedViewController)
    }
    if viewController.presentingViewController == nil {
      calculateDismissingViewControllers(from: viewController.presentedViewController)
    } else {
      calculateDismissingViewControllers(from: viewController)
    }

    viewController.dismiss(animated: animated) {
      viewControllers.forEach { self.runCompletion(for: $0) }
    }
  }

  public func popToRootViewController(animated: Bool) -> [UIViewController]? {
    guard let poppedControllers = navigationController.popToRootViewController(animated: animated) else {
      return nil
    }
    poppedControllers.forEach { runCompletion(for: $0) }
    return poppedControllers
  }

  public func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
    guard let poppedControllers = navigationController.popToViewController(viewController, animated: animated) else {
      return nil
    }
    poppedControllers.forEach { runCompletion(for: $0) }
    return poppedControllers
  }

  public func popViewController(animated: Bool) -> UIViewController? {
    guard let poppedController = navigationController.popViewController(animated: animated) else {
      return nil
    }
    runCompletion(for: poppedController)
    return poppedController
  }

  public func push(_ viewController: UIViewController, animated: Bool, completion: RemovalCompletion?) {
    if let completion = completion {
      completions[viewController] = completion
    }

    navigationController.pushViewController(viewController, animated: animated)
  }

  public func setViewControllers(
    _ viewControllers: [UIViewController],
    animated: Bool,
    completion: RemovalCompletion?
  ) {
    if let completion = completion {
      viewControllers.forEach { viewController in
        completions[viewController] = completion
      }
    }
    navigationController.setViewControllers(viewControllers, animated: animated)
    Array(completions.keys).forEach { vc in
      guard !viewControllers.contains(vc) else { return }
      runCompletion(for: vc)
    }
  }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension BasicNavigator {

  // Handles iOS 13 Swipe to dismiss of modals.
  public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    let dismissingViewController = presentationController.presentedViewController
    runCompletion(for: dismissingViewController)
  }

  // This allows explicitly setting the modalPresentationStyle from a view controller.
  public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    return controller.presentedViewController.modalPresentationStyle
  }
}

// MARK: - UINavigationControllerDelegate
extension BasicNavigator {

  // Handles when a user swipes to go back or taps the back button in the navigation bar.
  public func navigationController(
    _ navigationController: UINavigationController,
    didShow viewController: UIViewController,
    animated: Bool
  ) {
    guard let poppingViewController = navigationController.transitionCoordinator?.viewController(forKey: .from) else {
      return
    }
    // The view controller could be .from if it is being popped, or if another VC is being pushed. Check the
    // navigation stack to see if it is no longer there (meaning a pop).
    guard !navigationController.viewControllers.contains(poppingViewController) else {
      return
    }
    runCompletion(for: poppingViewController)
  }
}
