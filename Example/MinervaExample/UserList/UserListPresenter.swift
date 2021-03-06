//
//  UserListDataSource.swift
//  MinervaExample
//
//  Copyright © 2019 Optimize Fitness, Inc. All rights reserved.
//

import Foundation
import UIKit

import Minerva
import RxSwift

final class UserListPresenter: Presenter {

  enum Action {
    case delete(user: User)
    case edit(user: User)
    case view(user: User)
  }

  private(set) var sections: Observable<PresenterState>
  var actions: Observable<Action> {
    actionsSubject.asObservable()
  }

  private let actionsSubject: PublishSubject<Action>
  private let repository: UserListRepository

  // MARK: - Lifecycle

  init(repository: UserListRepository) {
    self.repository = repository
    self.actionsSubject = PublishSubject()
    self.sections = Observable.just(.loading)
    self.sections = self.sections.concat(repository.users.map { [weak self] usersResult -> PresenterState in
      guard let strongSelf = self else {
        return .failure(error: SystemError.cancelled)
      }
      switch usersResult {
      case .success(let users):
        let sections = [strongSelf.createSection(with: users.sorted { $0.email < $1.email })]
        return .loaded(sections: sections)
      case .failure(let error):
        return .failure(error: error)
      }
    })
  }

  // MARK: - Private

  private func createSection(with users: [User]) -> ListSection {
    var cellModels = [ListCellModel]()

    let allowSelection = repository.allowSelection
    for user in users {
      let userCellModel = createUserCellModel(for: user)
      if allowSelection {
        userCellModel.selectionAction = { [weak self] _, _ -> Void in
          guard let strongSelf = self else { return }
          strongSelf.actionsSubject.on(.next(.view(user: user)))
        }
      }
      cellModels.append(userCellModel)
    }

    let section = ListSection(cellModels: cellModels, identifier: "SECTION")
    return section
  }

  private func createUserCellModel(for user: User) -> SwipeableLabelCellModel {
    let cellModel = SwipeableLabelCellModel(
      identifier: user.description,
      title: user.email,
      details: String(user.dailyCalories))
    cellModel.bottomSeparatorColor = .separator
    cellModel.bottomSeparatorLeftInset = true
    cellModel.deleteAction = { [weak self] _ -> Void in
      guard let strongSelf = self else { return }
      strongSelf.actionsSubject.on(.next(.delete(user: user)))
    }
    cellModel.editAction = { [weak self] _ -> Void in
      guard let strongSelf = self else { return }
      strongSelf.actionsSubject.on(.next(.edit(user: user)))
    }
    return cellModel
  }

}
