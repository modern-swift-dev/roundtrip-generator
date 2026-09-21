import { createApp as createGeneratedApp } from "./app.js";
import type { GeneratedHandlers } from "./generated/routes.js";

export function createApp() {
    const handlers: GeneratedHandlers = {
        demoMessagesEcho: async (input) => input
    };
    return createGeneratedApp(handlers);
}
