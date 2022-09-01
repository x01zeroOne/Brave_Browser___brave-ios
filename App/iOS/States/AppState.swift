// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import OSLog
import BraveCore
import Brave
import BraveShared
import Data
import RuntimeWarnings
import Shared
import XCGLogger

#if DEBUG
import os
#endif

/// Class that does startup initialization
/// Everything in this class can only be execute ONCE
/// IE: BraveCore initialization, BuildChannel, Migrations, etc.
class AppState {
  static let shared = AppState()
  
  let braveCore: BraveCoreMain
  let dau: DAU
  let migrations: Migration
  
  var state: State = .launching(options: [:], active: false)
  
  private init() {
    // Setup Constants
    AppState.setupConstants()
    
    // Setup BraveCore
    braveCore = AppState.setupBraveCore().then {
      $0.scheduleLowPriorityStartupTasks()
    }
    
    // Setup DAU
    dau = DAU(braveCoreStats: braveCore.braveStats)
    
    // Setup Migrations
    migrations = Migration(braveCore: braveCore)
    migrations.moveDatabaseToApplicationDirectory()
  }
  
  enum State {
    case launching(options: [UIApplication.LaunchOptionsKey: Any], active: Bool)
    case active
    case backgrounded
    case terminating
  }
  
  private static func setupConstants() {
    // Application Constants must be initialized first
    #if MOZ_CHANNEL_RELEASE
    AppConstants.buildChannel = .release
    #elseif MOZ_CHANNEL_BETA
    AppConstants.buildChannel = .beta
    #elseif MOZ_CHANNEL_DEV
    AppConstants.buildChannel = .dev
    #elseif MOZ_CHANNEL_ENTERPRISE
    AppConstants.buildChannel = .enterprise
    #elseif MOZ_CHANNEL_DEBUG
    AppConstants.buildChannel = .debug
    #endif
  }
  
  private static func setupBraveCore() -> BraveCoreMain {
    // BraveCore Log Handler
    BraveCoreMain.setLogHandler { severity, file, line, messageStartIndex, message in
      let message = String(message.dropFirst(messageStartIndex).dropLast())
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if message.isEmpty {
        // Nothing to print
        return true
      }
      
      if severity == .fatal {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        #if DEBUG
        // Prints a special runtime warning instead of crashing.
        os_log(
          .fault,
          dso: os_rw.dso,
          log: os_rw.log(category: "BraveCore"),
          "[%@:%ld] > %@", filename, line, message
        )
        return true
        #else
        fatalError("Fatal BraveCore Error at \(filename):\(line).\n\(message)")
        #endif
      }

      let level: XCGLogger.Level = {
        switch severity {
        case .fatal: return .severe
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        default: return .debug
        }
      }()

      Logger.braveCoreLogger.logln(
        level,
        fileName: file,
        lineNumber: Int(line),
        // Only print the actual message content, and drop the final character which is
        // a new line as it will be handled by logln
        closure: { message }
      )
      return true
    }
    
    // Initialize BraveCore Switches
    var switches: [BraveCoreSwitch: String] = [:]
    if !AppConstants.buildChannel.isPublic {
      // Check prefs for additional switches
      let activeSwitches = Preferences.BraveCore.activeSwitches.value
      let switchValues = Preferences.BraveCore.switchValues.value
      for activeSwitch in activeSwitches {
        if let value = switchValues[activeSwitch], !value.isEmpty {
          switches[BraveCoreSwitch(rawValue: activeSwitch)] = value
        }
      }
    }
    
    // Initialize BraveCore
    return BraveCoreMain(userAgent: UserAgent.mobile, additionalSwitches: switches)
  }
}
