import Flutter

struct ObservableRegistrationRequest {
    let method: String
    let streamType: StreamType
    let requestId: Int
    let arguments: Any?
    let observableAction: ObservableAction
    
    init(
        _ methodCall: FlutterMethodCall
        ) throws {
        self.method = methodCall.method
        guard let args = methodCall.arguments as? [String: Any] else {
            throw PluginError.InvalidObservableType("FlutterMethodCall arguments could not be casted to [String: Any].")
        }
        guard let typeString =  args[Field.STREAM_TYPE.rawValue] as? String else {
            throw PluginError.InvalidObservableType("Could not get StreamType to init ObservableRegistrationRequest.")
        }
        guard let type = StreamType(rawValue: typeString) else {
            throw PluginError.InvalidObservableType("Could not get StreamType enum to init ObservableRegistrationRequest.")
        }
        self.streamType = type
        guard let requestId =  args[Field.REQUEST_ID.rawValue] as? Int else {
            throw PluginError.InvalidObservableType("Could not get requestId to init ObservableRegistrationRequest.")
        }
        self.requestId = requestId
        self.arguments = args[Field.PAYLOAD.rawValue]
        guard let observableActionString =  args[Field.OBSERVABLE_ACTION.rawValue] as? String else {
            throw PluginError.InvalidObservableType("Could not get observableAction to init ObservableRegistrationRequest.")
        }
        guard let observableAction = ObservableAction(rawValue: observableActionString) else {
            throw PluginError.InvalidObservableType("Could not get observableAction enum to init ObservableRegistrationRequest.")
        }
        self.observableAction = observableAction
    }
}

struct ObservableRegistrationResponse {
    let errorCode: Int
    let errorMessage: String?
    
    func toDictionary() -> [String: Any] {
        return [
            Field.ERROR_CODE.rawValue: errorCode,
            Field.ERROR_MESSAGE.rawValue: errorMessage
        ]
    }
}
