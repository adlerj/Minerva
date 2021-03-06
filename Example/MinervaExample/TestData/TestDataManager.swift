//
//  TestDataManager.swift
//  MinervaExample
//
//  Copyright © 2019 Optimize Fitness, Inc. All rights reserved.
//

import Foundation

final class TestDataManager {
  struct Subscription<T> {
    let userID: String
    let callback: T
  }
  let userAuthorization: UserAuthorization

  private let queue = DispatchQueue(label: "TestDataManager", qos: .userInitiated)
  private let testData: TestData
  private let userManager: UserManager

  private var userSubscriptions: [SubscriptionID: UsersCompletion] = [:]
  private var workoutSubscriptions: [SubscriptionID: Subscription<WorkoutsCompletion>] = [:]
  private var workoutUserIDToSubscriptions: [String: [SubscriptionID]] = [:]

  init(testData: TestData, userAuthorization: UserAuthorization, userManager: UserManager) {
    self.testData = testData
    self.userAuthorization = userAuthorization
    self.userManager = userManager
  }
}

// MARK: - DataManager
extension TestDataManager: DataManager {

  func loadUsers(completion: @escaping UsersCompletion) {
    self.queue.async {
      guard self.userAuthorization.role.userEditor else {
        completion([], SystemError.unauthorized)
        return
      }
      completion(Array(self.testData.idToUserMap.values), nil)
    }
  }
  func loadUser(withID userID: String, completion: @escaping UserCompletion) {
    self.queue.async {
      guard userID == self.userAuthorization.userID || self.userAuthorization.role.userEditor else {
        completion(nil, SystemError.unauthorized)
        return
      }
      completion(self.testData.idToUserMap[userID], nil)
    }
  }
  func update(user: User, completion: @escaping Completion) {
    self.queue.async {
      guard user.userID == self.userAuthorization.userID || self.userAuthorization.role.userEditor else {
        completion(SystemError.unauthorized)
        return
      }
      self.testData.idToUserMap[user.userID] = user
      self.notifyForUserChanges()
      completion(nil)
    }
  }

  func delete(userID: String, completion: @escaping Completion) {
    userManager.delete(userID: userID).done {
      self.queue.async {
        self.notifyForUserChanges()
        completion(nil)
      }
    }.catch {
      completion($0)
    }
  }

  func create(
    withEmail email: String,
    password: String,
    dailyCalories: Int32,
    role: UserRole,
    completion: @escaping Completion
  ) {
    self.queue.async {
      guard self.userAuthorization.role.userEditor else {
        completion(SystemError.unauthorized)
        return
      }
      guard self.userAuthorization.role == .admin || role != .admin else {
        completion(SystemError.unauthorized)
        return
      }
      guard email.isEmail else {
        completion(SystemError.invalidEmail)
        return
      }
      guard self.testData.emailToAuthorizationMap[email] == nil else {
        completion(SystemError.alreadyExists)
        return
      }
      let userID = UUID().uuidString
      let accessToken = UUID().uuidString
      let authorization = UserAuthorizationProto(userID: userID, accessToken: accessToken, role: role)
      self.testData.emailToAuthorizationMap[email] = authorization
      self.testData.emailToPasswordMap[email] = password
      self.testData.idToAuthorizationMap[userID] = authorization

      let user = UserProto(userID: userID, email: email, dailyCalories: dailyCalories)
      self.testData.idToUserMap[userID] = user
      self.notifyForUserChanges()
      completion(nil)
    }
  }

  func loadWorkouts(forUserID userID: String, completion: @escaping WorkoutsCompletion) {
    self.queue.async {
      guard userID == self.userAuthorization.userID || self.userAuthorization.role == .admin else {
        completion([], SystemError.unauthorized)
        return
      }
      let workoutMap = self.testData.idToWorkoutIDMap[userID] ?? [:]
      let workouts = Array(workoutMap.values)
      completion(workouts, nil)
    }
  }


  func store(workout: Workout, completion: @escaping Completion) {
    self.queue.async {
      guard workout.userID == self.userAuthorization.userID || self.userAuthorization.role == .admin else {
        completion(SystemError.unauthorized)
        return
      }
      var workoutIDMap = self.testData.idToWorkoutIDMap[workout.userID] ?? [:]
      workoutIDMap[workout.workoutID] = workout
      self.testData.idToWorkoutIDMap[workout.userID] = workoutIDMap
      self.notifyForWorkoutChanges(userID: workout.userID)
      completion(nil)
    }
  }

  func delete(workout: Workout, completion: @escaping Completion) {
    self.queue.async {
      guard workout.userID == self.userAuthorization.userID || self.userAuthorization.role == .admin else {
        completion(SystemError.unauthorized)
        return
      }
      var workoutIDMap = self.testData.idToWorkoutIDMap[workout.userID] ?? [:]
      workoutIDMap[workout.workoutID] = nil
      self.testData.idToWorkoutIDMap[workout.userID] = workoutIDMap
      self.notifyForWorkoutChanges(userID: workout.userID)
      completion(nil)
    }
  }

  func subscribeToWorkoutChanges(
    for userID: String,
    callback: @escaping WorkoutsCompletion
  ) -> SubscriptionID {
    let id = UUID().uuidString
    queue.async {
      let subscription = Subscription(userID: userID, callback: callback)
      self.workoutSubscriptions[id] = subscription
      var subscriptions = self.workoutUserIDToSubscriptions[userID, default: []]
      subscriptions.append(id)
      self.workoutUserIDToSubscriptions[userID] = subscriptions
      self.notifyForWorkoutChanges(userID: userID, subscriptions: [subscription])
    }
    return id
  }

  func subscribeToUserChanges(
    callback: @escaping UsersCompletion
  ) -> SubscriptionID {
    let id = UUID().uuidString
    queue.async {
      self.userSubscriptions[id] = callback
      self.notifyForUserChanges(completions: [callback])
    }
    return id
  }

  func unsubscribe(listenerID: SubscriptionID) {
    queue.sync {
      guard let subscription = workoutSubscriptions[listenerID] else {
        return
      }
      let userID = subscription.userID
      workoutSubscriptions[listenerID] = nil
      userSubscriptions[listenerID] = nil
      var subscriptions = workoutUserIDToSubscriptions[userID, default: []]
      subscriptions.removeAll { $0 == listenerID }
      workoutUserIDToSubscriptions[userID] = subscriptions.isEmpty ? nil : subscriptions
    }
  }
}

// MARK: - Private
extension TestDataManager {
  private func notifyForUserChanges() {
    dispatchPrecondition(condition: .onQueue(queue))
    let completions = Array(userSubscriptions.values)
    notifyForUserChanges(completions: completions)
  }

  private func notifyForUserChanges(completions: [UsersCompletion]) {
    dispatchPrecondition(condition: .onQueue(queue))
    let users = Array(testData.idToUserMap.values)
    DispatchQueue.main.async {
      completions.forEach {
        $0(users, nil)
      }
    }
  }
  private func notifyForWorkoutChanges(userID: String) {
    dispatchPrecondition(condition: .onQueue(queue))
    guard let subscriptionIDs = workoutUserIDToSubscriptions[userID] else {
      return
    }
    let subscriptions = subscriptionIDs.compactMap { workoutSubscriptions[$0] }
    notifyForWorkoutChanges(userID: userID, subscriptions: subscriptions)
  }

  private func notifyForWorkoutChanges(userID: String, subscriptions: [Subscription<WorkoutsCompletion>]) {
    dispatchPrecondition(condition: .onQueue(queue))
    let workoutMap = self.testData.idToWorkoutIDMap[userID] ?? [:]
    let workouts = Array(workoutMap.values)
    DispatchQueue.main.async {
      subscriptions.forEach {
        $0.callback(workouts, nil)
      }
    }
  }
}
