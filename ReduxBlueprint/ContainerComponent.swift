import Foundation

// Container components: Are concerned with how things work.
// Out: Maps a subset of the redux state to the properties that will be formatted by a PresentationComponent.
// In: Maps commands coming from a PresentationComponent to a store action, and dispatch the mapped action.

public protocol ContainerComponentDelegate: class {
    func containerComponentChanged()
}

public final class ContainerComponent<State, Action, Command, Properties> {
    public private(set) var properties: Properties
    public weak var delegate: ContainerComponentDelegate?
    private var unsubscribe: (() -> Void)?
    private weak var store: Store<State, Action>?
    private var mapStateToProperties: (State) -> Properties
    private var mapCommandToAction: (Command) -> (Action?)

    public init(
        store: Store<State, Action>,
        mapStateToProperties: @escaping (State) -> Properties,
        mapCommandToAction: @escaping (Command) -> Action?)
    {
        self.mapStateToProperties = mapStateToProperties
        self.mapCommandToAction = mapCommandToAction
        self.store = store
        properties = mapStateToProperties(store.state)
        unsubscribe = store.subscribe(observer: self)
    }

    deinit {
        unsubscribe?()
    }

    public func dispatch(command: Command) {
        if let action = mapCommandToAction(command) {
            store?.dispatch(action: action)
        }
    }
}

extension ContainerComponent: StoreObserver {
    func storeChanged() {
        guard let state = store?.state else { return }
        properties = mapStateToProperties(state)
        delegate?.containerComponentChanged()
    }
}
