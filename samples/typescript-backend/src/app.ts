// Generated code. Do not edit.

import express, { type Express } from "express";
import {
    registerGeneratedRoutes,
    type GeneratedHandlers,
    type GeneratedSchemaBindings,
    type GeneratedRouteOptions
} from "./generated/routes.js";

export function createApp<Bindings extends GeneratedSchemaBindings = {}>(
    handlers: GeneratedHandlers<Bindings>,
    bindings?: Bindings,
    options?: GeneratedRouteOptions,
): Express {
    const app = express();
    registerGeneratedRoutes(app, handlers, bindings, options);
    return app;
}
