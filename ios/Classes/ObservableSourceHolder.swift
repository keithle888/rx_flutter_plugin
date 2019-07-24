import RxSwift

struct ObservableSourceHolder<T> {
    let type: StreamType
    let sourceGenerator: (T?) -> Any
    let errorHandler: ((Error) -> Any?)?
    
    init(
        observable: @escaping (T?) -> Any,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        self.type = StreamType.OBSERVABLE
        self.sourceGenerator = observable
        self.errorHandler = errorHandler
    }
    
    init(
        single: @escaping (T?) -> Any,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        self.type = StreamType.SINGLE
        self.sourceGenerator = single
        self.errorHandler = errorHandler
    }
    
    init(
        completable: @escaping (T?) -> Any,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        self.type = StreamType.COMPLETABLE
        self.sourceGenerator = completable
        self.errorHandler = errorHandler
    }
    
    func getSourceAsObservable(
        _ args: T?
        ) -> Observable<Any> {
        return sourceGenerator(args) as! Observable<Any>
    }
    
    func getSourceAsSingle(
        _ args: T?
        ) -> PrimitiveSequence<SingleTrait, Any> {
        return sourceGenerator(args) as! PrimitiveSequence<SingleTrait, Any>
    }
    
    func getSourceAsCompletable(
        _ args: T?
        ) -> PrimitiveSequence<CompletableTrait, Never> {
        return sourceGenerator(args) as! PrimitiveSequence<CompletableTrait, Never>
    }
}
