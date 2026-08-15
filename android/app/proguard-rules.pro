# Custom R8/ProGuard rules for release builds.
#
# Flutter's own plugin AARs (supabase_flutter, flutter_bloc's Android side,
# provider, file_picker, app_links, etc.) each ship their own consumer
# proguard rules bundled in the AAR, so R8 already keeps what those need
# without anything added here.
#
# If a release build (but not debug) ever crashes with something like
# ClassNotFoundException / NoSuchMethodError after this file is introduced,
# it means some class is being reached only via reflection and R8 stripped
# it. Fix by adding a targeted keep rule here, e.g.:
#   -keep class com.example.SomeClass { *; }
# rather than turning off shrinking — that defeats the point of this file.
