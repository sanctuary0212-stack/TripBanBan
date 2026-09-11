import type { ConfigContext, ExpoConfig } from "expo/config";

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: "TripBanBan",
  slug: "tripbanban",
  version: "0.1.0",
  orientation: "portrait",
  scheme: "tripbanban",
  userInterfaceStyle: "automatic",
  android: {
    package: "com.tripbanban.app",
    edgeToEdgeEnabled: true
  },
  extra: {
    ...config.extra,
    eas: process.env.EXPO_PROJECT_ID
      ? { projectId: process.env.EXPO_PROJECT_ID }
      : undefined
  }
});
