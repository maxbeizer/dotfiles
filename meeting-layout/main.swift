import AppKit
import ApplicationServices

private let meetingAppNames: Set<String> = [
  "zoom.us",
  "Zoom",
  "Zoom Workplace",
  "Microsoft Teams",
  "Microsoft Teams (work or school)",
]

private struct Window {
  let element: AXUIElement
  let isMeeting: Bool
}

private enum LayoutError: LocalizedError {
  case accessibilityPermission
  case noMeetingWindow

  var errorDescription: String? {
    switch self {
    case .accessibilityPermission:
      return "Grant Accessibility permission to the app running meeting-layout."
    case .noMeetingWindow:
      return "No Zoom or Microsoft Teams window is open."
    }
  }
}

private func attribute<T>(_ element: AXUIElement, _ name: CFString) -> T? {
  var value: CFTypeRef?
  guard AXUIElementCopyAttributeValue(element, name, &value) == .success else {
    return nil
  }
  return value as? T
}

private func move(_ window: AXUIElement, to frame: CGRect) {
  var origin = frame.origin
  var size = frame.size
  guard
    let position = AXValueCreate(.cgPoint, &origin),
    let windowSize = AXValueCreate(.cgSize, &size)
  else {
    return
  }

  AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
  AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, windowSize)
}

private func layout() throws {
  guard AXIsProcessTrusted() else {
    throw LayoutError.accessibilityPermission
  }
  guard let display = NSScreen.main else {
    return
  }

  let frame = display.visibleFrame
  let leftWidth = round(frame.width / 3)
  let meetingFrame = CGRect(
    x: frame.minX,
    y: frame.minY,
    width: leftWidth,
    height: frame.height
  )
  let workFrame = CGRect(
    x: frame.minX + leftWidth,
    y: frame.minY,
    width: frame.width - leftWidth,
    height: frame.height
  )
  var windows: [Window] = []

  for application in NSWorkspace.shared.runningApplications
  where application.activationPolicy == .regular && !application.isTerminated {
    let element = AXUIElementCreateApplication(application.processIdentifier)
    let isMeeting = meetingAppNames.contains(application.localizedName ?? "")
    guard let applicationWindows: [AXUIElement] = attribute(
      element,
      kAXWindowsAttribute as CFString
    ) else {
      continue
    }

    for window in applicationWindows {
      guard
        let role: String = attribute(window, kAXRoleAttribute as CFString),
        role == kAXWindowRole,
        let subrole: String = attribute(window, kAXSubroleAttribute as CFString),
        subrole == kAXStandardWindowSubrole,
        (attribute(window, kAXMinimizedAttribute as CFString) as Bool?) != true
      else {
        continue
      }
      windows.append(Window(element: window, isMeeting: isMeeting))
    }
  }

  guard windows.contains(where: \.isMeeting) else {
    throw LayoutError.noMeetingWindow
  }

  for window in windows {
    move(window.element, to: window.isMeeting ? meetingFrame : workFrame)
  }
}

do {
  try layout()
} catch {
  FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
  exit(EXIT_FAILURE)
}
