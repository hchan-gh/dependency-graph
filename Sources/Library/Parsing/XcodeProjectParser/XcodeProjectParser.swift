import Foundation
import XcodeProj
import XcodeProject

public protocol XcodeProjectParser {
    func parseProject(at fileURL: URL, packagesURL: (URL) -> URL?, includeNativeTarget: ((PBXNativeTarget) -> Bool)?, includePackageProduct: ((XCSwiftPackageProductDependency) -> Bool)?) throws -> XcodeProject
}
