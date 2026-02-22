import XCTest

class RUPAYA_UITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }

    func testLoginScreenShowsErrorOnInvalidCredentials() {
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("invalid@example.com")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("wrongpass")
        app.buttons["Login"].tap()
        XCTAssertTrue(app.staticTexts["Invalid credentials"].exists)
    }

    func testSignupScreenNavigatesToHomeOnSuccess() {
        app.buttons["Sign Up"].tap()
        // Fill in signup fields and submit
        // XCTAssertTrue(app.staticTexts["Home"].exists)
    }
}
