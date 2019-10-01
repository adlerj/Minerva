//
//  DataManager+RxSwift.swift
//  MinervaExample
//
//  Copyright © 2019 Optimize Fitness, Inc. All rights reserved.
//

import Foundation

import RxSwift

extension DataManager {
  func users() -> Single<[User]> {
    return wrap {
      self.loadUsers(completion: $0)
      return {}
    }
  }

  func user(withID userID: String) -> Single<User?> {
    return wrap {
      self.loadUser(withID: userID, completion: $0)
      return {}
    }
  }

  func update(_ user: User) -> Single<Void> {
    return wrap {
      self.update(user: user, completion: $0)
      return {}
    }
  }

  func deleteUser(withUserID userID: String) -> Single<Void> {
    return wrap {
      self.delete(userID: userID, completion: $0)
      return {}
    }
  }

  func createUser(
    withEmail email: String,
    password: String,
    dailyCalories: Int32,
    role: UserRole
  ) -> Single<Void> {
    return wrap {
      self.create(
        withEmail: email,
        password: password,
        dailyCalories:
        dailyCalories,
        role: role,
        completion: $0
      )
      return {}
    }
  }

  func workouts(forUserID userID: String) -> Single<[Workout]> {
    return wrap {
      self.loadWorkouts(forUserID: userID, completion: $0)
      return {}
    }
  }

  func store(_ workout: Workout) -> Single<Void> {
    return wrap {
      self.store(workout: workout, completion: $0)
      return {}
    }
  }

  func delete(_ workout: Workout) -> Single<Void> {
    return wrap {
      self.delete(workout: workout, completion: $0)
      return {}
    }
  }

  func observeWorkouts(for userID: String) -> Observable<Result<[Workout], Error>> {
    return Observable<Result<[Workout], Error>>.wrap({ completion in
      let subscriptionID = self.subscribeToWorkoutChanges(for: userID, callback: completion)
      return { self.unsubscribe(listenerID: subscriptionID) }
    })
  }

  func observeUsers() -> Observable<Result<[User], Error>> {
    return Observable<Result<[User], Error>>.wrap({ completion in
      let subscriptionID = self.subscribeToUserChanges(callback: completion)
      return { self.unsubscribe(listenerID: subscriptionID) }
    })
  }
}

extension DataManager {
  private func wrap<Value>(
    _ work: @escaping (@escaping (Value, Swift.Error?) -> Void) -> () -> Void
  ) -> Single<Value> {
    return Single<Value>.create { single in
      let onDispose = work { value, error in
        if let error = error {
          single(.error(error))
        } else {
          single(.success(value))
        }
      }
      return Disposables.create { onDispose() }
    }
  }

  private func wrap(
    _ work: @escaping (@escaping (Swift.Error?) -> Void) -> () -> Void
  ) -> Single<Void> {
    return Single<Void>.create { single in
      let onDispose = work { error in
        if let error = error {
          single(.error(error))
        } else {
          single(.success(()))
        }
      }
      return Disposables.create { onDispose() }
    }
  }
}

extension ObservableType {
  public static func wrap<Value, Error>(
    _ work: @escaping (@escaping (Value, Error?) -> Void) -> () -> Void
  ) -> Observable<Result<Value, Error>> where Element == Result<Value, Error> {
    return Observable<Element>.create { observer in
      let onDispose = work { value, error in
        if let error = error {
          observer.onNext(.failure(error))
        } else {
          observer.onNext(.success(value))
        }
      }
      return Disposables.create { onDispose() }
    }
  }
}
