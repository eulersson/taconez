"use client";

import { useEffect, useState } from "react";

import { SoundBubble } from "@/components/sound-bubble";
import { ThemeSwitch } from "@/components/theme-switch";
import { SoundOccurrence } from "@/types";

export function SoundPlot({ initialData }: { initialData: SoundOccurrence[] }) {
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
      if (newData.length > 0) {
        setData((data) => [...newData, ...data]);
      }
    }, 10000);
    return () => clearInterval(interval);
  }, []);

  return (
    <>
      <div className="fixed flex justify-center top-3 inset-x-0">
        <ThemeSwitch />
      </div>
      <p>Number of detections: {data.length} </p>
      <ul className="space-y-1">
        {data.map((sound, i) => (
          <li key={i}>
            <SoundBubble sound={sound} />
          </li>
        ))}
      </ul>
    </>
  );
}
