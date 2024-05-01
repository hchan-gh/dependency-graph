import Foundation

extension XcodeProject {
    public struct Target: Equatable {
        public let name: String
        public let dependencies: [String]
        public let packageProductDependencies: [String]

        public init(name: String, dependencies: [String], packageProductDependencies: [String] = []) {
            self.name = name
            self.dependencies = dependencies
            self.packageProductDependencies = packageProductDependencies
        }
    }
}
