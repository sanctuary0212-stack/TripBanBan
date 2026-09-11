export type TripStatus = "draft" | "planned" | "active" | "completed";

export interface TripStop {
  id: string;
  name: string;
  city: string;
  startTime?: string;
  endTime?: string;
  note?: string;
}

export interface TripDay {
  date: string;
  title: string;
  stops: TripStop[];
}

export interface Trip {
  id: string;
  title: string;
  destination: string;
  startDate: string;
  endDate: string;
  status: TripStatus;
  days: TripDay[];
}

export const demoTrip: Trip = {
  id: "trip-demo-taipei",
  title: "台北兩天一夜",
  destination: "台北",
  startDate: "2026-10-03",
  endDate: "2026-10-04",
  status: "planned",
  days: [
    {
      date: "2026-10-03",
      title: "城市散步",
      stops: [
        {
          id: "stop-1",
          name: "大稻埕",
          city: "台北",
          startTime: "10:00",
          note: "先從老街與咖啡開始。"
        },
        {
          id: "stop-2",
          name: "中山商圈",
          city: "台北",
          startTime: "14:00"
        }
      ]
    },
    {
      date: "2026-10-04",
      title: "慢慢收尾",
      stops: [
        {
          id: "stop-3",
          name: "松山文創園區",
          city: "台北",
          startTime: "10:30"
        }
      ]
    }
  ]
};
