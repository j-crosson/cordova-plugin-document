
var exec = require('cordova/exec');

var PLUGIN_NAME = 'iDocument';

var iDocument = function() {};


iDocument.prototype.documentAction = function ( action, success = null, fail = null, args = []) {
    exec(success, fail, 'iDocument', 'documentAction',  [action,...args]);
    };

iDocument.prototype.onLoaded = function(results){
            this.loaded(results);
    };

iDocument.prototype.createOptions = {
    overwrite:    "0",
    failIfExists:    "1",
    iterate:  "2",
    getDir: "3",
    utf8: "4",
    bin: "5",
    iCloud: "6"
    };

iDocument.prototype.documentID = {
        primary:    0,
        otherDocument:    1
        };

iDocument.prototype.returnStatus = {
    normal:  "0",
    closed:  "1",
    inConflict:  "2",
    savingError: "3",
    editingDisabled: "4",
    progressAvailable:  "5",
    primaryDocument:  "a",
    conflictDocument:  "b",
    typeBin:        "c",
    typeUTF8:       "d",
    userCancelled:  "l",
    duplicate:  "m",
    notImplimented:  "n",
    badOptions:  "o",
    badExtensionsArg:  "p",
    badUTIArg:  "q",
    badCommand:  "r",
    badDirectoryArg:  "s",
    badBinArg:  "t",
    unexpectedError:  "u",
    badPath:  "v",
    badFilename:  "w",
    doesntExist:  "x",
    badArguments:  "y",
    noVersions:  "z"
    };

module.exports = new iDocument();

