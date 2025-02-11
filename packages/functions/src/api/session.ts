import { z } from "zod";
import { Hono } from "hono";
import { Result } from "../common";
import { describeRoute } from "hono-openapi";
import { Examples } from "@nestri/core/examples";
import { validator, resolver } from "hono-openapi/zod";
import { Sessions } from "@nestri/core/session/index";

export module SessionApi {
  export const route = new Hono()
    .get(
      "/active",
      describeRoute({
        tags: ["Session"],
        summary: "Retrieve all active gaming sessions",
        description: "Returns a list of all active gaming sessions associated with the authenticated user",
        responses: {
          200: {
            content: {
              "application/json": {
                schema: Result(
                  Sessions.Info.array().openapi({
                    description: "A list of active gaming sessions associated with the user",
                    example: [{ ...Examples.Session, public: true, endedAt: undefined }],
                  }),
                ),
              },
            },
            description: "Successfully retrieved the list of active gaming sessions",
          },
          404: {
            content: {
              "application/json": {
                schema: resolver(z.object({ error: z.string() })),
              },
            },
            description: "No active gaming sessions found for the authenticated user",
          },
        },
      }),
      async (c) => {
        const res = await Sessions.getActive();
        if (!res) return c.json({ error: "No active gaming sessions found for this user" }, 404);
        return c.json({ data: res }, 200);
      },
    )
    .get(
      "/:id",
      describeRoute({
        tags: ["Session"],
        summary: "Retrieve a gaming session by id",
        description: "Fetches detailed information about a specific gaming session using its unique id",
        responses: {
          404: {
            content: {
              "application/json": {
                schema: resolver(z.object({ error: z.string() })),
              },
            },
            description: "No gaming session found matching the provided id",
          },
          200: {
            content: {
              "application/json": {
                schema: Result(
                  Sessions.Info.openapi({
                    description: "Detailed information about the requested gaming session",
                    example: Examples.Session,
                  }),
                ),
              },
            },
            description: "Successfully retrieved gaming session information",
          },
        },
      }),
      validator(
        "param",
        z.object({
          id: Sessions.Info.shape.id.openapi({
            description: "The unique id used to identify the gaming session",
            example: Examples.Session.id,
          }),
        }),
      ),
      async (c) => {
        const params = c.req.valid("param");
        const res = await Sessions.fromID(params.id);
        if (!res) return c.json({ error: "Session not found" }, 404);
        return c.json({ data: res }, 200);
      },
    )
    .post(
      "/",
      describeRoute({
        tags: ["Session"],
        summary: "Create a new gaming session for this user",
        description: "Create a new gaming session for the currently authenticated user, enabling them to play a game",
        responses: {
          200: {
            content: {
              "application/json": {
                schema: Result(z.literal("ok"))
              },
            },
            description: "Gaming session successfully created",
          },
          422: {
            content: {
              "application/json": {
                schema: resolver(z.object({ error: z.string() })),
              },
            },
            description: "Something went wrong while creating a gaming session for this user",
          },
        },
      }),
      validator(
        "json",
        z.object({
          public: Sessions.Info.shape.public.openapi({
            description: "Whether the session is publicly viewable by all users. If false, only authorized users can access it",
            example: Examples.Session.public
          }),
        }),
      ),
      async (c) => {
        const params = c.req.valid("json")
        const session = await Sessions.create(params)
        if (!session) return c.json({ error: "Something went wrong while creating a session" }, 422);
        return c.json({ data: session }, 200);
      },
    )
    .delete(
      "/:id",
      describeRoute({
        tags: ["Session"],
        summary: "Terminate a gaming session",
        description: "This endpoint allows a user to terminate an active gaming session by providing the session's unique ID",
        responses: {
          200: {
            content: {
              "application/json": {
                schema: Result(z.literal("ok")),
              },
            },
            description: "The session was successfully terminated.",
          },
          404: {
            content: {
              "application/json": {
                schema: resolver(z.object({ error: z.string() })),
              },
            },
            description: "The session with the specified ID could not be found by this user",
          },
        }
      }),
      validator(
        "param",
        z.object({
          id: Sessions.Info.shape.id.openapi({
            description: "The unique identifier of the gaming session to be terminated. ",
            example: Examples.Session.id,
          }),
        }),
      ),
      async (c) => {
        const params = c.req.valid("param");
        const res = await Sessions.end(params.id)
        if (!res) return c.json({ error: "Session is not owned by this user" }, 404);
        return c.json({ data: res }, 200);
      },
    );
}