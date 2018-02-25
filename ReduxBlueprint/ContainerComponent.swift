import Foundation

public protocol ContainerComponentDelegate: class {
    func containerComponentChanged()
}

// Container components: Are concerned with how things work.

// Out: Maps a subset of the redux state to the properties that will be formatted by a PresentationComponent.
// In: Maps commands coming from a PresentationComponent to a store action, and dispatch the mapped action.

public final class ContainerComponent<State, Action, Command, Property> {
    typealias MapStateToProperties = (State) -> [Property]
    typealias MapCommandToAction = (Command) -> (Action)

    private var unsubscribe: (() -> Void)?
    private weak var store: Store<State, Action>?
    private var properties: [Property] = []
    private var mapStateToProperties: MapStateToProperties
    private var mapCommandToAction: MapCommandToAction
    weak var delegate: ContainerComponentDelegate?

    init(
        store: Store<State, Action>,
        mapStateToProperties: @escaping MapStateToProperties,
        mapCommandToAction: @escaping MapCommandToAction) {
        self.mapStateToProperties = mapStateToProperties
        self.mapCommandToAction = mapCommandToAction
        self.store = store
        self.unsubscribe = store.subscribe(observer: self)
    }

    deinit {
        unsubscribe?()
    }

    func dispatch(command: Command) {
        store?.dispatch(action: mapCommandToAction(command))
    }
}

extension ContainerComponent: StoreObserver {
    func storeChanged() {
        guard let state = store?.state else {
            return
        }
        properties = mapStateToProperties(state)
        delegate?.containerComponentChanged()
    }
}
