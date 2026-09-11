import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View
} from "react-native";
import { demoTrip } from "@tripbanban/domain";

export default function App() {
  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor="#f5f3ee" />
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.hero}>
          <Text style={styles.eyebrow}>TRIPBANBAN</Text>
          <Text style={styles.title}>{demoTrip.title}</Text>
          <Text style={styles.meta}>
            {demoTrip.destination} · {demoTrip.startDate} → {demoTrip.endDate}
          </Text>
          <Text style={styles.description}>
            第一版 Android MVP：先驗證行程瀏覽、每日節點與跨 Web / Mobile 共用資料模型。
          </Text>
        </View>

        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>行程</Text>
          <Text style={styles.badge}>{demoTrip.days.length} 天</Text>
        </View>

        {demoTrip.days.map((day, index) => (
          <View key={day.date} style={styles.dayCard}>
            <View style={styles.dayHeader}>
              <View>
                <Text style={styles.dayIndex}>DAY {index + 1}</Text>
                <Text style={styles.dayTitle}>{day.title}</Text>
              </View>
              <Text style={styles.date}>{day.date}</Text>
            </View>

            {day.stops.map((stop, stopIndex) => (
              <View key={stop.id} style={styles.stopRow}>
                <View style={styles.timelineColumn}>
                  <View style={styles.dot} />
                  {stopIndex < day.stops.length - 1 ? (
                    <View style={styles.line} />
                  ) : null}
                </View>
                <View style={styles.stopContent}>
                  <Text style={styles.stopTime}>{stop.startTime ?? "彈性"}</Text>
                  <Text style={styles.stopName}>{stop.name}</Text>
                  <Text style={styles.stopCity}>{stop.city}</Text>
                  {stop.note ? <Text style={styles.note}>{stop.note}</Text> : null}
                </View>
              </View>
            ))}
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: "#f5f3ee"
  },
  container: {
    padding: 20,
    paddingBottom: 40,
    gap: 16
  },
  hero: {
    backgroundColor: "#ffffff",
    borderRadius: 24,
    padding: 22,
    gap: 8
  },
  eyebrow: {
    fontSize: 12,
    fontWeight: "800",
    letterSpacing: 1.8,
    color: "#6c6a63"
  },
  title: {
    fontSize: 30,
    lineHeight: 36,
    fontWeight: "800",
    color: "#1f211d"
  },
  meta: {
    fontSize: 14,
    fontWeight: "600",
    color: "#575a52"
  },
  description: {
    marginTop: 6,
    fontSize: 15,
    lineHeight: 22,
    color: "#62655d"
  },
  sectionHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 4
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: "800",
    color: "#1f211d"
  },
  badge: {
    backgroundColor: "#dde6cf",
    color: "#334226",
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 999,
    fontWeight: "700"
  },
  dayCard: {
    backgroundColor: "#ffffff",
    borderRadius: 22,
    padding: 18,
    gap: 16
  },
  dayHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 12
  },
  dayIndex: {
    fontSize: 11,
    fontWeight: "800",
    letterSpacing: 1.3,
    color: "#80837a"
  },
  dayTitle: {
    marginTop: 3,
    fontSize: 19,
    fontWeight: "800",
    color: "#242620"
  },
  date: {
    fontSize: 12,
    color: "#797c73"
  },
  stopRow: {
    flexDirection: "row",
    minHeight: 72
  },
  timelineColumn: {
    width: 24,
    alignItems: "center"
  },
  dot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: "#536b3b",
    marginTop: 5
  },
  line: {
    width: 2,
    flex: 1,
    backgroundColor: "#e3e5df",
    marginVertical: 4
  },
  stopContent: {
    flex: 1,
    paddingBottom: 14
  },
  stopTime: {
    fontSize: 12,
    fontWeight: "700",
    color: "#6d7167"
  },
  stopName: {
    marginTop: 2,
    fontSize: 17,
    fontWeight: "800",
    color: "#23251f"
  },
  stopCity: {
    marginTop: 2,
    fontSize: 13,
    color: "#7c7f76"
  },
  note: {
    marginTop: 6,
    fontSize: 14,
    lineHeight: 20,
    color: "#555950"
  }
});
