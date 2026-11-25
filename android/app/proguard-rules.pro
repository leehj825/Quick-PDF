# ML Kit text recognition: the Flutter plugin references the optional Chinese/Japanese/
# Korean/Devanagari recognizers. We bundle Latin (English) only, so ignore the rest.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
