// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import Combine

/// The main wallet store
public class WalletStore {
  
  public let keyringStore: KeyringStore
  public var cryptoStore: CryptoStore?
  
  // MARK: -
  
  private var cancellable: AnyCancellable?
  let keyringService: BraveWalletKeyringService
  let rpcService: BraveWalletJsonRpcService
  let walletService: BraveWalletBraveWalletService
  let assetRatioService: BraveWalletAssetRatioService
  let swapService: BraveWalletSwapService
  let blockchainRegistry: BraveWalletBlockchainRegistry
  let txService: BraveWalletEthTxService
  
  public init(
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    assetRatioService: BraveWalletAssetRatioService,
    swapService: BraveWalletSwapService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    txService: BraveWalletEthTxService
  ) {
    self.keyringService = keyringService
    self.rpcService = rpcService
    self.walletService = walletService
    self.assetRatioService = assetRatioService
    self.swapService = swapService
    self.blockchainRegistry = blockchainRegistry
    self.txService = txService
    
    self.keyringStore = .init(keyringService: keyringService)
    
//    self.setUp(
//      keyringService: keyringService,
//      rpcService: rpcService,
//      walletService: walletService,
//      assetRatioService: assetRatioService,
//      swapService: swapService,
//      blockchainRegistry: blockchainRegistry,
//      txService: txService
//    )
  }
  
  private func setUp(
    keyringService: BraveWalletKeyringService,
    rpcService: BraveWalletJsonRpcService,
    walletService: BraveWalletBraveWalletService,
    assetRatioService: BraveWalletAssetRatioService,
    swapService: BraveWalletSwapService,
    blockchainRegistry: BraveWalletBlockchainRegistry,
    txService: BraveWalletEthTxService
  ) {
    self.cancellable = self.keyringStore.$keyring
      .map(\.isDefaultKeyringCreated)
      .removeDuplicates()
      .sink { [weak self] isDefaultKeyringCreated in
        guard let self = self else { return }
        if !isDefaultKeyringCreated, self.cryptoStore != nil {
          self.cryptoStore = nil
        } else if isDefaultKeyringCreated, self.cryptoStore == nil {
          self.cryptoStore = CryptoStore(
            keyringService: keyringService,
            rpcService: rpcService,
            walletService: walletService,
            assetRatioService: assetRatioService,
            swapService: swapService,
            blockchainRegistry: blockchainRegistry,
            txService: txService
          )
        }
    }
  }
}
