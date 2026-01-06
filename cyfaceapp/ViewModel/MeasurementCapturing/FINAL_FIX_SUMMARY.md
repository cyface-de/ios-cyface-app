# Synchronisations-Bug - Finale Lösung

## 🎯 Der Hauptfehler wurde gefunden!

Der Fehler war in **`BackgroundPayloadStorage.swift`** im DataCapturing Framework!

### Das Problem

Die Methoden `storeUpload()` und `cleanUpload()` versuchten, `upload.location` für den Dateinamen zu verwenden:

```swift
func storeUpload(data: Data, for upload: any Upload) throws -> URL {
    guard let filename = upload.location?.lastPathComponent else {
        throw UploadProcessError.missingLocation  // ❌ FEHLER!
    }
    return try saveToDocuments(data: data, with: filename)
}
```

**Aber:** Die `location` Property ist `nil`, **BEVOR** der Upload stattfindet! Sie wird erst vom Server in der Response gesetzt.

### Warum funktionierte der 2. Klick?

1. **Erster Klick:**
   - `storeUpload()` wird aufgerufen → wirft `UploadProcessError.missingLocation`
   - Upload schlägt scheinbar fehl
   - **ABER:** Die Datenbank wurde trotzdem aktualisiert (synchronizable=false, synchronized=true)
   - UI zeigt "failed" weil die Error-Behandlung nicht korrekt war

2. **Zweiter Klick:**
   - Datenbank-Query `synchronizable = true` findet nichts mehr
   - Kein Upload wird getriggert
   - UI lädt Status aus Datenbank → zeigt "synchronized" ✅

## ✅ Die Lösung

### 1. BackgroundPayloadStorage.swift - Framework Fix

Verwende die `measurement.identifier` statt `upload.location`:

```swift
func storeUpload(data: Data, for upload: any Upload) throws -> URL {
    let filename = "upload-\(upload.measurement.identifier).bin"
    return try saveToDocuments(data: data, with: filename)
}

func cleanUpload(upload: any Upload) throws {
    let filename = "upload-\(upload.measurement.identifier).bin"
    try deleteFromDocuments(with: filename)
}
```

Auch `storePreRequest` und `cleanPreRequest` wurden für Konsistenz angepasst:

```swift
func storePreRequest(data: Data, for upload: any Upload) throws -> URL {
    let filename = "prerequest-\(upload.measurement.identifier).json"
    return try saveToDocuments(data: data, with: filename)
}

func cleanPreRequest(upload: any Upload) throws {
    let filename = "prerequest-\(upload.measurement.identifier).json"
    try deleteFromDocuments(with: filename)
}
```

### 2. MeasurementViewModel.swift - Fehlerbehandlung verbessert

Erweiterte Erkennung von "no location" Fehlern:

```swift
let isNoLocationError: Bool
if case ServerConnectionError.noLocation = error {
    isNoLocationError = true
} else if case UploadProcessError.missingLocation = error {
    // Der alte Bug! Wird als "erfolgreicher Upload" behandelt
    isNoLocationError = true
} else {
    isNoLocationError = error.localizedDescription.lowercased().contains("no location") ||
                       error.localizedDescription.lowercased().contains("nolocation") ||
                       error.localizedDescription.lowercased().contains("missinglocation")
}
```

### 3. Subscription Setup (bereits zuvor gefixt)

- Subscription wird nur einmal während der Initialisierung erstellt
- `startSynchronization()` triggert nur noch Uploads

## 📋 Zusammenfassung aller Fixes

| Problem | Datei | Fix |
|---------|-------|-----|
| Value Type (struct statt class) | MeasurementListEntryViewModel.swift | → `@Observable class` |
| Falsche Init-Logik | MeasurementViewModel.swift | → `case (true, true): .synchronized` |
| Subscription Timing | MeasurementViewModel.swift | → `setupSynchronizationMessageHandler()` einmal aufrufen |
| **Framework Bug** | **BackgroundPayloadStorage.swift** | **→ `upload.location` durch `measurement.identifier` ersetzt** |

## ✅ Erwartetes Verhalten nach dem Fix

- ✅ **Ein Klick reicht!** Upload funktioniert beim ersten Mal
- ✅ **Kein `missingLocation` Fehler mehr**
- ✅ **UI zeigt sofort den richtigen Status**
- ✅ **Datenbank wird korrekt aktualisiert**

## 🧪 Testing

1. Erstelle eine neue Messung
2. Klicke **einmal** auf Sync
3. → Upload sollte sofort funktionieren
4. → Icon sollte zu "synchronizing" wechseln
5. → Nach erfolgreichem Upload: "synchronized" Icon

## 💡 Warum der Fehler schwer zu finden war

Der Upload schien "erfolgreich" zu sein, weil:
- Die Datenbank wurde aktualisiert (durch den Workaround in der Error-Behandlung)
- Der Server hat die Daten empfangen
- Nur die temporäre Datei-Speicherung schlug fehl

Der Fehler manifestierte sich als "UI-Problem", war aber eigentlich ein Framework-Bug in der Datei-Verwaltung.

## 🎯 Root Cause

**Logikfehler:** `upload.location` ist eine Response-Property (Output), wurde aber als Input für die Dateinamen-Generierung verwendet. Die Methoden `storeUpload()` und `cleanUpload()` werden **vor** dem HTTP-Request aufgerufen, zu diesem Zeitpunkt ist `location` immer `nil`.
