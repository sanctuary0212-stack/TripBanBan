import { demoTrip } from "@tripbanban/domain";

export default function Home() {
  const totalStops = demoTrip.days.reduce((sum, day) => sum + day.stops.length, 0);

  return (
    <main className="shell">
      <section className="hero">
        <div>
          <p className="eyebrow">TRIPBANBAN · MVP</p>
          <h1>把旅行排得剛剛好。</h1>
          <p className="heroCopy">
            一個先從「看懂整趟旅程」開始的行程規劃工具。下一步會加入建立、編輯、分享與地圖能力。
          </p>
        </div>
        <div className="summaryCard">
          <span>目前示範行程</span>
          <strong>{demoTrip.title}</strong>
          <small>
            {demoTrip.startDate} → {demoTrip.endDate}
          </small>
        </div>
      </section>

      <section className="stats" aria-label="行程摘要">
        <article>
          <span>目的地</span>
          <strong>{demoTrip.destination}</strong>
        </article>
        <article>
          <span>天數</span>
          <strong>{demoTrip.days.length}</strong>
        </article>
        <article>
          <span>景點</span>
          <strong>{totalStops}</strong>
        </article>
        <article>
          <span>狀態</span>
          <strong>{demoTrip.status}</strong>
        </article>
      </section>

      <section className="timeline">
        {demoTrip.days.map((day, index) => (
          <article className="dayCard" key={day.date}>
            <div className="dayHeader">
              <div>
                <span>DAY {index + 1}</span>
                <h2>{day.title}</h2>
              </div>
              <time>{day.date}</time>
            </div>

            <div className="stops">
              {day.stops.map((stop) => (
                <div className="stop" key={stop.id}>
                  <div className="time">{stop.startTime ?? "彈性"}</div>
                  <div>
                    <h3>{stop.name}</h3>
                    <p>{stop.city}</p>
                    {stop.note ? <small>{stop.note}</small> : null}
                  </div>
                </div>
              ))}
            </div>
          </article>
        ))}
      </section>

      <footer>
        API health: <code>/api/health</code> · Trips API: <code>/api/trips</code>
      </footer>
    </main>
  );
}
