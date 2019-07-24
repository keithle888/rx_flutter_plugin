enum PluginError: Error {
    case InvalidObservableType(String?)
    case ObservableState(String?)
    case ObservableNotAvailable(String?)
    case ObservableThrown
    
    static func getErrorCode(_ error: PluginError) -> Int {
        switch error {
        case .InvalidObservableType:
            return 1
        case .ObservableState:
            return 2
        case .ObservableNotAvailable:
            return 3
        case .ObservableThrown:
            return 4
        }
    }
}
