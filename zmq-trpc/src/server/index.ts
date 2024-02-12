
import { createHTTPServer } from "@trpc/server/adapters/standalone";
import { z } from "zod";
import { publicProcedure, router } from "./trpc";

import { Push } from "zeromq";

const appRouter = router({
  buy: publicProcedure.input(z.object({ productName: z.string() })).mutation((opts) => {
    const { input } = opts;
    console.log(`Buying ${input.productName}...`)
    const sock = new Push();
    return { success: true };
  })
})

export type AppRouter = typeof appRouter

const server = createHTTPServer({
  router: appRouter
})

server.listen(9976)
console.log("Listening on port 9976...")