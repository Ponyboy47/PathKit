//
//  FileSystemInfo.swift
//  Strings
//
//  Created by Jacob Williams on 7/4/17.
//

public protocol FileSystemInfo {
    /// The character used by the OS to separate two path elements
    var pathSeparator: String { get }
    func isFSCaseSensitive<P: PathProtocol>(at path: P) -> Bool
}

internal struct DefaultFileSystemInfo: FileSystemInfo {
    let pathSeparator: String = "/"
    func isFSCaseSensitive<P: PathProtocol>(at path: P) -> Bool {
        #if os(Linux)
            // URL resourceValues(forKeys:) is not supported on non-darwin platforms...
            // But we can (fairly?) safely assume for now that the Linux FS is case sensitive.
            // TODO: refactor when/if resourceValues is available, or look into using something
            // like stat or pathconf to determine if the mountpoint is case sensitive.
            return true
        #else
            var isCaseSensitive = false
            // Calling resourceValues will fail if the path does not exist on the filesystem, which
            // makes sense, but means we can only guarantee the return value is correct if the
            // path actually exists.
            if let resourceValues = try? path.url.resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey]) {
                isCaseSensitive = resourceValues.volumeSupportsCaseSensitiveNames ?? isCaseSensitive
            }
            return isCaseSensitive
        #endif
    }
}
