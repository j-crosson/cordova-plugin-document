//
//  DocumentView.swift
//
//  Created by jerry on 12/21/24.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import MobileCoreServices
// private var documentObserver: NSObjectProtocol?
var docVersions: DocumentVersions?

@available(iOS 16.0, *)
private let systemDirs: [String: URL] = [
                                        // "applicationDirectory": .applicationDirectory,
                                        // "applicationSupportDirectory": .applicationSupportDirectory,
                                        "cachesDirectory": .cachesDirectory,
                                        // "desktopDirectory": .desktopDirectory,
                                        "documentsDirectory": .documentsDirectory,
                                        // "downloadsDirectory": .downloadsDirectory,
                                        // "homeDirectory": .homeDirectory,
                                         "libraryDirectory": .libraryDirectory,
                                        // "moviesDirectory": .moviesDirectory,
                                        // "musicDirectory": .musicDirectory,
                                        // "picturesDirectory": .picturesDirectory,
                                        // "sharedPublicDirectory": .sharedPublicDirectory,
                                        "temporaryDirectory": .temporaryDirectory
                                        // "trashDirectory": .trashDirectory,
                                        // "userDirectory": .userDirectory
                                        ]

enum PickerState {
    case notActive, fileSelection, directorySelection
}

enum DocumentType {
    static let primaryDocument: Int = 0
    static let otherVersionDoc: Int = 1
}

enum CreateError: Error {
    case createError(String)
}

private var pickerFile: String?
private var pickerBin: Bool = false
private var pickerCallBack: String = ""
private var createFileURL: URL?
private var pickerState = PickerState.notActive

extension CDVViewController: @retroactive UIDocumentPickerDelegate {
    // will handle the delegate differently in a future version

    //
    // create document "documentName" in "documentDiretory"
    //
    // if "documentDiretory" is nil or empty, current directory
    // if "documentName" is nil or empty, the default name "Untitled" is used
    // if the document already exists, there will be three options:
    // 1) fail
    // 2) open document
    // 3) modify name

    // some redundant stuff here, can be made more simple --partial rewrite, currently in mid transition

    struct CCreateOptions {
        private var openOptionSet = false

        var getDir = false
        var isBin = false
        var isCloud = false

        init( rawOptions raw: String) throws {
            if raw.contains(CreateOptions.overwrite) {
                openOptionSet = true
            }
            if raw.contains(CreateOptions.failIfExists) {
                if openOptionSet {
                    throw CreateError.createError(ReturnStatus.duplicate)
                }
            }
            if raw.contains(CreateOptions.iterate) {
                throw CreateError.createError(ReturnStatus.notImplimented)
            }
            if raw.contains(CreateOptions.getDir) {
                getDir = true
            }
            if raw.contains(CreateOptions.iCloudDocument) {
                isCloud = true
            }
            // not error checking for duplicates. isBin goes away future version
            if raw.contains(CreateOptions.bin) {
                isBin = true
            }
        }
    }

    func getSystemDirURL(directory: String, fileName: String?) -> URL? {
        if #available(iOS 16.0, *) {
            if let sysDir = systemDirs[directory] {
                guard let fileName  else {
                    return sysDir
                }
                let fileURL = sysDir.appending(path: fileName)
                return fileURL
            } else {
                return nil
            }
        } else {
            // pre iOS16, the default is the only valid option
            if directory != PluginDefaults.defaultDocumentDirectory {
                return nil
            }
            let documentsDirectory = try? FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false)

            guard let fileName  else {
                return documentsDirectory
            }
            return documentsDirectory?.appendingPathComponent(fileName)
        }
    }

    // dataTypeBin -- Currently supports bin (true) and utf8 (false). Will support other text types in future as dataType.

    func documentCreate(documentName: String?, createOptions: CCreateOptions, documentDirectory: String?, callBackIDAsync: String) {
        var fileName = PluginDefaults.defaultDocumentName
        fileName =? documentName

        var directory = PluginDefaults.defaultDocumentDirectory
        directory =? documentDirectory

        if createOptions.getDir {
            if pickerState != PickerState.notActive {
                docError(ReturnStatus.duplicate, callBackIDAsync: callBackIDAsync)
            }

            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
            picker.delegate = self
            pickerFile = fileName
            pickerBin = createOptions.isBin

            guard let dir = getSystemDirURL(directory: directory, fileName: nil) else {
                docError(ReturnStatus.badPath, callBackIDAsync: callBackIDAsync)
                return
                }
            picker.directoryURL = dir
            pickerState = PickerState.directorySelection
            pickerCallBack = callBackIDAsync
            present(picker, animated: true)
            return
        }

        if createOptions.isCloud {
            var fileURL: URL?
            // potentially slow process --  use "weak self"
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                if let driveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
                    fileURL = driveURL
                        .appendingPathComponent(fileName)
                }
                DispatchQueue.main.async {
                    if let fileURL {
                        self?.createDocument(fileURL: fileURL, isBin: createOptions.isBin, callBackIDAsync: callBackIDAsync)
                    } else {
                        self?.docError(ReturnStatus.badPath, callBackIDAsync: callBackIDAsync)
                    }
                }
            }
            return
        }

        if #available(iOS 16.0, *) {
            if let sysDir = systemDirs[directory] {
                let fileURL = sysDir
                    .appending(path: fileName)
                createDocument(fileURL: fileURL, isBin: createOptions.isBin, callBackIDAsync: callBackIDAsync)
            } else {
                docError(ReturnStatus.badPath, callBackIDAsync: callBackIDAsync)
            }
        } else {
            let documentsDirectory = try? FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false)

            if let fileURL = documentsDirectory?.appendingPathComponent(fileName) {
                createDocument(fileURL: fileURL, isBin: createOptions.isBin, callBackIDAsync: callBackIDAsync)
            } else {
                docError(ReturnStatus.badPath, callBackIDAsync: callBackIDAsync)
            }
        }
    }

    //
    // returns a DocumentStatus that the JavaScript side understands
    //

    func returnDocumentStatus(docNumber: Int, success: Bool, callbackId: String) {
        var docStat =  DocumentType.primaryDocument == docNumber ? ReturnStatus.currentDocument : ReturnStatus.conflictDocument
        guard plugInDocument.count > docNumber, plugInDocument[docNumber] != nil  else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: docStat + ReturnStatus.doesntExist)
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        docStat += plugInDocument[docNumber]!.getDocumentStatus() // guard checks existance

        let pluginResult =  CDVPluginResult( status: success ? CDVCommandStatus.ok : CDVCommandStatus.error, messageAs: docStat)
        commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    func createDocument(fileURL: URL, isBin: Bool, callBackIDAsync: String) {
        // if there is a current document, fail
        guard plugInDocument[DocumentType.primaryDocument] == nil else {
            docError(ReturnStatus.duplicate, callBackIDAsync: callBackIDAsync)
            return
        }

        plugInDocument[DocumentType.primaryDocument] = PluginDocument(fileURL: fileURL, cDelegate: commandDelegate)
        // won't fail but...
        guard let piDoc = plugInDocument[DocumentType.primaryDocument] else { return}
        piDoc.isBin = isBin
        piDoc.save(to: piDoc.fileURL, for: .forCreating) { [weak self] success in
            let pluginResult =  CDVPluginResult(status: success ? CDVCommandStatus.ok : CDVCommandStatus.error, messageAs: success ? "Create Succeeded" : ReturnStatus.savingError)
            self?.commandDelegate.send(pluginResult, callbackId: callBackIDAsync)
        }
    }

    func closeDocument(documentNumber: Int, callBackIDAsync: String) {
        guard plugInDocument[documentNumber] != nil else {
            docError(ReturnStatus.doesntExist, callBackIDAsync: callBackIDAsync)
            return
        }
        plugInDocument[documentNumber]?.close { [weak self] success in
            guard let self else { return }
            returnDocumentStatus(docNumber: documentNumber, success: success, callbackId: callBackIDAsync)
            if success {
                createFileURL?.stopAccessingSecurityScopedResource()
                createFileURL = nil
                // documentObserver = nil //only for primary
                plugInDocument[documentNumber] = nil
            }
        }
    }

    func openUbiquityContainerDocument(fileName: String, isBin: Bool, documentNumber: Int, callBackIDAsync: String) {
        var fileURL: URL?
        // potentially slow process --  use "weak self"
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            if let driveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
                fileURL = driveURL
                    .appendingPathComponent(fileName)
            }
            DispatchQueue.main.async {
                if let fileURL {
                    self?.openFile(fileURL: fileURL, isBin: isBin, documentNumber: 0, callBackIDAsync: callBackIDAsync)
                } else {
                    self?.docError(ReturnStatus.badPath, callBackIDAsync: callBackIDAsync)
                }
            }
        }
    }

    func openFile( fileURL: URL, isBin: Bool, documentNumber: Int, callBackIDAsync: String) {
        if documentNumber > plugInDocument.count {
            return
        }
        plugInDocument[documentNumber] = PluginDocument(fileURL: fileURL, cDelegate: commandDelegate)
        plugInDocument[documentNumber]?.isBin = isBin
        plugInDocument[documentNumber]?.open { [weak self]  success in
                guard let self else {
                              return
                          }
                if let theDocument = plugInDocument[documentNumber], success == true {
                    // documentObserver = NotificationCenter.default.addObserver(forName:
                    // UIDocument.stateChangedNotification, object: theDocument, queue: nil) { [weak self] _ in
                    // }

                    let pluginResult = theDocument.isBin ?
                    CDVPluginResult(status: CDVCommandStatus.ok, messageAsArrayBuffer: theDocument.binData) :
                    CDVPluginResult(status: CDVCommandStatus.ok, messageAs: theDocument.text)
                    commandDelegate.send(pluginResult, callbackId: callBackIDAsync)
                } else {
                    var docStat = ReturnStatus.doesntExist
                    docStat.append(documentNumber == DocumentType.primaryDocument ? ReturnStatus.currentDocument : ReturnStatus.conflictDocument)
                    if let theDocument = plugInDocument[documentNumber] {
                        docStat = theDocument.getDocumentStatus()
                    }
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: docStat)
                    commandDelegate.send(pluginResult, callbackId: callBackIDAsync)
                    plugInDocument[documentNumber] = nil // open failed, no document
                    }
            }
    }

    func openDocument(UTIs: [String], extensions: [String], documentDirectory: String?, isBin: Bool, callBackIDAsync: String) {
        var pickTypes: [UTType] = []
        pickTypes = UTIs.compactMap(UTType.init)

        for extention in extensions {
            if let uType = UTType(filenameExtension: extention) {
                pickTypes.append(uType)
            }
        }

        // default if needed
        if pickTypes.isEmpty {
            pickTypes.append(.text)
        }

        if pickerState != PickerState.notActive {
            docError(ReturnStatus.duplicate, callBackIDAsync: callBackIDAsync)
            return
        }

            let picker = UIDocumentPickerViewController(forOpeningContentTypes: pickTypes)
            picker.delegate = self
            // there is no default directory.   Empty directory string or missing directory, current directory used
        if let directory = documentDirectory, directory != "" {
            guard let dir = getSystemDirURL(directory: directory, fileName: nil) else {
                docError(ReturnStatus.badPath, callBackIDAsync: callBackIDAsync)
                return
            }
            picker.directoryURL = dir
        }
    pickerBin = isBin
    pickerState = PickerState.fileSelection
    pickerCallBack = callBackIDAsync
    present(picker, animated: true)
    }

        func saveDocument(_ theDocument: PluginDocument, callBackIDAsync: String) {
            // we want a "normal" status, not in conflict
            // some of these tests are redundant, but...
            if theDocument.documentState.contains(.inConflict) || theDocument.documentState.contains(.closed) || theDocument.documentState.contains(.progressAvailable) || !theDocument.documentState.contains(.normal) {
                docError(theDocument.getDocumentStatus(), callBackIDAsync: callBackIDAsync)
                return
            }

            theDocument.save(to: theDocument.fileURL, for: .forOverwriting, completionHandler: {[weak self] ( success: Bool) in
                guard let self else {
                    return
                }
                returnDocumentStatus(docNumber: 0, success: success, callbackId: callBackIDAsync)
            })
        }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let state = pickerState
        pickerState = PickerState.notActive
        if  state == PickerState.fileSelection {
            guard let selectedFileURL = urls.first else {
                docError(ReturnStatus.unexpectedError, callBackIDAsync: pickerCallBack)
                return
            }
            openFile(fileURL: selectedFileURL, isBin: pickerBin, documentNumber: 0, callBackIDAsync: pickerCallBack)
        } else if state == PickerState.directorySelection {
            createFileURL = urls.first
            guard createFileURL != nil, pickerFile != nil else {
                docError(ReturnStatus.unexpectedError, callBackIDAsync: pickerCallBack)
                return
            }
            guard createFileURL!.startAccessingSecurityScopedResource() else {
                docError(ReturnStatus.unexpectedError, callBackIDAsync: pickerCallBack)
                return
            }
            let fileURL = createFileURL!.appendingPathComponent(pickerFile!) // let fileURL = createFileURL!.appending(path: file)  iOS16
            createDocument(fileURL: fileURL, isBin: pickerBin, callBackIDAsync: pickerCallBack)
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pickerState = PickerState.notActive
        docError(ReturnStatus.userCancelled, callBackIDAsync: pickerCallBack)
        }

    func docError(_ errorString: String, callBackIDAsync: String) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: errorString)
        commandDelegate.send(pluginResult, callbackId: callBackIDAsync)
    }
}
