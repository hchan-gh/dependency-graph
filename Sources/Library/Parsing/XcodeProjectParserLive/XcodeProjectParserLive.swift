import FileSystem
import Foundation
import PathKit
import XcodeProj
import XcodeProject
import XcodeProjectParser

public struct XcodeProjectParserLive: XcodeProjectParser {
    private let fileSystem: FileSystem

    public init(fileSystem: FileSystem) {
        self.fileSystem = fileSystem
    }

    public func parseProject(at fileURL: URL, packagesURL: (URL) -> URL?) throws -> XcodeProject {
        let path = Path(fileURL.relativePath)
        let project = try XcodeProj(path: path)
        let sourceRoot = fileURL.deletingLastPathComponent()
        let remoteSwiftPackages = remoteSwiftPackages(in: project)
        let localSwiftPackages = try localSwiftPackages(in: project, atSourceRoot: packagesURL(sourceRoot) ?? sourceRoot)
        return XcodeProject(
            name: fileURL.lastPathComponent,
            targets: targets(in: project),
            swiftPackages: (remoteSwiftPackages + localSwiftPackages)
        )
    }
}

private extension XcodeProjectParserLive {
    func targets(in project: XcodeProj) -> [XcodeProject.Target] {
        return project.pbxproj.nativeTargets.map { target in
            let packageProductDependencies = target.packageProductDependencies.map(\.productName)
            let dependencies = target.dependencies.compactMap({ $0.target?.uuid })
            // Name not product name
            let nativeTargets = project.pbxproj.nativeTargets.filter({ dependencies.contains($0.uuid) }).map({ $0.name })
            return .init(name: target.name, dependencies: nativeTargets, packageProductDependencies: packageProductDependencies)
        }
    }

    func remoteSwiftPackages(in project: XcodeProj) -> [XcodeProject.SwiftPackage] {
        struct IntermediateRemoteSwiftPackage {
            let name: String
            let repositoryURL: URL
            let products: [String]
        }
        var swiftPackages: [IntermediateRemoteSwiftPackage] = []
        for target in project.pbxproj.nativeTargets {
            for dependency in target.packageProductDependencies {
                guard let package = dependency.package, let packageName = package.name else {
                    continue
                }
                guard let rawRepositoryURL = package.repositoryURL, let repositoryURL = URL(string: rawRepositoryURL) else {
                    continue
                }
                if let existingSwiftPackageIndex = swiftPackages.firstIndex(where: { $0.name == packageName }) {
                    let existingSwiftPackage = swiftPackages[existingSwiftPackageIndex]
                    let newProducts = existingSwiftPackage.products + [dependency.productName]
                    let newSwiftPackage = IntermediateRemoteSwiftPackage(name: packageName, repositoryURL: repositoryURL, products: newProducts)
                    swiftPackages[existingSwiftPackageIndex] = newSwiftPackage
                } else {
                    let products = [dependency.productName]
                    let swiftPackage = IntermediateRemoteSwiftPackage(name: packageName, repositoryURL: repositoryURL, products: products)
                    swiftPackages.append(swiftPackage)
                }
            }
        }
        return swiftPackages.map { .remote(name: $0.name, repositoryURL: $0.repositoryURL, products: $0.products) }
    }

    func localSwiftPackages(in project: XcodeProj, atSourceRoot sourceRoot: URL) throws -> [XcodeProject.SwiftPackage] {
        return project.pbxproj.fileReferences.compactMap { fileReference in
            guard fileReference.isPotentialSwiftPackage else {
                return nil
            }
            guard let packageName = fileReference.potentialPackageName else {
                return nil
            }
            guard let packageSwiftFileURL = fileReference.potentialPackageSwiftFileURL(forSourceRoot: sourceRoot) else {
                return nil
            }
            guard fileSystem.fileExists(at: packageSwiftFileURL) else {
                return nil
            }
            return .local(.init(name: packageName, fileURL: packageSwiftFileURL))
        }
    }
}

private extension PBXFileReference {
    var isPotentialSwiftPackage: Bool {
        return lastKnownFileType == "folder" || lastKnownFileType == "wrapper"
    }

    var potentialPackageName: String? {
        return name ?? path
    }

    func potentialPackageSwiftFileURL(forSourceRoot sourceRoot: URL) -> URL? {
        guard let path = path else {
            return nil
        }
        return ((sourceRoot as NSURL).appendingPathComponent(path) as? NSURL)?.appendingPathComponent("Package.swift")
    }
}
