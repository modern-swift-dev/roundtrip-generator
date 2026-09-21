struct TypeScriptBackendRuntimeEmitter {
    func source() -> String {
        """
        // Generated code. Do not edit.

        export type BackendHandlerResult<T> = T | Promise<T>;
        """
    }
}
