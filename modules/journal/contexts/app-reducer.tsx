import { Dispatch, createContext, useContext, useReducer } from "react";

import { TimeRange } from "@/types";

type State = {
  selectedSound?: string | null;
  listeningSound?: string | null;
  broadcastingSound?: string | null;
  timeRange: TimeRange;
};

type Action =
  | { type: "select"; sound: string | null }
  | { type: "broadcast"; sound: string }
  | { type: "finishedBroadcasting" }
  | { type: "listen"; sound: string }
  | { type: "finishedListening" }
  | { type: "delete"; sound: string }
  | { type: "setTimeRange"; timeRange: TimeRange };

const initialState: State = {
  fetching: false,
  timeRange: TimeRange.Day,
};

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case "select":
      return {
        ...state,
        selectedSound: action.sound,
      };
    case "broadcast":
      return {
        ...state,
        broadcastingSound: action.sound,
      };
    case "finishedBroadcasting":
      return {
        ...state,
        broadcastingSound: null,
      };
    case "listen":
      return {
        ...state,
        listeningSound: action.sound,
      };
    case "finishedListening":
      return {
        ...state,
        listeningSound: null,
      };
    case "setTimeRange":
      return { ...state, timeRange: action.timeRange };
    default:
      return state;
  }
}

const AppContext = createContext<[State, Dispatch<Action>] | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(reducer, initialState);
  return (
    <AppContext.Provider value={[state, dispatch]}>
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error("useAppReducer must be used within an AppProvider");
  }
  return context;
}
