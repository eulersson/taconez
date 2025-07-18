import { useAppContext } from "@/contexts/app-reducer";
import { TimeRange } from "@/types";

export function TimeRangeSelector() {
  const [state, dispatch] = useAppContext();

  return (
    <div className="flex space-x-2">
      {Object.values(TimeRange).map((range) => (
        <button
          key={range}
          className={`${
            state.timeRange === range
              ? "bg-black text-white"
              : "bg-white text-black"
          } px-2 py-1 rounded-md`}
          onClick={() => dispatch({ type: "setTimeRange", timeRange: range })}
        >
          {range}
        </button>
      ))}
    </div>
  );
}
