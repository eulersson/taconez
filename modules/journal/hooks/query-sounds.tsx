import { useQuery } from "@tanstack/react-query";

export function useQuerySounds({
  from,
  limit,
  page,
}: {
  from: string;
  limit: number;
  page: number;
}) {
  return useQuery({
    queryKey: ["sounds", { from, limit, page }],
    queryFn: async () => {
      const searchParams = new URLSearchParams({
        from,
        limit: limit.toString(),
        page: page.toString(),
      });
      const res = await fetch(`/api/fetch-sound-occurrences?${searchParams}`);
      return res.json();
    },
  });
}
