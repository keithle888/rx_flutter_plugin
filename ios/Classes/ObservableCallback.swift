struct ObservableCallback {
    let callbackType: CallbackType
    let requestId: Int
    let payload: Any?
    let errorMessage: String?
    
    enum CallbackType: String {
        case ON_NEXT = "onNext"
        case ON_COMPLETE = "onComplete"
        case ON_ERROR = "onError"
    }
    
    func toDictionary() -> [String: Any?] {
        return [
            Field.OBSERVABLE_CALLBACK.rawValue: self.callbackType.rawValue,
            Field.REQUEST_ID.rawValue: self.requestId,
            Field.PAYLOAD.rawValue: self.payload,
            Field.ERROR_MESSAGE.rawValue: self.errorMessage
        ]
    }
}
