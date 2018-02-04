import Foundation

// Redux architecture revolves around a strict unidirectional data flow.
// Redux provides a single store.subscribe method for notifying listeners that the store has updated.

protocol StoreObserver: class {
    func storeChanged()
}

public final class Store<State, Action> {
    private var observers: StoreObservers
    private let reducer: (State, Action) -> State
    private(set) var state: State

    //To specify how the state tree is transformed by actions, you write pure reducers.
    public init(reducer: @escaping (State, Action) -> State, initialState: State) {
        self.reducer = reducer
        self.state = initialState
        self.observers = StoreObservers()
    }

    func subscribe(observer: StoreObserver) -> () -> Void {
        if let offset = observers.index(of: observer) {
            return { [weak self] in self?.observers.remove(at: offset) }
        }
        observers.append(observer)
        let offset = observers.count - 1
        return { [weak self] in self?.observers.remove(at: offset) }
    }

    // The only way to change the state is to emit an action, an object describing what happened.
    // This ensures that neither the views nor the network callbacks will ever write directly to the state.
    // Instead, they express an intent to transform the state.
    public func dispatch(action: Action) {
        state = reducer(state, action)
        observers.forEach { $0.storeChanged() }
    }
}

private struct StoreObservers {
    private final class WeakReference {
        weak var value: StoreObserver?

        init(value: StoreObserver) {
            self.value = value
        }
    }

    private var currentIndex: Int = 0
    private var weakReferences: [WeakReference] = []

    var count: Int {
        return weakReferences.filter({ $0.value != nil }).count
    }

    func index(of observer: StoreObserver) -> Int? {
        return weakReferences.index(where: {
            guard let value = $0.value else {
                return false
            }
            return observer === value
        })
    }

    subscript(offset: Int) -> StoreObserver? {
        return weakReferences[offset].value
    }

    mutating func compact() {
        weakReferences = weakReferences.filter { $0.value != nil }
    }

    mutating func append(_ observer: StoreObserver) {
        weakReferences.append(WeakReference(value: observer))
    }

    mutating func remove(at offset: Int) {
        weakReferences.remove(at: offset)
    }
}

extension StoreObservers: Sequence, IteratorProtocol {
    mutating func next() -> StoreObserver? {
        let numberOfValues = count
        guard numberOfValues > 0 && currentIndex < numberOfValues else {
            return nil
        }
        var value: StoreObserver?
        while value == nil, currentIndex < numberOfValues {
            value = weakReferences[currentIndex].value
            currentIndex += 1
        }
        return value
    }
}
