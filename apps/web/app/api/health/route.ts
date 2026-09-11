export async function GET() {
  return Response.json({
    status: "ok",
    service: "tripbanban-web",
    timestamp: new Date().toISOString()
  });
}
