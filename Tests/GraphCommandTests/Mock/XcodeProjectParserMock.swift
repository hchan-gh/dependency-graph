import Foundation
import XcodeProj
import XcodeProject
import XcodeProjectParser

struct XcodeProjectParserMock: XcodeProjectParser {
    func parseProject(at fileURL: URL, packagesURL: (URL) -> URL?, includeNativeTarget: ((PBXNativeTarget) -> Bool)?, includePackageProduct: ((XCSwiftPackageProductDependency) -> Bool)?) throws -> XcodeProject {
        return XcodeProject(name: "Example")
    }
}
