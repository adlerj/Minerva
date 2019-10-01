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

  private let repository: UserListRepository
  private let disposeBag = DisposeBag()
  private let sectionsSubject = BehaviorSubject<PresenterState>(value: .loading)
  private let actionsSubject = PublishSubject<Action>()

  var sections: Observable<PresenterState> { sectionsSubject.asObservable() }
  var actions: Observable<Action> { actionsSubject.asObservable() }

  // MARK: - Lifecycle

  init(repository: UserListRepository) {
    self.repository = repository

    repository
      .users
      .map(presenterState(from:))
      .subscribe(sectionsSubject)
      .disposed(by: disposeBag)
  }

  // MARK: - Private

  private func presenterState(from usersResult: Result<[User], Error>) -> PresenterState {
    switch usersResult {
    case .success(let users):
      let sections = [createSection(with: users.sorted { $0.email < $1.email })]
      return .loaded(sections: sections)
    case .failure(let error):
      return .failure(error: error)
    }
  }

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
