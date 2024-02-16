import { fetchSoundOccurrences } from "@/lib/influx-data";
import { unstable_noStore as noStore } from "next/cache";

export async function GET(request: Request) {
  // Prevents caching the GET request.
  noStore();

  const { searchParams } = new URL(request.url);

  // Ensure `from`, `limit`, and `page` query parameters are present.
  for (const param of ["from", "limit", "page"]) {
    if (!searchParams.has(param)) {
      return new Response(`Missing '${param}' query parameter.`, {
        status: 400,
      });
    }
  }

  // `from`, `limit`, and `page` are present since we checked for them above.
  const from = searchParams.get("from")!;
  const limit = parseInt(searchParams.get("limit")!);
  const page = parseInt(searchParams.get("page")!);

  const result = await fetchSoundOccurrences({
    from,
    limit,
    page,
  });

  return Response.json(result);
}
