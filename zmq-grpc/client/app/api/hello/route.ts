import { ChannelCredentials } from "@grpc/grpc-js";

import { GreeterClient } from "@/lib/rpc/taconez_grpc";

export function GET(request: Request) {

  if (process.env.GRPC_SERVER_HOST_NAME === undefined) {
    return Response.json(
      { error: "GRPC_SERVER_HOST_NAME is not set" },
      { status: 500 }
    );
  }

  // https://github.com/stephenh/ts-proto/blob/main/integration/grpc-js/grpc-js-test.ts
  const client = new GreeterClient(
    `${process.env.GRPC_SERVER_HOST_NAME}:9976`,
    ChannelCredentials.createInsecure()
  );

  const { searchParams } = new URL(request.url);
  const name = searchParams.get("name") || "world";
  return new Promise<Response>((resolve, reject) => {
    client.sayHello({ name }, (err, response) => {
      if (err) {
        console.error(err);
        resolve(
          Response.json(
            { error: "Request has failed, check server logs!" },
            { status: 500 }
          )
        );
      }
      resolve(Response.json(response, { status: 200 }));
    });
  });
}
