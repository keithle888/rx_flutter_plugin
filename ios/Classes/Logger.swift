enum LogEvent: String {
    case e = "[‼️]" // error
    case i = "[ℹ️]" // info
    case d = "[💬]" // debug
    case v = "[🔬]" // verbose
    case w = "[⚠️]" // warning
    case s = "[🔥]" // severe
}


public class RxFlutterPluginLogger {
    private static let LIBRARY_NAME = "RxFlutterPlugin/Swift"
    public static var debug = false
    
    internal static func d(_ log: String,
                           _ error: Error? = nil) {
        if (debug) {
            let logStr = "\(Date().toString()) \(LogEvent.d.rawValue)[\(RxFlutterPluginLogger.LIBRARY_NAME)] -> \(log)"
            print(logStr)
            
            if error != nil {
                let errorStr = "\(Date().toString()) \(LogEvent.d.rawValue)[\(RxFlutterPluginLogger.LIBRARY_NAME)] -> \(String(describing: error))"
                print(errorStr)
            }
        }
    }
    
    internal static func e(_ log: String, _ error: Error? = nil) {
        if (debug) {
            let logStr = "\(Date().toString()) \(LogEvent.e.rawValue)[\(RxFlutterPluginLogger.LIBRARY_NAME)] -> \(log)"
            print(logStr)
            
            if error != nil {
                let errorStr = "\(Date().toString()) \(LogEvent.e.rawValue)[\(RxFlutterPluginLogger.LIBRARY_NAME)] -> \(String(describing: error))"
                print(errorStr)
            }
        }
    }
    
    internal static func w(_ log: String, _ error: Error? = nil) {
        if (debug) {
            let logStr =  "\(Date().toString()) \(LogEvent.w.rawValue)[\(RxFlutterPluginLogger.LIBRARY_NAME)] -> \(log)"
            print(logStr)
            
            if error != nil {
                let errorStr = "\(Date().toString()) \(LogEvent.w.rawValue)[\(RxFlutterPluginLogger.LIBRARY_NAME)] -> \(String(describing: error))"
                print(errorStr)
            }
        }
    }
    
    // 1. The date formatter
    static var dateFormat = "dd-MM-yyyy hh:mm:ss" // Use your own
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    private static func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}


// 2. The Date to String extension
extension Date {
    func toString() -> String {
        return RxFlutterPluginLogger.dateFormatter.string(from: self as Date)
    }
}
