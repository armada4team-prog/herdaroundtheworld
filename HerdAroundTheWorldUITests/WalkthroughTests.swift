import XCTest

// A real-use walkthrough: taps through the app like a first-time finder would.
// On GitHub the simulator screen is recorded while this runs, so the video shows the app in use.
final class WalkthroughTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestSamplePhoto"]
        app.launch()
    }

    func testFinderWalkthrough() {
        // 1. Welcome: tap the bouncing Companion to come in.
        pause(2.5)
        tap(app.buttons["Say hi and come in"])
        pause()

        // 2. Scan tab: no camera in the simulator, so type #07's number.
        tapTab("Scan")
        let number = app.textFields["scanNumber"]
        tap(number)
        number.typeText("07")
        pause(0.8)
        tap(button("Find them →"))

        // 3. The hello card a finder sees after scanning.
        pause(2.5)
        tap(button("See where I’ve been ↓"))
        pause()

        // 4. Their page: look around, then log the find.
        app.swipeUp(velocity: .slow)
        pause()
        app.swipeDown(velocity: .slow)
        pause(0.8)
        tap(button("I just found them"))

        // 5. I found them: city and nickname.
        let city = app.textFields["foundCity"]
        tap(city)
        city.typeText("Denver, CO")
        let nickname = app.textFields["foundNickname"]
        tap(nickname)
        nickname.typeText("Sam")
        pause(0.8)
        tap(button("Log my find →"))
        pause(2)

        // 6. Pass them on: where, a chapter, and yes, we granted the wish.
        tap(button("I’m passing them on now"))
        let whereField = app.textFields["passWhere"]
        tap(whereField)
        whereField.typeText("Boulder, CO")
        let chapter = app.descendants(matching: .any).matching(identifier: "passChapter").firstMatch
        tap(chapter)
        chapter.typeText("We watched the sunrise over the Flatirons together.")
        pause(0.8)
        tap(buttonStarting("Yes, we did it"))
        pause()
        tap(button("Send them on their way →"))

        // 7. Wish granted: choose the next wish.
        pause(2)
        tap(button("I want to meet a dog."))
        pause()
        tap(button("Set their next wish →"))

        // 8. The postcard and the new stamp.
        pause(2)
        app.swipeUp(velocity: .slow)
        pause()
        tap(button("Done"))

        // 9. Passport: the new stamps.
        tapTab("Passport")
        pause(1.5)
        app.swipeUp(velocity: .slow)
        pause(2)

        // 10. Map: find #07 and see their journey, now ending in Boulder.
        tapTab("Map")
        pause(1.5)
        let search = app.textFields["mapSearch"]
        tap(search)
        search.typeText("07")
        tap(button("Go"))
        pause(3)
        tap(button("Open their page"))
        pause(1.5)
        app.swipeUp(velocity: .slow)
        pause(2)

        // 11. Activity: the find shows up in the news.
        tapTab("Activity")
        pause(3)
    }

    // MARK: Helpers

    private func pause(_ seconds: TimeInterval = 1.2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // Button whose label matches, ignoring capitals (button text is shown in capitals).
    private func button(_ label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label ==[c] %@", label)).firstMatch
    }

    private func buttonStarting(_ label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", label)).firstMatch
    }

    // Tabs are always on screen (unless a keyboard covers them), so no scrolling.
    private func tapTab(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        if app.keyboards.firstMatch.exists {
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
            pause(0.5)
        }
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 8), "Couldn’t find the \(name) tab", file: file, line: line)
        tab.tap()
        pause(0.8)
    }

    // Scrolls until the element is on screen and clear of the keyboard and tab bar, then taps it.
    private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 8), "Couldn’t find \(element)", file: file, line: line)
        var tries = 0
        while !isComfortablyVisible(element) && tries < 12 {
            app.swipeUp(velocity: .slow)
            tries += 1
        }
        element.tap()
        pause(0.6)
    }

    private func isComfortablyVisible(_ element: XCUIElement) -> Bool {
        guard element.exists, element.isHittable else { return false }
        let frame = element.frame
        let screen = app.windows.firstMatch.frame
        let keyboardTop = app.keyboards.firstMatch.exists ? app.keyboards.firstMatch.frame.minY : screen.maxY
        let tabBarTop = app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame.minY : screen.maxY
        return frame.minY > screen.minY + 40 && frame.maxY < min(keyboardTop, tabBarTop) - 8
    }
}
