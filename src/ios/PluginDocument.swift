//
//  PluginDocument.swift
//
//  Created by jerry on 4/10/23.
//

// for now we only support utf8 text and binary data.

import Foundation

enum CreateOptions {
    static let overwrite: String = "0"
    static let failIfExists: String = "1"
    static let iterate: String = "2"
    static let getDir: String = "3"
    static let utf8: String = "4"
    static let bin: String = "5"
    static let iCloudDocument: String = "6"
}
// Additional creation options: fail on existing file, create "file1" if "file" exists

// status that javascript side understands

enum ReturnStatus {
    static let normal: String = "0"
    static let closed: String = "1"
    static let inConflict: String = "2"
    static let savingError: String = "3"
    static let editingDisabled: String = "4"
    static let progressAvailable: String = "5"
    static let currentDocument: String = "a"
    static let conflictDocument: String = "b"
    static let typeBin: String = "c"
    static let typeUTF8: String = "d"
    static let userCancelled: String = "l"
    static let duplicate: String = "m"
    static let notImplimented: String = "n"
    static let badOptions: String = "o"
    static let badExtensionsArg: String = "p"
    static let badUTIArg: String = "q"
    static let badCommand: String = "r"
    static let badDirectoryArg: String = "s"
    static let badBinArg: String = "t"
    static let unexpectedError: String = "u"
    static let badPath: String = "v"
    static let badFilename: String = "w"
    static let doesntExist: String = "x"
    static let badArguments: String = "y"
    static let noVersions: String = "z"
}

/*
enum DocDataType {
 static let utf8: String = "0"
 static let bin: String = "1"
}
*/

class PluginDocument: UIDocument {
    var text = String()
    var binData =  Data()
    var willSaveHandler: (() -> String)?
    var isBin = false
    private let commandDelegate: CDVCommandDelegate
    private var initialLoad = true

    init (fileURL: URL, cDelegate: CDVCommandDelegate) {
        commandDelegate = cDelegate
        super.init(fileURL: fileURL)
    }

    // status for javascript
    func getDocumentStatus() -> String {
        var docStates = ""
        if documentState.contains(.normal) {
            docStates.append(ReturnStatus.normal)
        }
        if documentState.contains(.closed) {
            docStates.append(ReturnStatus.closed)
        }
        if documentState.contains(.inConflict) {
            docStates.append(ReturnStatus.inConflict)
        }
        if documentState.contains(.savingError) {
            docStates.append(ReturnStatus.savingError)
        }
        if documentState.contains(.editingDisabled) {
            docStates.append(ReturnStatus.editingDisabled)
        }
        if documentState.contains(.progressAvailable) {
            docStates.append(ReturnStatus.progressAvailable)
        }
        return docStates
    }

//    override func presentedItemDidChange() {
//    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if isBin {
            if let contents = contents as? Data {
                binData = contents
            }
        } else if let contents = contents as? Data, let textFromData = String(data: contents, encoding: .utf8) {
            text = textFromData
        }

        // don't want notification of initial load but
        // do want to know if externally updated
        if initialLoad {
            initialLoad = false } else {
                var status = isBin ? ReturnStatus.typeBin : ReturnStatus.typeUTF8
                status += getDocumentStatus()
                // this doesn't seem to be necessary but will keep until sure
                DispatchQueue.main.async {
                    self.commandDelegate.evalJs( "iDocument.onLoaded('\(status)');")
                }
            }
    }

    override func contents(forType typeName: String) throws -> Any {
        if isBin {
            return binData
        }
        if let data = text.data(using: .utf8) {
            return data
        }
        return Data()
    }
}
