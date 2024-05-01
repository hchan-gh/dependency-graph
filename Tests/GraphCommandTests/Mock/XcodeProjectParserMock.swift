import Foundation
import XcodeProject
import XcodeProjectParser

struct XcodeProjectParserMock: XcodeProjectParser {
    func parseProject(at fileURL: URL, packagesURL: (URL) -> URL?) throws -> XcodeProject {
        return XcodeProject(name: "Example")
    }
}
