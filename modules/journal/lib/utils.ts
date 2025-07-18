import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

import { SoundOccurrence } from "@/types";

/**
 * A function that allows the conditional classnames from ‘clsx’ or ‘classnames’ to be
 * passed into ‘tailwind-merge’.
 *
 * Combining clsx or classnames with tailwind-merge allows us to conditionally join
 * Tailwind CSS classes in classNames together without style conflicts. Inspired by
 * shadcn/ui.
 *
 * Source:
 * - [cn() - Every Tailwind Coder Needs It (clsx + twMerge)]
 *   (https://www.youtube.com/watch?v=re2JFITR7TI)
 */
export function cn(...args: ClassValue[]) {
  return twMerge(clsx(args));
}

/**
 * A simple Lehmer random number generator to produce the same sequence of numbers given
 * a seed, since with Math.random() we can't control the seed.
 */
export class LehmerRandomNumberGenerator {
  constructor(private seed: number) {}

  next() {
    this.seed = (this.seed * 16807) % 2147483647;
    return (this.seed - 1) / 2147483646;
  }
}

/**
 * Partitions the sounds array into hourly or daily chunks
 */
export function partitionSoundsArray(
  sounds: SoundOccurrence[],
  rule: "hourly" | "daily"
) {
  const result: SoundOccurrence[][] = [];
  let currentPartition: SoundOccurrence[] = [];
  let currentPartitionDate: Date | null = null;

  for (const sound of sounds) {
    const soundDate = new Date(sound.when);
    const shouldPartition =
      rule === "hourly"
        ? currentPartitionDate === null ||
          soundDate.getHours() !== currentPartitionDate.getHours()
        : currentPartitionDate === null ||
          soundDate.getDate() !== currentPartitionDate.getDate();

    if (shouldPartition) {
      if (currentPartition.length > 0) {
        result.push(currentPartition);
      }
      currentPartition = [];
      currentPartitionDate = soundDate;
    }

    currentPartition.push(sound);
  }

  if (currentPartition.length > 0) {
    result.push(currentPartition);
  }

  return result;
}
