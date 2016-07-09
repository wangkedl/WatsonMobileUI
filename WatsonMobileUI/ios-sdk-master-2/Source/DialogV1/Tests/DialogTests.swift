/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import XCTest
import DialogV1

class DialogTests: XCTestCase {

    private var dialog: Dialog!
    private let dialogNamePrefix = "swift-sdk-unit-test-"
    private let timeout: NSTimeInterval = 15.0

    // MARK: - Test Configuration

    /** Set up for each test by instantiating the service and deleting stale dialog applications. */
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        instantiateDialog()
        deleteStaleDialogs()
    }

    /** Instantiate Dialog. */
    func instantiateDialog() {
        let bundle = NSBundle(forClass: self.dynamicType)
        guard
            let file = bundle.pathForResource("Credentials", ofType: "plist"),
            let credentials = NSDictionary(contentsOfFile: file) as? [String: String],
            let username = credentials["DialogUsername"],
            let password = credentials["DialogPassword"]
        else {
            XCTFail("Unable to read credentials.")
            return
        }
        dialog = Dialog(username: username, password: password)
    }

    /** Delete any stale dialog applications previously created by unit tests. */
    func deleteStaleDialogs() {
        let description = "Delete any stale dialog applications previously created by unit tests."
        let expectation = expectationWithDescription(description)
        dialog.getDialogs(failWithError) { dialogs in
            for dialog in dialogs {
                if dialog.name.hasPrefix(self.dialogNamePrefix) {
                    self.dialog.deleteDialog(dialog.dialogID)
                }
            }
            expectation.fulfill()
        }
        waitForExpectations()
    }

    /** Fail false negatives. */
    func failWithError(error: NSError) {
        XCTFail("Positive test failed with error: \(error)")
    }

    /** Fail false positives. */
    func failWithResult<T>(result: T) {
        XCTFail("Negative test returned a result.")
    }

    /** Wait for expectation */
    func waitForExpectations() {
        waitForExpectationsWithTimeout(timeout) { error in
            XCTAssertNil(error, "Timeout")
        }
    }

    // MARK: - Helper Functions

    /** Generate a random alpha-numeric string. (Courtesy of Dschee on StackOverflow.) */
    func randomAlphaNumericString(length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyz0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var randomString = ""

        for _ in (0..<length) {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let newCharacter = allowedChars[allowedChars.startIndex.advancedBy(randomNum)]
            randomString += String(newCharacter)
        }

        return randomString
    }

    /** Generate the name for a dialog application. */
    func createDialogName() -> String {
        return dialogNamePrefix + randomAlphaNumericString(5)
    }

    /** Load a dialog file. */
    func loadDialogFile(name: String, withExtension: String) -> NSURL? {
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let url = bundle.URLForResource(name, withExtension: withExtension) else {
            return nil
        }
        return url
    }

    /** Create a dialog application for testing. */
    func createDialog(dialogName: String) -> DialogV1.DialogID? {
        let description = "Create a dialog application for testing."
        let expectation = expectationWithDescription(description)

        guard let fileURL = loadDialogFile("pizza_sample", withExtension: "xml") else {
            XCTFail("Failed to load dialog file.")
            return nil
        }

        var dialogID: String?
        dialog.createDialog(dialogName, fileURL: fileURL, failure: failWithError) { id in
            dialogID = id
            expectation.fulfill()
        }
        waitForExpectations()

        return dialogID
    }

    /** Start a new conversation with the dialog application. */
    func startConversation(dialogID: DialogV1.DialogID) -> DialogV1.ConversationResponse? {
        let description = "Start a conversation with the dialog application."
        let expectation = expectationWithDescription(description)

        let expectedResponse = "Hi, I\'m Watson! I can help you order a pizza, " +
                               "what size would you like?"

        var conversationResponse: DialogV1.ConversationResponse?

        dialog.converse(dialogID, failure: failWithError) { response in
            XCTAssertEqual(response.response.last, expectedResponse)
            conversationResponse = response
            expectation.fulfill()
        }
        waitForExpectations()

        return conversationResponse
    }

    /** Continue a conversation with the dialog application. */
    func continueConversation(
        dialogID: DialogV1.DialogID,
        conversationID: Int,
        clientID: Int,
        input: String,
        expectedResponse: String)
        -> DialogV1.ConversationResponse?
    {
        let description = "Continue a conversation with the dialog application."
        let expectation = expectationWithDescription(description)

        var conversationResponse: DialogV1.ConversationResponse?

        dialog.converse(
            dialogID,
            conversationID: conversationID,
            clientID: clientID,
            input: input,
            failure: failWithError)
        {
            response in
            XCTAssertEqual(response.response.last, expectedResponse)
            conversationResponse = response
            expectation.fulfill()
        }
        waitForExpectations()

        return conversationResponse
    }

    /** Delete the dialog application used for testing. */
    func deleteDialog(dialogID: DialogV1.DialogID) {
        let description = "Deleting the dialog application used for testing."
        let expectation = expectationWithDescription(description)

        dialog.deleteDialog(dialogID, failure: failWithError) {
            expectation.fulfill()
        }
        waitForExpectations()
    }

    // MARK: - Positive Tests - Content Operations

    /** List the dialog applications associated with this service instance. */
    func testGetDialogs() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "List the dialog applications associated with this service instance."
        let expectation = expectationWithDescription(description)

        dialog.getDialogs(failWithError) { dialogs in
            for dialog in dialogs {
                let nameMatch = (dialog.name == dialogName)
                let idMatch = (dialog.dialogID == dialogID)
                if nameMatch && idMatch {
                    expectation.fulfill()
                    return
                }
            }
            XCTFail("Could not retrieve the current dialog application used for testing.")
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Create and delete a dialog application. */
    func testCreateDelete() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        deleteDialog(dialogID)
    }

    /** Download the dialog file associated with this testing application. */
    func getDialogFile(format: DialogV1.Format? = nil) {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Download the dialog file associated with this testing application."
        let expectation = expectationWithDescription(description)

        dialog.getDialogFile(dialogID, format: format, failure: failWithError) { file in
            guard let path = file.path else {
                XCTFail("Dialog file does not exist at the given path.")
                return
            }

            XCTAssertTrue(NSFileManager().fileExistsAtPath(path))
            expectation.fulfill()
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Download the dialog file associated with this testing application. */
    func testGetDialogFile() {
        getDialogFile()
    }

    /** Download the dialog file associated with this testing application in OctetStream format. */
    func testGetDialogFileOctetStream() {
        getDialogFile(.OctetStream)
    }

    /** Download the dialog file associated with this testing application in JSON format. */
    func testGetDialogFileJSON() {
        getDialogFile(.WDSJSON)
    }

    /** Download the dialog file associated with this testing application in XML format. */
    func testGetDialogFileXML() {
        getDialogFile(.WDSXML)
    }

    /** Update the dialog application. */
    func testUpdateDialog() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Update the dialog application."
        let expectation = expectationWithDescription(description)

        guard let fileURL = loadDialogFile("pizza_sample", withExtension: "xml") else {
            XCTFail("Failed to load dialog file.")
            return
        }

        dialog.updateDialog(dialogID, fileURL: fileURL, failure: failWithError) {
            expectation.fulfill()
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Get the content for each node associated with the dialog application. */
    func testGetContent() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Get the content for each node."
        let expectation = expectationWithDescription(description)

        let initialNode = "OUTPUT(200000)"
        let initialResponse = "Hi, I\'m Watson! I can help you order a pizza, " +
                              "what size would you like?"

        dialog.getContent(dialogID, failure: failWithError) { nodes in
            for node in nodes {
                let nodeMatch = (node.node == initialNode)
                let contentMatch = (node.content == initialResponse)
                if nodeMatch && contentMatch {
                    expectation.fulfill()
                    return
                }
            }
            XCTFail("Failed to find the expected initial node.")
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Update the content for the initial node. */
    func testUpdateContent() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Update the content for the initial node."
        let expectation = expectationWithDescription(description)

        let initialNode = "OUTPUT(200000)"
        let newGreeting = "Hi, I\'m Watson! I can help you order a pizza through my " +
                          "convenient Swift SDK! What size would you like?"

        let newNode = DialogV1.Node(content: newGreeting, node: initialNode)

        dialog.updateContent(dialogID, nodes: [newNode], failure: failWithError) {
            expectation.fulfill()
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    // MARK: - Positive Tests - Conversation Operations

    /** Get conversation history. */
    func testGetConversationHistory() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description1 = "Start a conversation with the dialog application."
        let expectation1 = expectationWithDescription(description1)

        let response1 = "Hi, I\'m Watson! I can help you order a pizza, what size would you like?"
        var conversationID: Int?
        var clientID: Int?

        dialog.converse(dialogID, failure: failWithError) { response in
            XCTAssertEqual(response.response.last, response1)
            conversationID = response.conversationID
            clientID = response.clientID
            expectation1.fulfill()
        }
        waitForExpectations()

        let description2 = "Continue a conversation with the dialog application."
        let expectation2 = expectationWithDescription(description2)

        let response2 = "What toppings are you in the mood for? (Limit 4)"

        dialog.converse(
            dialogID,
            conversationID: conversationID!,
            clientID: clientID!,
            input: "large",
            failure: failWithError)
        {
            response in
            XCTAssertEqual(response.response.last, response2)
            expectation2.fulfill()
        }
        waitForExpectations()

        let description3 = "Get conversation history."
        let expectation3 = expectationWithDescription(description3)

        let sydneyOffset = abs(NSTimeZone(name: "Australia/Sydney")!.secondsFromGMT)
        let localOffset = abs(NSTimeZone.localTimeZone().secondsFromGMT)
        let serverOffset = sydneyOffset + localOffset
        let dateFromOffset: NSTimeInterval = -120.0 + Double(serverOffset)
        let dateToOffset: NSTimeInterval = 120 + Double(serverOffset)
        let dateFrom = NSDate(timeIntervalSinceNow: dateFromOffset)
        let dateTo = NSDate(timeIntervalSinceNow: dateToOffset)

        dialog.getConversationHistory(
            dialogID,
            dateFrom: dateFrom,
            dateTo: dateTo,
            failure: failWithError)
        {
            conversations in
            XCTAssertEqual(conversations.count, 1)
            XCTAssertEqual(conversations.first?.messages.count, 3)

            let message0 = conversations.first?.messages[0]
            XCTAssertEqual(message0?.fromClient, "false")
            XCTAssertEqual(message0?.text, response1)

            let message1 = conversations.first?.messages[1]
            XCTAssertEqual(message1?.fromClient, "true")
            XCTAssertEqual(message1?.text, "large")

            let message2 = conversations.first?.messages[2]
            XCTAssertEqual(message2?.fromClient, "false")
            XCTAssertEqual(message2?.text, response2)

            XCTAssertEqual(conversations.first?.profile["size"], "Large")

            expectation3.fulfill()
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /* Get conversation history with a date range that does not contain any history. */
    func testGetConversationhistoryWithDates() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Get conversation history with a date range."
        let expectation = expectationWithDescription(description)

        let sydneyOffset = abs(NSTimeZone(name: "Australia/Sydney")!.secondsFromGMT)
        let localOffset = abs(NSTimeZone.localTimeZone().secondsFromGMT)
        let serverOffset = sydneyOffset + localOffset
        let dateFromOffset: NSTimeInterval = -120.0 + Double(serverOffset)
        let dateToOffset: NSTimeInterval = 120 + Double(serverOffset)
        let dateFrom = NSDate(timeIntervalSinceNow: dateFromOffset)
        let dateTo = NSDate(timeIntervalSinceNow: dateToOffset)

        dialog.getConversationHistory(
            dialogID,
            dateFrom: dateFrom,
            dateTo: dateTo,
            failure: failWithError)
        {
            conversations in
            XCTAssertEqual(conversations.count, 0)
            expectation.fulfill()
        }
        waitForExpectations()
        
        deleteDialog(dialogID)
    }

    /** Get conversation history with an offset. */
    func testGetConversationHistoryWithOffset() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description1 = "Start a conversation with the dialog application."
        let expectation1 = expectationWithDescription(description1)

        let response1 = "Hi, I\'m Watson! I can help you order a pizza, what size would you like?"
        var conversationID: Int?
        var clientID: Int?

        dialog.converse(dialogID, failure: failWithError) { response in
            XCTAssertEqual(response.response.last, response1)
            conversationID = response.conversationID
            clientID = response.clientID
            expectation1.fulfill()
        }
        waitForExpectations()

        let description2 = "Continue a conversation with the dialog application."
        let expectation2 = expectationWithDescription(description2)

        let response2 = "What toppings are you in the mood for? (Limit 4)"

        dialog.converse(
            dialogID,
            conversationID: conversationID!,
            clientID: clientID!,
            input: "large",
            failure: failWithError)
        {
            response in
            XCTAssertEqual(response.response.last, response2)
            expectation2.fulfill()
        }
        waitForExpectations()

        let description3 = "Get conversation history with an offset."
        let expectation3 = expectationWithDescription(description3)

        let sydneyOffset = abs(NSTimeZone(name: "Australia/Sydney")!.secondsFromGMT)
        let localOffset = abs(NSTimeZone.localTimeZone().secondsFromGMT)
        let serverOffset = sydneyOffset + localOffset
        let dateFromOffset: NSTimeInterval = -120.0 + Double(serverOffset)
        let dateToOffset: NSTimeInterval = 120 + Double(serverOffset)
        let dateFrom = NSDate(timeIntervalSinceNow: dateFromOffset)
        let dateTo = NSDate(timeIntervalSinceNow: dateToOffset)

        dialog.getConversationHistory(
            dialogID,
            dateFrom: dateFrom,
            dateTo: dateTo,
            offset: 1,
            failure: failWithError)
        {
            conversations in
            XCTAssertEqual(conversations.count, 0)
            expectation3.fulfill()
        }
        waitForExpectations()
        
        deleteDialog(dialogID)
    }

    /** Get conversation history with a limit. */
    func testGetConversationHistoryWithLimit() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description1 = "Start a conversation with the dialog application."
        let expectation1 = expectationWithDescription(description1)

        let response1 = "Hi, I\'m Watson! I can help you order a pizza, what size would you like?"
        var conversationID: Int?
        var clientID: Int?

        dialog.converse(dialogID, failure: failWithError) { response in
            XCTAssertEqual(response.response.last, response1)
            conversationID = response.conversationID
            clientID = response.clientID
            expectation1.fulfill()
        }
        waitForExpectations()

        let description2 = "Continue a conversation with the dialog application."
        let expectation2 = expectationWithDescription(description2)

        let response2 = "What toppings are you in the mood for? (Limit 4)"

        dialog.converse(
            dialogID,
            conversationID: conversationID!,
            clientID: clientID!,
            input: "large",
            failure: failWithError)
        {
            response in
            XCTAssertEqual(response.response.last, response2)
            expectation2.fulfill()
        }
        waitForExpectations()

        let description3 = "Get conversation history with a limit."
        let expectation3 = expectationWithDescription(description3)

        let sydneyOffset = abs(NSTimeZone(name: "Australia/Sydney")!.secondsFromGMT)
        let localOffset = abs(NSTimeZone.localTimeZone().secondsFromGMT)
        let serverOffset = sydneyOffset + localOffset
        let dateFromOffset: NSTimeInterval = -120.0 + Double(serverOffset)
        let dateToOffset: NSTimeInterval = 120 + Double(serverOffset)
        let dateFrom = NSDate(timeIntervalSinceNow: dateFromOffset)
        let dateTo = NSDate(timeIntervalSinceNow: dateToOffset)

        dialog.getConversationHistory(
            dialogID,
            dateFrom: dateFrom,
            dateTo: dateTo,
            limit: 0,
            failure: failWithError)
        {
            conversations in
            XCTAssertEqual(conversations.count, 0)
            expectation3.fulfill()
        }
        waitForExpectations()
        
        deleteDialog(dialogID)
    }

    /** Converse with the dialog application. */
    func testConverse() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description1 = "Start a conversation with the dialog application."
        let expectation1 = expectationWithDescription(description1)

        let response1 = "Hi, I\'m Watson! I can help you order a pizza, what size would you like?"
        var conversationID: Int?
        var clientID: Int?

        dialog.converse(dialogID, failure: failWithError) { response in
            XCTAssertEqual(response.response.last, response1)
            conversationID = response.conversationID
            clientID = response.clientID
            expectation1.fulfill()
        }
        waitForExpectations()

        let description2 = "Continue a conversation with the dialog application."
        let expectation2 = expectationWithDescription(description2)

        let response2 = "What toppings are you in the mood for? (Limit 4)"

        dialog.converse(
            dialogID,
            conversationID: conversationID!,
            clientID: clientID!,
            input: "large",
            failure: failWithError)
        {
            response in
            XCTAssertEqual(response.response.last, response2)
            expectation2.fulfill()
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    // MARK: - Positive Tests - Profile Operations

    /** Retrieve a client's profile variables. */
    func testGetProfile() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description1 = "Start a conversation with the dialog application."
        let expectation1 = expectationWithDescription(description1)

        var conversationID: Int?
        var clientID: Int?

        dialog.converse(dialogID, failure: failWithError) { response in
            conversationID = response.conversationID
            clientID = response.clientID
            expectation1.fulfill()
        }
        waitForExpectations()

        let description2 = "Continue a conversation with the dialog application."
        let expectation2 = expectationWithDescription(description2)

        dialog.converse(
            dialogID,
            conversationID: conversationID!,
            clientID: clientID!,
            input: "large",
            failure: failWithError)
        {
            response in
            expectation2.fulfill()
        }
        waitForExpectations()

        let description3 = "Retrieve the client's profile variables."
        let expectation3 = expectationWithDescription(description3)

        dialog.getProfile(dialogID, clientID: clientID!, failure: failWithError) { profile in
            XCTAssertNil(profile.clientID)
            XCTAssertEqual(profile.parameters.first?.name, "size")
            XCTAssertEqual(profile.parameters.first?.value, "Large")
            expectation3.fulfill()
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Update a new client's profile variables. */
    func testUpdateNewProfile() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Update a new client's profile variables."
        let expectation = expectationWithDescription(description)

        dialog.updateProfile(dialogID, parameters: ["size": "Large"], failure: failWithError) {
            expectation.fulfill()
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Update an existing client's profile variables. */
    func testUpdateExistingProfile() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description1 = "Start a conversation with the dialog application."
        let expectation1 = expectationWithDescription(description1)

        var clientID: Int?

        dialog.converse(dialogID, failure: failWithError) { response in
            clientID = response.clientID
            expectation1.fulfill()
        }
        waitForExpectations()

        let description2 = "Update an existing client's profile variables."
        let expectation2 = expectationWithDescription(description2)

        dialog.updateProfile(
            dialogID,
            clientID: clientID!,
            parameters: ["size": "Large"],
            failure: failWithError)
        {
            expectation2.fulfill()
        }
        waitForExpectations()

        deleteDialog(dialogID)
    }

    // MARK: - Negative Tests - Content Operations

    /** Create a dialog application with an invalid dialog file. */
    func testCreateDialogWithInvalidFile() {

        let description = "Create a dialog application with an invalid dialog file."
        let expectation = expectationWithDescription(description)

        let dialogName = createDialogName()

        guard let fileURL = loadDialogFile("pizza_sample_invalid", withExtension: "xml") else {
            XCTFail("Failed to load invalid dialog file.")
            return
        }

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 400)
            expectation.fulfill()
        }

        dialog.createDialog(dialogName, fileURL: fileURL, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    /** Create a dialog with a conflicting name. */
    func testCreateDialogWithConflictingName() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Create a dialog with a conflicting name."
        let expectation = expectationWithDescription(description)

        guard let fileURL = loadDialogFile("pizza_sample", withExtension: "xml") else {
            XCTFail("Failed to load dialog file.")
            return
        }

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 409)
            expectation.fulfill()
        }

        dialog.createDialog(dialogName, fileURL: fileURL, failure: failure, success: failWithResult)
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Create a dialog with a name that is too long. */
    func testCreateDialogWithLongName() {

        let description = "Create a dialog with a long name."
        let expectation = expectationWithDescription(description)

        let longName = createDialogName() + randomAlphaNumericString(10)

        guard let fileURL = loadDialogFile("pizza_sample", withExtension: "xml") else {
            XCTFail("Failed to load dialog file.")
            return
        }

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 422)
            expectation.fulfill()
        }

        dialog.createDialog(longName, fileURL: fileURL, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    /** Create a dialog with a file that does not exist. */
    func testCreateDialogWithNonexistentFile() {

        let description = "Create a dialog with a file that does not exist."
        let expectation = expectationWithDescription(description)

        let dialogName = createDialogName()

        let fileURL = NSURL(fileURLWithPath: "/this/is/an/invalid/path.json")

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 0)
            expectation.fulfill()
        }

        dialog.createDialog(dialogName, fileURL: fileURL, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    /** Delete a dialog that doesn't exist. */
    func testDeleteInvalidDialogID() {

        let description = "Delete a dialog that doesn't exist."
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"
        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.deleteDialog(invalidID, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    /** Get the dialog file for a dialog that doesn't exist. */
    func testGetDialogFileForInvalidDialogID() {

        let description = "Get the dialog file for a dialog that doesn't exist."
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"
        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 516)
            expectation.fulfill()
        }

        dialog.getDialogFile(invalidID, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    /** Upload an invalid dialog file. */
    func testUpdateDialogWithInvalidFile() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Upload an invalid dialog file."
        let expectation = expectationWithDescription(description)

        guard let fileURL = loadDialogFile("pizza_sample_invalid", withExtension: "xml") else {
            XCTFail("Failed to load invalid dialog file.")
            return
        }

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 400)
            expectation.fulfill()
        }

        dialog.updateDialog(dialogID, fileURL: fileURL, failure: failure, success: failWithResult)
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Update a dialog with a file that does not exist. */
    func testUpdateDialogWithNonexistentFile() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Update a dialog with a file that does not exist."
        let expectation = expectationWithDescription(description)

        let fileURL = NSURL(fileURLWithPath: "/this/is/an/invalid/path.json")

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 0)
            expectation.fulfill()
        }

        dialog.updateDialog(dialogID, fileURL: fileURL, failure: failure, success: failWithResult)
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Update a dialog that doesn't exist. */
    func testUpdateDialogForInvalidDialogID() {

        let description = "Update a dialog that doesn't exist."
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"

        guard let fileURL = loadDialogFile("pizza_sample", withExtension: "xml") else {
            XCTFail("Failed to load dialog file.")
            return
        }

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.updateDialog(invalidID, fileURL: fileURL, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    /** Get the content for each node of a dialog application that doesn't exist. */
    func testGetContentForInvalidDialogID() {

        let description = "Retrieve the content from nodes "
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.getContent(invalidID, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    /** Update invalid content for a node of the dialog application. */
    func testUpdateContentInvalid() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Update invalid content for a node of the dialog application."
        let expectation = expectationWithDescription(description)

        let nodes = [DialogV1.Node(content: "this-is-invalid", node: "this-is-invalid")]

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 422)
            expectation.fulfill()
        }

        dialog.updateContent(dialogID, nodes: nodes, failure: failure, success: failWithResult)
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Update content for a dialog that doesn't exist. */
    func testUpdateContentForInvalidDialogID() {

        let description = "Update content for a dialog that doesn't exist."
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"

        let nodes = [DialogV1.Node(content: "", node: "")]

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.updateContent(invalidID, nodes: nodes, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    // MARK: - Negative Tests - Conversation Operations

    /** Get conversation history for a dialog that doesn't exit. */
    func testGetConversationHistoryForInvalidDialogID() {

        let description = "Get the conversation history for a dialog that doesn't exist."
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"

        let sydneyOffset = abs(NSTimeZone(name: "Australia/Sydney")!.secondsFromGMT)
        let localOffset = abs(NSTimeZone.localTimeZone().secondsFromGMT)
        let serverOffset = sydneyOffset + localOffset
        let dateFromOffset: NSTimeInterval = -120.0 + Double(serverOffset)
        let dateToOffset: NSTimeInterval = 120 + Double(serverOffset)
        let dateFrom = NSDate(timeIntervalSinceNow: dateFromOffset)
        let dateTo = NSDate(timeIntervalSinceNow: dateToOffset)

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.getConversationHistory(
            invalidID,
            dateFrom: dateFrom,
            dateTo: dateTo,
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()
    }

    /** Converse with a dialog application that doesn't exist.  */
    func testConverseWithInvalidDialogID() {

        let description = "Converse with a dialog application that doesn't exist."
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.converse(invalidID, failure: failure, success: failWithResult)
        waitForExpectations()
    }

    /** Converse with a dialog application using an invalid conversation id and client id. */
    func testConverseWithInvalidIDs() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Converse with a dialog application using invalid ids."
        let expectation = expectationWithDescription(description)

        let invalidConversationID = 0
        let invalidClientID = 0

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.converse(
            dialogID,
            conversationID: invalidConversationID,
            clientID: invalidClientID,
            input: "large",
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()

        deleteDialog(dialogID)
    }

    // MARK: - Negative Tests - Profile Operations

    /** Retrieve a client's profile variables for a dialog that doesn't exist. */
    func testGetProfileWithInvalidDialogID() {

        let description = "Retrieve a client's profile variables for a dialog that doesn't exist."
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"
        let invalidClientID = 0
        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.getProfile(
            invalidID,
            clientID: invalidClientID,
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()
    }

    /** Retrieve a client's profile variables using an invalid client id. */
    func testGetProfileWithInvalidClientID() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Retrieve the client's profile variables using an invalid client id."
        let expectation = expectationWithDescription(description)

        let invalidClientID = 0

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 400)
            expectation.fulfill()
        }

        dialog.getProfile(
            dialogID,
            clientID: invalidClientID,
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()
        
        deleteDialog(dialogID)
    }

    /** Retrieve a client's profile using invalid profile parameters. */
    func testGetProfileWithInvalidParameterNames() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description1 = "Start a conversation with the dialog application."
        let expectation1 = expectationWithDescription(description1)

        var clientID: Int?

        dialog.converse(dialogID, failure: failWithError) { response in
            clientID = response.clientID
            expectation1.fulfill()
        }
        waitForExpectations()

        let description2 = "Retrieve the client's profile using invalid profile parameters."
        let expectation2 = expectationWithDescription(description2)

        let invalidParameters = ["these", "parameter", "names", "do", "not", "exist"]

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 422)
            expectation2.fulfill()
        }

        dialog.getProfile(
            dialogID,
            clientID: clientID!,
            names: invalidParameters,
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()

        deleteDialog(dialogID)
    }

    /** Update a client's profile variables using an invalid dialog id. */
    func testUpdateProfileWithInvalidDialogID() {

        let description = "Update the client's profile variables using an invalid dialog id."
        let expectation = expectationWithDescription(description)

        let invalidID = "this-id-does-not-exist"

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 404)
            expectation.fulfill()
        }

        dialog.updateProfile(
            invalidID,
            parameters: ["size": "Large"],
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()
    }

    /** Update a client's profile using an invalid client id. */
    func testUpdateProfileWithInvalidClientID() {

        let dialogName = createDialogName()
        guard let dialogID = createDialog(dialogName) else {
            XCTFail("Failed to create a dialog application for testing.")
            return
        }

        let description = "Update a client's profile using an invalid client id."
        let expectation = expectationWithDescription(description)

        let invalidID = 0

        let failure = { (error: NSError) in
            XCTAssertEqual(error.code, 400)
            expectation.fulfill()
        }

        dialog.updateProfile(
            dialogID,
            clientID: invalidID,
            parameters: ["size": "Large"],
            failure: failure,
            success: failWithResult
        )
        waitForExpectations()

        deleteDialog(dialogID)
    }
}
