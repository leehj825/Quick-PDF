# ML Kit text recognition: the Flutter plugin references the optional Chinese/Japanese/
# Korean/Devanagari recognizers. We bundle Latin (English) only, so ignore the rest.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# WorkManager (pulled in by AdMob / ML Kit) builds its Room database reflectively at app
# start via androidx.startup. R8 must not strip or rename it, or the app crashes on launch
# ("Failed to create an instance of androidx.work.impl.WorkDatabase").
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.work.** { *; }
-keep class androidx.startup.** { *; }
