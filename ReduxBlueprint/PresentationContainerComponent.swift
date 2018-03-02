import Foundation

public final class PresentationContainerComponent<State, Action, Command, Properties> {
    private let container:  ContainerComponent<State, Action, Command, Properties>
    private let update: (Properties) -> Void
    
    public init(
        store: Store<State, Action>,
        mapStateToProperties: @escaping (State) -> Properties,
        mapCommandToAction: @escaping (Command) -> Action?,
        update: @escaping (Properties) -> Void)
    {
        self.update = update
        container = ContainerComponent(
            store: store,
            mapStateToProperties: mapStateToProperties,
            mapCommandToAction: mapCommandToAction
        )
        container.delegate = self
    }
    
    public func dispatch(command: Command) {
        container.dispatch(command: command)
    }
}

// MARK: ContainerComponentDelegate

extension PresentationContainerComponent: ContainerComponentDelegate {
    public func containerComponentChanged() {
        update(container.properties)
    }
}
