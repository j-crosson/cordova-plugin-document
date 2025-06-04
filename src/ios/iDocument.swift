//
// iDocument.swift
//
//  Created by jerry on 12/13/24.
//

import Foundation
import UIKit
import WebKit
import UniformTypeIdentifiers

enum PluginDefaults {
    static let defaultDocumentName: String = "untitled.txt"
    static let defaultDocumentDirectory: String = "documentsDirectory"
}

let resolver: [String: Resolve] = ["current": .current, "version": .version]

var plugInDocument: [PluginDocument?] = [nil, nil]

@objc public class iDocument: CDVPlugin {

    func commandError(_ command: CDVInvokedUrlCommand, _ errorString: String) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: errorString)
        commandDelegate?.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(documentAction:)
    func documentAction(command: CDVInvokedUrlCommand) {
        guard command.arguments.count > 0, let gAction  = command.arguments[0] as? String else {
            commandError(command, ReturnStatus.badCommand)
            return
        }
        switch gAction {
        case "create":
            var documentDirectory: String?
            var options: CDVViewController.CCreateOptions
            var fileName: String?

            // default options.
            do {
                options = try CDVViewController.CCreateOptions(rawOptions: "")
            } catch CreateError.createError(let errorString) {
                    commandError(command, errorString)
                    return
            } catch {
                commandError(command, ReturnStatus.unexpectedError)
                    return
                }

            switch command.arguments.count {
                case 4:
                documentDirectory = command.arguments[4] as? String
                    if documentDirectory == nil {
                        commandError(command, ReturnStatus.badDirectoryArg)
                        return
                    }
                    fallthrough
                case 3:
                    if let optionsString = command.arguments[2] as? String {
                        do {
                            options = try CDVViewController.CCreateOptions(rawOptions: optionsString)
                        } catch CreateError.createError(let errorString) {
                            commandError(command, errorString)
                            return
                        } catch {
                            commandError(command, ReturnStatus.unexpectedError)
                            return
                        }
                    } else {
                        commandError(command, ReturnStatus.badOptions)
                        return
                    }
                    fallthrough
                case 2:
                    fileName  = command.arguments[1] as? String
                    if fileName == nil {
                        commandError(command, ReturnStatus.badFilename)
                    }
                case 1:
                    fileName = PluginDefaults.defaultDocumentName
                default:
                    commandError(command, ReturnStatus.badArguments)
                    return
                }

            viewController.documentCreate(documentName: fileName, createOptions: options, documentDirectory: documentDirectory, callBackIDAsync: command.callbackId)

            case  "selectDocument":
                var isBin: Bool = false
                var extensions: [String] = []
                var UTIs: [String] = []
                var documentDirectory: String?

                switch command.arguments.count {
                case 5:
                    guard let bin = command.arguments[4] as? Bool else {
                        commandError(command, ReturnStatus.badBinArg)
                        return
                    }
                    isBin = bin
                    fallthrough
                case 4:
                    guard let ext = command.arguments[3] as? [String] else {
                        commandError(command, ReturnStatus.badExtensionsArg)
                        return
                    }
                    extensions = ext
                    fallthrough
                case 3:
                    guard let UTIsC = command.arguments[2] as? [String] else {
                        commandError(command, ReturnStatus.badUTIArg)
                        return
                    }
                    UTIs = UTIsC
                    fallthrough
                case 2:
                    documentDirectory = command.arguments[1] as? String
                    if documentDirectory == nil {
                        commandError(command, ReturnStatus.badDirectoryArg)
                        return
                    }
                    fallthrough
                case 1:
                    break
                default:
                    commandError(command, ReturnStatus.badArguments)
                    return
                }

                viewController.openDocument(UTIs: UTIs, extensions: extensions, documentDirectory: documentDirectory, isBin: isBin, callBackIDAsync: command.callbackId)

            case "openDocument":
                var documentDirectory = PluginDefaults.defaultDocumentDirectory
                var isBin: Bool = false
                var fileName: String

                switch command.arguments.count {

                case 4:
                    guard let bin = command.arguments[3] as? Bool else {
                        commandError(command, ReturnStatus.badBinArg)
                        return
                    }
                    isBin = bin
                    fallthrough
                case 3:
                    guard let docDir = command.arguments[2] as? String else {
                        commandError(command, ReturnStatus.badDirectoryArg)
                        return
                    }
                    documentDirectory = docDir
                    fallthrough
                case 2:
                    guard let name = command.arguments[1] as? String else {
                        commandError(command, ReturnStatus.badFilename)
                        return
                    }
                    fileName = name
                default:
                    commandError(command, ReturnStatus.badArguments)
                    return
                }

            if documentDirectory == "iCloud" {
                viewController.openUbiquityContainerDocument(fileName: fileName, isBin: isBin, documentNumber: 0, callBackIDAsync: command.callbackId)
             return
            }

                guard let openURL =  viewController.getSystemDirURL(directory: documentDirectory, fileName: fileName) else {
                    commandError(command, ReturnStatus.badPath)
                    return
                }
                viewController.openFile(fileURL: openURL, isBin: isBin, documentNumber: DocumentType.primaryDocument, callBackIDAsync: command.callbackId)

            case "save":
            if let theDocument = plugInDocument[DocumentType.primaryDocument] { // other than primary document is read-only
                    if theDocument.isBin {
                        theDocument.binData = command.arguments[1] as? Data ?? Data()
                    } else {
                        if let gData  = command.arguments[1] as? String {
                            theDocument.text = gData
                        } else {
                            commandError(command, ReturnStatus.badArguments)
                            return
                        }
                    }
                    viewController.saveDocument(theDocument, callBackIDAsync: command.callbackId)

                } else {
                    commandError(command, ReturnStatus.doesntExist)
                }

            case "close":
                var docNum: Int = DocumentType.primaryDocument
                switch command.arguments.count {
                case 2:
                    guard let doc = command.arguments[1] as? Int, doc  < 2 else {
                        commandError(command, ReturnStatus.badArguments)
                        return
                    }
                    docNum = doc
                default:
                    docNum = DocumentType.primaryDocument
                }
            viewController.closeDocument(documentNumber: docNum, callBackIDAsync: command.callbackId)

            case "getStatus":
                var docNum: Int = DocumentType.primaryDocument
                switch command.arguments.count {
                case 2: // replace 2 with array size
                    guard let doc = command.arguments[1] as? Int, doc  < 2 else {
                        commandError(command, ReturnStatus.badArguments)
                        return
                    }
                    docNum = doc
                default:
                    docNum = DocumentType.primaryDocument
                }
            viewController.returnDocumentStatus(docNumber: docNum, success: true, callbackId: command.callbackId)

            case "getOtherVersions":

                do {
                    docVersions =  try DocumentVersions(theDocument: plugInDocument[DocumentType.primaryDocument])
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: docVersions?.numberOfVersions ?? 0)
                    commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return

                } catch CreateError.createError(let errorString) {
                    commandError(command, errorString)
                    return
                } catch {
                    commandError(command, ReturnStatus.unexpectedError)
                    return
                }

            case "openOther":

                switch command.arguments.count {
                case 2:
                    guard let docVersions else {
                        commandError(command, ReturnStatus.noVersions)
                        return
                    }

                    guard let doc = command.arguments[1] as? Int, doc  < docVersions.numberOfVersions, let otherURLString = docVersions.getURL(version: doc)  else {
                        commandError(command, ReturnStatus.badArguments)
                        return
                    }

                    viewController.openFile(fileURL: otherURLString, isBin: docVersions.isBin, documentNumber: DocumentType.otherVersionDoc, callBackIDAsync: command.callbackId)

                default:
                    commandError(command, ReturnStatus.badArguments)
                    return
                }
            case "resolve":
                if docVersions == nil {
                    commandError(command, ReturnStatus.doesntExist)
                    return
                }
                guard command.arguments.count > 1, let res = command.arguments[1] as? String, let resolution = resolver[res] else {
                    commandError(command, ReturnStatus.badArguments)
                    return
                }
                // optional second argument
                var version: Int = 0
                if command.arguments.count > 2 {
                    guard let versionArg = command.arguments[2] as? Int else {
                        commandError(command, ReturnStatus.badArguments)
                        return
                    }
                    version = versionArg
                }

            if let theDocument = plugInDocument[DocumentType.primaryDocument] {
                if let conflictResolved = docVersions?.resolveConflict(resolutionType: resolution, document: theDocument, version: version) {
                    if !conflictResolved {
                        commandError(command, ReturnStatus.unexpectedError)
                        return
                        }
                    }
                } else {
                    commandError(command, ReturnStatus.doesntExist)
                    return
                }
                docVersions = nil
            viewController.returnDocumentStatus(docNumber: DocumentType.primaryDocument, success: true, callbackId: command.callbackId)

            case "getData":
            guard command.arguments.count > 1, let doc = command.arguments[1] as? Int, doc < plugInDocument.count else {
                    commandError(command, ReturnStatus.badArguments)
                    return
                }
                if let theDocument = plugInDocument[doc] {
                    if theDocument.isBin {
                        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAsArrayBuffer: theDocument.binData)
                        commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                    } else {
                        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: theDocument.text)
                        commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                    }
                } else {
                    commandError(command, ReturnStatus.doesntExist)
                }

            default:
                commandError(command, ReturnStatus.badCommand)
                return
            }
        }
    }

// --------  =? operator --------------
precedencegroup ConditionalAssignmentPrecedence {
    associativity: left
    assignment: true
    higherThan: AssignmentPrecedence
}

infix operator =?: ConditionalAssignmentPrecedence
// Set value of left-hand side only if right-hand side differs from `nil`
public func =? <T>(variable: inout T, value: T?) {
    if let val = value {
        variable = val
    }
}

/*
 let utiTypes = [UTType.image, .text, .plainText, .pdf,.epub,.rtf,.xml,.json, .movie, .video, .mp3, .audio, .quickTimeMovie, .mpeg, .mpeg2Video, .mpeg2TransportStream, .mpeg4Movie, .mpeg4Audio, .appleProtectedMPEG4Audio, .appleProtectedMPEG4Video, .avi, .aiff, .wav, .midi, .livePhoto, .tiff, .gif, UTType("com.apple.quicktime-image"), .icns]
 
 print(utiTypes.flatMap { $0?.tags[.filenameExtension] ?? [] })
 */
