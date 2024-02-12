import { createTRPCProxyClient, httpBatchLink } from "@trpc/client";
import type { AppRouter } from "../server";

const trpc = createTRPCProxyClient<AppRouter>({
  links: [
    httpBatchLink({
      url: `http://${process.env.TRPC_SERVER_HOST_NAME}:9976`,
    }),
  ],
});

const result = await trpc.buy.mutate({ productName: "apples"});
console.log(result);
