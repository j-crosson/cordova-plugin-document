//
//  DocVersion.swift
//
//  Created by jerry on 2/11/25.
//

enum Resolve {
    case current
    case version
}

struct DocumentVersions {

    private let docURL: URL
    private let versions: [NSFileVersion]
    let numberOfVersions: Int
    let isBin: Bool

    init( theDocument: PluginDocument?) throws {
        guard let theDocument else {
            throw CreateError.createError(ReturnStatus.doesntExist)
        }
        docURL = theDocument.fileURL
        isBin = theDocument.isBin
        guard NSFileVersion.currentVersionOfItem(at: docURL) != nil else {
            throw CreateError.createError(ReturnStatus.doesntExist)
        }

        let versn = NSFileVersion.unresolvedConflictVersionsOfItem(at: docURL)
        numberOfVersions = versn?.count ?? 0
        if numberOfVersions == 0 {
            throw CreateError.createError(ReturnStatus.noVersions)
        }
        versions = versn ?? []
     }

    func getURL(version: Int) -> URL? {
        if version >= numberOfVersions {
            return nil
        }
        return versions[version].url
    }

    func resolveConflict(resolutionType: Resolve, document: PluginDocument, version: Int = 0) -> Bool {
        guard  version < numberOfVersions  else {
            return false
        }

        if resolutionType == .current {
            do {
                try NSFileVersion.removeOtherVersionsOfItem(at: docURL)
            } catch {
                return false
            }
        } else {
            do {
                let selectedVersion =  versions[version]
                try selectedVersion.replaceItem(at: docURL,
                options: NSFileVersion.ReplacingOptions.byMoving)
                document.revert( toContentsOf: docURL)
                try NSFileVersion.removeOtherVersionsOfItem(at: docURL)

            } catch {
                return false
            }
        }
        if let versn = NSFileVersion.unresolvedConflictVersionsOfItem(at: docURL) {
            for version in versn {
                version.isResolved = true
            }
        }
        return true
    }
}
