/// Small explicit set of schematic icon shapes. These are semantic CSS/SVG
/// approximations, not extracted Material font outlines.
const nativeIconShapes = <String, String>{
  'data_usage_rounded':
      '<path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="M12 3a9 9 0 1 0 9 9M16 3a9 9 0 0 1 5 5"/>',
  'chevron_right_rounded':
      '<path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="m9 5 7 7-7 7"/>',
  'timer_outlined':
      '<circle cx="12" cy="14" r="8" fill="none" stroke="currentColor" stroke-width="2"/><path d="M9 1h6v2H9zM11 8h2v7h-2zM18 4l2 2-2 2-2-2z"/>',
  'emoji_events_outlined':
      '<path fill="none" stroke="currentColor" stroke-width="2" d="M7 3h10v6a5 5 0 0 1-10 0zM7 5H3v3a5 5 0 0 0 5 5m9-8h4v3a5 5 0 0 1-5 5m-4 1v6m-5 1h10"/>',
  'favorite':
      '<path d="M12 21C10 19 3 14 3 8a4.5 4.5 0 0 1 9-1 4.5 4.5 0 0 1 9 1c0 6-7 11-9 13Z"/>',
  'bedtime': '<path d="M20 15A9 9 0 0 1 9 4a9 9 0 1 0 11 11Z"/>',
  'directions_walk':
      '<circle cx="13" cy="4" r="2"/><path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="m7 12 3-4 4 1 3 4h3M11 9l-1 7-4 6m4-7 5 3v4"/>',
  'monitor_heart_rounded':
      '<path fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" d="M2 5h20v14H2zM2 12h5l2-4 4 9 2-5h7"/>',
};
