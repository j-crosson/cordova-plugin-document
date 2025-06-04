# cordova-plugin-Document

* Create, read, and write text and binary documents--locally and outside the app's sandbox--including iCloud documents as well as documents shared by other apps. 

* Resolve iCloud and shared document conflicts caused by other apps or devices updating shared documents.

Document URLs can be specified programmatically--in system directories or ubiquity containers--or documents can be selected by a Document Picker. Documents can be created in a Document-Picker-selected directory.
     
Creating/reading/writing local unshared documents is relatively simple, but handling Cloud documents and documents shared between apps can be much more complex because there can be conflicts which must be resolved. Also, suspended app's shared documents can get out of sync. 

If a shared document is treated as read-only, the only additional consideration is handling the "document-updated" notification. 

If all you want to do is read a file selected by a Document Picker, other plugins do this more easily in a cross-platform way.  

Minimum supported Deployment Target is iOS14.  iOS16 is required to support all features. 

## What’s Ahead

* Bookmarks
* Additional creation options


## Installation
```bash
cordova plugin add cordova-plugin-document
```

## Getting Started

The best way is to build the Demo App. This app demonstrates the following:

* Programmatic creation of text and binary documents in the Documents Directory.
* Programmatic creation of an iCloud text document.
* Document creation in a directory user-selected via the Document Picker.
* Opening Documents programmatically and via the Document Picker.
* Editing text and binary documents.
* Resolving iCloud Document Conflicts.  


 - https://github.com/j-crosson/cordova-document-demo


## Example

```javascript
//creates 'untitled.txt' in 'Documents' directory
iDocument.documentAction ('create', docCreated, operationFailed,['untitled.txt'])}; 

 // save text
function docCreated() {
    let text = "this is text";
    iDocument.documentAction("save",docSaved,saveFailed,[text]);
}

// close document
function docSaved() {
    iDocument.documentAction ("close",operationComplete, closeFailed);
}

```



## documentAction
```javascript
iDocument.documentAction(action,success,error,arguments[])
```

Perform Document Action such as creating, reading, and writing documents.


| Parameter | Type | Description | Default |
| --- | --- | --- |--- |
| action | String |  action  to perform | |
| success | Function | Success callback function| null |
| error | Function | Error callback | null|
| arguments | [String] |  action  data | [""]|



###actions:


***
**create** 
***
Create Document

Creates a document.  Either supply a directory and filename or let user choose a directory.  Directory choices that are not user selected are limited to system directories. Creates 'untitled.txt' in the "Documents" directory if no arguments supplied.  


| arguments | Type | Description | Default |
| --- | --- | --- |--- |
| filename | String |  file name and extension |untitled.txt |
| createOptions | createOptions |  action  to perform | overwrite + utf8 |
| documentDirectory | String |  file's system directory | "documentsDirectory"|


### filename

Name and extension of file to be created.  The extension can be whatever you like but the plugin uses Uniform Type Identifiers (UTIs) or extensions that Apple recognizes. 

### createOptions

File creation options.

**iDocument.createOptions:**

| option | Description |
| --- | --- |
| overwrite | overwrite file if it exists |
| utf8 |  utf8 text file |
| bin |  binary file |
| getDir | user supplies directory |

  
  ```javascript
const options  = iDocument.createOptions.utf8 + iDocument.createOptions.overwrite;
// this is the default 
```

For now, overwrite is the only write option, utf8 is the only text option.  These are the defaults. 


### documentDirectory

System directory in which file is created.  

Supported directories:

* "documentsDirectory"
* "temporaryDirectory"
* "cachesDirectory"
* "libraryDirectory"


Apple documentation explains the use and behavior of these directories.  If it is desired to use other system directories, "systemDirs" in DocumentView.swift has a selection of system directories most of which are commented out and can be reactivated.  Some are Mac-only, some work, some don't.
 
If an app's Deployment Target is less tham iOS 16,  "documentsDirectory" is the only option. 


Cloud Directory

* "iCloud"


The only way this plugin can programmatically create a file on iCloud is to specify "iCloud" for "documentDirectory". This will create the file "filename" in the "Documents" directory of the default Ubiquity Container.  


### success

Document Creation succeeded callback.

Returns "Succeeded" status which can be safely ignored since it contains no additional info.

### error

Document Creation failed callback.

Returns:

* returnStatus.savingError  -- document save failed
* returnStatus.badPath -- path was bad
* returnStatus.duplicate -- there is another document open
* returnStatus.badArguments -- couldn't parse arguments
* returnStatus.badFilename -- bad file name
* returnStatus.badOptions -- options argument was bad
* returnStatus.badDirectoryArg --  bad directory
* returnStatus.unexpectedError -- unknown error
* returnStatus.userCancelled -- user cancelled directory picker

  ```javascript
//creates 'untitled.txt' in 'Documents' directory
iDocument.documentAction ('create', docCreated, operationFailed)};  

//creates 'untitled.txt' in 'Documents' directory
iDocument.documentAction ('create', docCreated, operationFailed,['untitled.txt'])}; 
  
//creates 'untitled.txt' in 'Documents' directory
iDocument.documentAction ('create', docCreated, operationFailed,['untitled.txt',iDocument.createOptions.overwrite,'documentsDirectory'])};
   
//creates 'untitled.txt' in user-selected directory
iDocument.documentAction ('create', docCreated, operationFailed,['untitled.txt',iDocument.createOptions.getDir])};

function operationFailed(status) {
    if(status.includes(iDocument.returnStatus.userCancelled)) {
    // user changed mind
    }
}


```
***            
**openDocument**
***

Open document for read/write. 

 
| arguments | Type | Description | Default |
| --- | --- | --- |--- |
| filename | String |  file name and extension |untitled.txt |
| documentDirectory | String |  file's system directory | "documentsDirectory"|
| isBinary | Bool |  is file binary | False|


### filename

Name and extension of file to be opened. 
 
### documentDirectory

System directory in which file exists.  

 Supported directories:

* "documentsDirectory"
* "temporaryDirectory"
* "cachesDirectory"
* "libraryDirectory"
* "iCloud"

See "create" for additional "documentDirectory" info.
 
 ### isBinary
 
 If "True" file will be treated as binary.
 
 
 ### success
 
 Document Open succeeded callback.
 
 Returns text or binary document data.  
 
 ```javascript 
// text data
 function textDocOpened(text) {
    console.log(text);
}

// binary data
  function binDocOpened(bin) {
    let bytes = new Uint8Array(bin);
  }
```
 
  ### error
  
  Returns:
  
* returnStatus.doesntExist -- file doesn't exist  
* returnStatus.badArguments -- couldn't parse arguments
* returnStatus.badFilename -- bad file name
* returnStatus.badDirectoryArg --  bad directory
* returnStatus.badPath -- path was bad
* returnStatus.badBinArg -- isBinary argument is bad
 
 
```javascript 
// opens 'untitled.txt' in 'Documents' directory
iDocument.documentAction("openDocument",docOpened,openFailed,["untitled.txt","documentsDirectory"]);

// opens 'untitled.bin' as binary file in 'Documents' directory
iDocument.documentAction("openDocument",binDocOpened,openFailed,["untitled.bin","documentsDirectory",true]);

function openFailed(status) {
    if(status.includes(iDocument.returnStatus.doesntExist)) {
    // file not found
    }
}


``` 
 ***  
 **selectDocument**
 ***  
 
 Opens user-selected document for read/write.
 
 
| arguments | Type | Description | Default |
| --- | --- | --- |--- |
| documentDirectory | String |  initial directory | |
| UTIs | [String] |  document types to open by Uniform Type Identifier | [public.plain-text]|
| extensions | [String] |  document types to open by extension | [txt]|
| isBinary | Bool |  is file binary | False|

 
 
### documentDirectory

The directory initially displayed by the document picker.  If null or an empty string then the picker will show what iOS considers to be the current directory. 

 Supported directories:

* "documentsDirectory"
* "temporaryDirectory"
* "cachesDirectory"
* "libraryDirectory"


See "create" for additional "documentDirectory" info.
 
### isBinary
 
If "True" file will be treated as binary.

### UTIs

An array of UTIs that the document picker can open (public.plain-text, public.rtf, etc.) The default is "public.plain-text"

### extensions

An array of extensions that the document picker can open (txt, jpg, etc.) The default is "txt".  The extensions must be recognized by iOS. 

 
UTIs and extensions can be used simultaneously but it is a good idea to use one or the other.

 ### success
 
 Document Select succeeded callback.
 
 Returns text or binary document data.  
 
 ```javascript 
// text data
 function textDocOpened(text) {
    console.log(text);
}

// binary data
  function binDocOpened(bin) {
    let bytes = new Uint8Array(bin);
  }
```
 
### error
  
Document Select failed callback.

Returns:
         
* returnStatus.userCancelled -- user cancelled directory picker    
* returnStatus.badExtensionsArg -- extensions argument is bad
* returnStatus.badUTIArg -- UTIs argument is bad
* returnStatus.badArguments -- couldn't parse arguments
* returnStatus.badDirectoryArg --  bad directory
* returnStatus.badPath -- path was bad
* returnStatus.badBinArg -- isBinary argument is bad
* returnStatus.unexpectedError -- unexpected error


```javascript 

//both lines select text documents

iDocument.documentAction("selectDocument",textDocOpened,selectFailed,["documentsDirectory",[],["txt"]]);

iDocument.documentAction("selectDocument",textDocOpened,selectFailed,["documentsDirectory",["public.plain-text"],[]]);

function selectFailed(status) {
    if(status.includes(iDocument.returnStatus.userCancelled)) {
    // user cancelled picker
    }
}


```
***
**save** 
***

Save document.

Will only save main document.  Documents opened for conflict resolution are read only.

| arguments | Type | Description | 
| --- | --- | --- |
| data | Data |  saved data |


### data

Saved data

### success
 
 Document Save succeeded callback.
 
 Returns status:
 
* returnStatus.normal -- normal state, always present
* returnStatus.currentDocument -- always present, can only save current document

### error
  
    Document Save failed callback.

  
Returns:
  
* returnStatus.doesntExist -- document doesn't exist  
* returnStatus.savingError -- iOS returned saving error
* returnStatus.closed -- document closed
* returnStatus.inConflict -- conflict exists
* returnStatus.badArguments -- couldn't parse arguments
* returnStatus.normal -- normal status but there was an additional disqualifing status
* returnStatus.progressAvailable --  update in progress
* returnStatus.editingDisabled  --  editing disabled, update in progress
 
For a local document the "closed" status means the document is closed, however, for a cloud document the status could be a link in the document update chain, a temporary status that will eventually resolve to "normal".  In the cloud "closed" case (and in the case of other non-"normal" statuses) the document is being updated externally and the "save" can be aborted and handled when the "update" (iDocument.loaded) notification is recieved.                         
 The plugin will not allow a cloud document that is in conflict to be saved.  If the only status that is preventing a save is "inConflict" (not closed but "inConflict" and "normal"), the conflict must be resolved before a save is allowed. An additional status such as "editingDisabled" indicates that an update is in progress and an "update" notification will be recieved upon completion of the update.                      


                         
 ```javascript 
 //text
    let text = "this is text";
    iDocument.documentAction("save",docSaved,saveFailed,[text]);

// binary data "00,01,02,FF"
    let arr8 = new Uint8Array([0, 1, 2, 255]);
    iDocument.documentAction("save",docSaved,  saveFailed, [arr8.buffer]);
```

***
**close**   
***

Close document.

Typically there will not be a document ID supplied unless working with conflict documents. 

| arguments | Type | Description | Default |
| --- | --- | --- |--- |
| ID | documentID |  document to close | documentID.primary|


documentID:

| ID | Description |
| --- | --- |
| primary | primary document |
| otherDocument |  iCloud conflict document |

 
 
### success
 
 Close document succeeded callback.
 
 Returns:
 
* returnStatus.closed -- document is closed
* returnStatus.currentDocument  || returnStatus.conflictDocument-- ID of closed document
* returnStatus.inConflict -- if closed document was in conflict
 
 
### error
  
 Close document failed callback.

  
Returns:
  
* returnStatus.doesntExist -- document doesn't exist  
* returnStatus.badArguments -- couldn't parse arguments
 
  ```javascript 
  //typical document close
    iDocument.documentAction ("close",docClosed, operationFailed);

 //close conflict resolution document
    iDocument.documentAction ("close",docClosed, operationFailed,[iDocument.documentID.otherDocument]);

```

***
**getStatus**   
***

Returns document status.

Typically there will not be a document ID supplied.  

| arguments | Type | Description | Default |
| --- | --- | --- |--- |
|  ID  | documentID |  status document | documentID.primary|


**iDocument.documentID:**


| ID | Description |
| --- | --- |
| primary | primary document |
| otherDocument |  iCloud conflict document |


### success
 
 Returns status.
 
 Returns:
 
* returnStatus.doesntExist -- document doesn't exist
* returnStatus.normal -- normal state
* returnStatus.editingDisabled -- editing disabled

This status is returned when a document is being externally updated. When the update is complete, an update notification (iDocument.loaded) will be sent at which time suspended operations can resume. 
  
* returnStatus.currentDocument --  document is current document
* returnStatus.conflictDocument -- document is conflict document
* returnStatus.closed -- document closed

For a local document the "closed" status means the document is closed, however, for a cloud document the status could be a link in the document update chain, a temporary status that will eventually resolve to "normal".  In the cloud "closed" case (and in the case of other non-"normal" statuses) if the document is being updated externally an "update" (iDocument.loaded) notification will be sent when the update is complete.                         

* returnStatus.inConflict -- conflict exists

Current and conflict version(s) of the document exist. Needs to be resolved before the document can be saved.

* returnStatus.progressAvailable
  
  The plugin doesn't use progress information but this status indicates that the document is being updated.  When the update is complete, an update notification (iDocument.loaded) will be sent. 

 Testing for absence of "normal" (which is what the "save" option does) is usually sufficient.            
 
 ### error
  
 get status failed callback.

  
Returns:
  
* returnStatus.doesntExist -- document doesn't exist  
* returnStatus.badArguments -- couldn't parse arguments
            
  ```javascript 
    //get status of document
    iDocument.documentAction ("getStatus",docStatus, operationFailed);

    //get status of conflict resolution document
    iDocument.documentAction ("getStatus",docStatus, operationFailed,[iDocument.documentID.otherDocument]);
    
    function docStatus (status) {
        if(status.includes(iDocument.returnStatus.inConflict)) {
        // do something
        }    
    }


```
***
 **getData**   
***

Retrieve document data from plugin.

When a document is opened, document data is returned: it is not necessary to do a "getData" unless you want a fresh copy, maybe to undo changes. If a document is externally updated, you are notified and can retrieve the new data with "getData". 
 
 

| arguments | Type | Description | 
| --- | --- | --- |
|  ID  | documentID |  status document | 


**iDocument.documentID:**

| ID | Description |
| --- | --- |
| primary | primary document |
| otherDocument |  iCloud conflict document |
             
             
 ### success
 
 Returns Document data.
            
             
  ### error
  
 get data failed callback.
            
 Returns:
  
* returnStatus.doesntExist -- document doesn't exist  
* returnStatus.badArguments -- couldn't parse arguments
            
  ```javascript 
    iDocument.documentAction("getData",updateRetrieved,operationFailed,[iDocument.documentID.primary]);
    
    function updateRetrieved (theData) {
        console.log(theData);
    }

``` 
 
 
***             
**resolve**
*** 

Resolves document conflicts.

Documents that can be externally updated (iCloud documents, for example) can have conflicting versions. When there is a conflict, there is a current version of the document and one or more conflict versions. To resolve the conflict, a "conflict winner" version  needs to be selected. This version will supersede all other versions.  The current version or one of the conflict versions can be chosen as the winner or the versions can be merged.  To merge versions, select the current version as the conflict winner and then save the merged version. 

    "Current version" is what iCloud thinks is the current version, not necessarily what is currently displaying. The plugin will have the current version and will have sent an "update" notification--perhaps this has triggered the resolution process--but the plugin data and local data will be out of sync until a "getData" happens.        

Before  "resolve" can be called,   "getOtherVersions" must be called first. 

| arguments | Type | Description |
| --- | --- | --- |
| resolutionType | String |  file's system directory |
| versionNumber | Int| selected version |

 
 ### resolutionType

Type of conflict resolution.  

Supported resolutions:

* "current"

Selects current version as document version.

* "version"

Selects conflict version "versionNumber"  as document version.
    
### versionNumber 

Conflict version to assign to document.   

  ```javascript 
  // resolve to current version
    iDocument.documentAction("resolve",finished,operationFailed,["current"]);
 
  // resolve to conflict document "0"      
    iDocument.documentAction("resolve",finished,operationFailed,["version",0]);    

``` 
***
**getOtherVersions** 
***

Get other (conflict) versions of the document.

 ### success
 
 Returns number of other versions. After "getOtherVersions" is called, "openOther" can open other versions by version number. Other documents are available until "resolve" resolves conflicts. 

  ### error
  
  Failed.
            
 Returns:
  
* returnStatus.doesntExist -- document doesn't exist  
* returnStatus.noVersions -- there are not any other versions
* returnStatus.unexpectedError -- unexpected error

  ```javascript 
        iDocument.documentAction("getOtherVersions",resolve,failed);
        
        function resolve (numberOfVersions) {
            //if "getOtherVersions" succeeds, there is at least one other version so "0" will work
            iDocument.documentAction("openOther",getOther,operationFailed,[0]);
        }

``` 
***
 **openOther** 
*** 
 
 Opens other document "documentNumber." These documents are "conflict" documents
  
 The primary document should remain open while other versions of the document are opened and closed.  Only one "other" document can be open a time. "Other" documents should be closed before "resolve" is attempted.   
 
 
| arguments | Type | Description |
| --- | --- | --- |
| documentNumber | Int| document version to open  |



### documentNumber

"getOtherVersions" returns the number of existing Other (conflict) Versions. "documentNumber" is a zero-based index into these Other Versions. 

 
### success
 
 Document Open succeeded callback.
 
 Returns other document data.  
 

  ### error
  
  Returns:
  
* returnStatus.doesntExist -- file doesn't exist  
* returnStatus.badArguments -- couldn't parse arguments
* returnStatus.noVersions -- there are not any other versions (or "getOtherVersions" was not previously called)
  
  
   ```javascript 
 
      iDocument.documentAction("openOther",getOther,operationFailed,[0]);
      
      
      function getOther(data) {
        console.log(data);
        iDocument.documentAction ("close",resolveWithOther, operationFailed,[iDocument.documentID.otherDocument]);
        }

```           

## Notifications

There is a single notification that needs to be handled: "loaded," which is triggered when new document data is loaded. This notification is only useful for iCloud or shared documents. Apps that only deal with local documents do not need to handle this notification.  The app will recieve this notification when another device or app updates a document. The new document data can be retrieved via a "getData."  The app will also be notified if a new document is downloaded as the result of a conflict resolution.  


    iDocument.loaded = [the Event Handler];

```javascript    
function EventHandler(documentStatus)
```

| Param | Type | Description |
| --- | --- | --- |
| documentStatus | returnStatus| Current Document Status |  

See "getstatus"  for  description of "returnStatus" 

This notification returns two additional status entries:

* returnStatus.typeUTF8 -- file type is UTF8  
* returnStatus.typeBin -- file type is binary


```javascript
function onDeviceReady() {
        iDocument.loaded = newData;
}


function newData(documentStatus) { 
    if(documentStatus.includes(iDocument.returnStatus.inConflict) {
    //do something
    } else {
    //do something else
    }
}
```


## Configuration

No configuration is necessary to deal with unshared local documents.  To share documents or access iCloud, there are multiple properties that need to be set. The following list is far from inclusive.  There are many options depending on your app goals.  These options are not listed here, this is only a brief list to get started.

### iCloud
 
A paid developer account is necessary to test the plugin with iCloud.  

In the Project Configuration Signing & Capabilities pane, for "iCloud" select "iCloud Documents" and optionally select a container. There are configuration keys for other options, making the container public (NSUbiquitousContainerIsDocumentScopePublic), for example. 

### Property List Keys

UISupportsDocumentBrowser


## Privacy Manifest file (PrivacyInfo.xcprivacy)

Your app will require a Privacy Manifest.  Here is a manifest fragment that applies to this plugin when using default functionality:

  ```xml

 <dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>E174.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
</dict>
```

## Conflict resolution.


iCloud documents can be modified on multiple devices leading to conflicts.  There are a couple of cases that have to be handled. The first case occurs when another device updates a document you are working on.  This technically isn't a conflict and isn't marked as such.  You will receive a notification that a new version of the document is available and you will need to do a "getData" to retrieve it.  At this point you can merge the new version with the local version or otherwise resolve the conflict. 
The second case occurs when iCloud detects a conflict.  One way this can be caused is if an offline device changes a document which your online device has also modified.  When the offline device comes online and syncs with iCloud, a conflict version of the document is created.  The conflict version(s) (there can be more than one) can be opened and you can merge the  version(s)  with the local version or otherwise resolve the conflict. You could, for example,  make one of the conflict versions the current version.   In general, a conflict can be detected via a notification or by the status returned when the document is opened (or by any other action that returns a status, including a status request).  

Documents shared between apps can also have conflicts and  can be resolved in a similar way.

Suspended apps don’t get notifications:  the app doesn’t know if a document has been updated.  It’s necessary to close and reopen the document to see if there were any changes while suspended.




## Suspended Apps

If an app is suspended it doesen't recieve notification that a document has been updated thus potentially rendering a local shared document out of sync with the current document.  It is necessary to refresh the document when the app becomes active. 


## Background Info

A little bit about what's going on "behind the scenes" 

The plug-in uses a UIDocument to handle the document I/O functions.  UIDocument simplifies handling iCloud documents and conflicts as well as providing other features, most of which we don't use. 

The UIDocument has its own copy of document data.  This data is retrieved on an "open" or updated on a "save".  The UIDocument can be externally updated--rendering the viewed document out of sync--at which point the plugin sends a "document-updated" notification.  A "getData" is used to retrieve the updated document data.  

A typical UIDocument is autosaved periodically and relies on notifications to track state changes.  Autosave doesn't make sense in our case since the UIDocument doesn't change continuously:  we have to send our document data across the JavaScript/native bridge to the UIDocument  (our "save" operation) at which point we initiate a save which will call our success/fail callback on completion.  The plug-in doesn't expose the state notifications:  they aren't useful given our approach.  The plug-in can request document state and operations such as “open” and “save” return document state.  

UIDocument as well as this plugin is not a good choice for large documents.  
