"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";

import { SoundPartition } from "@/components/sound-partition";
import { TimeRangeSelector } from "@/components/time-range-selector";
import { useAppContext } from "@/contexts/app-reducer";
import { useQuerySounds } from "@/hooks/query-sounds";
import { MOST_RECENT_SOUNDS_PARAMS } from "@/lib/influx-query";
import { partitionSoundsArray } from "@/lib/utils";
import { SoundOccurrence, TimeRange } from "@/types";

export function SoundPlot({ initialData }: { initialData: SoundOccurrence[] }) {
  const queryClient = useQueryClient();
  const { isPending, isError, error, data, isFetching } = useQuerySounds(
    MOST_RECENT_SOUNDS_PARAMS
  );

  // Every 10 seconds, fetch new data.
  useEffect(() => {
    const interval = setInterval(async () => {
      queryClient.invalidateQueries({
        queryKey: ["sounds", MOST_RECENT_SOUNDS_PARAMS],
      });
    }, 10000);
    return () => clearInterval(interval);
  }, []);

  const [state, dispatch] = useAppContext();

  // Merge initial data with new data only if `data` is not `undefined`.
  const sounds: SoundOccurrence[] =
    data && data.length > 0 ? [...data, ...initialData] : initialData;

  const soundPartitions: SoundOccurrence[][] = partitionSoundsArray(
    sounds,
    state.timeRange === TimeRange.Day ? "hourly" : "daily"
  );

  return (
    <>
      <TimeRangeSelector />
      <ul className="space-y-1">
        {soundPartitions.map((sounds, i) => (
          <li key={i}>
            <SoundPartition partitionId={i} sounds={sounds} />
          </li>
        ))}
      </ul>
    </>
  );
}
