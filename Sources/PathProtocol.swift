//
//  PathProtocol.swift
//  Strings
//
//  Created by Jacob Williams on 7/3/17.
//

import Foundation

public protocol PathProtocol: ExpressibleByStringLiteral, ExpressibleByArrayLiteral, CustomStringConvertible, Hashable {
    static var fileSystemInfo: FileSystemInfo { get }
    var path: String { set get }
    var string: String { get }
    var url: URL { get }
    var exists: Bool { get }
    var isDirectory: Bool { get }
    var isFile: Bool { get }
    var isAbsolute: Bool { get }
    var isRelative: Bool { get }
    var absolute: Self { get }
    var normalized: Self { get }
    var abbreviated: Self { get }
    var lastComponent: String? { get }
    var deletingPathExtension: String { get }
    var lastComponentWithoutExtension: String? { get }
    var components: [String] { get }
    var `extension`: String? { get }
    init()
    init(_ path: String?)
    init<S: Collection>(components: S) where S.Iterator.Element == StringLiteralType
    mutating func normalize()
    func symlinkDestination() throws -> Self
}

extension PathProtocol {
    internal static var fileManager: FileManager { return FileManager.default }
    public var string: String {
        return path
    }
    public var url: URL {
        if isDirectory {
            return URL(fileURLWithPath: path, isDirectory: isDirectory)
        }
        return URL(fileURLWithPath: path)
    }
}

// MARK: Init
extension PathProtocol {
    /// Create a Path from a possibly null String object
    public init(_ path: String?) {
        if let p = path {
            self.init(p)
        } else {
            self.init("")
        }
    }

    /// Create a Path by joining multiple path components together
    public init<S: Collection>(components: S) where S.Iterator.Element == String {
        if components.isEmpty {
            self.init("")
        } else if components.first == Path.fileSystemInfo.pathSeparator && components.count > 1 {
            let p = components.joined(separator: Path.fileSystemInfo.pathSeparator)
            self.init(String(p[p.index(after: p.startIndex)...]))
        } else {
            self.init(components.joined(separator: Path.fileSystemInfo.pathSeparator))
        }
    }
}
// MARK: StringLiteralConvertible
extension PathProtocol {
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String

    public init(extendedGraphemeClusterLiteral path: String) {
        self.init(stringLiteral: path)
    }

    public init(unicodeScalarLiteral path: String) {
        self.init(stringLiteral: path)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: ArrayLiteralConvertible
extension PathProtocol {
    public typealias ArrayLiteralElement = String

    public init(arrayLiteral elements: String...) {
        self.init(components: elements)
    }
}

// MARK: CustomStringConvertible
extension PathProtocol {
    public var description: String {
        return path
    }
}

// MARK: Hashable
extension PathProtocol {
    public var hashValue: Int {
        return path.hashValue
    }
}


// MARK: Path Info

extension PathProtocol {
    /**
     Test whether a path is absolute.

     - Note: `true` if the path begins with a slash
     */
    public var isAbsolute: Bool {
        return path.hasPrefix(Self.fileSystemInfo.pathSeparator)
    }

    /**
     Test whether a path is relative.

     - Note: `true` if a path is relative (not absolute)
     */
    public var isRelative: Bool {
        return !isAbsolute
    }

    /**
     Concatenates relative paths to the current directory and derives the normalized path

     - Note: the absolute path in the actual filesystem
     */
    public var absolute: Self {
        // Normalization will expand tildes and replace .. with the parent directory and remove .
        guard !self.normalized.isAbsolute else { return self.normalized }

        return (Self.current + self.normalized).normalized
    }

    /**
     Normalizes the path, this cleans up redundant ".." and ".", double slashes
     and resolves "~".

     - Note: a new path made by removing extraneous path components from the underlying String
     representation.
     */
    public var normalized: Self {
        return Self(NSString(string: path).standardizingPath)
    }

    /**
     Normalizes the path, this cleans up redundant ".." and ".", double slashes
     and resolves "~".

     - Note: a new path made by removing extraneous path components from the underlying String
     representation.
     */
    public mutating func normalize() {
        path = normalized.path
    }

    /**
     De-normalizes the path, by replacing the current user home directory with "~".

     - Note: a new path made by removing extraneous path components from the underlying String
     representation.
     */
    public var abbreviated: Self {
        let rangeOptions: String.CompareOptions = Self.fileSystemInfo.isFSCaseSensitive(at: self) ?
            [.anchored] : [.anchored, .caseInsensitive]
        let home = Self.home.string
        guard let homeRange = path.range(of: home, options: rangeOptions) else { return self }
        let withoutHome = Self(path.replacingCharacters(in: homeRange, with: ""))

        if withoutHome.path.isEmpty || withoutHome.path == Self.fileSystemInfo.pathSeparator {
            return Self("~")
        } else if withoutHome.isAbsolute {
            return Self("~" + withoutHome.path)
        } else {
            return Self("~") + withoutHome.path
        }
    }
    /**
     The last path component

     - Note: the last path component
     */
    public var lastComponent: String? {
        return components.last
    }

    /**
     The last path component without file extension

     - Note: The last path component without file extension.
     This returns "." for "..".
     */
    public func deletingExtension(from path: String?) -> String? {
        return path?.deletingPathExtension
    }

    /**
     The last path component without file extension

     - Note: The last path component without file extension.
     This returns "." for "..".
     */
    public var lastComponentWithoutExtension: String? {
        return lastComponent?.deletingPathExtension
    }

    /**
     Splits the string representation on the directory separator.
     Absolute paths remain the leading slash as first component.

     - Note: all path components
     */
    public var components: [String] {
        var c: [String] = []
        if path.hasPrefix(Self.fileSystemInfo.pathSeparator) {
            c.append(Self.fileSystemInfo.pathSeparator)
        }
        c += path.components(separatedBy: Self.fileSystemInfo.pathSeparator)
        return c
    }

    /**
     The file extension behind the last dot of the last component.

     - Note: the file extension
     */
    public var `extension`: String? {
        let pathExtension = NSString(string: path).pathExtension
        guard !pathExtension.isEmpty else { return nil }

        return pathExtension
    }

    /**
     Returns the path of the item pointed to by a symbolic link.

     - Returns: the path of directory or file to which the symbolic link refers
     */
    public func symlinkDestination() throws -> Path {
        let symlinkDestination = try Path.fileManager.destinationOfSymbolicLink(atPath: path)
        let symlinkPath = Path(symlinkDestination)
        if symlinkPath.isRelative {
            return self + ".." + symlinkPath
        } else {
            return symlinkPath
        }
    }
}

extension String {
    public var deletingPathExtension: String {
        guard let match = self.range(of: "\\.[a-zA-Z0-9_-]+$", options: String.CompareOptions.regularExpression) else { return self }
        return String(self[..<match.lowerBound])
    }
}
