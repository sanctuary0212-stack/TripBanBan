import { demoTrip } from "@tripbanban/domain";

export async function GET() {
  return Response.json({ trips: [demoTrip] });
}
