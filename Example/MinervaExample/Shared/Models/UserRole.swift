//
//  UserRole.swift
//  MinervaExample
//
//  Copyright © 2019 Optimize Fitness, Inc. All rights reserved.
//

import Foundation

extension UserRole: CustomStringConvertible {
  var description: String {
    switch self {
    case .admin: return "Admin"
    case .user: return "User"
    case .userManager: return "User Manager"
    }
  }
  var userEditor: Bool {
    switch self {
    case .admin, .userManager: return true
    case .user: return false
    }
  }
}
