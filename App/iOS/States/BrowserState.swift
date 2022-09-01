// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import Brave
import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

class BrowserState {
  let profile: Profile
  let diskImageStore: DiskImageStore?
  let webServer: WebServer
  
  init() {
    // Setup Browser Profile (Logins, etc)
    profile = BrowserProfile(localName: "profile")
    
    // Setup DiskImageStore for Screenshots
    diskImageStore = BrowserState.createDiskImageStore(for: profile)
    
    // Setup WebServer
    webServer = WebServer.sharedInstance
  }
  
  private static func createDiskImageStore(for profile: Profile) -> DiskImageStore? {
    do {
      return try DiskImageStore(
        files: profile.files,
        namespace: "TabManagerScreenshots",
        quality: UIConstants.screenshotQuality)
    } catch {
      log.error("Failed to create an image store for files: \(profile.files) and namespace: \"TabManagerScreenshots\": \(error.localizedDescription)")
      assertionFailure()
    }
    return nil
  }
}
