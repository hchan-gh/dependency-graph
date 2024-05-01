import Foundation
import XcodeProject

public protocol XcodeProjectParser {
    func parseProject(at fileURL: URL, packagesURL: (URL) -> URL?) throws -> XcodeProject
}
