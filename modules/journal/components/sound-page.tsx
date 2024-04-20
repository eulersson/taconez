"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

import { SoundPlot } from "@/components/sound-plot";
import { AppProvider } from "@/contexts/app-reducer";
import { SoundOccurrence } from "@/types";

export function SoundPage({ initialData }: { initialData: SoundOccurrence[] }) {
  const queryClient = new QueryClient();

  return (
    <QueryClientProvider client={queryClient}>
      <AppProvider>
        <SoundPlot initialData={initialData}></SoundPlot>
      </AppProvider>
    </QueryClientProvider>
  );
}
