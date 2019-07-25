import RxSwift

protocol ObservableSourceHolder {
    var type: StreamType {get set}
    var sourceGenerator: (Any?) throws -> Any {get set}
    var errorHandler: ((Error) -> Any?)? {get set}
    
    func getSourceAsObservable(
        _ args: Any?
        ) throws -> Observable<Any>
    
    func getSourceAsSingle(
        _ args: Any?
        ) throws -> PrimitiveSequence<SingleTrait, Any>
    
    func getSourceAsCompletable(
        _ args: Any?
        ) throws -> PrimitiveSequence<CompletableTrait, Never>
}

class ObservableSourceHolderImpl: ObservableSourceHolder {
    var type: StreamType
    var sourceGenerator: (Any?) throws -> Any
    var errorHandler: ((Error) -> Any?)?
    
    init(
        observable: @escaping (Any?) throws -> Any,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        self.type = StreamType.OBSERVABLE
        self.sourceGenerator = observable
        self.errorHandler = errorHandler
    }
    
    init(
        single: @escaping (Any?) throws -> Any,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        self.type = StreamType.SINGLE
        self.sourceGenerator = single
        self.errorHandler = errorHandler
    }
    
    init(
        completable: @escaping (Any?) throws -> Any,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        self.type = StreamType.COMPLETABLE
        self.sourceGenerator = completable
        self.errorHandler = errorHandler
    }
    
    func getSourceAsObservable(
        _ args: Any?
        ) throws -> Observable<Any> {
        return try sourceGenerator(args) as! Observable<Any>
    }
    
    func getSourceAsSingle(
        _ args: Any?
        ) throws -> PrimitiveSequence<SingleTrait, Any> {
        return try sourceGenerator(args) as! PrimitiveSequence<SingleTrait, Any>
    }
    
    func getSourceAsCompletable(
        _ args: Any?
        ) throws -> PrimitiveSequence<CompletableTrait, Never> {
        return try sourceGenerator(args) as! PrimitiveSequence<CompletableTrait, Never>
    }
}
