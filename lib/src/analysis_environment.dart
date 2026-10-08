import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
// Analyzer's public factory cannot configure conditional-import variables.
// Keep this internal API behind one adapter and pin the tested analyzer version.
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

/// A fixed JavaScript-web target, independent of the compiler's host platform.
/// Unknown project conditions fail explicitly rather than guessing their value.
const webAnalysisEnvironment = <String, String>{
  'dart.library.html': 'true',
  'dart.library.js': 'true',
  'dart.library.js_util': 'true',
  'dart.library.js_interop': 'true',
  'dart.library.io': 'false',
  'dart.library.ffi': 'false',
  'dart.library.isolate': 'false',
  'dart.library.ui': 'true',
};

AnalysisContextCollection webAnalysisContexts(String lib) =>
    AnalysisContextCollectionImpl(
      includedPaths: [lib],
      declaredVariables: webAnalysisEnvironment,
    );
