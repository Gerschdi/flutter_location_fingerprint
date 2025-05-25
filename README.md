# flutter\_location\_fingerprint

Eine Flutter-Bibliothek zur Ermittlung des Standorts anhand von WLAN- und BLE-Fingerprints.

## Installation

1. Öffne deine `pubspec.yaml` im Root-Verzeichnis deiner Flutter-App.

2. Füge folgende Zeilen unter `dependencies:` hinzu:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_location_fingerprint:
       git:
         url: https://github.com/Gerschdi/flutter_location_fingerprint
         ref: main
   ```

3. Führe im Terminal aus:

   ```bash
   flutter pub get
   ```

## Android-Berechtigungen

In deiner Datei `android/app/src/main/AndroidManifest.xml` müssen folgende Berechtigungen stehen:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>

<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
```

## Supabase-Verbindung und Standortabfrage

Importiere die benötigten Pakete:

```dart
import 'package:flutter_location_fingerprint/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
```

Initialisiere Supabase und verwende Platzhalter für URL und Anon-Key:

```dart
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: [supabase-url],
    anonKey: '[anonKey]',
  );
}
```

Rufe anschließend die Standortfunktionen auf:

```dart
Future<void> loadLocations() async {
  try {
    final wifiStandort = await getWifiStandort();
    final bleStandort = await getBleStandort();
    // Verwende die Rückgaben z.B. zum Anzeigen oder Speichern
    print('WLAN-Standort: \$wifiStandort');
    print('BLE-Standort: \$bleStandort');
  } catch (e) {
    print('Fehler beim Ermitteln des Standorts: \$e');
  }
}
```

## Fehlerbehandlung

Die Funktionen `getWifiStandort()` und `getBleStandort()` können Ausnahmen werfen. Verwende daher `try/catch`, um Fehler abzufangen und entsprechend zu reagieren.
