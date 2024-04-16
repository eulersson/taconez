import { memo, useEffect, useMemo, useRef } from "react";

import { LehmerRandomNumberGenerator } from "@/lib/utils";
import { SoundOccurrence } from "@/types";

export const SoundPartition = memo(function SoundPartition({
  partitionId,
  sounds,
}: {
  partitionId: number;
  sounds: SoundOccurrence[];
}) {
  const numSounds = sounds.length;

  const generateRNG = () =>
    new LehmerRandomNumberGenerator(partitionId + 1);

  const rngRef = useRef<LehmerRandomNumberGenerator>(generateRNG());

  useEffect(() => {
    rngRef.current = generateRNG();
  }, [numSounds]);

  function getColor(i: number) {
    const colors = ["bg-tz-red", "bg-tz-blue", "bg-black"];
    const randomIndex = Math.floor(rngRef.current!.next() * colors.length);
    return colors[randomIndex];
  }

  const computedColors = useMemo(
    () => sounds.slice(0, 7).map((_, i) => getColor(i)),
    [numSounds]
  );

  return (
    <div className="w-[200px] h-[200px] rounded-full bg-white">
      {/* TODO: Use framer motion to move them around. Storybook to present them. */}
      {Array.from({ length: Math.min(numSounds, 7) }).map((_, i) => (
        <div
          key={i}
          className={
            `h-[70px] w-[70px] absolute rounded-full ${computedColors[i]} ` +
            `top-[50%] left-[50%] transform -translate-x-1/2 -translate-y-1/4 `}
        ></div>
      ))}
    </div>
  );
});
