// PathKit - Effortless path operations

/// Represents a filesystem path.
public struct Path: PathProtocol {
    /// The underlying string representation
    public var path: String
    public static var fileSystemInfo: FileSystemInfo = DefaultFileSystemInfo()

    public init() {
        path = ""
    }
}
