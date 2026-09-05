import Foundation

public extension FileManager {
    func dirExist(at: String) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: at, isDirectory: &isDir), isDir.boolValue {
            return true
        }
        return false
    }

    func dirExist(at: URL) -> Bool {
        guard at.isFileURL else {
            return false
        }
        return dirExist(at: at.path)
    }

    func deleteDir(at path: String) -> Bool {
        guard dirExist(at: path) else {
            return false
        }

        do {
            try deleteDirContent(at: path)
            try removeItem(atPath: path)
            return true
        } catch _ {
            return false
        }
    }

    func fileExist(at path: String) -> Bool {
        var isDir: ObjCBool = false
        let exist = fileExists(atPath: path, isDirectory: &isDir)
        return exist && !isDir.boolValue
    }

    @discardableResult func deleteDirContent(at path: String) throws -> Int {
        guard dirExist(at: path) else {
            return 0
        }

        let directoryURL = URL(fileURLWithPath: path, isDirectory: true)
        let directoryValues = try directoryURL.resourceValues(forKeys: [.isSymbolicLinkKey])
        guard directoryValues.isSymbolicLink != true else {
            return 0
        }

        var nbDeleted = 0
        let contentOfDirs = try contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
        )
        for contentOfDir in contentOfDirs {
            let values = try contentOfDir.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            if values.isSymbolicLink == true {
                try removeItem(at: contentOfDir)
                nbDeleted += 1
            } else if values.isDirectory == true {
                nbDeleted += try deleteDirContent(at: contentOfDir.path)
                try removeItem(at: contentOfDir)
            } else {
                try removeItem(at: contentOfDir)
                nbDeleted += 1
            }
        }
        return nbDeleted
    }
}
