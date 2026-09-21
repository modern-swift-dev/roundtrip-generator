// Generated code. Do not edit.

import express, { type Express } from "express";
import {
    registerGeneratedRoutes,
    type GeneratedHandlers,
    type GeneratedRequestIntegration,
    type GeneratedSchemaBindings,
    type GeneratedRouteOptions
} from "./generated/routes.js";

export function createApp<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}>(
    handlers: GeneratedHandlers<Bindings, Integration>,
    bindings?: Bindings,
    options?: GeneratedRouteOptions<Integration>,
): Express {
    const app = express();
    registerGeneratedRoutes(app, handlers, bindings, options);
    return app;
}
