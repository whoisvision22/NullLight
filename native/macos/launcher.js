ObjC.import('Cocoa');
ObjC.import('WebKit');

var windowRef;
var webView;
var engine;
var failed = false;
var exportHandler;
ObjC.registerSubclass({
    name: 'LichtpultExportHandler',
    methods: {
        'userContentController:didReceiveScriptMessage:': {
            types: ['void', ['id', 'id']],
            implementation: function(controller, message) {
                var json = ObjC.unwrap(message.body);
                if (typeof json !== 'string') return;
                var panel = $.NSSavePanel.savePanel;
                panel.nameFieldStringValue = 'NullLight-Show.json';
                panel.allowedFileTypes = $(['json']);
                if (Number(panel.runModal) === 1) {
                    var errorRef = Ref();
                    var saved = $(json).writeToURLAtomicallyEncodingError(
                        panel.URL, true, $.NSUTF8StringEncoding, errorRef
                    );
                    if (!saved) {
                        var alert = $.NSAlert.alloc.init;
                        alert.messageText = 'Die Show konnte nicht gespeichert werden';
                        alert.informativeText = 'Bitte wähle einen anderen Speicherort.';
                        alert.runModal;
                    }
                }
            }
        }
    }
});

function stopEngine() {
    if (engine && engine.running) {
        engine.terminate;
        engine.waitUntilExit;
    }
    engine = null;
}
function launchEngine(directory, bundleResources, failedUpdate) {
    var pipe = $.NSPipe.pipe;
    engine = $.NSTask.alloc.init;
    engine.launchPath = '/usr/bin/ruby';
    engine.arguments = $([directory + '/artnet.rb', directory + '/NullLight.html']);
    var environment = $.NSProcessInfo.processInfo.environment.mutableCopy;
    environment.setObjectForKey($(bundleResources), $('NULLLIGHT_BUNDLE_RESOURCES'));
    environment.setObjectForKey($(failedUpdate ? '1' : '0'), $('NULLLIGHT_UPDATE_FAILED'));
    engine.environment = environment;
    engine.standardOutput = pipe;
    engine.standardError = pipe;
    engine.launch;
    var bytes = pipe.fileHandleForReading.availableData;
    var line = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(bytes, $.NSUTF8StringEncoding)).trim().split('\n')[0];
    if (line.indexOf('http://127.0.0.1:49365/?session=') !== 0) {
        throw new Error(line || 'Der Art-Net-Dienst konnte nicht gestartet werden.');
    }
    return line;
}
function run() {
    var app = $.NSApplication.sharedApplication;
    app.setActivationPolicy($.NSApplicationActivationPolicyRegular);
    var resources = $.NSBundle.mainBundle.resourceURL.path;
    var bundleResources = ObjC.unwrap(resources);
    var activeResources = bundleResources;
    try {
        var updatePipe = $.NSPipe.pipe;
        var updateTask = $.NSTask.alloc.init;
        updateTask.launchPath = '/usr/bin/ruby';
        updateTask.arguments = $([bundleResources + '/updater.rb', bundleResources]);
        updateTask.standardOutput = updatePipe;
        updateTask.standardError = $.NSPipe.pipe;
        updateTask.launch;
        updateTask.waitUntilExit;
        if (Number(updateTask.terminationStatus) === 0) {
            var updateBytes = updatePipe.fileHandleForReading.readDataToEndOfFile;
            var updateText = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(updateBytes, $.NSUTF8StringEncoding));
            var release = JSON.parse(updateText);
            if (typeof release.path === 'string' &&
                $.NSFileManager.defaultManager.fileExistsAtPath($(release.path + '/artnet.rb')) &&
                $.NSFileManager.defaultManager.fileExistsAtPath($(release.path + '/NullLight.html'))) {
                activeResources = release.path;
            }
        }
    } catch (error) {
        activeResources = bundleResources;
    }

try {
    var line;
    try {
        line = launchEngine(activeResources, bundleResources, false);
    } catch (error) {
        if (activeResources === bundleResources) throw error;
        stopEngine();
        line = launchEngine(bundleResources, bundleResources, true);
    }
        windowRef = $.NSWindow.alloc.initWithContentRectStyleMaskBackingDefer(
            $.NSMakeRect(0, 0, 1280, 850), 15, 2, false
        );
        windowRef.title = 'NullLight';
        windowRef.minSize = $.NSMakeSize(760, 580);
        windowRef.releasedWhenClosed = false;
        var configuration = $.WKWebViewConfiguration.alloc.init;
        exportHandler = $.LichtpultExportHandler.alloc.init;
        configuration.userContentController.addScriptMessageHandlerName(exportHandler, $("showExport"));
        webView = $.WKWebView.alloc.initWithFrameConfiguration(
            $.NSMakeRect(0, 0, 1280, 850), configuration
        );
        windowRef.contentView = webView;
        webView.loadRequest($.NSURLRequest.requestWithURL($.NSURL.URLWithString($(line))));
        windowRef.center;
        windowRef.makeKeyAndOrderFront(null);
        app.activateIgnoringOtherApps(true);
    } catch (error) {
        failed = true;
        stopEngine();
        var alert = $.NSAlert.alloc.init;
        alert.messageText = 'NullLight konnte nicht starten';
        alert.informativeText = String(error) + '\nSchließe eine eventuell bereits geöffnete NullLight-App und versuche es erneut.';
        alert.runModal;
    }
}
function idle() {
    if (failed || !windowRef || !windowRef.isVisible) {
        stopEngine();
        $.NSApplication.sharedApplication.terminate(null);
    }
    return 1;
}
function quit() {
    stopEngine();
}
