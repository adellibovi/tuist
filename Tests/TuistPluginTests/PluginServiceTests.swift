import TSCBasic
import TuistCore
import TuistCoreTesting
import TuistLoader
import TuistLoaderTesting
import TuistSupport
import TuistSupportTesting
import XCTest

@testable import TuistPlugin

final class PluginServiceTests: TuistTestCase {
    private var modelLoader: MockGeneratorModelLoader!
    private var gitHandler: MockGitHandler!
    private var manifestFilesLocator: MockManifestFilesLocator!
    private var subject: PluginService!
    private lazy var tuistPath = try! temporaryPath().appending(component: "Tuist")

    override func setUp() {
        super.setUp()
        modelLoader = MockGeneratorModelLoader(basePath: tuistPath)
        gitHandler = MockGitHandler()
        manifestFilesLocator = MockManifestFilesLocator()
        subject = PluginService(
            modelLoader: modelLoader,
            fileHandler: fileHandler,
            gitHandler: gitHandler,
            manifestFilesLocator: manifestFilesLocator
        )
    }

    override func tearDown() {
        super.tearDown()
        modelLoader = nil
        gitHandler = nil
        manifestFilesLocator = nil
        subject = nil
    }

    func test_loadPlugins_atPath_WHEN_localHelpers() throws {
        // Given
        let pluginPath = "/path/to/plugin"
        modelLoader.mockConfig("Config.swift") { _ in
            Config.test(plugins: [.local(path: pluginPath)])
        }
        modelLoader.mockPlugin(pluginPath) { _ in
            Plugin(name: "MockPlugin")
        }
        fileHandler.stubExists = { _ in
            true
        }

        // When
        let plugins = try subject.loadPlugins(at: try temporaryPath())

        // Then
        let expectedPlugins = Plugins(projectDescriptionHelpers: [
            .init(name: "MockPlugin", path: AbsolutePath(pluginPath).appending(component: Constants.helpersDirectoryName)),
        ])

        XCTAssertEqual(plugins, expectedPlugins)
    }

    func test_loadPlugins_usingConfig_WHEN_localHelpers() throws {
        // Given
        let pluginPath = "/path/to/plugin"
        let config = Config.test(plugins: [.local(path: pluginPath)])
        modelLoader.mockPlugin(pluginPath) { _ in
            Plugin(name: "MockPlugin")
        }
        fileHandler.stubExists = { _ in
            true
        }

        // When
        let plugins = try subject.loadPlugins(using: config)

        // Then
        let expectedPlugins = Plugins(projectDescriptionHelpers: [
            .init(name: "MockPlugin", path: AbsolutePath(pluginPath).appending(component: Constants.helpersDirectoryName)),
        ])
        XCTAssertEqual(plugins, expectedPlugins)
    }

    func test_loadPlugin_atPath_WHEN_gitHelpers() throws {
        // Given
        let pluginGitUrl = "https://url/to/repo.git"
        let pluginReference = "1234"
        let pluginFingerprint = "\(pluginGitUrl)-\(pluginReference)".md5
        let cachedPluginPath = environment.pluginsDirectory.appending(component: pluginFingerprint)
        modelLoader.mockConfig("Config.swift") { _ in
            Config.test(plugins: [.gitWithSha(url: pluginGitUrl, sha: pluginReference)])
        }
        modelLoader.mockPlugin(cachedPluginPath.pathString) { _ in
            Plugin(name: "MockPlugin")
        }
        fileHandler.stubExists = { _ in
            true
        }

        // When
        let plugins = try subject.loadPlugins(at: try temporaryPath())

        // Then
        let expectedPlugins = Plugins(projectDescriptionHelpers: [
            .init(name: "MockPlugin", path: cachedPluginPath.appending(component: Constants.helpersDirectoryName)),
        ])
        XCTAssertEqual(plugins, expectedPlugins)
    }

    func test_loadPlugin_usingConfig_WHEN_gitHelpers() throws {
        // Given
        let pluginGitUrl = "https://url/to/repo.git"
        let pluginReference = "v1.0.0"
        let pluginFingerprint = "\(pluginGitUrl)-\(pluginReference)".md5
        let cachedPluginPath = environment.pluginsDirectory.appending(component: pluginFingerprint)
        let config = Config.test(plugins: [.gitWithTag(url: pluginGitUrl, tag: pluginReference)])
        modelLoader.mockPlugin(cachedPluginPath.pathString) { _ in
            Plugin(name: "MockPlugin")
        }
        fileHandler.stubExists = { _ in
            true
        }

        // When
        let plugins = try subject.loadPlugins(using: config)

        // Then
        let expectedPlugins = Plugins(projectDescriptionHelpers: [
            .init(name: "MockPlugin", path: cachedPluginPath.appending(component: Constants.helpersDirectoryName)),
        ])
        XCTAssertEqual(plugins, expectedPlugins)
    }
}
