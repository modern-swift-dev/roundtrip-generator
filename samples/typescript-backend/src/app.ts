// Generated code. Do not edit.

import express, { type Express } from "express";
import {
    registerGeneratedRoutes,
    type GeneratedHandlers,
    type GeneratedMultipartAdapters,
    type GeneratedRequestIntegration,
    type GeneratedSchemaBindings,
    type GeneratedRouteOptions
} from "./generated/routes.js";

export function createApp<Bindings extends GeneratedSchemaBindings = {}, Integration extends GeneratedRequestIntegration = {}, Multipart extends GeneratedMultipartAdapters = {}>(
    handlers: GeneratedHandlers<Bindings, Integration, Multipart>,
    bindings?: Bindings,
    options?: GeneratedRouteOptions<Integration, Multipart>,
): Express {
    const app = express();
    registerGeneratedRoutes(app, handlers, bindings, options);
    return app;
}
