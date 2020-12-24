import XCTest

@testable import TuistSupport
@testable import TuistSupportTesting

final class GitHandlerTests: TuistUnitTestCase {
    private var subject: GitHandler!

    override func setUp() {
        super.setUp()
        subject = GitHandler(system: system)
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    func test_cloneInto() throws {
        let url = "https://some/url/to/repo.git"
        let path = try temporaryPath()

        system.stubs["git -C \(path.pathString) clone \(url)"] = (stderror: nil, stdout: nil, exitstatus: 0)

        XCTAssertNoThrow(try subject.clone(url: url, into: path))
        XCTAssertTrue(system.called("git", "-C", path.pathString, "clone", url))
    }

    func test_cloneTo() throws {
        let url = "https://some/url/to/repo.git"

        system.stubs["git clone \(url)"] = (stderror: nil, stdout: nil, exitstatus: 0)

        XCTAssertNoThrow(try subject.clone(url: url))
        XCTAssertTrue(system.called("git", "clone", url))
    }

    func test_cloneTo_WITH_path() throws {
        let url = "https://some/url/to/repo.git"
        let path = try temporaryPath()

        system.stubs["git clone \(url) \(path.pathString)"] = (stderror: nil, stdout: nil, exitstatus: 0)

        XCTAssertNoThrow(try subject.clone(url: url, to: path))
        XCTAssertTrue(system.called("git", "clone", url, path.pathString))
    }

    func test_checkout() throws {
        let reference = "main"

        system.stubs["git checkout \(reference)"] = (stderror: nil, stdout: nil, exitstatus: 0)

        XCTAssertNoThrow(try subject.checkout(reference: reference, in: nil))
    }

    func test_checkout_WITH_path() throws {
        let reference = "main"
        let path = try temporaryPath()

        let expectedCommand = [
            "git",
            "--git-dir",
            path.appending(.init(".git")).pathString,
            "--work-tree",
            path.pathString,
            "checkout",
            reference,
        ].joined(separator: " ")

        system.stubs[expectedCommand] = (stderror: nil, stdout: nil, exitstatus: 0)

        XCTAssertNoThrow(try subject.checkout(reference: reference, in: path))
        XCTAssertTrue(system.called(
            "git",
            "--git-dir",
            path.appending(.init(".git")).pathString,
            "--work-tree",
            path.pathString,
            "checkout",
            reference
        ))
    }
}
