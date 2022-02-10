// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import ComposableArchitecture

struct OnboardingState: Equatable {
  enum Path: Equatable {
    case create(CreatePathStep)
    case restore
  }
  enum CreatePathStep: Int {
    case createWallet
    case backupWelcome
    case backupPhrase
    case verifyPhrase
    
    var next: Self? {
      .init(rawValue: rawValue + 1)
    }
    var previous: Self? {
      .init(rawValue: rawValue - 1)
    }
  }
  var path: Path?
  var recoveryPhrase: String?
}

enum OnboardingAction {
  case moveForward
  case moveBackward
  case fetchRecoveryPhrase
  case recoveryPhraseFetched(String)
  case setupButtonTapped
  case restoreButtonTapped
}

struct OnboardingEnvironment {
  var keyringService: BraveWalletKeyringService
}

let onboardingReducer = Reducer<
  OnboardingState, OnboardingAction, OnboardingEnvironment
> { state, action, environment in
  switch action {
  case .moveForward:
    return .none
  case .fetchRecoveryPhrase:
    return .future { callback in
      environment
        .keyringService.mnemonic { phrase in
          callback(.success(.recoveryPhraseFetched(phrase)))
        }
    }
  case .recoveryPhraseFetched(let phrase):
    state.recoveryPhrase = phrase
    return .none
  case .setupButtonTapped:
    state.path = .create(.createWallet)
    return .none
  case .restoreButtonTapped:
    state.path = .restore
    return .none
  case .moveBackward:
    switch state.path {
    case .create(let path):
      state.path = path.previous.map { .create($0) }
    case .restore:
      state.path = nil
    case .none:
      state.path = nil
    }
    return .none
  }
}

import BraveUI
import SwiftUI
import struct Shared.Strings
import Introspect

struct TcaWelcomeView: View {
  private struct ViewState: Equatable {
    var path: OnboardingState.Path?
  }
  
  let store: Store<OnboardingState, OnboardingAction>
  @ObservedObject private var viewStore: ViewStore<ViewState, OnboardingAction>
  
  init(store: Store<OnboardingState, OnboardingAction>) {
    self.store = store
    self.viewStore = ViewStore(store.scope(state: { ViewState(path: $0.path )}))
  }
  
  var body: some View {
    VStack(spacing: 46) {
      Image("setup-welcome")
      VStack(spacing: 14) {
        Text(Strings.Wallet.setupCryptoTitle)
          .foregroundColor(.primary)
          .font(.headline)
        Text(Strings.Wallet.setupCryptoSubtitle)
          .foregroundColor(.secondary)
          .font(.subheadline)
      }
      .fixedSize(horizontal: false, vertical: true)
      .multilineTextAlignment(.center)
      VStack(spacing: 26) {
        NavigationLink(
          isActive: viewStore.binding(
            get: { (/OnboardingState.Path.create .. /OnboardingState.CreatePathStep.createWallet).extract(from: $0.path) != nil },
            send: { state in
              if state {
                return .setupButtonTapped
              } else {
                return .moveBackward
              }
            }
          )
        ) {
          EmptyView()
        } label: {
          Text(Strings.Wallet.setupCryptoButtonTitle)
        }
        .buttonStyle(BraveFilledButtonStyle(size: .normal))
//        NavigationLink(
//          destination: RestoreWalletContainerView(keyringStore: keyringStore)
//        ) {
//          Text(Strings.Wallet.restoreWalletButtonTitle)
//            .font(.subheadline.weight(.medium))
//            .foregroundColor(Color(.braveLabel))
//        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityEmbedInScrollView()
    .navigationTitle(Strings.Wallet.cryptoTitle)
    .navigationBarTitleDisplayMode(.inline)
    .introspectViewController { vc in
      vc.navigationItem.backButtonTitle = Strings.Wallet.setupCryptoButtonBackButtonTitle
      vc.navigationItem.backButtonDisplayMode = .minimal
    }
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
  }
}

struct TcaCreateWalletView: View {
  private struct ViewState: Equatable {
    var path: OnboardingState.Path?
  }
  
  let store: Store<OnboardingState, OnboardingAction>
  @ObservedObject private var viewStore: ViewStore<ViewState, OnboardingAction>
  
  init(store: Store<OnboardingState, OnboardingAction>) {
    self.store = store
    self.viewStore = ViewStore(store.scope(state: { ViewState(path: $0.path )}))
  }
  
  var body: some View {
    ScrollView(.vertical) {
      
    }
  }
}
