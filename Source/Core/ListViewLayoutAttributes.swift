//
//  ListViewLayoutAttributes.swift
//  Minerva
//
//  Copyright © 2019 Optimize Fitness, Inc. All rights reserved.
//

import Foundation
import UIKit

public class ListViewLayoutAttributes: UICollectionViewLayoutAttributes {
  public var animationGroup: CAAnimationGroup?

  override public func copy(with zone: NSZone? = nil) -> Any {
    let superCopy = super.copy(with: zone)
    guard let attributes = superCopy as? ListViewLayoutAttributes else { return superCopy }
    if let animationGroup = self.animationGroup {
      attributes.animationGroup = animationGroup.copy(with: zone) as? CAAnimationGroup
    }
    return attributes
  }

  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object else { return false }
    guard let object = other as? ListViewLayoutAttributes else { return false }
    guard object.animationGroup == animationGroup else { return false }
    return super.isEqual(object)
  }
}
