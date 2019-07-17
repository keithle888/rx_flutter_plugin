enum PluginError: Error {
    case InvalidObservableType(String?)
    case ObservableState
    case ObservableNotAvailable
    case ObservableThrown
    
    func getErrorCode() -> Int {
        switch self {
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
