"use client";

import { useEffect, useState } from "react";

import { SoundBubble } from "@/components";
import { SoundOccurrence } from "@/types";

export function SoundPlot({
  initialData,
}: {
  initialData: SoundOccurrence[];
}) {
  const [data, setData] = useState(initialData);

  // Every 10 seconds, fetch new data.
  useEffect(() => {
    const interval = setInterval(async () => {
      const searchParams = new URLSearchParams({
        from: "-10s",
        limit: "10",
        page: "1",
      });
      const response = await fetch(
        `/api/fetch-sound-occurrences?${searchParams}`
      );
      const newData = await response.json();
      setData((data) => [...newData, ...data]);
    }, 10000);
    return () => clearInterval(interval);
  }, []);

  return (
    <>
      <p>Number of items: {data.length} </p>
        {data.map((sound, i) => (
          <SoundBubble key={i} sound={sound} />
        ))}
    </>
  );
}
